#!groovy
properties(
  [
    buildDiscarder(logRotator(artifactDaysToKeepStr: '', artifactNumToKeepStr: '', daysToKeepStr: '', numToKeepStr: '30')),
    parameters(
      [
        string(name: 'DOCKER_CE_REPO', defaultValue: 'git@github.com:docker/docker-ce.git', description: 'Docker git source repository.'),
        string(name: 'DOCKER_CE_BRANCH', defaultValue: '17.06', description: 'Docker git source repository.'),
        string(name: 'DOCKER_CE_GITCOMMIT', defaultValue: '', description: 'Docker git commit hash to build from. If blank, will auto detect tip of branch of repo')
      ]
    )
  ]
)

def saveS3(def Map args=[:]) {
    def destS3Uri = "s3://docker-ci-artifacts/ci.qa.aws.dckr.io/${env.BUILD_TAG}/"
    def awscli = "docker run --rm -e AWS_SECRET_ACCESS_KEY -e AWS_ACCESS_KEY_ID -v `pwd`:/z -w /z ${args.awscli_image}"
    withCredentials([[
        $class: 'AmazonWebServicesCredentialsBinding',
        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY',
        credentialsId: 'ci@docker-qa.aws'
    ]]) {
        sh("${awscli} s3 cp --only-show-errors '${args.name}' '${destS3Uri}'")
    }
}

def genBuildResult(def Map args=[:]) {
    def destS3Uri = "s3://docker-ci-artifacts/ci.qa.aws.dckr.io/${env.BUILD_TAG}/"
    def awscli = "docker run --rm -e AWS_SECRET_ACCESS_KEY -e AWS_ACCESS_KEY_ID -v `pwd`:/z -w /z ${args.awscli_image}"
    withCredentials([[
        $class: 'AmazonWebServicesCredentialsBinding',
        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY',
        credentialsId: 'ci@docker-qa.aws'
    ]]) {
        sh("${awscli} s3 ls '${destS3Uri}' > build-result.txt")
    }
}

def stashS3(def Map args=[:]) {
    def destS3Uri = "s3://docker-ci-artifacts/ci.qa.aws.dckr.io/${env.BUILD_TAG}/"
    def awscli = "docker run --rm -e AWS_SECRET_ACCESS_KEY -e AWS_ACCESS_KEY_ID -v `pwd`:/z -w /z ${args.awscli_image}"
    sh("find . -path './${args.includes}' | tar -c -z -f '${args.name}.tar.gz' -T -")
    withCredentials([[
        $class: 'AmazonWebServicesCredentialsBinding',
        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY',
        credentialsId: 'ci@docker-qa.aws'
    ]]) {
        sh("${awscli} s3 cp --only-show-errors '${args.name}.tar.gz' '${destS3Uri}'")
    }
    sh("rm -f '${args.name}.tar.gz'")
}

def unstashS3(def Map args=[:]) {
    def awscli = "docker run --rm -e AWS_SECRET_ACCESS_KEY -e AWS_ACCESS_KEY_ID -v `pwd`:/z -w /z ${args.awscli_image}"
    def srcS3Uri = "s3://docker-ci-artifacts/ci.qa.aws.dckr.io/${env.BUILD_TAG}/${args.name}.tar.gz"
    withCredentials([[
        $class: 'AmazonWebServicesCredentialsBinding',
        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY',
        credentialsId: 'ci@docker-qa.aws'
    ]]) {
        sh("${awscli} s3 cp --only-show-errors '${srcS3Uri}' .")
    }
    sh("tar -x -z -f '${args.name}.tar.gz'")
    sh("rm -f '${args.name}.tar.gz'")
}

def init_steps = [
  'src': { ->
    stage('src') {
      wrappedNode(label: 'aufs', cleanWorkspace: true) {
        withChownWorkspace {
          checkout scm
          sshagent(['docker-jenkins.github.ssh']) {
            sh("make DOCKER_CE_BRANCH=${params.DOCKER_CE_BRANCH} DOCKER_CE_REPO=${params.DOCKER_CE_REPO} docker-ce.tar.gz")
          }
          saveS3(name: 'docker-ce.tar.gz', awscli_image: 'anigeo/awscli')
        }
      }
    }
  }
]

def result_steps = [
  'result': { ->
    stage('result') {
      wrappedNode(label: 'aufs', cleanWorkspace: true) {
        withChownWorkspace {
          checkout scm
          unstashS3(name: 'docker-ce', awscli_image: 'anigeo/awscli')
          genBuildResult(awscli_image: 'anigeo/awscli')
          sh('git -C docker-ce rev-parse HEAD >> build-result.txt')
          saveS3(name: 'build-result.txt', awscli_image: 'anigeo/awscli')
        }
      }
    }
  }
]

def amd64_pkgs = [
  'ubuntu-trusty',
  'ubuntu-xenial',
  'ubuntu-yakkety',
  'ubuntu-zesty',
  'debian-stretch',
  'debian-jessie',
  'debian-wheezy',
  'centos-7',
  'fedora-24',
  'fedora-25',
]

def armhf_pkgs = [
  'ubuntu-trusty',
  'ubuntu-xenial',
  'ubuntu-yakkety',
  'ubuntu-zesty',
  'debian-stretch',
  'debian-jessie',
  'debian-wheezy',
]

def genBuildStep(String distro_flavor, String arch, String label, String awscli_image) {
  return [ "${distro_flavor}-${arch}" : { ->
    stage("${distro_flavor}-${arch}") {
      wrappedNode(label: label, cleanWorkspace: true) {
        withChownWorkspace {
          checkout scm
          unstashS3(name: 'docker-ce', awscli_image: awscli_image)
          sh("make ${distro_flavor} bundles-ce-${distro_flavor}-${arch}.tar.gz")
          saveS3(name: "bundles-ce-${distro_flavor}-${arch}.tar.gz", awscli_image: awscli_image)
        }
      }
    }
  } ]
}

def build_package_steps = [
  'static-linux': { ->
    stage('static-linux') {
      wrappedNode(label: 'aufs', cleanWorkspace: true) {
        withChownWorkspace {
          checkout scm
          unstashS3(name: 'docker-ce', awscli_image: 'anigeo/awscli')
          sh('make clean static-linux bundles-ce-binary.tar.gz')
          saveS3(name: 'bundles-ce-binary.tar.gz', awscli_image: 'anigeo/awscli')
        }
      }
    }
  },
  'cross-mac': { ->
    stage('cross-mac') {
      wrappedNode(label: 'aufs', cleanWorkspace: true) {
        withChownWorkspace {
          checkout scm
          unstashS3(name: 'docker-ce', awscli_image: 'anigeo/awscli')
          sh('make clean cross-mac bundles-ce-cross-darwin.tar.gz')
          saveS3(name: 'bundles-ce-cross-darwin.tar.gz', awscli_image: 'anigeo/awscli')
        }
      }
    }
  },
  'cross-win': { ->
    stage('cross-win') {
      wrappedNode(label: 'aufs', cleanWorkspace: true) {
        withChownWorkspace {
          checkout scm
          unstashS3(name: 'docker-ce', awscli_image: 'anigeo/awscli')
          sh('make clean cross-win bundles-ce-cross-windows.tar.gz')
          saveS3(name: 'bundles-ce-cross-windows.tar.gz', awscli_image: 'anigeo/awscli')
        }
      }
    }
  },
  'shell-completion': { ->
    stage('shell-completion') {
      wrappedNode(label: 'aufs', cleanWorkspace: true) {
        withChownWorkspace {
          checkout scm
          unstashS3(name: 'docker-ce', awscli_image: 'anigeo/awscli')
          sh('make clean bundles-ce-shell-completion.tar.gz')
          saveS3(name: 'bundles-ce-shell-completion.tar.gz', awscli_image: 'anigeo/awscli')
        }
      }
    }
  },
]

for (t in amd64_pkgs) {
  build_package_steps << genBuildStep(t, 'amd64', 'aufs', 'anigeo/awscli')
}

for (t in armhf_pkgs) {
  build_package_steps << genBuildStep(t, 'armhf', 'armhf', 'seemethere/awscli-armhf')
}

parallel(init_steps)
parallel(build_package_steps)
parallel(result_steps)
