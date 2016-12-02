#!groovy
properties(
  [
    buildDiscarder(logRotator(artifactDaysToKeepStr: '', artifactNumToKeepStr: '', daysToKeepStr: '', numToKeepStr: '10')),
    parameters(
      [
        string(name: 'DOCKER_BUILD_IMG', defaultValue: '', description: 'Docker image used to build artifacts. If blank, will build a new image if necessary from the tip of corresponding branch in docker/docker repo.'),
        string(name: 'DOCKER_REPO', defaultValue: 'https://github.com/docker/docker.git', description: 'Docker git source repository.')
      ]
    )
  ]
)

this.dockerBuildImgDigest = [amd64: "", armhf: ""]

def dockerBuildStep = { Map args=[:], Closure body=null ->
  // Work around groovy closure issues
  def theArgs = args
  def theBody = body
  if (theArgs instanceof Closure) {
    theBody = theArgs
    theArgs = [:]
  }

  def arch = theArgs.arch ?: "amd64"
  def label = "linux && ${arch}"
  if (arch == "amd64") {
    label += "&& aufs"
  }

  { ->
    wrappedNode(label: label, cleanWorkspace: true) {
      withChownWorkspace {
        withEnv(["DOCKER_BUILD_IMG=${this.dockerBuildImgDigest[arch]}", "ARCH=${arch}", "DOCKER_REPO=${params.DOCKER_REPO}"]) {
          checkout scm
          if (theBody) {
            theBody.call()
          }
        }
      }
    }
  }
}

def stashS3(def Map args=[:]) {
    def destS3Uri = "s3://docker-ci-artifacts/ci.qa.aws.dckr.io/${env.BUILD_TAG}/"
    def awscli = args.awscli ?: 'docker run --rm -e AWS_SECRET_ACCESS_KEY -e AWS_ACCESS_KEY_ID -v `pwd`:/z -w /z anigeo/awscli'
    sh("find . -path './${args.includes}' | tar -c -z -v -f '${args.name}.tar.gz' -T -")
    withCredentials([[
        $class: 'AmazonWebServicesCredentialsBinding',
        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY',
        credentialsId: 'ci@docker-qa.aws'
    ]]) {
        sh("${awscli} s3 cp '${args.name}.tar.gz' '${destS3Uri}'")
    }
    sh("rm -f '${args.name}.tar.gz'")
}

def unstashS3(def name) {
    def srcS3Uri = "s3://docker-ci-artifacts/ci.qa.aws.dckr.io/${env.BUILD_TAG}/${name}.tar.gz"
    withCredentials([[
        $class: 'AmazonWebServicesCredentialsBinding',
        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY',
        credentialsId: 'ci@docker-qa.aws'
    ]]) {
        sh("docker run --rm -e AWS_SECRET_ACCESS_KEY -e AWS_ACCESS_KEY_ID -v `pwd`:/z anigeo/awscli s3 cp '${srcS3Uri}' /z/")
    }
    sh("tar -x -z -v -f '${name}.tar.gz'")
    sh("rm -f '${name}.tar.gz'")
}

def build_docker_dev_steps = [
  'build-docker-dev': dockerBuildStep { ->
    sh("make docker-dev-digest.txt")
    this.dockerBuildImgDigest["amd64"] = readFile('docker-dev-digest.txt').trim()
  },
]

def build_binary_steps = [
  'build-binary': dockerBuildStep { ->
    sh("make binary")
    stashS3(name: 'bundles-binary', includes: 'bundles/*/binary*/**')
  },
  'build-binary-experimental': dockerBuildStep { ->
    sh("make binary-experimental")
    stashS3(name: 'bundles-experimental-binary', includes: 'bundles-experimental/*/binary*/**')
  },
]

def build_cross_dynbinary_steps = [
  'build-dynbinary': dockerBuildStep { ->
    sh("make dynbinary")
    stashS3(name: 'bundles-dynbinary', includes: 'bundles/*/dynbinary*/**')
  },
  'build-dynbinary-experimental': dockerBuildStep { ->
    sh("make dynbinary-experimental")
    stashS3(name: 'bundles-experimental-dynbinary', includes: 'bundles-experimental/*/dynbinary*/**')
  },
  'build-cross': dockerBuildStep { ->
    unstashS3('bundles-binary')
    sh("make cross")
    stashS3(name: 'bundles-cross', includes: 'bundles/*/cross/**')
  },
  'build-cross-experimental': dockerBuildStep { ->
    unstashS3('bundles-experimental-binary')
    sh("make cross-experimental")
    stashS3(name: 'bundles-experimental-cross', includes: 'bundles-experimental/*/cross/**')
  }
]

def build_package_steps = [
  'build-tgz': dockerBuildStep {
    unstashS3('bundles-binary')
    unstashS3('bundles-cross')
    sh("make tgz")
    stashS3(name: 'bundles-tgz', includes: 'bundles/*/tgz/**')
  },
  'build-tgz-experimental': dockerBuildStep {
    unstashS3('bundles-experimental-binary')
    unstashS3('bundles-experimental-cross')
    sh("make tgz-experimental")
    stashS3(name: 'bundles-experimental-tgz', includes: 'bundles-experimental/*/tgz/**')
  },
  'build-deb': dockerBuildStep {
    unstashS3('bundles-binary')
    sh("make deb")
    stashS3(name: 'bundles-debian', includes: 'bundles/*/build-deb/**')
  },
  'build-deb-experimental': dockerBuildStep {
    unstashS3('bundles-experimental-binary')
    sh("make deb-experimental")
    stashS3(name: 'bundles-experimental-debian', includes: 'bundles-experimental/*/build-deb/**')
  },
  'build-ubuntu': dockerBuildStep {
    unstashS3('bundles-binary')
    sh("make ubuntu")
    archiveArtifacts 'bundles/*/build-deb/**'
    stashS3(name: 'bundles-ubuntu', includes: 'bundles/*/build-deb/**')
  },
  'build-ubuntu-experimental': dockerBuildStep {
    unstashS3('bundles-experimental-binary')
    sh("make ubuntu-experimental")
    stashS3(name: 'bundles-experimental-ubuntu', includes: 'bundles-experimental/*/build-deb/**')
  },
  'build-fedora': dockerBuildStep {
    unstashS3('bundles-binary')
    retry(2) { sh("make fedora") }
    stashS3(name: 'bundles-fedora', includes: 'bundles/*/build-rpm/**')
  },
  'build-fedora-experimental': dockerBuildStep {
    unstashS3('bundles-experimental-binary')
    retry(2) { sh("make fedora-experimental") }
    stashS3(name: 'bundles-experimental-fedora', includes: 'bundles-experimental/*/build-rpm/**')
  },
  'build-centos': dockerBuildStep {
    unstashS3('bundles-binary')
    sh("make centos")
    stashS3(name: 'bundles-centos', includes: 'bundles/*/build-rpm/**')
  },
  'build-centos-experimental': dockerBuildStep {
    unstashS3('bundles-experimental-binary')
    sh("make centos-experimental")
    stashS3(name: 'bundles-experimental-centos', includes: 'bundles-experimental/*/build-rpm/**')
  },
  'build-oraclelinux': dockerBuildStep {
    unstashS3('bundles-binary')
    retry(2) { sh("make oraclelinux") }
    stashS3(name: 'bundles-oraclelinux', includes: 'bundles/*/build-rpm/**')
  },
  'build-oraclelinux-experimental': dockerBuildStep {
    unstashS3('bundles-experimental-binary')
    retry(2) { sh("make oraclelinux-experimental") }
    stashS3(name: 'bundles-experimental-oraclelinux', includes: 'bundles-experimental/*/build-rpm/**')
  },
  'build-opensuse': dockerBuildStep {
    unstashS3('bundles-binary')
    sh("make opensuse")
    stashS3(name: 'bundles-opensuse', includes: 'bundles/*/build-rpm/**')
  },
  'build-opensuse-experimental': dockerBuildStep {
    unstashS3('bundles-experimental-binary')
    sh("make opensuse-experimental")
    stashS3(name: 'bundles-experimental-opensuse', includes: 'bundles-experimental/*/build-rpm/**')
  }
]

def build_arm_steps = [
  'build-debian-jessie-arm': dockerBuildStep(arch: 'armhf') { ->
    sh("make binary")
    sh("make DOCKER_BUILD_PKGS=debian-jessie deb-arm")
    archiveArtifacts 'bundles/*/build-deb/**'
    stashS3(name: 'bundles-debian-jessie-arm', includes: 'bundles/*/build-deb/**', awscli: 'aws')
  },
  'build-raspbian-jessie-arm': dockerBuildStep(arch: 'armhf') { ->
    sh("make binary")
    sh("make DOCKER_BUILD_PKGS=raspbian-jessie deb-arm")
    stashS3(name: 'bundles-raspbian-jessie-arm', includes: 'bundles/*/build-deb/**', awscli: 'aws')
  },
  'build-ubuntu-trusty-arm': dockerBuildStep(arch: 'armhf') { ->
    sh("make binary")
    sh("make DOCKER_BUILD_PKGS=ubuntu-trusty ubuntu-arm")
    stashS3(name: 'bundles-ubuntu-trusty-arm', includes: 'bundles/*/build-deb/**', awscli: 'aws')
  },
  'build-ubuntu-xenial-arm': dockerBuildStep(arch: 'armhf') { ->
    sh("make binary")
    sh("make DOCKER_BUILD_PKGS=ubuntu-xenial ubuntu-arm")
    stashS3(name: 'bundles-ubuntu-xenial-arm', includes: 'bundles/*/build-deb/**', awscli: 'aws')
  },
  'build-debian-jessie-arm-experimental': dockerBuildStep(arch: 'armhf') { ->
    sh("make binary-experimental")
    sh("make DOCKER_BUILD_PKGS=debian-jessie deb-arm-experimental")
    stashS3(name: 'bundles-debian-jessie-arm-experimental', includes: 'bundles-experimental/*/build-deb/**', awscli: 'aws')
  },
  'build-raspbian-jessie-arm-experimental': dockerBuildStep(arch: 'armhf') { ->
    sh("make binary-experimental")
    sh("make DOCKER_BUILD_PKGS=raspbian-jessie deb-arm-experimental")
    stashS3(name: 'bundles-raspbian-jessie-arm-experimental', includes: 'bundles-experimental/*/build-deb/**', awscli: 'aws')
  },
  'build-ubuntu-trusty-arm-experimental': dockerBuildStep(arch: 'armhf') { ->
    sh("make binary-experimental")
    sh("make DOCKER_BUILD_PKGS=ubuntu-trusty ubuntu-arm-experimental")
    stashS3(name: 'bundles-ubuntu-trusty-arm-experimental', includes: 'bundles-experimental/*/build-deb/**', awscli: 'aws')
  },
  'build-ubuntu-xenial-arm-experimental': dockerBuildStep(arch: 'armhf') { ->
    sh("make binary-experimental")
    sh("make DOCKER_BUILD_PKGS=ubuntu-xenial ubuntu-arm-experimental")
    stashS3(name: 'bundles-ubuntu-xenial-arm-experimental', includes: 'bundles-experimental/*/build-deb/**', awscli: 'aws')
  },
]

parallel(
  'amd64': { ->
    stage(name: 'build docker-dev steps') {
      timeout(time: 1, unit: 'HOURS') {
        parallel(build_docker_dev_steps)
      }
    }
    stage(name: 'build binary steps') {
      timeout(time: 1, unit: 'HOURS') {
        parallel(build_binary_steps)
      }
    }
    stage(name: 'build cross dynbinary steps') {
      timeout(time: 1, unit: 'HOURS') {
        parallel(build_cross_dynbinary_steps)
      }
    }
    stage(name: 'build package steps') {
      timeout(time: 2, unit: 'HOURS') {
        parallel(build_package_steps)
      }
    }
  },
  'arm': { ->
    stage("build docker-dev arm") {
      timeout(time: 1, unit: 'HOURS') {
        dockerBuildStep(arch: 'armhf') {
          sh("make docker-dev-digest.txt")
          this.dockerBuildImgDigest["armhf"] = readFile('docker-dev-digest.txt').trim()
        }.call()
      }
    }
    stage("build all arm") {
      timeout(time: 3, unit: 'HOURS') {
        parallel(build_arm_steps)
      }
    }
  }
)
