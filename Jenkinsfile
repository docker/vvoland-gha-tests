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
    archiveArtifacts 'bundles/*/tgz/**'
  },
  'build-tgz-experimental': dockerBuildStep {
    unstash 'bundles-experimental-binary'
    unstash 'bundles-experimental-cross'
    sh("make tgz-experimental")
    archiveArtifacts 'bundles-experimental/*/tgz/**'
  },
  'build-deb': dockerBuildStep {
    unstash 'bundles-binary'
    unstash 'bundles-dynbinary'
    sh("make deb")
    archiveArtifacts 'bundles/*/build-deb/**'
  },
  'build-deb-experimental': dockerBuildStep {
    unstash 'bundles-experimental-binary'
    unstash 'bundles-experimental-dynbinary'
    sh("make deb-experimental")
    archiveArtifacts 'bundles-experimental/*/build-deb/**'
  },
  'build-ubuntu': dockerBuildStep {
    unstash 'bundles-binary'
    unstash 'bundles-dynbinary'
    sh("make ubuntu")
    archiveArtifacts 'bundles/*/build-deb/**'
  },
  'build-ubuntu-experimental': dockerBuildStep {
    unstash 'bundles-experimental-binary'
    unstash 'bundles-experimental-dynbinary'
    sh("make ubuntu-experimental")
    archiveArtifacts 'bundles-experimental/*/build-deb/**'
  },
  'build-fedora': dockerBuildStep {
    unstash 'bundles-binary'
    unstash 'bundles-dynbinary'
    retry(2) { sh("make fedora") }
    archiveArtifacts 'bundles/*/build-rpm/**'
  },
  'build-fedora-experimental': dockerBuildStep {
    unstash 'bundles-experimental-binary'
    unstash 'bundles-experimental-dynbinary'
    sh("make fedora-experimental")
    archiveArtifacts 'bundles-experimental/*/build-rpm/**'
  },
  'build-centos': dockerBuildStep {
    unstash 'bundles-binary'
    unstash 'bundles-dynbinary'
    sh("make centos")
    archiveArtifacts 'bundles/*/build-rpm/**'
  },
  'build-centos-experimental': dockerBuildStep {
    unstash 'bundles-experimental-binary'
    unstash 'bundles-experimental-dynbinary'
    sh("make centos-experimental")
    archiveArtifacts 'bundles-experimental/*/build-rpm/**'
  },
  'build-oraclelinux': dockerBuildStep {
    unstash 'bundles-binary'
    unstash 'bundles-dynbinary'
    retry(2) { sh("make oraclelinux") }
    archiveArtifacts 'bundles/*/build-rpm/**'
  },
  'build-oraclelinux-experimental': dockerBuildStep {
    unstash 'bundles-experimental-binary'
    unstash 'bundles-experimental-dynbinary'
    retry(2) { sh("make oraclelinux-experimental") }
    archiveArtifacts 'bundles-experimental/*/build-rpm/**'
  },
  'build-opensuse': dockerBuildStep {
    unstash 'bundles-binary'
    unstash 'bundles-dynbinary'
    sh("make opensuse")
    archiveArtifacts 'bundles/*/build-rpm/**'
  },
  'build-opensuse-experimental': dockerBuildStep {
    unstash 'bundles-experimental-binary'
    unstash 'bundles-experimental-dynbinary'
    sh("make opensuse-experimental")
    archiveArtifacts 'bundles-experimental/*/build-rpm/**'
  }
]

def build_arm_steps = [
  'build-arm': dockerBuildStep(label: 'arm', arch: 'armhf') { ->
    sh("make binary")
    sh("make dynbinary")
    sh("make deb-arm")
    archiveArtifacts 'bundles/*/build-deb/**'
  },
  'build-arm-experimental': dockerBuildStep(label: 'arm', arch: 'armhf') { ->
    sh("make binary-experimental")
    sh("make dynbinary-experimental")
    sh("make deb-experimental-arm")
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
