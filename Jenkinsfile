#!groovy
properties(
  [
    buildDiscarder(logRotator(artifactDaysToKeepStr: '', artifactNumToKeepStr: '', daysToKeepStr: '', numToKeepStr: '5')),
    parameters(
      [
        string(defaultValue: '', description: '', name: 'GIT_REF'),
        string(defaultValue: 'dockerbuildbot/docker-dev', description: '', name: 'DOCKER_REPO'),
      ]
    )
  ]
)

def build_binary_steps = [
  'build-binary': {
    wrappedNode(label: 'docker && ubuntu && aufs') {
      checkout scm
      withChownWorkspace(sh('make binary'))
      stash(name: 'bundles-binary', includes: 'bundles/*/binary*/**')
    }
  },
  'build-binary-experimental': {
    wrappedNode(label: 'docker && ubuntu && aufs') {
      checkout scm
      withChownWorkspace(sh('make binary-experimental'))
      stash(name: 'bundles-experimental-binary', includes: 'bundles-experimental/*/binary*/**')
    }
  }
]

def build_cross_dynbinary_steps = [
  'build-dynbinary': {
    wrappedNode(label: 'docker && ubuntu && aufs') {
      checkout scm
      withChownWorkspace(sh('make dynbinary'))
      stash(name: 'bundles-dynbinary', includes: 'bundles/*/dynbinary*/**')
    }
  },
 'build-dynbinary-experimental': {
    wrappedNode(label: 'docker && ubuntu && aufs') {
      checkout scm
      withChownWorkspace(sh('make dynbinary-experimental'))
      stash(name: 'bundles-experimental-dynbinary', includes: 'bundles-experimental/*/dynbinary*/**')
    }
  },
  'build-cross': {
    wrappedNode(label: 'docker && ubuntu && aufs') {
      checkout scm
      unstash 'bundles-binary'
      withChownWorkspace(sh('make cross'))
      stash(name: 'bundles-cross', includes: 'bundles/*/cross/**')
    }
  },
  'build-cross-experimental': {
    wrappedNode(label: 'docker && ubuntu && aufs') {
      checkout scm
      unstash 'bundles-experimental-binary'
      withChownWorkspace(sh('make cross-experimental'))
      stash(name: 'bundles-experimental-cross', includes: 'bundles-experimental/*/cross/**')
    }
  }
]

def build_package_steps = [
  'build-tgz': {
    wrappedNode(label: 'docker && ubuntu && aufs') {
      checkout scm
      unstash 'bundles-binary'
      unstash 'bundles-cross'
      withChownWorkspace(sh('make tgz'))
      archiveArtifacts 'bundles/*/tgz/**'
    }
  },
  'build-tgz-experimental': {
    wrappedNode(label: 'docker && ubuntu && aufs') {
      checkout scm
      unstash 'bundles-experimental-binary'
      unstash 'bundles-experimental-cross'
      withChownWorkspace(sh('make tgz-experimental'))
      archiveArtifacts 'bundles-experimental/*/tgz/**'
    }
  },
  'build-deb': {
    wrappedNode(label: 'docker && ubuntu && aufs') {
      checkout scm
      unstash 'bundles-binary'
      unstash 'bundles-dynbinary'
      withChownWorkspace(sh('make deb'))
      archiveArtifacts 'bundles/*/build-deb/**'
    }
  },
  'build-deb-experimental': {
    wrappedNode(label: 'docker && ubuntu && aufs') {
      checkout scm
      unstash 'bundles-experimental-binary'
      unstash 'bundles-experimental-dynbinary'
      withChownWorkspace(sh('make deb-experimental'))
      archiveArtifacts 'bundles-experimental/*/build-deb/**'
    }
  },
  'build-ubuntu': {
    wrappedNode(label: 'docker && ubuntu && aufs') {
      checkout scm
      unstash 'bundles-binary'
      unstash 'bundles-dynbinary'
      withChownWorkspace(sh('make ubuntu'))
      archiveArtifacts 'bundles/*/build-deb/**'
    }
  },
  'build-ubuntu-experimental': {
    wrappedNode(label: 'docker && ubuntu && aufs') {
      checkout scm
      unstash 'bundles-experimental-binary'
      unstash 'bundles-experimental-dynbinary'
      withChownWorkspace(sh('make ubuntu-experimental'))
      archiveArtifacts 'bundles-experimental/*/build-deb/**'
    }
  },
  'build-fedora': {
    wrappedNode(label: 'docker && ubuntu && aufs') {
      checkout scm
      unstash 'bundles-binary'
      unstash 'bundles-dynbinary'
      withChownWorkspace(sh('make fedora'))
      archiveArtifacts 'bundles/*/build-rpm/**'
    }
  },
  'build-fedora-experimental': {
    wrappedNode(label: 'docker && ubuntu && aufs') {
      checkout scm
      unstash 'bundles-experimental-binary'
      unstash 'bundles-experimental-dynbinary'
      withChownWorkspace(sh('make fedora-experimental'))
      archiveArtifacts 'bundles-experimental/*/build-rpm/**'
    }
  },
  'build-centos': {
    wrappedNode(label: 'docker && ubuntu && aufs') {
      checkout scm
      unstash 'bundles-binary'
      unstash 'bundles-dynbinary'
      withChownWorkspace(sh('make centos'))
      archiveArtifacts 'bundles/*/build-rpm/**'
    }
  },
  'build-centos-experimental': {
    wrappedNode(label: 'docker && ubuntu && aufs') {
      checkout scm
      unstash 'bundles-experimental-binary'
      unstash 'bundles-experimental-dynbinary'
      withChownWorkspace(sh('make centos-experimental'))
      archiveArtifacts 'bundles-experimental/*/build-rpm/**'
    }
  },
  'build-oraclelinux': {
    wrappedNode(label: 'docker && ubuntu && aufs') {
      checkout scm
      unstash 'bundles-binary'
      unstash 'bundles-dynbinary'
      withChownWorkspace(sh('make oraclelinux'))
      archiveArtifacts 'bundles/*/build-rpm/**'
    }
  },
  'build-oraclelinux-experimental': {
    wrappedNode(label: 'docker && ubuntu && aufs') {
      checkout scm
      unstash 'bundles-experimental-binary'
      unstash 'bundles-experimental-dynbinary'
      withChownWorkspace(sh('make oraclelinux-experimental'))
      archiveArtifacts 'bundles-experimental/*/build-rpm/**'
    }
  },
  'build-opensuse': {
    wrappedNode(label: 'docker && ubuntu && aufs') {
      checkout scm
      unstash 'bundles-binary'
      unstash 'bundles-dynbinary'
      withChownWorkspace(sh('make opensuse'))
      archiveArtifacts 'bundles/*/build-rpm/**'
    }
  },
  'build-opensuse-experimental': {
    wrappedNode(label: 'docker && ubuntu && aufs') {
      checkout scm
      unstash 'bundles-experimental-binary'
      unstash 'bundles-experimental-dynbinary'
      withChownWorkspace(sh('make opensuse-experimental'))
      archiveArtifacts 'bundles-experimental/*/build-rpm/**'
    }
  }
]

stage(name: 'build binary steps') {
  parallel(build_binary_steps)
}
stage(name: 'build cross dynbinary steps') {
  parallel(build_cross_dynbinary_steps)
}
stage(name: 'build package steps') {
  parallel(build_package_steps)
}
