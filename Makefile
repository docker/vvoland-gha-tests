SHELL:=/bin/bash
DOCKER_BUILD_IMG?='' # Jenkinsfile should populate this var with contents of docker-dev-digest.txt
CONTAINER_NAME:=$(BUILD_TAG)-$(EXECUTOR_NUMBER)
VOL_MNT_STABLE:=$(WORKSPACE)/bundles:/go/src/github.com/docker/docker/bundles
VOL_MNT_EXPERIMENTAL:=$(WORKSPACE)/bundles-experimental:/go/src/github.com/docker/docker/bundles
DOCKER_BUILD_PKGS?='' # if left empty, hack/make.sh will build all packages

docker-dev-digest.txt: build-docker-dev
	./$<

binary:
	docker run --rm --privileged --name $(CONTAINER_NAME) -v $(VOL_MNT_STABLE) \
		$(DOCKER_BUILD_IMG) hack/make.sh binary
	./fix-bundles-symlinks bundles

binary-experimental:
	docker run --rm --privileged --name $(CONTAINER_NAME) -v $(VOL_MNT_EXPERIMENTAL) -e DOCKER_EXPERIMENTAL=1 \
		$(DOCKER_BUILD_IMG) hack/make.sh binary
	./fix-bundles-symlinks bundles-experimental

dynbinary:
	docker run --rm --privileged --name $(CONTAINER_NAME) -v $(VOL_MNT_STABLE) \
		$(DOCKER_BUILD_IMG) hack/make.sh dynbinary
	./fix-bundles-symlinks bundles

dynbinary-experimental:
	docker run --rm --privileged --name $(CONTAINER_NAME) -v $(VOL_MNT_EXPERIMENTAL) -e DOCKER_EXPERIMENTAL=1 \
		$(DOCKER_BUILD_IMG) hack/make.sh dynbinary
	./fix-bundles-symlinks bundles-experimental

cross:
	docker run --rm --privileged --name $(CONTAINER_NAME) -v $(VOL_MNT_STABLE) -e KEEPBUNDLE=1 \
		$(DOCKER_BUILD_IMG) hack/make.sh cross
	./fix-bundles-symlinks bundles

cross-experimental:
	docker run --rm --privileged --name $(CONTAINER_NAME) -v $(VOL_MNT_EXPERIMENTAL) -e KEEPBUNDLE=1 -e DOCKER_EXPERIMENTAL=1 \
		$(DOCKER_BUILD_IMG) hack/make.sh cross
	./fix-bundles-symlinks bundles-experimental

tgz:
	docker run --rm --privileged --name $(CONTAINER_NAME) -v $(VOL_MNT_STABLE) -e KEEPBUNDLE=1 \
		$(DOCKER_BUILD_IMG) hack/make.sh tgz
	docker run --rm --privileged --name $(CONTAINER_NAME) -v $(VOL_MNT_STABLE) -e KEEPBUNDLE=1 -e GOOS=windows \
		$(DOCKER_BUILD_IMG) hack/make.sh tgz
	$(RM) -r "$(WORKSPACE)/bundles/latest"

tgz-experimental:
	docker run --rm --privileged --name $(CONTAINER_NAME) -v $(VOL_MNT_EXPERIMENTAL) -e KEEPBUNDLE=1 -e DOCKER_EXPERIMENTAL=1 \
		$(DOCKER_BUILD_IMG) hack/make.sh tgz
	docker run --rm --privileged --name $(CONTAINER_NAME) -v $(VOL_MNT_EXPERIMENTAL) -e KEEPBUNDLE=1 -e GOOS=windows -e DOCKER_EXPERIMENTAL=1 \
		$(DOCKER_BUILD_IMG) hack/make.sh tgz
	$(RM) -r "$(WORKSPACE)/bundles-experimental/latest"

deb:
	DOCKER_GRAPHDRIVER=$(shell docker info | awk -F ': ' '$$1 == "Storage Driver" { print $$2; exit }' ) && \
		docker run --rm --privileged --name $(CONTAINER_NAME) -v $(VOL_MNT_STABLE) -e KEEPBUNDLE=1 \
		-e "DOCKER_GRAPHDRIVER=$$DOCKER_GRAPHDRIVER" \
		-e "DOCKER_BUILD_PKGS=debian-jessie debian-stretch debian-wheezy" \
		-e "DOCKER_BUILD_ARGS=--build-arg=APT_MIRROR=ftp.us.debian.org" \
		$(DOCKER_BUILD_IMG) hack/make.sh build-deb
	$(RM) -r "$(WORKSPACE)/bundles/latest"

deb-arm:
	DOCKER_GRAPHDRIVER=$(shell docker info | awk -F ': ' '$$1 == "Storage Driver" { print $$2; exit }' ) && \
		docker run --rm --privileged --name $(CONTAINER_NAME) -v $(VOL_MNT_STABLE) -e KEEPBUNDLE=1 \
			-e "DOCKER_GRAPHDRIVER=$$DOCKER_GRAPHDRIVER" \
			-e "DOCKER_BUILD_PKGS" \
			-e "DOCKER_BUILD_ARGS=--build-arg=APT_MIRROR=ftp.fr.debian.org" \
		$(DOCKER_BUILD_IMG) hack/make.sh build-deb
	$(RM) -r "$(WORKSPACE)/bundles/latest"

deb-experimental:
	DOCKER_GRAPHDRIVER=$(shell docker info | awk -F ': ' '$$1 == "Storage Driver" { print $$2; exit }' ) && \
		docker run --rm --privileged --name $(CONTAINER_NAME) -v $(VOL_MNT_EXPERIMENTAL) -e KEEPBUNDLE=1 -e DOCKER_EXPERIMENTAL=1 \
			-e "DOCKER_GRAPHDRIVER=$$DOCKER_GRAPHDRIVER" \
			-e "DOCKER_BUILD_PKGS=debian-jessie debian-stretch debian-wheezy" \
			-e "DOCKER_BUILD_ARGS=--build-arg=APT_MIRROR=ftp.us.debian.org" \
			$(DOCKER_BUILD_IMG) hack/make.sh build-deb
	$(RM) -r "$(WORKSPACE)/bundles-experimental/latest"

deb-arm-experimental:
	DOCKER_GRAPHDRIVER=$(shell docker info | awk -F ': ' '$$1 == "Storage Driver" { print $$2; exit }' ) && \
		docker run --rm --privileged --name $(CONTAINER_NAME) -v $(VOL_MNT_EXPERIMENTAL) -e KEEPBUNDLE=1 -e DOCKER_EXPERIMENTAL=1 \
			-e "DOCKER_GRAPHDRIVER=$$DOCKER_GRAPHDRIVER" \
			-e "DOCKER_BUILD_PKGS" \
			-e "DOCKER_BUILD_ARGS=--build-arg=APT_MIRROR=ftp.fr.debian.org" \
			$(DOCKER_BUILD_IMG) hack/make.sh build-deb
	$(RM) -r "$(WORKSPACE)/bundles-experimental/latest"

ubuntu:
	DOCKER_GRAPHDRIVER=$(shell docker info | awk -F ': ' '$$1 == "Storage Driver" { print $$2; exit }' ) && \
		docker run --rm --privileged --name $(CONTAINER_NAME) -v $(VOL_MNT_STABLE) -e KEEPBUNDLE=1 \
		-e "DOCKER_GRAPHDRIVER=$$DOCKER_GRAPHDRIVER" \
		-e "DOCKER_BUILD_PKGS=ubuntu-precise ubuntu-trusty ubuntu-wily ubuntu-xenial" \
		$(DOCKER_BUILD_IMG) hack/make.sh build-deb
	$(RM) -r "$(WORKSPACE)/bundles/latest"

ubuntu-experimental:
	DOCKER_GRAPHDRIVER=$(shell docker info | awk -F ': ' '$$1 == "Storage Driver" { print $$2; exit }' ) && \
		docker run --rm --privileged --name $(CONTAINER_NAME) -v $(VOL_MNT_EXPERIMENTAL) -e KEEPBUNDLE=1 -e DOCKER_EXPERIMENTAL=1 \
		-e "DOCKER_GRAPHDRIVER=$$DOCKER_GRAPHDRIVER" \
		-e "DOCKER_BUILD_PKGS=ubuntu-precise ubuntu-trusty ubuntu-wily ubuntu-xenial" \
		$(DOCKER_BUILD_IMG) hack/make.sh build-deb
	$(RM) -r "$(WORKSPACE)/bundles-experimental/latest"

fedora:
	DOCKER_GRAPHDRIVER=$(shell docker info | awk -F ': ' '$$1 == "Storage Driver" { print $$2; exit }' ) && \
		docker run --rm --privileged --name $(CONTAINER_NAME) -v $(VOL_MNT_STABLE) -e KEEPBUNDLE=1 \
		-e "DOCKER_GRAPHDRIVER=$$DOCKER_GRAPHDRIVER" \
		-e "DOCKER_BUILD_PKGS=fedora-22 fedora-23 fedora-24" \
		$(DOCKER_BUILD_IMG) hack/make.sh build-rpm
	$(RM) -r "$(WORKSPACE)/bundles/latest"

fedora-experimental:
	DOCKER_GRAPHDRIVER=$(shell docker info | awk -F ': ' '$$1 == "Storage Driver" { print $$2; exit }' ) && \
		docker run --rm --privileged --name $(CONTAINER_NAME) -v $(VOL_MNT_EXPERIMENTAL) -e KEEPBUNDLE=1 -e DOCKER_EXPERIMENTAL=1 \
		-e "DOCKER_GRAPHDRIVER=$$DOCKER_GRAPHDRIVER" \
		-e "DOCKER_BUILD_PKGS=fedora-22 fedora-23 fedora-24" \
		$(DOCKER_BUILD_IMG) hack/make.sh build-rpm
	$(RM) -r "$(WORKSPACE)/bundles-experimental/latest"

centos:
	DOCKER_GRAPHDRIVER=$(shell docker info | awk -F ': ' '$$1 == "Storage Driver" { print $$2; exit }' ) && \
		docker run --rm --privileged --name $(CONTAINER_NAME) -v $(VOL_MNT_STABLE) -e KEEPBUNDLE=1 \
		-e "DOCKER_GRAPHDRIVER=$$DOCKER_GRAPHDRIVER" \
		-e "DOCKER_BUILD_PKGS=centos-7" \
		$(DOCKER_BUILD_IMG) hack/make.sh build-rpm
	$(RM) -r "$(WORKSPACE)/bundles/latest"

centos-experimental:
	DOCKER_GRAPHDRIVER=$(shell docker info | awk -F ': ' '$$1 == "Storage Driver" { print $$2; exit }' ) && \
		docker run --rm --privileged --name $(CONTAINER_NAME) -v $(VOL_MNT_EXPERIMENTAL) -e KEEPBUNDLE=1 -e DOCKER_EXPERIMENTAL=1 \
		-e "DOCKER_GRAPHDRIVER=$$DOCKER_GRAPHDRIVER" \
		-e "DOCKER_BUILD_PKGS=centos-7" \
		$(DOCKER_BUILD_IMG) hack/make.sh build-rpm
	$(RM) -r "$(WORKSPACE)/bundles-experimental/latest"

oraclelinux:
	DOCKER_GRAPHDRIVER=$(shell docker info | awk -F ': ' '$$1 == "Storage Driver" { print $$2; exit }' ) && \
		docker run --rm --privileged --name $(CONTAINER_NAME) -v $(VOL_MNT_STABLE) -e KEEPBUNDLE=1 \
		-e "DOCKER_GRAPHDRIVER=$$DOCKER_GRAPHDRIVER" \
		-e "DOCKER_BUILD_PKGS=oraclelinux-6 oraclelinux-7" \
		$(DOCKER_BUILD_IMG) hack/make.sh build-rpm
	$(RM) -r "$(WORKSPACE)/bundles/latest"

oraclelinux-experimental:
	DOCKER_GRAPHDRIVER=$(shell docker info | awk -F ': ' '$$1 == "Storage Driver" { print $$2; exit }' ) && \
		docker run --rm --privileged --name $(CONTAINER_NAME) -v $(VOL_MNT_EXPERIMENTAL) -e KEEPBUNDLE=1 -e DOCKER_EXPERIMENTAL=1 \
		-e "DOCKER_GRAPHDRIVER=$$DOCKER_GRAPHDRIVER" \
		-e "DOCKER_BUILD_PKGS=oraclelinux-6 oraclelinux-7" \
		$(DOCKER_BUILD_IMG) hack/make.sh build-rpm
	$(RM) -r "$(WORKSPACE)/bundles-experimental/latest"

opensuse:
	DOCKER_GRAPHDRIVER=$(shell docker info | awk -F ': ' '$$1 == "Storage Driver" { print $$2; exit }' ) && \
		docker run --rm --privileged --name $(CONTAINER_NAME) -v $(VOL_MNT_STABLE) -e KEEPBUNDLE=1 \
		-e "DOCKER_GRAPHDRIVER=$$DOCKER_GRAPHDRIVER" \
		-e "DOCKER_BUILD_PKGS=opensuse-13.2" \
		$(DOCKER_BUILD_IMG) hack/make.sh build-rpm
	$(RM) -r "$(WORKSPACE)/bundles/latest"

opensuse-experimental:
	DOCKER_GRAPHDRIVER=$(shell docker info | awk -F ': ' '$$1 == "Storage Driver" { print $$2; exit }' ) && \
		docker run --rm --privileged --name $(CONTAINER_NAME) -v $(VOL_MNT_EXPERIMENTAL) -e KEEPBUNDLE=1 -e DOCKER_EXPERIMENTAL=1 \
		-e "DOCKER_GRAPHDRIVER=$$DOCKER_GRAPHDRIVER" \
		-e "DOCKER_BUILD_PKGS=opensuse-13.2" \
		$(DOCKER_BUILD_IMG) hack/make.sh build-rpm
	$(RM) -r "$(WORKSPACE)/bundles-experimental/latest"
