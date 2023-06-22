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
            string(name: 'VERSION',                  defaultValue: '0.0.0-dev',                                     description: 'Version used to build binaries and to tag Docker CLI/Docker Engine repositories when doing a release to production, e.g. "20.10.6" (no v-prefix). Required when releasing Docker'),
            string(name: 'CONTAINERD_VERSION',       defaultValue: '',                                              description: 'Containerd version to build for the static packages. Leave empty to build the default version as specified in the Dockerfile in moby/moby.'),
            string(name: 'RUNC_VERSION',             defaultValue: '',                                              description: 'Runc version to build for the static packages. Leave empty to build the default version as specified in the Dockerfile in moby/moby.'),
            booleanParam(name: 'SKIP_VERIFY',        defaultValue: false,                                           description: 'Skip package verification. Use this when testing builds of a new distro for which no containerd.io packages are available yet.'),
            string(name: 'VERIFY_PACKAGE_REPO',      defaultValue: 'prod',                                          description: 'Packaging repo to use for installing dependencies (stage=download-stage.docker.com or prod=download.docker.com (default))'),
        ])
    ]
)

BUILD_TAG="${env.BUILD_TAG}"
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

def genBuildResult() {
    def destS3Uri = "s3://${getS3Bucket()}/${BUILD_TAG}/"
    def awscli_image = AWS_IMAGE
    def awscli = "docker run --rm -e AWS_SECRET_ACCESS_KEY -e AWS_ACCESS_KEY_ID -v `pwd`:/z -w /z ${awscli_image}"
    withCredentials([awsCred]) {
        sh("${awscli} s3 ls '${destS3Uri}' > build-result.txt")
    }
}

def init_steps = [
    'init': { ->
        stage('init') {
            wrappedNode(label: 'amd64 && overlay2') {
                if (env.BRANCH_NAME != 'ce-nightly' && params.VERSION != '0.0.0-dev') {
                    slackSend(channel: "#release", message: "Initiating build pipeline. Building packages from `docker/cli:${params.DOCKER_CLI_REF}`, `docker/docker:${params.DOCKER_ENGINE_REF}`, `docker/docker-ce-packaging:${params.DOCKER_PACKAGING_REF}` for version `${params.VERSION}`. ${env.BUILD_URL}")
                }
            }
        }
    }
]

def result_steps = [
    'result': { ->
        stage('result') {
            wrappedNode(label: 'amd64 && overlay2', cleanWorkspace: true) {
                checkout scm
                genBuildResult()

                // Append the git commit information of docker and cli to build-result.txt
                sshagent(['docker-jenkins.github.ssh']) {
                    sh """
                    make clean
                    make build-result.txt
                    """
                }
                saveS3(name: 'build-result.txt')
                // Note: gen-static-ver only adds git commit and git date info to a `*-dev` version, in which case the CLI's git is used.
                // TODO do we use this VERSION file anywhere? Should this be part of build-result.txt as well?
                sh("./packaging/static/gen-static-ver packaging/src/github.com/docker/cli '${params.VERSION}' > VERSION")
                saveS3(name: 'VERSION')
                slackSend(channel: "#release", message: "Docker CE (cli: `${params.DOCKER_CLI_REF}`, engine: `${params.DOCKER_ENGINE_REF}`, packaging: `${params.DOCKER_PACKAGING_REF}`, version: `${params.VERSION}`) https://s3.us-east-1.amazonaws.com/${getS3Bucket()}/${BUILD_TAG}/build-result.txt")
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
    [target: "centos-8",                 image: "quay.io/centos/centos:stream8",          arches: ["amd64", "aarch64"]],
    [target: "centos-9",                 image: "quay.io/centos/centos:stream9",          arches: ["amd64", "aarch64"]],
    [target: "debian-buster",            image: "debian:buster",                          arches: ["amd64", "aarch64", "armhf"]], // Debian 10 (EOL: 2024)
    [target: "debian-bullseye",          image: "debian:bullseye",                        arches: ["amd64", "aarch64", "armhf"]], // Debian 11 (stable)
    [target: "debian-bookworm",          image: "debian:bookworm",                        arches: ["amd64", "aarch64", "armhf"]], // Debian 12 (Next stable)
    [target: "fedora-37",                image: "fedora:37",                              arches: ["amd64", "aarch64"]],          // EOL: November 14, 2023
    [target: "fedora-38",                image: "fedora:38",                              arches: ["amd64", "aarch64"]],          // EOL: May 14, 2024
    [target: "raspbian-buster",          image: "balenalib/rpi-raspbian:buster",          arches: ["armhf"]],                     // Debian/Raspbian 10 (EOL: 2024)
    [target: "raspbian-bullseye",        image: "balenalib/rpi-raspbian:bullseye",        arches: ["armhf"]],                     // Debian/Raspbian 11 (stable)
    [target: "raspbian-bookworm",        image: "balenalib/rpi-raspbian:bookworm",        arches: ["armhf"]],                     // Debian/Raspbian 12 (next stable)
    [target: "ubuntu-focal",             image: "ubuntu:focal",                           arches: ["amd64", "aarch64", "armhf"]], // Ubuntu 20.04 LTS (End of support: April, 2025. EOL: April, 2030)
    [target: "ubuntu-jammy",             image: "ubuntu:jammy",                           arches: ["amd64", "aarch64", "armhf"]], // Ubuntu 22.04 LTS (End of support: April, 2027. EOL: April, 2032)
    [target: "ubuntu-kinetic",           image: "ubuntu:kinetic",                         arches: ["amd64", "aarch64", "armhf"]], // Ubuntu 22.10 (EOL: July, 2023)
    [target: "ubuntu-lunar",             image: "ubuntu:lunar",                           arches: ["amd64", "aarch64", "armhf"]], // Ubuntu 23.04 (EOL: January, 2024)
]

def genBuildStep(LinkedHashMap pkg, String arch) {
    def nodeLabel = "linux&&${arch}&&ubuntu-2004"

    // Running armhf builds on EC2 requires --platform parameter, otherwise it
    // accidentally pulls armel images which then breaks the verify step.
    //
    // Setting the platform explicitly for all architectures shouldn't hurt
    // though, so always passing it here.
    def platform = "--platform=linux/${arch}"

    return { ->
        wrappedNode(label: nodeLabel, cleanWorkspace: true) {
            stage("${pkg.target}-${arch}") {
                // This is just a "dummy" stage to make the distro/arch visible
                // in Jenkins' BlueOcean view, which truncates names....
                echo "starting ${pkg.target}-${arch}..."
            }
            stage("info") {
                sh 'docker version'
                sh 'docker info'
                sh 'env'
            }
            stage("build bundle") {
                checkout scm
                sshagent(['docker-jenkins.github.ssh']) {
                    sh """
                    make clean
                    make bundles-ce-${pkg.target}-${arch}.tar.gz
                    """
                }
            }
            stage("verify") {
                // Skip verify if SKIP_VERIFY is set, to solve the chicken and egg problem
                // when creating new docker-ce and containerd packages for new arch and distros
                def buildImage = pkg.image
                if (!params.SKIP_VERIFY) {
                    sh"""
                    make -C packaging \
                        VERIFY_PLATFORM=${platform} \
                        IMAGE=${buildImage} \
                        verify
                    """
                }
            }
            stage("upload") {
                saveS3(name: "bundles-ce-${pkg.target}-${arch}.tar.gz")
            }
        }
    }
}

def genStaticBuildStep(String uname_arch) {
    def config = archConfig[uname_arch]

    // TODO: figure out why building arm on arm64 machines does not work with cgo enabled
    def cgo_enabled = ''
    if (config.arch == 'armhf' || config.arch == 'armel') {
        cgo_enabled = '0'
    }

    return [ "static-linux-${config.arch}": { ->
        wrappedNode(label: config.label, cleanWorkspace: true) {
            stage("static-linux-${config.arch}") {
                // This is just a "dummy" stage to make the distro/arch visible
                // in Jenkins' BlueOcean view, which truncates names....
                echo "starting static-linux-${config.arch}..."
            }
            stage("info") {
                sh 'docker version'
                sh 'docker info'
                sh 'env'
            }
            stage("static") {
                checkout scm
                sshagent(['docker-jenkins.github.ssh']) {
                    sh """
                    make clean
                    make CGO_ENABLED=${cgo_enabled} docker-${config.arch}.tgz
                    """
                }
            }
            stage("upload") {
                saveS3(name: "docker-${config.arch}.tgz")
                saveS3(name: "docker-rootless-extras-${config.arch}.tgz")
            }
        }
    }]
}

def build_package_steps = [
    'cross-mac'         : { ->
        wrappedNode(label: 'amd64 && overlay2', cleanWorkspace: true) {
            stage('cross-mac') {
                // This is just a "dummy" stage to make the distro/arch visible
                // in Jenkins' BlueOcean view, which truncates names....
                echo "starting cross-mac..."
            }
            stage("info") {
                sh 'docker version'
                sh 'docker info'
                sh 'env'
            }
            stage('build') {
                checkout scm
                sshagent(['docker-jenkins.github.ssh']) {
                    sh """
                    make clean
                    make cross-mac
                    """
                }
            }
            stage("bundle") {
                sh """
                make bundles-ce-cross-darwin-amd64.tar.gz
                make bundles-ce-cross-darwin-arm64.tar.gz
                make docker-mac-amd64.tgz
                make docker-mac-aarch64.tgz
                """
            }
            stage('upload') {
                saveS3(name: 'bundles-ce-cross-darwin-amd64.tar.gz')
                saveS3(name: 'bundles-ce-cross-darwin-arm64.tar.gz')
                saveS3(name: 'docker-mac-amd64.tgz')
                saveS3(name: 'docker-mac-aarch64.tgz')
            }
        }
    },
    'cross-win'         : { ->
        wrappedNode(label: 'amd64 && overlay2', cleanWorkspace: true) {
            stage('cross-win') {
                // This is just a "dummy" stage to make the distro/arch visible
                // in Jenkins' BlueOcean view, which truncates names....
                echo "starting cross-win..."
            }
            stage("info") {
                sh 'docker version'
                sh 'docker info'
                sh 'env'
            }
            stage('build') {
                checkout scm
                sshagent(['docker-jenkins.github.ssh']) {
                    sh """
                    make clean
                    make cross-win
                    """
                }
            }
            stage("bundle") {
                sh """
                make bundles-ce-cross-windows-amd64.tar.gz
                make docker-win-amd64.zip
                """
            }
            stage('upload') {
                saveS3(name: 'bundles-ce-cross-windows-amd64.tar.gz')
                saveS3(name: 'docker-win-amd64.zip')
            }
        }
    },
    'shell-completion'  : { ->
        wrappedNode(label: 'amd64 && overlay2', cleanWorkspace: true) {
            stage('shell-completion') {
                checkout scm
                sshagent(['docker-jenkins.github.ssh']) {
                    sh """
                    make clean
                    make bundles-ce-shell-completion.tar.gz
                    """
                }
            }
            stage('upload') {
                saveS3(name: 'bundles-ce-shell-completion.tar.gz')
            }
        }
    },
]

def static_arches = [
    "x86_64",
    "armv6l",
    "armv7l",
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
    slackSend(channel: "#release", color: 'danger', message: "Release Packaging job ${env.JOB_NAME} failed. ${env.BUILD_URL}")
    throw err
}
