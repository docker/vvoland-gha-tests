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
            booleanParam(name: 'RELEASE_STAGING',    defaultValue: false,                                           description: 'Trigger release to staging after a successful build. Leave unchecked to only build artifacts (and manually start a release from the release-repo build pipeline)'),
            booleanParam(name: 'RELEASE_PRODUCTION', defaultValue: false,                                           description: 'Trigger release to production after a successful build. Leave unchecked to only build artifacts (and manually start a release from the release-repo build pipeline)'),
            booleanParam(name: 'SKIP_VERIFY',        defaultValue: false,                                           description: 'Skip package verification. Use this when testing builds of a new distro for which no containerd.io packages are available yet.'),
            string(name: 'VERIFY_PACKAGE_REPO',      defaultValue: 'prod',                                          description: 'Packaging repo to use for installing dependencies (stage=download-stage.docker.com or prod=download.docker.com (default))'),
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
                announceChannel = "#ship-builders"
                // This is only the case on a nightly build
                if (env.BRANCH_NAME == 'ce-nightly') {
                    announceChannel = "#release-ci-feed"
                }
                if (params.RELEASE_PRODUCTION) {
                    slackSend(channel: announceChannel, message: "Initiating build pipeline. Building packages from `docker/cli:${params.DOCKER_CLI_REF}`, `docker/docker:${params.DOCKER_ENGINE_REF}`, `docker/docker-ce-packaging:${params.DOCKER_PACKAGING_REF}` for version `${params.VERSION}`. ${env.BUILD_URL}")
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
                sshagent(['docker-jenkins.github.ssh']) {
                    sh """
                    make clean
                    make \
                        DOCKER_PACKAGING_REPO=${params.DOCKER_PACKAGING_REPO} \
                        DOCKER_PACKAGING_REF=${params.DOCKER_PACKAGING_REF} \
                        DOCKER_ENGINE_REPO=${params.DOCKER_ENGINE_REPO} \
                        DOCKER_ENGINE_REF=${params.DOCKER_ENGINE_REF} \
                        DOCKER_CLI_REPO=${params.DOCKER_CLI_REPO} \
                        DOCKER_CLI_REF=${params.DOCKER_CLI_REF} \
                        packaging/src/github.com/docker/docker \
                        packaging/src/github.com/docker/cli
                    """
                }
                // TODO these build-result.txt lines should not be here in Jenkinsfile, but result from a Makefile target.
                sh('git -C packaging rev-parse HEAD >> build-result.txt')
                sh('git -C packaging/src/github.com/docker/docker rev-parse HEAD >> build-result.txt')
                sh('git -C packaging/src/github.com/docker/cli rev-parse HEAD >> build-result.txt')
                saveS3(name: 'build-result.txt')
                // Note: gen-static-ver only adds git commit and git date info to a `*-dev` version, in which case the CLI's git is used.
                sh("./packaging/static/gen-static-ver packaging/src/github.com/docker/cli '${params.VERSION}' > VERSION")
                saveS3(name: 'VERSION')
                slackSend(channel: "#release-ci-feed", message: "Docker CE (cli: `${params.DOCKER_CLI_REF}`, engine: `${params.DOCKER_ENGINE_REF}`, packaging: `${params.DOCKER_PACKAGING_REF}`, version: `${params.VERSION}`) https://s3.us-east-1.amazonaws.com/${getS3Bucket()}/${BUILD_TAG}/build-result.txt")
                if (params.RELEASE_STAGING || params.RELEASE_PRODUCTION) {
                    // Triggers builds to go through to staging and/or production
                    build(
                        job: "release-repo/ce",
                        parameters: [
                            [$class: 'StringParameterValue',  name: 'ARTIFACT_BUILD_TAG',      value: "${BUILD_TAG}"],
                            [$class: 'StringParameterValue',  name: 'EXPECTED_DOCKER_VERSION', value: "${VERSION}"],
                            [$class: 'BooleanParameterValue', name: 'RELEASE_STAGING',         value: STAGING],
                            [$class: 'BooleanParameterValue', name: 'RELEASE_PRODUCTION',      value: PROD],
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
    [target: "debian-buster",            image: "debian:buster",                          arches: ["amd64", "aarch64", "armhf"]], // Debian 10 (EOL: 2024)
    [target: "debian-bullseye",          image: "debian:bullseye",                        arches: ["amd64", "aarch64", "armhf"]], // Debian 11 (Next stable)
    [target: "fedora-33",                image: "fedora:33",                              arches: ["amd64", "aarch64"]],
    [target: "fedora-34",                image: "fedora:34",                              arches: ["amd64", "aarch64"]],
    [target: "raspbian-buster",          image: "balenalib/rpi-raspbian:buster",          arches: ["armhf"]],                     // Debian/Raspbian 10 (EOL: 2024)
    [target: "raspbian-bullseye",        image: "balenalib/rpi-raspbian:bullseye",        arches: ["armhf"]],                     // Debian/Raspbian 11 (Next stable)
    [target: "ubuntu-bionic",            image: "ubuntu:bionic",                          arches: ["amd64", "aarch64", "armhf"]], // Ubuntu 18.04 LTS (End of support: April, 2023. EOL: April, 2028)
    [target: "ubuntu-focal",             image: "ubuntu:focal",                           arches: ["amd64", "aarch64"]],          // Ubuntu 20.04 LTS (End of support: April, 2025. EOL: April, 2030)
    [target: "ubuntu-groovy",            image: "ubuntu:groovy",                          arches: ["amd64", "aarch64"]],          // Ubuntu 20.10 (EOL: July, 2021)
    [target: "ubuntu-hirsute",           image: "ubuntu:hirsute",                         arches: ["amd64", "aarch64"]],          // Ubuntu 21.04 (EOL: January, 2022)
]

def genBuildStep(LinkedHashMap pkg, String arch) {
    def nodeLabel = "linux&&${arch}"
    def platform = ""

    if (arch == 'armhf') {
        // Running armhf builds on EC2 requires --platform parameter
        // Otherwise it accidentally pulls armel images which then breaks the verify step
        platform = "--platform=linux/${arch}"
        nodeLabel = "${nodeLabel}&&ubuntu"
    } else {
        nodeLabel = "${nodeLabel}&&ubuntu-2004"
    }
    return { ->
        wrappedNode(label: nodeLabel, cleanWorkspace: true) {
           stage("${pkg.target}-${arch}") {
                // This is just a "dummy" stage to make the distro/arch visible
                // in Jenkins' BlueOcean view, which truncates names....
                sh 'echo starting...'
            }
            stage("info") {
                sh 'docker version'
                sh 'docker info'
            }
            stage("build bundle") {
                checkout scm
                sshagent(['docker-jenkins.github.ssh']) {
                    sh """
                    make clean
                    make \
                        DOCKER_PACKAGING_REPO=${params.DOCKER_PACKAGING_REPO} \
                        DOCKER_PACKAGING_REF=${params.DOCKER_PACKAGING_REF} \
                        DOCKER_CLI_REPO=${params.DOCKER_CLI_REPO} \
                        DOCKER_CLI_REF=${params.DOCKER_CLI_REF} \
                        DOCKER_ENGINE_REPO=${params.DOCKER_ENGINE_REPO} \
                        DOCKER_ENGINE_REF=${params.DOCKER_ENGINE_REF} \
                        VERSION=${params.VERSION} \
                        bundles-ce-${pkg.target}-${arch}.tar.gz
                    """
                }
            }
            stage("verify") {
                // Skip verify if SKIP_VERIFY is set, to solve the chicken and egg problem
                // when creating new docker-ce and containerd packages for new arch and distros
                def buildImage = pkg.image
                if (!params.SKIP_VERIFY) {
                    sh"""
                    make \
                        VERIFY_PACKAGE_REPO=${params.VERIFY_PACKAGE_REPO} \
                        VERIFY_PLATFORM=${platform} IMAGE=${buildImage} \
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
            stage("static") {
                checkout scm
                sshagent(['docker-jenkins.github.ssh']) {
                    sh """
                    make clean
                    make \
                        CGO_ENABLED=${cgo_enabled} \
                        DOCKER_PACKAGING_REPO=${params.DOCKER_PACKAGING_REPO} \
                        DOCKER_PACKAGING_REF=${params.DOCKER_PACKAGING_REF} \
                        DOCKER_CLI_REPO=${params.DOCKER_CLI_REPO} \
                        DOCKER_CLI_REF=${params.DOCKER_CLI_REF} \
                        DOCKER_ENGINE_REPO=${params.DOCKER_ENGINE_REPO} \
                        DOCKER_ENGINE_REF=${params.DOCKER_ENGINE_REF} \
                        VERSION=${params.VERSION} \
                        docker-${config.arch}.tgz
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
                sh 'echo starting...'
            }
            stage("info") {
                sh 'docker version'
                sh 'docker info'
            }
            stage('build') {
                checkout scm
                sshagent(['docker-jenkins.github.ssh']) {
                    sh """
                    make clean
                    make \
                        DOCKER_PACKAGING_REPO=${params.DOCKER_PACKAGING_REPO} \
                        DOCKER_PACKAGING_REF=${params.DOCKER_PACKAGING_REF} \
                        DOCKER_CLI_REPO=${params.DOCKER_CLI_REPO} \
                        DOCKER_CLI_REF=${params.DOCKER_CLI_REF} \
                        DOCKER_ENGINE_REPO=${params.DOCKER_ENGINE_REPO} \
                        DOCKER_ENGINE_REF=${params.DOCKER_ENGINE_REF} \
                        VERSION=${params.VERSION} \
                        cross-mac
                    """
                }
            }
            stage("bundle") {
                sh """
                make VERSION=${params.VERSION} bundles-ce-cross-darwin-amd64.tar.gz
                make VERSION=${params.VERSION} bundles-ce-cross-darwin-arm64.tar.gz
                make docker-mac-amd64.tgz docker-mac-aarch64.tgz
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
                sh 'echo starting...'
            }
            stage("info") {
                sh 'docker version'
                sh 'docker info'
            }
            stage('build') {
                checkout scm
                sshagent(['docker-jenkins.github.ssh']) {
                    sh """
                    make clean
                    make \
                        DOCKER_PACKAGING_REPO=${params.DOCKER_PACKAGING_REPO} \
                        DOCKER_PACKAGING_REF=${params.DOCKER_PACKAGING_REF} \
                        DOCKER_CLI_REPO=${params.DOCKER_CLI_REPO} \
                        DOCKER_CLI_REF=${params.DOCKER_CLI_REF} \
                        DOCKER_ENGINE_REPO=${params.DOCKER_ENGINE_REPO} \
                        DOCKER_ENGINE_REF=${params.DOCKER_ENGINE_REF} \
                        VERSION=${params.VERSION} \
                        cross-win
                    """
                }
            }
            stage("bundle") {
                sh """
                make VERSION=${params.VERSION} bundles-ce-cross-windows-amd64.tar.gz
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
                    make \
                        DOCKER_PACKAGING_REPO=${params.DOCKER_PACKAGING_REPO} \
                        DOCKER_PACKAGING_REF=${params.DOCKER_PACKAGING_REF} \
                        DOCKER_CLI_REPO=${params.DOCKER_CLI_REPO} \
                        DOCKER_CLI_REF=${params.DOCKER_CLI_REF} \
                        VERSION=${params.VERSION} \
                        bundles-ce-shell-completion.tar.gz
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
    def failChannel = "#release-announce-test"
    def notify = ""
    if (params.RELEASE_STAGING || params.RELEASE_PRODUCTION) {
        failChannel = "#release-ci-feed"
        notify = "@sf-release-eng"
    }
    slackSend(channel: failChannel, color: 'danger', message: "${notify}Release Packaging job ${env.JOB_NAME} failed. ${env.BUILD_URL}")
    throw err
}
