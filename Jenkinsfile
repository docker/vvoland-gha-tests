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
AWS_IMAGE = "dockereng/awscli:1.16.156"

awsCred = [
    $class           : 'AmazonWebServicesCredentialsBinding',
    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY',
    credentialsId    : 'ci@docker-qa.aws'
]

def saveS3(def Map args=[:]) {
    def destS3Uri = "s3://docker-ci-artifacts/ci.qa.aws.dckr.io/${BUILD_TAG}/"
    def awscli_image = AWS_IMAGE
    def awscli = "docker run --rm -e AWS_SECRET_ACCESS_KEY -e AWS_ACCESS_KEY_ID -v `pwd`:/z -w /z ${awscli_image}"
    withCredentials([awsCred]) {
        sh("${awscli} s3 cp --only-show-errors '${args.name}' '${destS3Uri}'")
    }
}

def loadS3(def Map args=[:]) {
    def destS3Uri = "s3://docker-ci-artifacts/ci.qa.aws.dckr.io/${BUILD_TAG}/${args.name}"
    def awscli_image = AWS_IMAGE
    def awscli = "docker run --rm -e AWS_SECRET_ACCESS_KEY -e AWS_ACCESS_KEY_ID -v `pwd`:/z -w /z ${awscli_image}"
    withCredentials([awsCred]) {
        sh("${awscli} s3 cp --only-show-errors  '${destS3Uri}' '${args.name}'")
    }
}

def genBuildResult() {
    def destS3Uri = "s3://docker-ci-artifacts/ci.qa.aws.dckr.io/${BUILD_TAG}/"
    def awscli_image = AWS_IMAGE
    def awscli = "docker run --rm -e AWS_SECRET_ACCESS_KEY -e AWS_ACCESS_KEY_ID -v `pwd`:/z -w /z ${awscli_image}"
    withCredentials([awsCred]) {
        sh("${awscli} s3 ls '${destS3Uri}' > build-result.txt")
    }
}

def stashS3(def Map args=[:]) {
    def destS3Uri = "s3://docker-ci-artifacts/ci.qa.aws.dckr.io/${BUILD_TAG}/"
    def awscli_image = AWS_IMAGE
    def awscli = "docker run --rm -e AWS_SECRET_ACCESS_KEY -e AWS_ACCESS_KEY_ID -v `pwd`:/z -w /z ${awscli_image}"
    sh("find . -path './${args.includes}' | tar -c -z -f '${args.name}.tar.gz' -T -")
    withCredentials([awsCred]) {
        sh("${awscli} s3 cp --only-show-errors '${args.name}.tar.gz' '${destS3Uri}'")
    }
    sh("rm -f '${args.name}.tar.gz'")
}

def unstashS3(def Map args=[:]) {
    def srcS3Uri = "s3://docker-ci-artifacts/ci.qa.aws.dckr.io/${BUILD_TAG}/${args.name}.tar.gz"
    def awscli_image = AWS_IMAGE
    def awscli = "docker run --rm -e AWS_SECRET_ACCESS_KEY -e AWS_ACCESS_KEY_ID -v `pwd`:/z -w /z ${awscli_image}"
    withCredentials([awsCred]) {
        sh("${awscli} s3 cp --only-show-errors '${srcS3Uri}' .")
    }
    sh("tar -x -z -f '${args.name}.tar.gz'")
    sh("rm -f '${args.name}.tar.gz'")
}

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
                saveS3(name: 'docker-ce.tar.gz')
            }
        }
    }
]

def result_steps = [
    'result': { ->
        stage('result') {
            wrappedNode(label: 'aufs', cleanWorkspace: true) {
                checkout scm
                unstashS3(name: 'docker-ce')
                genBuildResult()
                sh('git -C docker-ce rev-parse HEAD >> build-result.txt')
                saveS3(name: 'build-result.txt')
                slackSend(channel: "#release-ci-feed", message: "Docker CE ${params.DOCKER_CE_REF} https://s3-us-west-2.amazonaws.com/docker-ci-artifacts/ci.qa.aws.dckr.io/${BUILD_TAG}/build-result.txt")
                if (params.RELEASE_STAGING || params.RELEASE_PRODUCTION) {
                    // Triggers builds to go through to staging and/or production
                    build(
                        job: "release-repo/ce",
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
    x86_64 : [label: "x86_64&&ubuntu", arch: "amd64"],
    amd64 :  [label: "x86_64&&ubuntu", arch: "amd64"],
    armv6l : [label: "armhf",          arch: "armel"],
    armv7l : [label: "armhf",          arch: "armhf"],
    s390x  : [label: "s390x",          arch: "s390x"],
    ppc64le: [label: "ppc64le",        arch: "ppc64le"],
    aarch64: [label: "aarch64",        arch: "aarch64"],
]

def arches = ["amd64", "armhf", "aarch64"]

def pkgs = [
    [target: "ubuntu-xenial",            image: "ubuntu:xenial",                          arches: arches],
    [target: "ubuntu-bionic",            image: "ubuntu:bionic",                          arches: arches],
// TODO re-enable eoan once containerd.io packages are available
//     [target: "ubuntu-eoan",              image: "ubuntu:eoan",                            arches: arches],
    [target: "debian-buster",            image: "debian:buster",                          arches: arches],
    [target: "debian-stretch",           image: "debian:stretch",                         arches: arches],
    [target: "fedora-31",                image: "fedora:31",                              arches: arches - ["armhf"]],
    [target: "fedora-30",                image: "fedora:30",                              arches: arches - ["armhf"]],
    [target: "fedora-29",                image: "fedora:29",                              arches: arches - ["armhf"]],
    [target: "centos-7",                 image: "centos:7",                               arches: arches - ["armhf"]],
    [target: "raspbian-buster",          image: "resin/rpi-raspbian:buster",              arches: arches - ["amd64", "aarch64"]],
    [target: "raspbian-stretch",         image: "resin/rpi-raspbian:stretch",             arches: arches - ["amd64", "aarch64"]],

]

def genBuildStep(LinkedHashMap pkg, String arch) {
    def nodeLabel = "linux&&${arch}"
    return { ->
        stage("${pkg.target}-${arch}") {
            retry(3) {
                wrappedNode(label: nodeLabel, cleanWorkspace: true) {
                    checkout scm
                    unstashS3(name: 'docker-ce')
                    sshagent(['docker-jenkins.github.ssh']) {
                        def buildImage = pkg.image
                        sh("make clean ${pkg.target} bundles-ce-${pkg.target}-${arch}.tar.gz")
                        sh("docker run --rm -i -v \"\$(pwd):/v\" -w /v ${buildImage} ./verify")
                    }
                    saveS3(name: "bundles-ce-${pkg.target}-${arch}.tar.gz")
                }
            }
        }
    }
}

def genStaticBuildStep(String uname_arch) {
    def config = archConfig[uname_arch]
    return [ "static-linux-${config.arch}": { ->
        stage("static-linux-${config.arch}") {
            retry(3) {
                wrappedNode(label: config.label, cleanWorkspace: true) {
                    checkout scm
                    unstashS3(name: 'docker-ce')
                    sh("make clean docker-${config.arch}.tgz")
                    saveS3(name: "docker-${config.arch}.tgz")
                    saveS3(name: "docker-rootless-extras-${config.arch}.tgz")
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
                    unstashS3(name: 'docker-ce')
                    sh('make clean cross-mac bundles-ce-cross-darwin.tar.gz docker-mac.tgz')
                    saveS3(name: 'bundles-ce-cross-darwin.tar.gz')
                    saveS3(name: 'docker-mac.tgz')
                }
            }
        }
    },
    'cross-win'         : { ->
        stage('cross-win') {
            retry(3) {
                wrappedNode(label: 'aufs', cleanWorkspace: true) {
                    checkout scm
                    unstashS3(name: 'docker-ce')
                    sh('make clean cross-win bundles-ce-cross-windows.tar.gz docker-win.zip')
                    saveS3(name: 'bundles-ce-cross-windows.tar.gz')
                    saveS3(name: 'docker-win.zip')
                }
            }
        }
    },
    'shell-completion'  : { ->
        stage('shell-completion') {
            retry(3) {
                wrappedNode(label: 'aufs', cleanWorkspace: true) {
                    checkout scm
                    unstashS3(name: 'docker-ce')
                    sh('make clean bundles-ce-shell-completion.tar.gz')
                    saveS3(name: 'bundles-ce-shell-completion.tar.gz')
                }
            }
        }
    },
    'bundles-ce-binary' : { ->
        stage('bundles-ce-binary') {
            retry(3) {
                wrappedNode(label: 'aufs', cleanWorkspace: true) {
                    checkout scm
                    unstashS3(name: 'docker-ce')
                    sh('make clean static-linux bundles-ce-binary.tar.gz')
                    saveS3(name: 'bundles-ce-binary.tar.gz')
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

for (arch in static_arches) {
    build_package_steps << genStaticBuildStep(arch)
}

def genPackageSteps(opts) {
    return opts.arches.collectEntries {
        ["${opts.image}-${it}": genBuildStep(opts, it)]
    }
}

build_package_steps << pkgs.collectEntries { genPackageSteps(it) }

try {
    parallel(init_steps)
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
