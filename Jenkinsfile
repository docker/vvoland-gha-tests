#!groovy
properties(
	[
		buildDiscarder(logRotator(artifactDaysToKeepStr: '', artifactNumToKeepStr: '', daysToKeepStr: '', numToKeepStr: '30')),
		parameters(
			[
				string(name: 'DOCKER_CE_REPO', defaultValue: 'git@github.com:docker/docker-ce.git', description: 'Docker git source repository.'),
				string(name: 'DOCKER_CE_REF', defaultValue: '18.02', description: 'Docker CE reference to build from (usually a branch).'),
				string(name: 'ARTIFACT_BUILD_TAG', defaultValue:'', description: 'ONLY USED BY NIGHTLY BUILDS, LEAVE BLANK OTHERWISE'),
				booleanParam(name: 'TRIGGER_RELEASE', description: 'Trigger release after a successful build', defaultValue: false)
			]
		)
	]
)

if ("${params.ARTIFACT_BUILD_TAG}" == "") {
	BUILD_TAG="${env.BUILD_TAG}"
} else {
	BUILD_TAG="${params.ARTIFACT_BUILD_TAG}"
}

awscli_images = [
	amd64: "anigeo/awscli@sha256:f4685e66230dcb77c81dc590140aee61e727936cf47e8f4f19a427fc851844a1",
	armel: "seemethere/awscli-armhf@sha256:2a92eebed76e3e82f3899c6851cfaf8b7eb26d08cabcb5938dfcd66115d37977",
	armhf: "seemethere/awscli-armhf@sha256:2a92eebed76e3e82f3899c6851cfaf8b7eb26d08cabcb5938dfcd66115d37977",
	s390x: "seemethere/awscli-s390x@sha256:198e47b58a868784bce929a1c8dc8a25c521f9ce102a3eb0aa2094d44c241c03",
	ppc64le: "seemethere/awscli-ppc64le@sha256:1f46b7687cc70bbf4f9bcf67c5e779b65c67088f1a946c9759be470a41da06d7",
	aarch64: "seemethere/awscli-aarch64@sha256:2d646ae12278006a710f74e57c27e23fb73eee027f237ab72ebb02ef66a447b9",
]

def saveS3(def Map args=[:]) {
	def destS3Uri = "s3://docker-ci-artifacts/ci.qa.aws.dckr.io/${BUILD_TAG}/"
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
	def destS3Uri = "s3://docker-ci-artifacts/ci.qa.aws.dckr.io/${BUILD_TAG}/"
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
	def destS3Uri = "s3://docker-ci-artifacts/ci.qa.aws.dckr.io/${BUILD_TAG}/"
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
	def srcS3Uri = "s3://docker-ci-artifacts/ci.qa.aws.dckr.io/${BUILD_TAG}/${args.name}.tar.gz"
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
	'init': { ->
		stage('init') {
			wrappedNode(label: 'aufs', cleanWorkspace: true) {
				announceChannel = "#ship-builders"
				// This is only the case on a nightly build
				if (params.ARTIFACT_BUILD_TAG != "") {
					announceChannel = "#release-sprint"
				}
				if (params.TRIGGER_RELEASE) {
					slackSend(channel: announceChannel, message: "Initiating build pipeline. Building packages from `docker/docker-ce:${params.DOCKER_CE_REF}`. ${env.BUILD_URL}")
				}
				checkout scm
				sshagent(['docker-jenkins.github.ssh']) {
					sh("make DOCKER_CE_REF=${params.DOCKER_CE_REF} DOCKER_CE_REPO=${params.DOCKER_CE_REPO} docker-ce.tar.gz")
				}
				saveS3(name: 'docker-ce.tar.gz', awscli_image: awscli_images['amd64'])
			}
		}
	}
]

def result_steps = [
	'result': { ->
		stage('result') {
			wrappedNode(label: 'aufs', cleanWorkspace: true) {
				checkout scm
				unstashS3(name: 'docker-ce', awscli_image: awscli_images['amd64'])
				genBuildResult(awscli_image: awscli_images['amd64'])
				sh('git -C docker-ce rev-parse HEAD >> build-result.txt')
				saveS3(name: 'build-result.txt', awscli_image: awscli_images['amd64'])
				slackSend(channel: "#release-announce-test", message: "Docker CE ${params.DOCKER_CE_REF} https://s3-us-west-2.amazonaws.com/docker-ci-artifacts/ci.qa.aws.dckr.io/${BUILD_TAG}/build-result.txt")
				if (params.TRIGGER_RELEASE) {
					// Triggers builds to go through to staging
					build(
						job: 'docker/release-repo/ce',
						parameters: [
							[$class: 'StringParameterValue', name: 'ARTIFACT_BUILD_TAG', value: "${BUILD_TAG}"],
							[$class: 'BooleanParameterValue', name: 'TRIGGER_RELEASE', value: params.TRIGGER_RELEASE],
						],
						wait: false,
					)
				}
			}
		}
	}
]

def amd64_pkgs = [
	'ubuntu-trusty',
	'ubuntu-xenial',
	'ubuntu-artful',
	'debian-buster',
	'debian-stretch',
	'debian-jessie',
	'debian-wheezy',
	'centos-7',
	'fedora-26',
	'fedora-27',
]

def armhf_pkgs = [
	'ubuntu-trusty',
	'ubuntu-xenial',
	'ubuntu-artful',
	'debian-buster',
	'debian-stretch',
	'debian-jessie',
	'raspbian-jessie',
	'raspbian-stretch',
]

def s390x_pkgs = [
	'ubuntu-artful',
	'ubuntu-xenial',
]

def ppc64le_pkgs = [
	'ubuntu-artful',
	'ubuntu-xenial',
]

def aarch64_pkgs = [
	'ubuntu-xenial',
	'debian-stretch',
	'debian-jessie',
	'centos-7',
	'fedora-26',
	'fedora-27',
]

def static_arches = [
	"amd64",
	"armel",
	"armhf",
	"s390x",
	"ppc64le",
	"aarch64"
]

def genBuildStep(String distro_flavor, String arch, String label, String awscli_image) {
	return [ "${distro_flavor}-${arch}" : { ->
		stage("${distro_flavor}-${arch}") {
			wrappedNode(label: label, cleanWorkspace: true) {
				checkout scm
				unstashS3(name: 'docker-ce', awscli_image: awscli_image)
				retry(3) {
					sh("make clean ${distro_flavor} bundles-ce-${distro_flavor}-${arch}.tar.gz")
				}
				saveS3(name: "bundles-ce-${distro_flavor}-${arch}.tar.gz", awscli_image: awscli_image)
			}
		}
	} ]
}

def genStaticBuildStep(String arch) {
	def label
	switch (arch) {
		case "amd64":
			label = "aufs"
			break
		case "armel":
			label = "armhf"
			break
		default:
			label = arch
			break
	}
	return [ "static-linux-${arch}": { ->
		stage("static-linux-${arch}") {
			wrappedNode(label: label, cleanWorkspace: true) {
				checkout scm
					unstashS3(name: 'docker-ce', awscli_image: awscli_images[arch])
					retry(3) {
						sh("make clean docker-${arch}.tgz")
					}
					saveS3(name: "docker-${arch}.tgz", awscli_image: awscli_images[arch])
			}
		}
	}]
}

def build_package_steps = [
	'cross-mac': { ->
		stage('cross-mac') {
			wrappedNode(label: 'aufs', cleanWorkspace: true) {
				checkout scm
				unstashS3(name: 'docker-ce', awscli_image: awscli_images['amd64'])
				sh('make clean cross-mac bundles-ce-cross-darwin.tar.gz docker-mac.tgz')
				saveS3(name: 'bundles-ce-cross-darwin.tar.gz', awscli_image: awscli_images['amd64'])
				saveS3(name: 'docker-mac.tgz', awscli_image: awscli_images['amd64'])
			}
		}
	},
	'cross-win': { ->
		stage('cross-win') {
			wrappedNode(label: 'aufs', cleanWorkspace: true) {
				checkout scm
				unstashS3(name: 'docker-ce', awscli_image: awscli_images['amd64'])
				sh('make clean cross-win bundles-ce-cross-windows.tar.gz docker-win.zip')
				saveS3(name: 'bundles-ce-cross-windows.tar.gz', awscli_image: awscli_images['amd64'])
				saveS3(name: 'docker-win.zip', awscli_image: awscli_images['amd64'])
			}
		}
	},
	'shell-completion': { ->
		stage('shell-completion') {
			wrappedNode(label: 'aufs', cleanWorkspace: true) {
				checkout scm
				unstashS3(name: 'docker-ce', awscli_image: awscli_images['amd64'])
				sh('make clean bundles-ce-shell-completion.tar.gz')
				saveS3(name: 'bundles-ce-shell-completion.tar.gz', awscli_image: awscli_images['amd64'])
			}
		}
	},
	'bundles-ce-binary': { ->
		stage('bundles-ce-binary') {
			wrappedNode(label: 'aufs', cleanWorkspace: true) {
				checkout scm
				unstashS3(name: 'docker-ce', awscli_image: awscli_images['amd64'])
				sh('make clean static-linux bundles-ce-binary.tar.gz')
				saveS3(name: 'bundles-ce-binary.tar.gz', awscli_image: awscli_images['amd64'])
			}
		}
	},
]

for (arch in static_arches) {
	build_package_steps << genStaticBuildStep(arch)
}

for (t in amd64_pkgs) {
	build_package_steps << genBuildStep(t, 'amd64', 'ubuntu-1604-aufs-edge', awscli_images['amd64'])
}

for (t in armhf_pkgs) {
	build_package_steps << genBuildStep(t, 'armhf', 'armhf', awscli_images['armhf'])
}

for (t in s390x_pkgs) {
	build_package_steps << genBuildStep(t, 's390x', 's390x-ubuntu-1604', awscli_images['s390x'])
}

for (t in ppc64le_pkgs) {
	build_package_steps << genBuildStep(t, 'ppc64le', 'ppc64le-ubuntu-1604', awscli_images['ppc64le'])
}

for (t in aarch64_pkgs) {
	build_package_steps << genBuildStep(t, 'aarch64', 'aarch64', awscli_images['aarch64'])
}

parallel(init_steps)
parallel(build_package_steps)
parallel(result_steps)
