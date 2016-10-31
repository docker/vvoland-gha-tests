#!groovy
properties(
  [
    buildDiscarder(logRotator(artifactDaysToKeepStr: '', artifactNumToKeepStr: '', daysToKeepStr: '', numToKeepStr: '5'))
  ]
)

def dockerBuildImgDigest

def build_docker_dev_steps = [
  'build-docker-dev': {
    wrappedNode(label: 'docker && ubuntu && aufs') {
      deleteDir()
      checkout scm
      withChownWorkspace {
        sh("make docker-dev-digest.txt")
        dockerBuildImgDigest = sh(returnStdout: true, script: "awk '{print\$1;exit}' docker-dev-digest.txt").trim()
      }
    }
  }
]

def build_binary_steps = [
  'build-binary': {
    wrappedNode(label: 'docker && ubuntu && aufs') {
      deleteDir()
      checkout scm
      withChownWorkspace { sh("make DOCKER_BUILD_IMG=${dockerBuildImgDigest} binary") }
      stash(name: 'bundles-binary', includes: 'bundles/*/binary*/**')
    }
  },
  'build-binary-experimental': {
    wrappedNode(label: 'docker && ubuntu && aufs') {
      deleteDir()
      checkout scm
      withChownWorkspace { sh("make DOCKER_BUILD_IMG=${dockerBuildImgDigest} binary-experimental") }
      stash(name: 'bundles-experimental-binary', includes: 'bundles-experimental/*/binary*/**')
    }
  }
]

def build_cross_dynbinary_steps = [
  'build-dynbinary': {
    wrappedNode(label: 'docker && ubuntu && aufs') {
      deleteDir()
      checkout scm
      withChownWorkspace { sh("make DOCKER_BUILD_IMG=${dockerBuildImgDigest} dynbinary") }
      stash(name: 'bundles-dynbinary', includes: 'bundles/*/dynbinary*/**')
    }
  },
 'build-dynbinary-experimental': {
    wrappedNode(label: 'docker && ubuntu && aufs') {
      deleteDir()
      checkout scm
      withChownWorkspace { sh("make DOCKER_BUILD_IMG=${dockerBuildImgDigest} dynbinary-experimental") }
      stash(name: 'bundles-experimental-dynbinary', includes: 'bundles-experimental/*/dynbinary*/**')
    }
  },
  'build-cross': {
    wrappedNode(label: 'docker && ubuntu && aufs') {
      deleteDir()
      checkout scm
      unstash 'bundles-binary'
      withChownWorkspace { sh("make DOCKER_BUILD_IMG=${dockerBuildImgDigest} cross") }
      stash(name: 'bundles-cross', includes: 'bundles/*/cross/**')
    }
  },
  'build-cross-experimental': {
    wrappedNode(label: 'docker && ubuntu && aufs') {
      deleteDir()
      checkout scm
      unstash 'bundles-experimental-binary'
      withChownWorkspace { sh("make DOCKER_BUILD_IMG=${dockerBuildImgDigest} cross-experimental") }
      stash(name: 'bundles-experimental-cross', includes: 'bundles-experimental/*/cross/**')
    }
  }
]

def build_package_steps = [
  'build-tgz': {
    wrappedNode(label: 'docker && ubuntu && aufs') {
      deleteDir()
      checkout scm
      unstash 'bundles-binary'
      unstash 'bundles-cross'
      withChownWorkspace { sh("make DOCKER_BUILD_IMG=${dockerBuildImgDigest} tgz") }
      archiveArtifacts 'bundles/*/tgz/**'
    }
  },
  'build-tgz-experimental': {
    wrappedNode(label: 'docker && ubuntu && aufs') {
      deleteDir()
      checkout scm
      unstash 'bundles-experimental-binary'
      unstash 'bundles-experimental-cross'
      withChownWorkspace { sh("make DOCKER_BUILD_IMG=${dockerBuildImgDigest} tgz-experimental") }
      archiveArtifacts 'bundles-experimental/*/tgz/**'
    }
  },
  'build-deb': {
    wrappedNode(label: 'docker && ubuntu && aufs') {
      deleteDir()
      checkout scm
      unstash 'bundles-binary'
      unstash 'bundles-dynbinary'
      withChownWorkspace { sh("make DOCKER_BUILD_IMG=${dockerBuildImgDigest} deb") }
      archiveArtifacts 'bundles/*/build-deb/**'
    }
  },
  'build-deb-experimental': {
    wrappedNode(label: 'docker && ubuntu && aufs') {
      deleteDir()
      checkout scm
      unstash 'bundles-experimental-binary'
      unstash 'bundles-experimental-dynbinary'
      withChownWorkspace { sh("make DOCKER_BUILD_IMG=${dockerBuildImgDigest} deb-experimental") }
      archiveArtifacts 'bundles-experimental/*/build-deb/**'
    }
  },
  'build-ubuntu': {
    wrappedNode(label: 'docker && ubuntu && aufs') {
      deleteDir()
      checkout scm
      unstash 'bundles-binary'
      unstash 'bundles-dynbinary'
      withChownWorkspace { sh("make DOCKER_BUILD_IMG=${dockerBuildImgDigest} ubuntu") }
      archiveArtifacts 'bundles/*/build-deb/**'
    }
  },
  'build-ubuntu-experimental': {
    wrappedNode(label: 'docker && ubuntu && aufs') {
      deleteDir()
      checkout scm
      unstash 'bundles-experimental-binary'
      unstash 'bundles-experimental-dynbinary'
      withChownWorkspace { sh("make DOCKER_BUILD_IMG=${dockerBuildImgDigest} ubuntu-experimental") }
      archiveArtifacts 'bundles-experimental/*/build-deb/**'
    }
  },
  'build-fedora': {
    wrappedNode(label: 'docker && ubuntu && aufs') {
      deleteDir()
      checkout scm
      unstash 'bundles-binary'
      unstash 'bundles-dynbinary'
      withChownWorkspace { sh("make DOCKER_BUILD_IMG=${dockerBuildImgDigest} fedora") }
      archiveArtifacts 'bundles/*/build-rpm/**'
    }
  },
  'build-fedora-experimental': {
    wrappedNode(label: 'docker && ubuntu && aufs') {
      deleteDir()
      checkout scm
      unstash 'bundles-experimental-binary'
      unstash 'bundles-experimental-dynbinary'
      withChownWorkspace { sh("make DOCKER_BUILD_IMG=${dockerBuildImgDigest} fedora-experimental") }
      archiveArtifacts 'bundles-experimental/*/build-rpm/**'
    }
  },
  'build-centos': {
    wrappedNode(label: 'docker && ubuntu && aufs') {
      deleteDir()
      checkout scm
      unstash 'bundles-binary'
      unstash 'bundles-dynbinary'
      withChownWorkspace { sh("make DOCKER_BUILD_IMG=${dockerBuildImgDigest} centos") }
      archiveArtifacts 'bundles/*/build-rpm/**'
    }
  },
  'build-centos-experimental': {
    wrappedNode(label: 'docker && ubuntu && aufs') {
      deleteDir()
      checkout scm
      unstash 'bundles-experimental-binary'
      unstash 'bundles-experimental-dynbinary'
      withChownWorkspace { sh("make DOCKER_BUILD_IMG=${dockerBuildImgDigest} centos-experimental") }
      archiveArtifacts 'bundles-experimental/*/build-rpm/**'
    }
  },
  'build-oraclelinux': {
    wrappedNode(label: 'docker && ubuntu && aufs') {
      retry(2) {
        deleteDir()
        checkout scm
        unstash 'bundles-binary'
        unstash 'bundles-dynbinary'
        withChownWorkspace { sh("make DOCKER_BUILD_IMG=${dockerBuildImgDigest} oraclelinux") }
        archiveArtifacts 'bundles/*/build-rpm/**'
      }
    }
  },
  'build-oraclelinux-experimental': {
    wrappedNode(label: 'docker && ubuntu && aufs') {
      retry(2) {
        deleteDir()
        checkout scm
        unstash 'bundles-experimental-binary'
        unstash 'bundles-experimental-dynbinary'
        withChownWorkspace { sh("make DOCKER_BUILD_IMG=${dockerBuildImgDigest} oraclelinux-experimental") }
        archiveArtifacts 'bundles-experimental/*/build-rpm/**'
      }
    }
  },
  'build-opensuse': {
    wrappedNode(label: 'docker && ubuntu && aufs') {
      deleteDir()
      checkout scm
      unstash 'bundles-binary'
      unstash 'bundles-dynbinary'
      withChownWorkspace { sh("make DOCKER_BUILD_IMG=${dockerBuildImgDigest} opensuse") }
      archiveArtifacts 'bundles/*/build-rpm/**'
    }
  },
  'build-opensuse-experimental': {
    wrappedNode(label: 'docker && ubuntu && aufs') {
      deleteDir()
      checkout scm
      unstash 'bundles-experimental-binary'
      unstash 'bundles-experimental-dynbinary'
      withChownWorkspace { sh("make DOCKER_BUILD_IMG=${dockerBuildImgDigest} opensuse-experimental") }
      archiveArtifacts 'bundles-experimental/*/build-rpm/**'
    }
  }
]

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
