SHELL:=/bin/bash
DOCKER_BUILD_IMG:=$(DOCKER_REPO):$(GIT_REF)
CONTAINER_NAME:=$(BUILD_TAG)-$(EXECUTOR_NUMBER)
VOL_MNT_STABLE:=$(WORKSPACE)/bundles:/go/src/github.com/docker/docker/bundles
VOL_MNT_EXPERIMENTAL:=$(WORKSPACE)/bundles-experimental:/go/src/github.com/docker/docker/bundles

binary:
	docker pull $(DOCKER_BUILD_IMG)
	docker run --rm --privileged --name $(CONTAINER_NAME) -v $(VOL_MNT_STABLE) \
		$(DOCKER_BUILD_IMG) hack/make.sh binary
	./fix-bundles-symlinks bundles

binary-experimental:
	docker pull $(DOCKER_BUILD_IMG)
	docker run --rm --privileged --name $(CONTAINER_NAME) -v $(VOL_MNT_EXPERIMENTAL) -e DOCKER_EXPERIMENTAL=1 \
		$(DOCKER_BUILD_IMG) hack/make.sh binary
	./fix-bundles-symlinks bundles-experimental

dynbinary:
	docker pull $(DOCKER_BUILD_IMG)
	docker run --rm --privileged --name $(CONTAINER_NAME) -v $(VOL_MNT_STABLE) \
		$(DOCKER_BUILD_IMG) hack/make.sh dynbinary
	./fix-bundles-symlinks bundles

dynbinary-experimental:
	docker pull $(DOCKER_BUILD_IMG)
	docker run --rm --privileged --name $(CONTAINER_NAME) -v $(VOL_MNT_EXPERIMENTAL) -e DOCKER_EXPERIMENTAL=1 \
		$(DOCKER_BUILD_IMG) hack/make.sh dynbinary
	./fix-bundles-symlinks bundles-experimental

cross:
	docker pull $(DOCKER_BUILD_IMG)
	docker run --rm --privileged --name $(CONTAINER_NAME) -v $(VOL_MNT_STABLE) -e KEEPBUNDLE=1 \
		$(DOCKER_BUILD_IMG) hack/make.sh cross
	./fix-bundles-symlinks bundles

cross-experimental:
	docker pull $(DOCKER_BUILD_IMG)
	docker run --rm --privileged --name $(CONTAINER_NAME) -v $(VOL_MNT_EXPERIMENTAL) -e KEEPBUNDLE=1 -e DOCKER_EXPERIMENTAL=1 \
		$(DOCKER_BUILD_IMG) hack/make.sh cross
	./fix-bundles-symlinks bundles-experimental

tgz:
	docker pull $(DOCKER_BUILD_IMG)
	docker run --rm --privileged --name $(CONTAINER_NAME) -v $(VOL_MNT_STABLE) -e KEEPBUNDLE=1 \
		$(DOCKER_BUILD_IMG) hack/make.sh tgz
	docker run --rm --privileged --name $(CONTAINER_NAME) -v $(VOL_MNT_STABLE) -e KEEPBUNDLE=1 -e GOOS=windows \
		$(DOCKER_BUILD_IMG) hack/make.sh tgz
	$(RM) -r "$(WORKSPACE)/bundles/latest"

tgz-experimental:
	docker pull $(DOCKER_BUILD_IMG)
	docker run --rm --privileged --name $(CONTAINER_NAME) -v $(VOL_MNT_EXPERIMENTAL) -e KEEPBUNDLE=1 -e DOCKER_EXPERIMENTAL=1 \
		$(DOCKER_BUILD_IMG) hack/make.sh tgz
	docker run --rm --privileged --name $(CONTAINER_NAME) -v $(VOL_MNT_EXPERIMENTAL) -e KEEPBUNDLE=1 -e GOOS=windows -e DOCKER_EXPERIMENTAL=1 \
		$(DOCKER_BUILD_IMG) hack/make.sh tgz
	$(RM) -r "$(WORKSPACE)/bundles-experimental/latest"

deb:
	docker pull $(DOCKER_BUILD_IMG)
	DOCKER_GRAPHDRIVER=$(shell docker info | awk -F ': ' '$$1 == "Storage Driver" { print $$2; exit }' ) && \
		docker run --rm --privileged --name $(CONTAINER_NAME) -v $(VOL_MNT_STABLE) -e KEEPBUNDLE=1 \
		-e "DOCKER_GRAPHDRIVER=$$DOCKER_GRAPHDRIVER" \
		-e "DOCKER_BUILD_PKGS=debian-jessie debian-stretch debian-wheezy" \
		-e "DOCKER_BUILD_ARGS=--build-arg=APT_MIRROR=ftp.us.debian.org" \
		$(DOCKER_BUILD_IMG) hack/make.sh build-deb
	$(RM) -r "$(WORKSPACE)/bundles/latest"

deb-experimental:
	docker pull $(DOCKER_BUILD_IMG)
	DOCKER_GRAPHDRIVER=$(shell docker info | awk -F ': ' '$$1 == "Storage Driver" { print $$2; exit }' ) && \
		docker run --rm --privileged --name $(CONTAINER_NAME) -v $(VOL_MNT_EXPERIMENTAL) -e KEEPBUNDLE=1 -e DOCKER_EXPERIMENTAL=1 \
			-e "DOCKER_GRAPHDRIVER=$$DOCKER_GRAPHDRIVER" \
			-e "DOCKER_BUILD_PKGS=debian-jessie debian-stretch debian-wheezy" \
			-e "DOCKER_BUILD_ARGS=--build-arg=APT_MIRROR=ftp.us.debian.org" \
			$(DOCKER_BUILD_IMG) hack/make.sh build-deb
	$(RM) -r "$(WORKSPACE)/bundles-experimental/latest"

ubuntu:
	docker pull $(DOCKER_BUILD_IMG)
	DOCKER_GRAPHDRIVER=$(shell docker info | awk -F ': ' '$$1 == "Storage Driver" { print $$2; exit }' ) && \
		docker run --rm --privileged --name $(CONTAINER_NAME) -v $(VOL_MNT_STABLE) -e KEEPBUNDLE=1 \
		-e "DOCKER_GRAPHDRIVER=$$DOCKER_GRAPHDRIVER" \
		-e "DOCKER_BUILD_PKGS=ubuntu-precise ubuntu-trusty ubuntu-wily ubuntu-xenial" \
		$(DOCKER_BUILD_IMG) hack/make.sh build-deb
	$(RM) -r "$(WORKSPACE)/bundles/latest"

ubuntu-experimental:
	docker pull $(DOCKER_BUILD_IMG)
	DOCKER_GRAPHDRIVER=$(shell docker info | awk -F ': ' '$$1 == "Storage Driver" { print $$2; exit }' ) && \
		docker run --rm --privileged --name $(CONTAINER_NAME) -v $(VOL_MNT_EXPERIMENTAL) -e KEEPBUNDLE=1 -e DOCKER_EXPERIMENTAL=1 \
		-e "DOCKER_GRAPHDRIVER=$$DOCKER_GRAPHDRIVER" \
		-e "DOCKER_BUILD_PKGS=ubuntu-precise ubuntu-trusty ubuntu-wily ubuntu-xenial" \
		$(DOCKER_BUILD_IMG) hack/make.sh build-deb
	$(RM) -r "$(WORKSPACE)/bundles-experimental/latest"

fedora:
	docker pull $(DOCKER_BUILD_IMG)
	DOCKER_GRAPHDRIVER=$(shell docker info | awk -F ': ' '$$1 == "Storage Driver" { print $$2; exit }' ) && \
		docker run --rm --privileged --name $(CONTAINER_NAME) -v $(VOL_MNT_STABLE) -e KEEPBUNDLE=1 \
		-e "DOCKER_GRAPHDRIVER=$$DOCKER_GRAPHDRIVER" \
		-e "DOCKER_BUILD_PKGS=fedora-22 fedora-23 fedora-24" \
		$(DOCKER_BUILD_IMG) hack/make.sh build-rpm
	$(RM) -r "$(WORKSPACE)/bundles/latest"

fedora-experimental:
	docker pull $(DOCKER_BUILD_IMG)
	DOCKER_GRAPHDRIVER=$(shell docker info | awk -F ': ' '$$1 == "Storage Driver" { print $$2; exit }' ) && \
		docker run --rm --privileged --name $(CONTAINER_NAME) -v $(VOL_MNT_EXPERIMENTAL) -e KEEPBUNDLE=1 -e DOCKER_EXPERIMENTAL=1 \
		-e "DOCKER_GRAPHDRIVER=$$DOCKER_GRAPHDRIVER" \
		-e "DOCKER_BUILD_PKGS=fedora-22 fedora-23 fedora-24" \
		$(DOCKER_BUILD_IMG) hack/make.sh build-rpm
	$(RM) -r "$(WORKSPACE)/bundles-experimental/latest"

centos:
	docker pull $(DOCKER_BUILD_IMG)
	DOCKER_GRAPHDRIVER=$(shell docker info | awk -F ': ' '$$1 == "Storage Driver" { print $$2; exit }' ) && \
		docker run --rm --privileged --name $(CONTAINER_NAME) -v $(VOL_MNT_STABLE) -e KEEPBUNDLE=1 \
		-e "DOCKER_GRAPHDRIVER=$$DOCKER_GRAPHDRIVER" \
		-e "DOCKER_BUILD_PKGS=centos-7" \
		$(DOCKER_BUILD_IMG) hack/make.sh build-rpm
	$(RM) -r "$(WORKSPACE)/bundles/latest"

centos-experimental:
	docker pull $(DOCKER_BUILD_IMG)
	DOCKER_GRAPHDRIVER=$(shell docker info | awk -F ': ' '$$1 == "Storage Driver" { print $$2; exit }' ) && \
		docker run --rm --privileged --name $(CONTAINER_NAME) -v $(VOL_MNT_EXPERIMENTAL) -e KEEPBUNDLE=1 -e DOCKER_EXPERIMENTAL=1 \
		-e "DOCKER_GRAPHDRIVER=$$DOCKER_GRAPHDRIVER" \
		-e "DOCKER_BUILD_PKGS=centos-7" \
		$(DOCKER_BUILD_IMG) hack/make.sh build-rpm
	$(RM) -r "$(WORKSPACE)/bundles-experimental/latest"

oraclelinux:
	docker pull $(DOCKER_BUILD_IMG)
	DOCKER_GRAPHDRIVER=$(shell docker info | awk -F ': ' '$$1 == "Storage Driver" { print $$2; exit }' ) && \
		docker run --rm --privileged --name $(CONTAINER_NAME) -v $(VOL_MNT_STABLE) -e KEEPBUNDLE=1 \
		-e "DOCKER_GRAPHDRIVER=$$DOCKER_GRAPHDRIVER" \
		-e "DOCKER_BUILD_PKGS=oraclelinux-6 oraclelinux-7" \
		$(DOCKER_BUILD_IMG) hack/make.sh build-rpm
	$(RM) -r "$(WORKSPACE)/bundles/latest"

oraclelinux-experimental:
	docker pull $(DOCKER_BUILD_IMG)
	DOCKER_GRAPHDRIVER=$(shell docker info | awk -F ': ' '$$1 == "Storage Driver" { print $$2; exit }' ) && \
		docker run --rm --privileged --name $(CONTAINER_NAME) -v $(VOL_MNT_EXPERIMENTAL) -e KEEPBUNDLE=1 -e DOCKER_EXPERIMENTAL=1 \
		-e "DOCKER_GRAPHDRIVER=$$DOCKER_GRAPHDRIVER" \
		-e "DOCKER_BUILD_PKGS=oraclelinux-6 oraclelinux-7" \
		$(DOCKER_BUILD_IMG) hack/make.sh build-rpm
	$(RM) -r "$(WORKSPACE)/bundles-experimental/latest"

opensuse:
	docker pull $(DOCKER_BUILD_IMG)
	DOCKER_GRAPHDRIVER=$(shell docker info | awk -F ': ' '$$1 == "Storage Driver" { print $$2; exit }' ) && \
		docker run --rm --privileged --name $(CONTAINER_NAME) -v $(VOL_MNT_STABLE) -e KEEPBUNDLE=1 \
		-e "DOCKER_GRAPHDRIVER=$$DOCKER_GRAPHDRIVER" \
		-e "DOCKER_BUILD_PKGS=opensuse-13.2" \
		$(DOCKER_BUILD_IMG) hack/make.sh build-rpm
	$(RM) -r "$(WORKSPACE)/bundles/latest"

opensuse-experimental:
	docker pull $(DOCKER_BUILD_IMG)
	DOCKER_GRAPHDRIVER=$(shell docker info | awk -F ': ' '$$1 == "Storage Driver" { print $$2; exit }' ) && \
		docker run --rm --privileged --name $(CONTAINER_NAME) -v $(VOL_MNT_EXPERIMENTAL) -e KEEPBUNDLE=1 -e DOCKER_EXPERIMENTAL=1 \
		-e "DOCKER_GRAPHDRIVER=$$DOCKER_GRAPHDRIVER" \
		-e "DOCKER_BUILD_PKGS=opensuse-13.2" \
		$(DOCKER_BUILD_IMG) hack/make.sh build-rpm
	$(RM) -r "$(WORKSPACE)/bundles-experimental/latest"
