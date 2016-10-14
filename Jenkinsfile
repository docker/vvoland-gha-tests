#!groovy
properties(
  [
    buildDiscarder(logRotator(artifactDaysToKeepStr: '', artifactNumToKeepStr: '', daysToKeepStr: '', numToKeepStr: '5')),
    [
      $class: 'RebuildSettings',
      autoRebuild: false,
      rebuildDisabled: false
    ],
    parameters(
      [
        string(defaultValue: 'bb80604a0b200140a440675348c848a137a1b2e2', description: '', name: 'GIT_REF'),
        string(defaultValue: 'dockerbuildbot/andrewhsu-docker-dev', description: '', name: 'DOCKER_REPO'),
      ]
    ),
    [
      $class: 'ThrottleJobProperty',
      categories: [],
      limitOneJobWithMatchingParams: false,
      maxConcurrentPerNode: 0,
      maxConcurrentTotal: 0,
      paramsToUseForLimit: '',
      throttleEnabled: false,
      throttleOption: 'project'
    ],
    pipelineTriggers([])
  ]
)

def build_binary_steps = [
  'build-binary': {
    stage(name: 'build binary') {
      wrappedNode(label: 'docker && ubuntu') {
        withChownWorkspace(sh('make binary'))
        stash(name: 'bundles-binary', includes: 'bundles/*/binary*/**')
      }
    }
  },
  'build-binary-experimental': {
    stage(name: 'build binary experimental') {
      wrappedNode(label: 'docker && ubuntu') {
        withChownWorkspace(sh('make binary-experimental'))
        stash(name: 'bundles-experimental-binary', includes: 'bundles-experimental/*/binary*/**')
      }
    }
  }
]

def build_cross_dynbinary_steps = [
  'build-dynbinary': {
    stage(name: 'build dynbinary') {
      wrappedNode(label: 'docker && ubuntu') {
        withChownWorkspace(sh('make dynbinary'))
        stash(name: 'bundles-dynbinary', includes: 'bundles/*/dynbinary*/**')
      }
    }
  },
 'build-dynbinary-experimental': {
    stage(name: 'build dynbinary experimental') {
      wrappedNode(label: 'docker && ubuntu') {
        withChownWorkspace(sh('make dynbinary-experimental'))
        stash(name: 'bundles-experimental-dynbinary', includes: 'bundles-experimental/*/dynbinary*/**')
      }
    }
  },
  'build-cross': {
    stage(name: 'build cross') {
      wrappedNode(label: 'docker && ubuntu') {
        unstash 'bundles-binary'
        withChownWorkspace(sh('make cross'))
        stash(name: 'bundles-cross', includes: 'bundles/*/cross/**')
      }
    }
  },
  'build-cross-experimental': {
    stage(name: 'build cross experimental') {
      wrappedNode(label: 'docker && ubuntu') {
        unstash 'bundles-experimental-binary'
        withChownWorkspace(sh('make cross-experimental'))
        stash(name: 'bundles-experimental-cross', includes: 'bundles-experimental/*/cross/**')
      }
    }
  }
]

def build_package_steps = [
  'build-tgz': {
    stage(name: 'build tgz') {
      wrappedNode(label: 'docker && ubuntu') {
        unstash 'bundles-binary'
        unstash 'bundles-cross'
        withChownWorkspace(sh('make tgz'))
        archiveArtifacts 'bundles/*/tgz/**'
      }
    }
  },
  'build-tgz-experimental': {
    stage(name: 'build tgz experimental') {
      wrappedNode(label: 'docker && ubuntu') {
        unstash 'bundles-experimental-binary'
        unstash 'bundles-experimental-cross'
        withChownWorkspace(sh('make tgz-experimental'))
        archiveArtifacts 'bundles-experimental/*/tgz/**'
      }
    }
  },
  'build-deb': {
    stage(name: 'build deb') {
      wrappedNode(label: 'docker && ubuntu') {
        unstash 'bundles-binary'
        unstash 'bundles-dynbinary'
        withChownWorkspace(sh('make deb'))
        archiveArtifacts 'bundles/*/build-deb/**'
      }
    }
  },
  'build-deb-experimental': {
    stage(name: 'build deb experimental') {
      wrappedNode(label: 'docker && ubuntu') {
        unstash 'bundles-experimental-binary'
        unstash 'bundles-experimental-dynbinary'
        withChownWorkspace(sh('make deb-experimental'))
        archiveArtifacts 'bundles-experimental/*/build-deb/**'
      }
    }
  },
  'build-ubuntu': {
    stage(name: 'build ubuntu') {
      wrappedNode(label: 'docker && ubuntu') {
        unstash 'bundles-binary'
        unstash 'bundles-dynbinary'
        withChownWorkspace(sh('make ubuntu'))
        archiveArtifacts 'bundles/*/build-deb/**'
      }
    }
  },
  'build-ubuntu-experimental': {
    stage(name: 'build ubuntu experimental') {
      wrappedNode(label: 'docker && ubuntu') {
        unstash 'bundles-experimental-binary'
        unstash 'bundles-experimental-dynbinary'
        withChownWorkspace(sh('make ubuntu-experimental'))
        archiveArtifacts 'bundles-experimental/*/build-deb/**'
      }
    }
  },
  'build-fedora': {
    stage(name: 'build fedora') {
      wrappedNode(label: 'docker && ubuntu') {
        unstash 'bundles-binary'
        unstash 'bundles-dynbinary'
        withChownWorkspace(sh('make fedora'))
        archiveArtifacts 'bundles/*/build-rpm/**'
      }
    }
  },
  'build-fedora-experimental': {
    stage(name: 'build fedora experimental') {
      wrappedNode(label: 'docker && ubuntu') {
        unstash 'bundles-experimental-binary'
        unstash 'bundles-experimental-dynbinary'
        withChownWorkspace(sh('make fedora-experimental'))
        archiveArtifacts 'bundles-experimental/*/build-rpm/**'
      }
    }
  },
  'build-centos': {
    stage(name: 'build centos') {
      wrappedNode(label: 'docker && ubuntu') {
        unstash 'bundles-binary'
        unstash 'bundles-dynbinary'
        withChownWorkspace(sh('make centos'))
        archiveArtifacts 'bundles/*/build-rpm/**'
      }
    }
  },
  'build-centos-experimental': {
    stage(name: 'build centos experimental') {
      wrappedNode(label: 'docker && ubuntu') {
        unstash 'bundles-experimental-binary'
        unstash 'bundles-experimental-dynbinary'
        withChownWorkspace(sh('make centos-experimental'))
        archiveArtifacts 'bundles-experimental/*/build-rpm/**'
      }
    }
  },
  'build-oraclelinux': {
    stage(name: 'build oraclelinux') {
      wrappedNode(label: 'docker && ubuntu') {
        unstash 'bundles-binary'
        unstash 'bundles-dynbinary'
        withChownWorkspace(sh('make oraclelinux'))
        archiveArtifacts 'bundles/*/build-rpm/**'
      }
    }
  },
  'build-oraclelinux-experimental': {
    stage(name: 'build oraclelinux experimental') {
      wrappedNode(label: 'docker && ubuntu') {
        unstash 'bundles-experimental-binary'
        unstash 'bundles-experimental-dynbinary'
        withChownWorkspace(sh('make oraclelinux-experimental'))
        archiveArtifacts 'bundles-experimental/*/build-rpm/**'
      }
    }
  },
  'build-opensuse': {
    stage(name: 'build opensuse') {
      wrappedNode(label: 'docker && ubuntu') {
        unstash 'bundles-binary'
        unstash 'bundles-dynbinary'
        withChownWorkspace(sh('make opensuse'))
        archiveArtifacts 'bundles/*/build-rpm/**'
      }
    }
  },
  'build-opensuse-experimental': {
    stage(name: 'build opensuse experimental') {
      wrappedNode(label: 'docker && ubuntu') {
        unstash 'bundles-experimental-binary'
        unstash 'bundles-experimental-dynbinary'
        withChownWorkspace(sh('make opensuse-experimental'))
        archiveArtifacts 'bundles-experimental/*/build-rpm/**'
      }
    }
  }
]

parallel(build_binary_steps)
parallel(build_cross_dynbinary_steps)
parallel(build_package_steps)
