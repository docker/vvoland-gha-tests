#!groovy
properties(
  [
    buildDiscarder(logRotator(artifactDaysToKeepStr: '', artifactNumToKeepStr: '', daysToKeepStr: '', numToKeepStr: '10')),
    parameters(
      [
        string(name: 'DOCKER_BUILD_IMG', defaultValue: '', description: 'Docker image used to build artifacts. If blank, will build a new image if necessary from the tip of corresponding branch in docker/docker repo.')
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

  { ->
    wrappedNode(label: theArgs.get('label', 'docker && aufs'), cleanWorkspace: true) {
      withChownWorkspace {
        withEnv(["DOCKER_BUILD_IMG=${this.dockerBuildImgDigest[arch]}", "ARCH=${arch}"]) {
          checkout scm
          if (theBody) {
            theBody.call()
          }
        }
      }
    }
  }
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
    stash(name: 'bundles-binary', includes: 'bundles/*/binary*/**')
  },
  'build-binary-experimental': dockerBuildStep { ->
    sh("make binary-experimental")
    stash(name: 'bundles-experimental-binary', includes: 'bundles-experimental/*/binary*/**')
  },
]

def build_cross_dynbinary_steps = [
  'build-dynbinary': dockerBuildStep { ->
    sh("make dynbinary")
    stash(name: 'bundles-dynbinary', includes: 'bundles/*/dynbinary*/**')
  },
  'build-dynbinary-experimental': dockerBuildStep { ->
    sh("make dynbinary-experimental")
    stash(name: 'bundles-experimental-dynbinary', includes: 'bundles-experimental/*/dynbinary*/**')
  },
  'build-cross': dockerBuildStep { ->
    unstash 'bundles-binary'
    sh("make cross")
    stash(name: 'bundles-cross', includes: 'bundles/*/cross/**')
  },
  'build-cross-experimental': dockerBuildStep { ->
    unstash 'bundles-experimental-binary'
    sh("make cross-experimental")
    stash(name: 'bundles-experimental-cross', includes: 'bundles-experimental/*/cross/**')
  }
]

def build_package_steps = [
  'build-tgz': dockerBuildStep {
    unstash 'bundles-binary'
    unstash 'bundles-cross'
    sh("make tgz")
    stash(name: 'bundles-tgz', includes: 'bundles/*/tgz/**')
  },
  'build-tgz-experimental': dockerBuildStep {
    unstash 'bundles-experimental-binary'
    unstash 'bundles-experimental-cross'
    sh("make tgz-experimental")
    stash(name: 'bundles-tgz-experimental', includes: 'bundles-experimental/*/tgz/**')
  },
  'build-deb': dockerBuildStep {
    unstash 'bundles-binary'
    unstash 'bundles-dynbinary'
    sh("make deb")
    stash(name: 'bundles-deb', includes: 'bundles/*/build-deb/**')
  },
  'build-deb-experimental': dockerBuildStep {
    unstash 'bundles-experimental-binary'
    unstash 'bundles-experimental-dynbinary'
    sh("make deb-experimental")
    stash(name: 'bundles-deb-experimental', includes: 'bundles-experimental/*/build-deb/**')
  },
  'build-ubuntu': dockerBuildStep {
    unstash 'bundles-binary'
    unstash 'bundles-dynbinary'
    sh("make ubuntu")
    stash(name: 'bundles-ubuntu', includes: 'bundles/*/build-deb/**')
  },
  'build-ubuntu-experimental': dockerBuildStep {
    unstash 'bundles-experimental-binary'
    unstash 'bundles-experimental-dynbinary'
    sh("make ubuntu-experimental")
    stash(name: 'bundles-ubuntu-experimental', includes: 'bundles-experimental/*/build-deb/**')
  },
  'build-fedora': dockerBuildStep {
    unstash 'bundles-binary'
    unstash 'bundles-dynbinary'
    retry(2) { sh("make fedora") }
    stash(name: 'bundles-fedora', includes: 'bundles/*/build-rpm/**')
  },
  'build-fedora-experimental': dockerBuildStep {
    unstash 'bundles-experimental-binary'
    unstash 'bundles-experimental-dynbinary'
    sh("make fedora-experimental")
    stash(name: 'bundles-fedora-experimental', includes: 'bundles-experimental/*/build-rpm/**')
  },
  'build-centos': dockerBuildStep {
    unstash 'bundles-binary'
    unstash 'bundles-dynbinary'
    sh("make centos")
    stash(name: 'bundles-centos', includes: 'bundles/*/build-rpm/**')
  },
  'build-centos-experimental': dockerBuildStep {
    unstash 'bundles-experimental-binary'
    unstash 'bundles-experimental-dynbinary'
    sh("make centos-experimental")
    stash(name: 'bundles-centos-experimental', includes: 'bundles-experimental/*/build-rpm/**')
  },
  'build-oraclelinux': dockerBuildStep {
    unstash 'bundles-binary'
    unstash 'bundles-dynbinary'
    retry(2) { sh("make oraclelinux") }
    stash(name: 'bundles-oraclelinux', includes: 'bundles/*/build-rpm/**')
  },
  'build-oraclelinux-experimental': dockerBuildStep {
    unstash 'bundles-experimental-binary'
    unstash 'bundles-experimental-dynbinary'
    retry(2) { sh("make oraclelinux-experimental") }
    stash(name: 'bundles-oraclelinux-experimental', includes: 'bundles-experimental/*/build-rpm/**')
  },
  'build-opensuse': dockerBuildStep {
    unstash 'bundles-binary'
    unstash 'bundles-dynbinary'
    sh("make opensuse")
    stash(name: 'bundles-opensuse', includes: 'bundles/*/build-rpm/**')
  },
  'build-opensuse-experimental': dockerBuildStep {
    unstash 'bundles-experimental-binary'
    unstash 'bundles-experimental-dynbinary'
    sh("make opensuse-experimental")
    stash(name: 'bundles-opensuse-experimental', includes: 'bundles-experimental/*/build-rpm/**')
  }
]

def build_arm_steps = [
  'build-debian-jessie-arm': dockerBuildStep(label: 'arm', arch: 'armhf') { ->
    sh("make binary")
    sh("make DOCKER_BUILD_PKGS=debian-jessie deb-arm")
    stash(name: 'bundles-debian-jessie-arm', includes: 'bundles/*/build-deb/**')
  },
  'build-raspbian-jessie-arm': dockerBuildStep(label: 'arm', arch: 'armhf') { ->
    sh("make binary")
    sh("make DOCKER_BUILD_PKGS=raspbian-jessie deb-arm")
    stash(name: 'bundles-raspbian-jessie-arm', includes: 'bundles/*/build-deb/**')
  },
  'build-ubuntu-trusty-arm': dockerBuildStep(label: 'arm', arch: 'armhf') { ->
    sh("make binary")
    sh("make DOCKER_BUILD_PKGS=ubuntu-trusty ubuntu-arm")
    stash(name: 'bundles-ubuntu-trusty-arm', includes: 'bundles/*/build-deb/**')
  },
  'build-ubuntu-xenial-arm': dockerBuildStep(label: 'arm', arch: 'armhf') { ->
    sh("make binary")
    sh("make DOCKER_BUILD_PKGS=ubuntu-xenial ubuntu-arm")
    archiveArtifacts 'bundles/*/build-deb/**'
  },
  'build-debian-jessie-arm-experimental': dockerBuildStep(label: 'arm', arch: 'armhf') { ->
    sh("make binary-experimental")
    sh("make DOCKER_BUILD_PKGS=debian-jessie deb-arm-experimental")
    stash(name: 'bundles-debian-jessie-arm-experimental', includes: 'bundles-experimental/*/build-deb/**')
  },
  'build-raspbian-jessie-arm-experimental': dockerBuildStep(label: 'arm', arch: 'armhf') { ->
    sh("make binary-experimental")
    sh("make DOCKER_BUILD_PKGS=raspbian-jessie deb-arm-experimental")
    stash(name: 'bundles-raspbian-jessie-arm-experimental', includes: 'bundles-experimental/*/build-deb/**')
  },
  'build-ubuntu-trusty-arm-experimental': dockerBuildStep(label: 'arm', arch: 'armhf') { ->
    sh("make binary-experimental")
    sh("make DOCKER_BUILD_PKGS=ubuntu-trusty ubuntu-arm-experimental")
    stash(name: 'bundles-ubuntu-trusty-arm-experimental', includes: 'bundles-experimental/*/build-deb/**')
  },
  'build-ubuntu-xenial-arm-experimental': dockerBuildStep(label: 'arm', arch: 'armhf') { ->
    sh("make binary-experimental")
    sh("make DOCKER_BUILD_PKGS=ubuntu-xenial ubuntu-arm-experimental")
    archiveArtifacts 'bundles-experimental/*/build-deb/**'
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
        dockerBuildStep(label: 'arm', arch: 'armhf') {
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

stage("generate index") {
  timeout(time: 1, unit: 'HOURS') {
    dockerBuildStep(label: 'volumes-repos') {
      withCredentials([[
        $class: 'AmazonWebServicesCredentialsBinding',
        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY',
        credentialsId: 'jenkins@dockerengine.aws'
      ],
        file(credentialsId: 'releasedocker-secret-gpg.key', variable: 'RELEASEDOCKER_SECRET_GPG_KEY_FILE'),
        file(credentialsId: 'releasedocker-ownertrust-gpg.txt', variable: 'RELEASEDOCKER_OWNERTRUST_GPG_TXT_FILE'),
        string(credentialsId: 'releasedocker-gpg-passphrase', variable: 'GPG_PASSPHRASE')
      ]) {
        unstash 'bundles-deb'
        unstash 'bundles-ubuntu'
        unstash 'bundles-fedora'
        unstash 'bundles-centos'
        unstash 'bundles-oraclelinux'
        unstash 'bundles-opensuse'
        unstash 'bundles-debian-jessie-arm'
        unstash 'bundles-raspbian-jessie-arm'
        unstash 'bundles-ubuntu-trusty-arm'
        unstash 'bundles-deb-experimental'
        unstash 'bundles-ubuntu-experimental'
        unstash 'bundles-fedora-experimental'
        unstash 'bundles-centos-experimental'
        unstash 'bundles-oraclelinux-experimental'
        unstash 'bundles-opensuse-experimental'
        unstash 'bundles-debian-jessie-arm-experimental'
        unstash 'bundles-raspbian-jessie-arm-experimental'
        unstash 'bundles-ubuntu-trusty-arm-experimental'
        sh("make sync-repos-from-staging-to-local")
        sh("make prep-gpg")
        sh("make gen-index")
        sh("make gen-index-experimental")
        archiveArtifacts 'bundles/**'
        archiveArtifacts 'bundles-experimental/**'
      }
    }.call()
  }
}
