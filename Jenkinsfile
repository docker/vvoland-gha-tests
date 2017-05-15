#!groovy
properties(
  [
    buildDiscarder(logRotator(artifactDaysToKeepStr: '', artifactNumToKeepStr: '', daysToKeepStr: '', numToKeepStr: '20')),
    parameters(
      [
        string(name: 'DOCKER_REPO', defaultValue: 'git@github.com:docker/docker-ce.git', description: 'Docker git source repository.'),
        string(name: 'DOCKER_BRANCH', defaultValue: 'master', description: 'Docker git source repository.'),
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
    this.dockerRepo = 'git@github.com:docker/ce-docker.git'
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

def build_pkgs_amd64 = [
  'build-tgz-amd64': dockerBuildStep {
    sshagent(['docker-jenkins.github.ssh']) {
      sh('make tgz')
    }
  },
]

def build_pkgs_armhf = [
  'build-tgz-armhf': dockerBuildStep(arch: 'armhf') {
    sshagent(['docker-jenkins.github.ssh']) {
      sh('make tgz')
    }
  },
]

def arch_steps = [
  'amd64': {
    stage('build pkgs amd64') {
      timeout(time: 1, unit: 'HOURS') { parallel(build_pkgs_amd64) }
    }
  },
  'armhf': {
    stage('build pkgs armhf') {
      timeout(time: 1, unit: 'HOURS') { parallel(build_pkgs_armhf) }
    }
  }
]

stage('init') {
  node(label: 'aufs') {
    initParams()
  }
}

parallel(arch_steps)
