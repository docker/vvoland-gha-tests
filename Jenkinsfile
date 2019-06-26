#!groovy
properties(
    [
        buildDiscarder(logRotator(artifactDaysToKeepStr: '', artifactNumToKeepStr: '', daysToKeepStr: '', numToKeepStr: '30')),
        parameters([
            string(name: 'DOCKER_CE_REPO', defaultValue: 'git@github.com:docker/docker-ce.git', description: 'Docker git source repository.'),
            string(name: 'DOCKER_CE_REF', defaultValue: 'master', description: 'Docker CE reference to build from (usually a branch).'),
            booleanParam(name: 'RELEASE_STAGING', description: 'Trigger release to staging after a successful build', defaultValue: false),
            booleanParam(name: 'RELEASE_PRODUCTION', description: 'Trigger release to production after a successful build', defaultValue: false),
        ])
    ]
)

BUILD_TAG="${env.BUILD_TAG}"
STAGING = params.RELEASE_STAGING
PROD = params.RELEASE_PRODUCTION
// Releasing to staging must always happen before a release to production
if (params.RELEASE_PRODUCTION) {
    STAGING = true
}


def saveS3(def Map args=[:]) {
    def destS3Uri = "s3://docker-ci-artifacts/ci.qa.aws.dckr.io/${BUILD_TAG}/"
    def awscli = "docker run --rm -e AWS_SECRET_ACCESS_KEY -e AWS_ACCESS_KEY_ID -v `pwd`:/z -w /z ${args.awscli_image}"
    withCredentials([[
         $class           : 'AmazonWebServicesCredentialsBinding',
         accessKeyVariable: 'AWS_ACCESS_KEY_ID',
         secretKeyVariable: 'AWS_SECRET_ACCESS_KEY',
         credentialsId    : 'ci@docker-qa.aws'
     ]]) {
        sh("${awscli} s3 cp --only-show-errors '${args.name}' '${destS3Uri}'")
    }
}

def loadS3(def Map args=[:]) {
    def destS3Uri = "s3://docker-ci-artifacts/ci.qa.aws.dckr.io/${BUILD_TAG}/${args.name}"
    def awscli = "docker run --rm -e AWS_SECRET_ACCESS_KEY -e AWS_ACCESS_KEY_ID -v `pwd`:/z -w /z ${args.awscli_image}"
    withCredentials([[
        $class: 'AmazonWebServicesCredentialsBinding',
        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY',
        credentialsId: 'ci@docker-qa.aws'
    ]]) {
        sh("${awscli} s3 cp --only-show-errors  '${destS3Uri}' '${args.name}'")
    }
}

def genBuildResult(def Map args=[:]) {
    def destS3Uri = "s3://docker-ci-artifacts/ci.qa.aws.dckr.io/${BUILD_TAG}/"
    def awscli = "docker run --rm -e AWS_SECRET_ACCESS_KEY -e AWS_ACCESS_KEY_ID -v `pwd`:/z -w /z ${args.awscli_image}"
    withCredentials([[
        $class: 'AmazonWebServicesCredentialsBinding',
        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY',
        credentialsId: 'ci@docker-qa.aws'
    ]]) {
        sh("${awscli} s3 ls '${destS3Uri}' > build-result.txt")
    }
}

def stashS3(def Map args=[:]) {
    def destS3Uri = "s3://docker-ci-artifacts/ci.qa.aws.dckr.io/${BUILD_TAG}/"
    def awscli = "docker run --rm -e AWS_SECRET_ACCESS_KEY -e AWS_ACCESS_KEY_ID -v `pwd`:/z -w /z ${args.awscli_image}"
    sh("find . -path './${args.includes}' | tar -c -z -f '${args.name}.tar.gz' -T -")
    withCredentials([[
        $class: 'AmazonWebServicesCredentialsBinding',
        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY',
        credentialsId: 'ci@docker-qa.aws'
    ]]) {
        sh("${awscli} s3 cp --only-show-errors '${args.name}.tar.gz' '${destS3Uri}'")
    }
    sh("rm -f '${args.name}.tar.gz'")
}

def unstashS3(def Map args=[:]) {
    def awscli = "docker run --rm -e AWS_SECRET_ACCESS_KEY -e AWS_ACCESS_KEY_ID -v `pwd`:/z -w /z ${args.awscli_image}"
    def srcS3Uri = "s3://docker-ci-artifacts/ci.qa.aws.dckr.io/${BUILD_TAG}/${args.name}.tar.gz"
    withCredentials([[
        $class: 'AmazonWebServicesCredentialsBinding',
        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY',
        credentialsId: 'ci@docker-qa.aws'
    ]]) {
        sh("${awscli} s3 cp --only-show-errors '${srcS3Uri}' .")
    }
    sh("tar -x -z -f '${args.name}.tar.gz'")
    sh("rm -f '${args.name}.tar.gz'")
}

DEFAULT_AWS_IMAGE = "anigeo/awscli@sha256:f4685e66230dcb77c81dc590140aee61e727936cf47e8f4f19a427fc851844a1"

def init_steps = [
    'init': { ->
        stage('init') {
            wrappedNode(label: 'aufs', cleanWorkspace: true) {
                announceChannel = "#ship-builders"
                // This is only the case on a nightly build
                if (env.BRANCH_NAME == 'ce-nightly') {
                    announceChannel = "#release-ci-feed"
                }
                if (params.RELEASE_PRODUCTION) {
                    slackSend(channel: announceChannel, message: "Initiating build pipeline. Building packages from `docker/docker-ce:${params.DOCKER_CE_REF}`. ${env.BUILD_URL}")
                }
                checkout scm
                sshagent(['docker-jenkins.github.ssh']) {
                    sh("make DOCKER_CE_REF=${params.DOCKER_CE_REF} DOCKER_CE_REPO=${params.DOCKER_CE_REPO} docker-ce.tar.gz")
                }
                saveS3(name: 'docker-ce.tar.gz', awscli_image: DEFAULT_AWS_IMAGE)
            }
        }
    }
]

def result_steps = [
    'result': { ->
        stage('result') {
            wrappedNode(label: 'aufs', cleanWorkspace: true) {
                checkout scm
                unstashS3(name: 'docker-ce', awscli_image: DEFAULT_AWS_IMAGE)
                genBuildResult(awscli_image: DEFAULT_AWS_IMAGE)
                sh('git -C docker-ce rev-parse HEAD >> build-result.txt')
                saveS3(name: 'build-result.txt', awscli_image: DEFAULT_AWS_IMAGE)
                // upload supported file to our s3 bucket
                saveS3(name: 'supported', awscli_image: DEFAULT_AWS_IMAGE)
                slackSend(channel: "#release-ci-feed", message: "Docker CE ${params.DOCKER_CE_REF} https://s3-us-west-2.amazonaws.com/docker-ci-artifacts/ci.qa.aws.dckr.io/${BUILD_TAG}/build-result.txt")
                if (params.RELEASE_STAGING || params.RELEASE_PRODUCTION) {
                    // Triggers builds to go through to staging and/or production
                    build(
                        job: "docker/release-repo/ce",
                        parameters: [
                            [$class: 'StringParameterValue', name: 'ARTIFACT_BUILD_TAG', value: "${BUILD_TAG}"],
                            [$class: 'BooleanParameterValue', name: 'RELEASE_STAGING', value: STAGING],
                            [$class: 'BooleanParameterValue', name: 'RELEASE_PRODUCTION', value: PROD],
                        ],
                        wait: false,
                    )
                }
            }
        }
    }
]

archConfig = [
    x86_64 : [label: "x86_64&&ubuntu", awscli_image: DEFAULT_AWS_IMAGE, arch: "amd64"],
    armv6l : [label: "armhf", awscli_image: "seemethere/awscli-armhf@sha256:2a92eebed76e3e82f3899c6851cfaf8b7eb26d08cabcb5938dfcd66115d37977", arch: "armel"],
    armv7l : [label: "armhf", awscli_image: "seemethere/awscli-armhf@sha256:2a92eebed76e3e82f3899c6851cfaf8b7eb26d08cabcb5938dfcd66115d37977", arch: "armhf"],
    s390x  : [label: "s390x", awscli_image: "seemethere/awscli-s390x@sha256:198e47b58a868784bce929a1c8dc8a25c521f9ce102a3eb0aa2094d44c241c03", arch: "s390x"],
    ppc64le: [label: "ppc64le", awscli_image: "seemethere/awscli-ppc64le@sha256:1f46b7687cc70bbf4f9bcf67c5e779b65c67088f1a946c9759be470a41da06d7", arch: "ppc64le"],
    aarch64: [label: "aarch64", awscli_image: "seemethere/awscli-aarch64@sha256:2d646ae12278006a710f74e57c27e23fb73eee027f237ab72ebb02ef66a447b9", arch: "aarch64"],
]

def genBuildStep(String supportedString) {
    // since historically we've named our stuff after the dpkg --print-architecture string we're bound by this
    def uname_arch = supportedString.tokenize('-')[0]        // get first part of the string
    def distro_flavor = supportedString - (uname_arch + "-") // grab distro_flavor by deleting the arch from original string
    def config = archConfig[uname_arch]
    return [ "${distro_flavor}-${config.arch}" : { ->
        stage("${distro_flavor}-${config.arch}") {
            retry(3) {
                wrappedNode(label: config.label, cleanWorkspace: true) {
                    checkout scm
                    unstashS3(name: 'docker-ce', awscli_image: config.awscli_image)
                    loadS3(name: "engine-${uname_arch}-docker-compat.tar", awscli_image: config.awscli_image)
                    loadS3(name: "engine-${uname_arch}-dm-docker-compat.tar", awscli_image: config.awscli_image)
                    sh("make clean ${distro_flavor} bundles-ce-${distro_flavor}-${config.arch}.tar.gz")
                    saveS3(name: "bundles-ce-${distro_flavor}-${config.arch}.tar.gz", awscli_image: config.awscli_image)
                }
            }
        }
    } ]
}

def genSaveDockerImage(String arch) {
    def config = archConfig[arch]
    return [ "image-ce-binary-${arch}": { ->
        stage("image-ce-binary-${arch}") {
            retry(3) {
                wrappedNode(label: config.label, cleanWorkspace: true) {
                    checkout scm
                    def MAKE = "make -C docker-ce/components/packaging/image ENGINE_IMAGE=engine-community DOCKER_HUB_ORG=dockereng"
                    unstashS3(name: 'docker-ce', awscli_image: config.awscli_image)
                    sh("${MAKE} clean engine-${arch}.tar")
                    saveS3(name: "docker-ce/components/packaging/image/engine-${arch}.tar", awscli_image: config.awscli_image)
                    saveS3(name: "docker-ce/components/packaging/image/engine-${arch}-docker-compat.tar", awscli_image: config.awscli_image)
                    // TODO: make engine-${arch}.tar clean up the `artifacts/engine-image` directory
                    // Is this an awful way to do it? Yeah but we don't really have a choice without making a change upstream
                    sh("${MAKE} clean engine-${arch}-dm.tar")
                    saveS3(name: "docker-ce/components/packaging/image/engine-${arch}-dm.tar", awscli_image: config.awscli_image)
                    saveS3(name: "docker-ce/components/packaging/image/engine-${arch}-dm-docker-compat.tar", awscli_image: config.awscli_image)
                }
            }
        }
    }]
}

def genStaticBuildStep(String uname_arch) {
    def config = archConfig[uname_arch]
    return [ "static-linux-${config.arch}": { ->
        stage("static-linux-${config.arch}") {
            retry(3) {
                wrappedNode(label: config.label, cleanWorkspace: true) {
                    checkout scm
                    unstashS3(name: 'docker-ce', awscli_image: config.awscli_image)
                    sh("make clean docker-${config.arch}.tgz")
                    saveS3(name: "docker-${config.arch}.tgz", awscli_image: config.awscli_image)
                    saveS3(name: "docker-rootless-extras-${config.arch}.tgz", awscli_image: config.awscli_image)
                }
            }
        }
    }]
}

def build_package_steps = [
    'cross-mac'         : { ->
        stage('cross-mac') {
            retry(3) {
                wrappedNode(label: 'aufs', cleanWorkspace: true) {
                    checkout scm
                    unstashS3(name: 'docker-ce', awscli_image: DEFAULT_AWS_IMAGE)
                    sh('make clean cross-mac bundles-ce-cross-darwin.tar.gz docker-mac.tgz')
                    saveS3(name: 'bundles-ce-cross-darwin.tar.gz', awscli_image: DEFAULT_AWS_IMAGE)
                    saveS3(name: 'docker-mac.tgz', awscli_image: DEFAULT_AWS_IMAGE)
                }
            }
        }
    },
    'cross-win'         : { ->
        stage('cross-win') {
            retry(3) {
                wrappedNode(label: 'aufs', cleanWorkspace: true) {
                    checkout scm
                    unstashS3(name: 'docker-ce', awscli_image: DEFAULT_AWS_IMAGE)
                    sh('make clean cross-win bundles-ce-cross-windows.tar.gz docker-win.zip')
                    saveS3(name: 'bundles-ce-cross-windows.tar.gz', awscli_image: DEFAULT_AWS_IMAGE)
                    saveS3(name: 'docker-win.zip', awscli_image: DEFAULT_AWS_IMAGE)
                }
            }
        }
    },
    'shell-completion'  : { ->
        stage('shell-completion') {
            retry(3) {
                wrappedNode(label: 'aufs', cleanWorkspace: true) {
                    checkout scm
                    unstashS3(name: 'docker-ce', awscli_image: DEFAULT_AWS_IMAGE)
                    sh('make clean bundles-ce-shell-completion.tar.gz')
                    saveS3(name: 'bundles-ce-shell-completion.tar.gz', awscli_image: DEFAULT_AWS_IMAGE)
                }
            }
        }
    },
    'bundles-ce-binary' : { ->
        stage('bundles-ce-binary') {
            retry(3) {
                wrappedNode(label: 'aufs', cleanWorkspace: true) {
                    checkout scm
                    unstashS3(name: 'docker-ce', awscli_image: DEFAULT_AWS_IMAGE)
                    sh('make clean static-linux bundles-ce-binary.tar.gz')
                    saveS3(name: 'bundles-ce-binary.tar.gz', awscli_image: DEFAULT_AWS_IMAGE)
                }
            }
        }
    },
]

def static_arches = [
    "x86_64",
    "armv6l",
    "armv7l",
    // "s390x",
    //"ppc64le",
    "aarch64"
]
post_init_steps = [:]

for (arch in static_arches) {
    build_package_steps << genStaticBuildStep(arch)
    if ( arch != "armv6l" ) {
        post_init_steps << genSaveDockerImage(arch)
    }
}

stage("generate package steps") {
    wrappedNode(label: "x86_64&&ubuntu", cleanWorkspace: true) {
        checkout scm
        supported = readFile("supported")
        for (String line : supported.split("\n")) {
            build_package_steps << genBuildStep(line)
        }
    }
}

try {
    // post_init_steps build the docker images
    // and saves the tar
    // these steps need to be run after the init step because that
    // is when the docker-ce tar is available and before the build_package_steps
    // because some of those steps rely on the image tar
    parallel(init_steps)
    parallel(post_init_steps)
    parallel(build_package_steps)
    parallel(result_steps)
} catch (err) {
    def failChannel = "#release-announce-test"
    def notify = ""
    if (params.RELEASE_STAGING || params.RELEASE_PRODUCTION) {
        failChannel = "#release-ci-feed"
        notify = "@sf-release-eng"
    }
    slackSend(channel: failChannel, color: 'danger', message: "${notify}Release Packaging job ${env.JOB_NAME} failed. ${env.BUILD_URL}")
    throw err
}
