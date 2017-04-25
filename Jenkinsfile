#!groovy
properties(
  [
    buildDiscarder(logRotator(artifactDaysToKeepStr: '', artifactNumToKeepStr: '', daysToKeepStr: '', numToKeepStr: '10')),
    parameters(
      [
        string(name: 'DOCKER_REPO', defaultValue: 'git@github.com:docker/docker.git', description: 'Docker git source repository.'),
        string(name: 'DOCKER_BRANCH', defaultValue: '17.05.x', description: 'Docker git source repository.'),
        string(name: 'DOCKER_GITCOMMIT', defaultValue: '', description: 'Docker git commit hash to build from. If blank, will auto detect tip of branch of repo')
      ]
    )
  ]
)

this.dockerBuildImgDigest = [amd64: env.DOCKER_BUILD_IMG_AMD64 ?: '', armhf: env.DOCKER_BUILD_IMG_ARMHF ?: '']
this.dockerRepo = ''
this.dockerBranch = ''
this.dockerGitCommit = ''

def getGitCommit(repo = '', branch = '', cred = '') {
  def gitCommit = ''
  sshagent(credentials: [cred], ignoreMissing: true) {
    gitCommit = sh(script: "GIT_SSH_COMMAND='ssh -oStrictHostKeyChecking=no' git ls-remote ${repo} ${branch} | awk '{print\$1;exit}'", returnStdout: true).trim()
  }
  return gitCommit
}

def initParams() {
  if(params.DOCKER_REPO == '') {
    this.dockerRepo = 'https://github.com/docker/docker.git'
  } else {
    this.dockerRepo = params.DOCKER_REPO
  }
  if(params.DOCKER_BRANCH == '') {
    this.dockerBranch = 'master'
  } else {
    this.dockerBranch = params.DOCKER_BRANCH
  }
  if(params.DOCKER_GITCOMMIT == '') {
    this.dockerGitCommit = getGitCommit(this.dockerRepo, this.dockerBranch, 'docker-jenkins.github.ssh')
  } else {
    this.dockerGitCommit = params.DOCKER_GITCOMMIT
  }

  println 'docker repo: ' + this.dockerRepo
  println 'docker branch: ' + this.dockerBranch
  println 'docker gitcommit: ' + this.dockerGitCommit
}

def dockerBuildStep = { Map args=[:], Closure body=null ->
  // Work around groovy closure issues
  def theArgs = args
  def theBody = body
  if (theArgs instanceof Closure) {
    theBody = theArgs
    theArgs = [:]
  }

  def arch = theArgs.arch ?: 'amd64'
  def label = "linux && ${arch}"
  if (arch == 'amd64') {
    label += '&& aufs'
  }

  { ->
    wrappedNode(label: label, cleanWorkspace: true) {
      withChownWorkspace {
        withEnv([
          "DOCKER_BUILD_IMG=${this.dockerBuildImgDigest[arch]}",
          "ARCH=${arch}",
          "DOCKER_REPO=${this.DOCKER_REPO}",
          "DOCKER_GITCOMMIT=${this.dockerGitCommit}",
        ]) {
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
        sh("${awscli} s3 cp --only-show-errors '${args.name}.tar.gz' '${destS3Uri}'")
    }
    sh("rm -f '${args.name}.tar.gz'")
}

def unstashS3(def name = '', def awscli = 'docker run --rm -e AWS_SECRET_ACCESS_KEY -e AWS_ACCESS_KEY_ID -v `pwd`:/z -w /z anigeo/awscli') {
    def srcS3Uri = "s3://docker-ci-artifacts/ci.qa.aws.dckr.io/${env.BUILD_TAG}/${name}.tar.gz"
    withCredentials([[
        $class: 'AmazonWebServicesCredentialsBinding',
        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY',
        credentialsId: 'ci@docker-qa.aws'
    ]]) {
        sh("${awscli} s3 cp --only-show-errors '${srcS3Uri}' .")
    }
    sh("tar -x -z -v -f '${name}.tar.gz'")
    sh("rm -f '${name}.tar.gz'")
}

def build_docker_dev_steps = [
  'build-docker-dev': dockerBuildStep { ->
    sshagent(['docker-jenkins.github.ssh']) {
      sh('make docker-dev-digest.txt')
    }
    this.dockerBuildImgDigest['amd64'] = readFile('docker-dev-digest.txt').trim()
    stashS3(name: 'docker-src', includes: 'docker/**')
  },
]

def build_binary_steps = [
  'build-binary': dockerBuildStep { ->
    sh('make binary')
    stashS3(name: 'bundles-binary', includes: 'bundles/*/binary*/**')
  }
]

def build_cross_dynbinary_steps = [
  'build-dynbinary': dockerBuildStep { ->
    sh('make dynbinary')
    stashS3(name: 'bundles-dynbinary', includes: 'bundles/*/dynbinary*/**')
  },
  'build-cross': dockerBuildStep { ->
    unstashS3('bundles-binary')
    sh('make cross')
    stashS3(name: 'bundles-cross', includes: 'bundles/*/cross/**')
  }
]

def build_package_steps = [
  'build-tgz': dockerBuildStep {
    unstashS3('bundles-binary')
    unstashS3('bundles-cross')
    sh('make tgz')
    stashS3(name: 'bundles-tgz', includes: 'bundles/*/tgz/**')
  },
  'build-deb': dockerBuildStep {
    unstashS3('bundles-binary')
    unstashS3('docker-src')
    sh('make deb')
    stashS3(name: 'bundles-debian', includes: 'bundles/*/build-deb/**')
  },
  'build-ubuntu': dockerBuildStep {
    unstashS3('bundles-binary')
    unstashS3('docker-src')
    sh('make ubuntu')
    stashS3(name: 'bundles-ubuntu', includes: 'bundles/*/build-deb/**')
  },
  'build-fedora': dockerBuildStep {
    unstashS3('bundles-binary')
    unstashS3('docker-src')
    retry(2) { sh('make fedora') }
    stashS3(name: 'bundles-fedora', includes: 'bundles/*/build-rpm/**')
  },
  'build-centos': dockerBuildStep {
    unstashS3('bundles-binary')
    unstashS3('docker-src')
    sh('make centos')
    stashS3(name: 'bundles-centos', includes: 'bundles/*/build-rpm/**')
  },
  'build-oraclelinux': dockerBuildStep {
    unstashS3('bundles-binary')
    unstashS3('docker-src')
    retry(2) { sh('make oraclelinux') }
    stashS3(name: 'bundles-oraclelinux', includes: 'bundles/*/build-rpm/**')
  },
  'build-opensuse': dockerBuildStep {
    unstashS3('bundles-binary')
    unstashS3('docker-src')
    sh('make opensuse')
    stashS3(name: 'bundles-opensuse', includes: 'bundles/*/build-rpm/**')
  }
]

def build_pkgs_armhf = [
  'build-debian-jessie-arm': dockerBuildStep(arch: 'armhf') {
    sh('make binary')
    unstashS3('docker-src', 'aws')
    sh('make DOCKER_BUILD_PKGS=debian-jessie deb-arm')
    stashS3(name: 'bundles-debian-jessie-arm', includes: 'bundles/*/build-deb/**', awscli: 'aws')
  },
  'build-raspbian-jessie-arm': dockerBuildStep(arch: 'armhf') {
    sh('make binary')
    unstashS3('docker-src', 'aws')
    sh('make DOCKER_BUILD_PKGS=raspbian-jessie deb-arm')
    stashS3(name: 'bundles-raspbian-jessie-arm', includes: 'bundles/*/build-deb/**', awscli: 'aws')
  },
  'build-ubuntu-trusty-arm': dockerBuildStep(arch: 'armhf') {
    sh('make binary')
    unstashS3('docker-src', 'aws')
    sh('make DOCKER_BUILD_PKGS=ubuntu-trusty ubuntu-arm')
    stashS3(name: 'bundles-ubuntu-trusty-arm', includes: 'bundles/*/build-deb/**', awscli: 'aws')
  },
  'build-ubuntu-xenial-arm': dockerBuildStep(arch: 'armhf') {
    sh('make binary')
    unstashS3('docker-src', 'aws')
    sh('make DOCKER_BUILD_PKGS=ubuntu-xenial ubuntu-arm')
    stashS3(name: 'bundles-ubuntu-xenial-arm', includes: 'bundles/*/build-deb/**', awscli: 'aws')
  },
]

def build_docker_dev_armhf = [
  'build-docker-dev-arm': dockerBuildStep(arch: 'armhf') {
    sshagent(['docker-jenkins.github.ssh']) {
      sh('make docker-dev-digest.txt')
    }
    this.dockerBuildImgDigest['armhf'] = readFile('docker-dev-digest.txt').trim()
  },
]

def arch_steps = [
  'amd64': {
    stage('build docker-dev amd64') {
      timeout(time: 1, unit: 'HOURS') { parallel(build_docker_dev_steps) }
    }
    stage('build binary amd64') {
      timeout(time: 1, unit: 'HOURS') { parallel(build_binary_steps) }
    }
    stage('build cross dynbinary amd64') {
      timeout(time: 1, unit: 'HOURS') { parallel(build_cross_dynbinary_steps) }
    }
    stage('build pkgs amd64') {
      timeout(time: 2, unit: 'HOURS') { parallel(build_package_steps) }
    }
  },
  'arm': {
    stage('build docker-dev armhf') {
      timeout(time: 1, unit: 'HOURS') { parallel(build_docker_dev_armhf) }
    }
    stage('build pkgs armhf') {
      timeout(time: 2, unit: 'HOURS') { parallel(build_pkgs_armhf) }
    }
  }
]

stage('init') {
  node(label: 'aufs') {
    initParams()
  }
}

parallel(arch_steps)
