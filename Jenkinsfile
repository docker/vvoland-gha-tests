#!groovy
properties(
    [
        buildDiscarder(logRotator(artifactDaysToKeepStr: '', artifactNumToKeepStr: '', daysToKeepStr: '', numToKeepStr: '30')),
        parameters([
            string(name: 'DOCKER_CLI_REPO',          defaultValue: 'git@github.com:docker/cli.git',                 description: 'Docker CLI git source repository.'),
            string(name: 'DOCKER_CLI_REF',           defaultValue: 'master',                                        description: 'Docker CLI reference to build from (usually a branch).'),
            string(name: 'DOCKER_ENGINE_REPO',       defaultValue: 'git@github.com:moby/moby.git',                  description: 'Docker Engine git source repository.'),
            string(name: 'DOCKER_ENGINE_REF',        defaultValue: 'master',                                        description: 'Docker Engine reference to build from (usually a branch).'),
            string(name: 'DOCKER_PACKAGING_REPO',    defaultValue: 'git@github.com:docker/docker-ce-packaging.git', description: 'Packaging scripts git source repository.'),
            string(name: 'DOCKER_PACKAGING_REF',     defaultValue: 'master',                                        description: 'Packaging scripts reference to build from (usually a branch).'),
            string(name: 'VERSION',                  defaultValue: '0.0.0-dev',                                     description: 'Version used to build binaries and to tag Docker CLI/Docker Engine repositories'),
            booleanParam(name: 'RELEASE_STAGING',    defaultValue: false,                                           description: 'Trigger release to staging after a successful build'),
            booleanParam(name: 'RELEASE_PRODUCTION', defaultValue: false,                                           description: 'Trigger release to production after a successful build'),
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
// Check that VERSION parameter must be filled if we release
if ((params.RELEASE_STAGING || params.RELEASE_PRODUCTION ) && params.VERSION == "0.0.0-dev"){
    error("Build failed as this is a release but no VERSION has been set")
}
AWS_IMAGE = "dockereng/awscli:1.16.156"

awsCred = [
    $class           : 'AmazonWebServicesCredentialsBinding',
    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY',
    credentialsId    : 'docker-ci-artifacts'
]

def getS3Bucket() {
    withCredentials([string(credentialsId: 'AWS_DOCKER_CI_ARTIFACTS_S3_BUCKET', variable: 'awsBucket')]) {
        return awsBucket
    }
}

def saveS3(def Map args=[:]) {
    def destS3Uri = "s3://${getS3Bucket()}/${BUILD_TAG}/"
    def awscli_image = AWS_IMAGE
    def awscli = "docker run --rm -e AWS_SECRET_ACCESS_KEY -e AWS_ACCESS_KEY_ID -v `pwd`:/z -w /z ${awscli_image}"
    withCredentials([awsCred]) {
        sh("${awscli} s3 cp --only-show-errors '${args.name}' '${destS3Uri}'")
    }
}

def loadS3(def Map args=[:]) {
    def destS3Uri = "s3://${getS3Bucket()}/${BUILD_TAG}/${args.name}"
    def awscli_image = AWS_IMAGE
    def awscli = "docker run --rm -e AWS_SECRET_ACCESS_KEY -e AWS_ACCESS_KEY_ID -v `pwd`:/z -w /z ${awscli_image}"
    withCredentials([awsCred]) {
        sh("${awscli} s3 cp --only-show-errors  '${destS3Uri}' '${args.name}'")
    }
}

def genBuildResult() {
    def destS3Uri = "s3://${getS3Bucket()}/${BUILD_TAG}/"
    def awscli_image = AWS_IMAGE
    def awscli = "docker run --rm -e AWS_SECRET_ACCESS_KEY -e AWS_ACCESS_KEY_ID -v `pwd`:/z -w /z ${awscli_image}"
    withCredentials([awsCred]) {
        sh("${awscli} s3 ls '${destS3Uri}' > build-result.txt")
    }
}

def stashS3(def Map args=[:]) {
    def destS3Uri = "s3://${getS3Bucket()}/${BUILD_TAG}/"
    def awscli_image = AWS_IMAGE
    def awscli = "docker run --rm -e AWS_SECRET_ACCESS_KEY -e AWS_ACCESS_KEY_ID -v `pwd`:/z -w /z ${awscli_image}"
    sh("find . -path './${args.includes}' | tar -c -z -f '${args.name}.tar.gz' -T -")
    withCredentials([awsCred]) {
        sh("${awscli} s3 cp --only-show-errors '${args.name}.tar.gz' '${destS3Uri}'")
    }
    sh("rm -f '${args.name}.tar.gz'")
}

def unstashS3(def Map args=[:]) {
    def srcS3Uri = "s3://${getS3Bucket()}/${BUILD_TAG}/${args.name}.tar.gz"
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
            wrappedNode(label: 'amd64 && ubuntu-1804 && overlay2', cleanWorkspace: true) {
                announceChannel = "#ship-builders"
                // This is only the case on a nightly build
                if (env.BRANCH_NAME == 'ce-nightly') {
                    announceChannel = "#release-ci-feed"
                }
                if (params.RELEASE_PRODUCTION) {
                    slackSend(channel: announceChannel, message: "Initiating build pipeline. Building packages from `docker/cli:${params.DOCKER_CLI_REF}`, `docker/docker:${params.DOCKER_ENGINE_REF}`, `docker/docker-ce-packaging:${params.DOCKER_PACKAGING_REF}` for version `${params.VERSION}`. ${env.BUILD_URL}")
                }
                checkout scm
                sshagent(['docker-jenkins.github.ssh']) {
                    // Checkout source files from the CLI/ENGINE/PACKAGING repositories, tar them and upload it to S3 for further steps
                    sh """
                    make \
                        DOCKER_CLI_REF=${params.DOCKER_CLI_REF} DOCKER_CLI_REPO=${params.DOCKER_CLI_REPO} \
                        DOCKER_ENGINE_REF=${params.DOCKER_ENGINE_REF} DOCKER_ENGINE_REPO=${params.DOCKER_ENGINE_REPO} \
                        DOCKER_PACKAGING_REF=${params.DOCKER_PACKAGING_REF} DOCKER_PACKAGING_REPO=${params.DOCKER_PACKAGING_REPO} \
                        docker-ce.tar.gz
                    """
                }
                saveS3(name: 'docker-ce.tar.gz')
            }
        }
    }
]

def result_steps = [
    'result': { ->
        stage('result') {
            wrappedNode(label: 'amd64 && ubuntu-1804 && overlay2', cleanWorkspace: true) {
                checkout scm
                unstashS3(name: 'docker-ce')
                genBuildResult()
                // TODO: cli and engine packages should get their own git-commit listed. Temporarily using the "engine" commit
                sh('git -C docker-ce/engine rev-parse HEAD >> build-result.txt')
                saveS3(name: 'build-result.txt')
                slackSend(channel: "#release-ci-feed", message: "Docker CE (cli: `${params.DOCKER_CLI_REF}`, engine: `${params.DOCKER_ENGINE_REF}`, packaging: `${params.DOCKER_PACKAGING_REF}`, version: `${params.VERSION}`) https://s3.us-east-1.amazonaws.com/${getS3Bucket()}/${BUILD_TAG}/build-result.txt")
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
    aarch64: [label: "aarch64",        arch: "aarch64"],
    amd64 :  [label: "x86_64&&ubuntu", arch: "amd64"],
    armv6l : [label: "armhf",          arch: "armel"],
    armv7l : [label: "armhf",          arch: "armhf"],
    ppc64le: [label: "ppc64le",        arch: "ppc64le"],
    s390x  : [label: "s390x",          arch: "s390x"],
    x86_64 : [label: "x86_64&&ubuntu", arch: "amd64"],
]

def pkgs = [
    [target: "centos-7",                 image: "centos:7",                               arches: ["amd64", "aarch64"]],          // (EOL: June 30, 2024)
    [target: "centos-8",                 image: "centos:8",                               arches: ["amd64", "aarch64"]],
    [target: "rhel-7",                   image: "dockereng/rhel:7-s390x",                 arches: ["s390x"]],
    [target: "debian-stretch",           image: "debian:stretch",                         arches: ["amd64", "aarch64", "armhf"]], // Debian 9  (EOL: June, 2022)
    [target: "debian-buster",            image: "debian:buster",                          arches: ["amd64", "aarch64", "armhf"]], // Debian 10 (EOL: 2024)
    [target: "fedora-30",                image: "fedora:30",                              arches: ["amd64", "aarch64"]],
    [target: "fedora-31",                image: "fedora:31",                              arches: ["amd64", "aarch64"]],
    [target: "raspbian-stretch",         image: "balenalib/rpi-raspbian:stretch",         arches: ["armhf"]],
    [target: "raspbian-buster",          image: "balenalib/rpi-raspbian:buster",          arches: ["armhf"]],
    [target: "ubuntu-xenial",            image: "ubuntu:xenial",                          arches: ["amd64", "aarch64", "armhf"]],          // Ubuntu 16.04 LTS (End of support: April, 2021. EOL: April, 2024)
    [target: "ubuntu-bionic",            image: "ubuntu:bionic",                          arches: ["amd64", "aarch64", "armhf", "s390x"]], // Ubuntu 18.04 LTS (End of support: April, 2023. EOL: April, 2028)
    [target: "ubuntu-eoan",              image: "ubuntu:eoan",                            arches: ["amd64", "aarch64", "armhf"]],          // Ubuntu 19.10 (EOL: July, 2020)
]

def genBuildStep(LinkedHashMap pkg, String arch) {
    def nodeLabel = "linux&&${arch}"
    return { ->
        stage("${pkg.target}-${arch}") {
            retry(3) {
                wrappedNode(label: nodeLabel, cleanWorkspace: true) {
                    checkout scm
                    unstashS3(name: 'docker-ce')
                    def buildImage = pkg.image
                    withDockerRegistry([url: "", credentialsId: "dockerbuildbot-index.docker.io"]) {
                        sh """
                        make clean
                        make VERSION=${params.VERSION} ${pkg.target}
                        make VERSION=${params.VERSION} bundles-ce-${pkg.target}-${arch}.tar.gz
                        docker run --rm -i -v \"\$(pwd):/v\" -w /v ${buildImage} ./verify
                        """
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
                    sh """
                    make clean
                    make VERSION=${params.VERSION} docker-${config.arch}.tgz
                    """
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
                wrappedNode(label: 'amd64 && ubuntu-1804 && overlay2', cleanWorkspace: true) {
                    checkout scm
                    unstashS3(name: 'docker-ce')
                    sh """
                    make clean
                    make VERSION=${params.VERSION} cross-mac
                    make VERSION=${params.VERSION} bundles-ce-cross-darwin.tar.gz
                    make docker-mac.tgz
                    """
                    saveS3(name: 'bundles-ce-cross-darwin.tar.gz')
                    saveS3(name: 'docker-mac.tgz')
                }
            }
        }
    },
    'cross-win'         : { ->
        stage('cross-win') {
            retry(3) {
                wrappedNode(label: 'amd64 && ubuntu-1804 && overlay2', cleanWorkspace: true) {
                    checkout scm
                    unstashS3(name: 'docker-ce')
                    sh """
                    make clean
                    make VERSION=${params.VERSION} cross-win
                    make VERSION=${params.VERSION} bundles-ce-cross-windows.tar.gz
                    make docker-win.zip
                    """
                    saveS3(name: 'bundles-ce-cross-windows.tar.gz')
                    saveS3(name: 'docker-win.zip')
                }
            }
        }
    },
    'shell-completion'  : { ->
        stage('shell-completion') {
            retry(3) {
                wrappedNode(label: 'amd64 && ubuntu-1804 && overlay2', cleanWorkspace: true) {
                    checkout scm
                    unstashS3(name: 'docker-ce')
                    sh """
                    make clean
                    make VERSION=${params.VERSION} bundles-ce-shell-completion.tar.gz
                    """
                    saveS3(name: 'bundles-ce-shell-completion.tar.gz')
                }
            }
        }
    },
    'bundles-ce-binary' : { ->
        stage('bundles-ce-binary') {
            retry(3) {
                wrappedNode(label: 'amd64 && ubuntu-1804 && overlay2', cleanWorkspace: true) {
                    checkout scm
                    unstashS3(name: 'docker-ce')
                    sh """
                    make clean
                    make VERSION=${params.VERSION} static-linux
                    make VERSION=${params.VERSION} bundles-ce-binary.tar.gz
                    """
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
