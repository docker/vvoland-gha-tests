SHELL:=/bin/bash
DOCKER_BUILD_IMG?='' # Jenkinsfile should populate this var with contents of docker-dev-digest.txt
CONTAINER_NAME:=$(BUILD_TAG)-$(EXECUTOR_NUMBER)-$(shell date | md5sum | head -c6)
VOL_MNT_STABLE:=$(WORKSPACE)/bundles:/go/src/github.com/docker/docker/bundles
DOCKER_BUILD_PKGS?='' # if left empty, hack/make.sh will build all packages
DOCKER_GITCOMMIT?=''

docker-dev-digest.txt: build-docker-dev
	./$<

binary:
	docker run --rm --privileged --name $(CONTAINER_NAME) -v $(VOL_MNT_STABLE) -e DOCKER_GITCOMMIT \
		$(DOCKER_BUILD_IMG) hack/make.sh binary
	./fix-bundles-symlinks bundles

dynbinary:
	docker run --rm --privileged --name $(CONTAINER_NAME) -v $(VOL_MNT_STABLE) -e DOCKER_GITCOMMIT \
		$(DOCKER_BUILD_IMG) hack/make.sh dynbinary
	./fix-bundles-symlinks bundles

cross:
	docker run --rm --privileged --name $(CONTAINER_NAME) -v $(VOL_MNT_STABLE) -e DOCKER_GITCOMMIT -e KEEPBUNDLE=1 \
		$(DOCKER_BUILD_IMG) hack/make.sh cross
	./fix-bundles-symlinks bundles

tgz:
	docker run --rm --privileged --name $(CONTAINER_NAME) -v $(VOL_MNT_STABLE) -e DOCKER_GITCOMMIT -e KEEPBUNDLE=1 \
		$(DOCKER_BUILD_IMG) hack/make.sh tgz
	docker run --rm --privileged --name $(CONTAINER_NAME) -v $(VOL_MNT_STABLE) -e DOCKER_GITCOMMIT -e KEEPBUNDLE=1 -e GOOS=windows \
		$(DOCKER_BUILD_IMG) hack/make.sh tgz
	$(RM) -r "$(WORKSPACE)/bundles/latest"

deb:
	DOCKER_GRAPHDRIVER=$(shell docker info | awk -F ': ' '$$1 == "Storage Driver" { print $$2; exit }' ) && \
		docker run --rm --privileged --name $(CONTAINER_NAME) -v $(VOL_MNT_STABLE) -e DOCKER_GITCOMMIT -e KEEPBUNDLE=1 \
		-e "DOCKER_GRAPHDRIVER=$$DOCKER_GRAPHDRIVER" \
		-e "DOCKER_BUILD_PKGS=debian-jessie debian-stretch debian-wheezy" \
		-e "DOCKER_BUILD_ARGS=--build-arg=APT_MIRROR=ftp.us.debian.org" \
		$(DOCKER_BUILD_IMG) hack/make.sh build-deb
	$(RM) -r "$(WORKSPACE)/bundles/latest"

deb-arm:
	DOCKER_GRAPHDRIVER=$(shell docker info | awk -F ': ' '$$1 == "Storage Driver" { print $$2; exit }' ) && \
		docker run --rm --privileged --name $(CONTAINER_NAME) -v $(VOL_MNT_STABLE) -e DOCKER_GITCOMMIT -e KEEPBUNDLE=1 \
			-e "DOCKER_GRAPHDRIVER=$$DOCKER_GRAPHDRIVER" \
			-e "DOCKER_BUILD_PKGS" \
			-e "DOCKER_BUILD_ARGS=--build-arg=APT_MIRROR=ftp.fr.debian.org" \
		$(DOCKER_BUILD_IMG) hack/make.sh build-deb
	$(RM) -r "$(WORKSPACE)/bundles/latest"

ubuntu-arm:
	DOCKER_GRAPHDRIVER=$(shell docker info | awk -F ': ' '$$1 == "Storage Driver" { print $$2; exit }' ) && \
		docker run --rm --privileged --name $(CONTAINER_NAME) -v $(VOL_MNT_STABLE) -e DOCKER_GITCOMMIT -e KEEPBUNDLE=1 \
			-e "DOCKER_GRAPHDRIVER=$$DOCKER_GRAPHDRIVER" \
			-e "DOCKER_BUILD_PKGS" \
		$(DOCKER_BUILD_IMG) hack/make.sh build-deb
	$(RM) -r "$(WORKSPACE)/bundles/latest"

ubuntu:
	DOCKER_GRAPHDRIVER=$(shell docker info | awk -F ': ' '$$1 == "Storage Driver" { print $$2; exit }' ) && \
		docker run --rm --privileged --name $(CONTAINER_NAME) -v $(VOL_MNT_STABLE) -e DOCKER_GITCOMMIT -e KEEPBUNDLE=1 \
		-e "DOCKER_GRAPHDRIVER=$$DOCKER_GRAPHDRIVER" \
		-e "DOCKER_BUILD_PKGS=ubuntu-precise ubuntu-trusty ubuntu-wily ubuntu-xenial ubuntu-yakkety" \
		$(DOCKER_BUILD_IMG) hack/make.sh build-deb
	$(RM) -r "$(WORKSPACE)/bundles/latest"

fedora:
	DOCKER_GRAPHDRIVER=$(shell docker info | awk -F ': ' '$$1 == "Storage Driver" { print $$2; exit }' ) && \
		docker run --rm --privileged --name $(CONTAINER_NAME) -v $(VOL_MNT_STABLE) -e DOCKER_GITCOMMIT -e KEEPBUNDLE=1 \
		-e "DOCKER_GRAPHDRIVER=$$DOCKER_GRAPHDRIVER" \
		-e "DOCKER_BUILD_PKGS=fedora-23 fedora-24 fedora-25" \
		$(DOCKER_BUILD_IMG) hack/make.sh build-rpm
	$(RM) -r "$(WORKSPACE)/bundles/latest"

centos:
	DOCKER_GRAPHDRIVER=$(shell docker info | awk -F ': ' '$$1 == "Storage Driver" { print $$2; exit }' ) && \
		docker run --rm --privileged --name $(CONTAINER_NAME) -v $(VOL_MNT_STABLE) -e DOCKER_GITCOMMIT -e KEEPBUNDLE=1 \
		-e "DOCKER_GRAPHDRIVER=$$DOCKER_GRAPHDRIVER" \
		-e "DOCKER_BUILD_PKGS=centos-7" \
		$(DOCKER_BUILD_IMG) hack/make.sh build-rpm
	$(RM) -r "$(WORKSPACE)/bundles/latest"

oraclelinux:
	DOCKER_GRAPHDRIVER=$(shell docker info | awk -F ': ' '$$1 == "Storage Driver" { print $$2; exit }' ) && \
		docker run --rm --privileged --name $(CONTAINER_NAME) -v $(VOL_MNT_STABLE) -e DOCKER_GITCOMMIT -e KEEPBUNDLE=1 \
		-e "DOCKER_GRAPHDRIVER=$$DOCKER_GRAPHDRIVER" \
		-e "DOCKER_BUILD_PKGS=oraclelinux-6 oraclelinux-7" \
		$(DOCKER_BUILD_IMG) hack/make.sh build-rpm
	$(RM) -r "$(WORKSPACE)/bundles/latest"

opensuse:
	DOCKER_GRAPHDRIVER=$(shell docker info | awk -F ': ' '$$1 == "Storage Driver" { print $$2; exit }' ) && \
		docker run --rm --privileged --name $(CONTAINER_NAME) -v $(VOL_MNT_STABLE) -e DOCKER_GITCOMMIT -e KEEPBUNDLE=1 \
		-e "DOCKER_GRAPHDRIVER=$$DOCKER_GRAPHDRIVER" \
		-e "DOCKER_BUILD_PKGS=opensuse-13.2" \
		$(DOCKER_BUILD_IMG) hack/make.sh build-rpm
	$(RM) -r "$(WORKSPACE)/bundles/latest"
