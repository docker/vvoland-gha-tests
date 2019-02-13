SHELL:=/bin/bash
DOCKER_CE_REPO:=git@github.com:docker/docker-ce
DOCKER_CE_REF:=
VERSION=$(shell cat docker-ce/VERSION)
ARCH=$(shell uname -m)
GITCOMMIT=$(shell git -C docker-ce rev-parse --short HEAD)
LDD_RUN=ldd >/dev/null 2>/dev/null
ENGINE_IMAGE?=engine-community-arches
DOCKER_HUB_ORG?=dockereng
DOCKER_CLI_GOLANG_IMG=$(shell awk '$$1=="FROM"{split($$2,a,"-");print a[1];exit}' $(CURDIR)/docker-ce/components/cli/dockerfiles/Dockerfile.dev)

STATIC_VERSION=$(shell ./docker-ce/components/packaging/static/gen-static-ver docker-ce/components/engine "$(VERSION)")

ARCHES?=x86_64 ppc64le aarch64 armv7l

help:
	@echo help

clean:
	make -C docker-ce clean
	$(RM) -r bundles
	$(RM) *.gz
	$(RM) *.tgz

docker-ce:
	git clone $(DOCKER_CE_REPO) $@
	git -C $@ checkout $(DOCKER_CE_REF)

docker-ce.tar.gz: docker-ce
	tar czf $@ $<

static-linux:
	make -C docker-ce/components/packaging VERSION=$(VERSION) GITCOMMIT=$(GITCOMMIT) DOCKER_BUILD_PKGS=static-linux static

image-linux:
	make -C docker-ce/components/packaging VERSION=$(VERSION) GITCOMMIT=$(GITCOMMIT) DOCKER_BUILD_PKGS=image-linux image

cross-mac:
	make -C docker-ce/components/packaging VERSION=$(VERSION) GITCOMMIT=$(GITCOMMIT) DOCKER_BUILD_PKGS=cross-mac static

cross-win:
	make -C docker-ce/components/packaging VERSION=$(VERSION) GITCOMMIT=$(GITCOMMIT) DOCKER_BUILD_PKGS=cross-win static

DEB_DEPENDENCIES=docker-ce/components/packaging/deb/sources/engine-image
docker-ce/components/packaging/deb/sources/engine-image: engine-$(ARCH)-docker-compat.tar
	mkdir -p $(@D)
	docker load -i $< | sed '/Loaded image/!d' | cut -d':' -f2- | xargs > $@

RPM_DEPENDENCIES=docker-ce/components/packaging/rpm/rpmbuild/SOURCES/engine-image
docker-ce/components/packaging/rpm/rpmbuild/SOURCES/engine-image: engine-$(ARCH)-dm-docker-compat.tar
	mkdir -p $(@D)
	docker load -i $< | sed '/Loaded image/!d' | cut -d':' -f2- | xargs > $@

debian-%: $(DEB_DEPENDENCIES)
	make -C docker-ce/components/packaging/deb VERSION=$(VERSION) GITCOMMIT=$(GITCOMMIT) IMAGE_TAG=$(STATIC_VERSION) $@

raspbian-%: $(DEB_DEPENDENCIES)
	make -C docker-ce/components/packaging/deb VERSION=$(VERSION) GITCOMMIT=$(GITCOMMIT) IMAGE_TAG=$(STATIC_VERSION) $@

ubuntu-%: $(DEB_DEPENDENCIES)
	make -C docker-ce/components/packaging/deb VERSION=$(VERSION) GITCOMMIT=$(GITCOMMIT) IMAGE_TAG=$(STATIC_VERSION) $@

fedora-%: $(RPM_DEPENDENCIES)
	make -C docker-ce/components/packaging/rpm VERSION=$(VERSION) GITCOMMIT=$(GITCOMMIT) IMAGE_TAG=$(STATIC_VERSION) $@

centos-%: $(RPM_DEPENDENCIES)
	make -C docker-ce/components/packaging/rpm VERSION=$(VERSION) GITCOMMIT=$(GITCOMMIT) IMAGE_TAG=$(STATIC_VERSION) $@

bundles-ce-binary.tar.gz:
	mkdir -p bundles/$(VERSION)/binary-client bundles/$(VERSION)/binary-daemon
	cp docker-ce/components/packaging/static/build/linux/docker/docker bundles/$(VERSION)/binary-client/
	for f in dockerd docker-init docker-proxy runc containerd ctr containerd-shim; do \
		cp docker-ce/components/packaging/static/build/linux/docker/$$f bundles/$(VERSION)/binary-daemon/; \
		if $(LDD_RUN) bundles/$(VERSION)/binary-daemon/$$f; then echo "$$f is not static, exiting..."; exit 1; fi \
	done
	tar czf $@ bundles

bundles-ce-cross-darwin.tar.gz:
	mkdir -p bundles/$(VERSION)/cross/darwin/amd64
	cp docker-ce/components/packaging/static/build/mac/docker/docker bundles/$(VERSION)/cross/darwin/amd64/
	tar czf $@ bundles

bundles-ce-cross-windows.tar.gz:
	mkdir -p bundles/$(VERSION)/cross/windows/amd64
	cp docker-ce/components/packaging/static/build/win/docker/docker.exe bundles/$(VERSION)/cross/windows/amd64/
	cp docker-ce/components/packaging/static/build/win/docker/dockerd.exe bundles/$(VERSION)/cross/windows/amd64/
	tar czf $@ bundles

bundles-ce-debian-%-amd64.tar.gz:
	mkdir -p bundles/$(VERSION)/build-deb
	cp -R docker-ce/components/packaging/deb/debbuild/debian-$* bundles/$(VERSION)/build-deb/
	tar czf $@ bundles

bundles-ce-ubuntu-%-amd64.tar.gz:
	mkdir -p bundles/$(VERSION)/build-deb
	cp -R docker-ce/components/packaging/deb/debbuild/ubuntu-$* bundles/$(VERSION)/build-deb/
	tar czf $@ bundles

bundles-ce-fedora-%-amd64.tar.gz:
	mkdir -p bundles/$(VERSION)/build-rpm/fedora-$*
	cp -R docker-ce/components/packaging/rpm/rpmbuild/RPMS bundles/$(VERSION)/build-rpm/fedora-$*/
	cp -R docker-ce/components/packaging/rpm/rpmbuild/SRPMS bundles/$(VERSION)/build-rpm/fedora-$*/
	tar czf $@ bundles

bundles-ce-centos-%-amd64.tar.gz:
	mkdir -p bundles/$(VERSION)/build-rpm/centos-$*
	cp -R docker-ce/components/packaging/rpm/rpmbuild/RPMS bundles/$(VERSION)/build-rpm/centos-$*/
	cp -R docker-ce/components/packaging/rpm/rpmbuild/SRPMS bundles/$(VERSION)/build-rpm/centos-$*/
	tar czf $@ bundles

bundles-ce-debian-%-armhf.tar.gz:
	mkdir -p bundles/$(VERSION)/build-deb
	cp -R docker-ce/components/packaging/deb/debbuild/debian-$* bundles/$(VERSION)/build-deb/
	tar czf $@ bundles

bundles-ce-raspbian-%-armhf.tar.gz:
	mkdir -p bundles/$(VERSION)/build-deb
	cp -R docker-ce/components/packaging/deb/debbuild/raspbian-$* bundles/$(VERSION)/build-deb/
	tar czf $@ bundles

bundles-ce-ubuntu-%-armhf.tar.gz:
	mkdir -p bundles/$(VERSION)/build-deb
	cp -R docker-ce/components/packaging/deb/debbuild/ubuntu-$* bundles/$(VERSION)/build-deb/
	tar czf $@ bundles

bundles-ce-ubuntu-%-s390x.tar.gz:
	mkdir -p bundles/$(VERSION)/build-deb
	cp -R docker-ce/components/packaging/deb/debbuild/ubuntu-$* bundles/$(VERSION)/build-deb/
	tar czf $@ bundles

bundles-ce-ubuntu-%-ppc64le.tar.gz:
	mkdir -p bundles/$(VERSION)/build-deb
	cp -R docker-ce/components/packaging/deb/debbuild/ubuntu-$* bundles/$(VERSION)/build-deb/
	tar czf $@ bundles

bundles-ce-ubuntu-%-aarch64.tar.gz:
	mkdir -p bundles/$(VERSION)/build-deb
	cp -R docker-ce/components/packaging/deb/debbuild/ubuntu-$* bundles/$(VERSION)/build-deb/
	tar czf $@ bundles

bundles-ce-debian-%-aarch64.tar.gz:
	mkdir -p bundles/$(VERSION)/build-deb
	cp -R docker-ce/components/packaging/deb/debbuild/debian-$* bundles/$(VERSION)/build-deb/
	tar czf $@ bundles

bundles-ce-fedora-%-aarch64.tar.gz:
	mkdir -p bundles/$(VERSION)/build-rpm/fedora-$*
	cp -R docker-ce/components/packaging/rpm/rpmbuild/RPMS bundles/$(VERSION)/build-rpm/fedora-$*/
	cp -R docker-ce/components/packaging/rpm/rpmbuild/SRPMS bundles/$(VERSION)/build-rpm/fedora-$*/
	tar czf $@ bundles

bundles-ce-centos-%-aarch64.tar.gz:
	mkdir -p bundles/$(VERSION)/build-rpm/centos-$*
	cp -R docker-ce/components/packaging/rpm/rpmbuild/RPMS bundles/$(VERSION)/build-rpm/centos-$*/
	cp -R docker-ce/components/packaging/rpm/rpmbuild/SRPMS bundles/$(VERSION)/build-rpm/centos-$*/
	tar czf $@ bundles

bundles-ce-shell-completion.tar.gz:
	install -D docker-ce/components/cli/contrib/completion/bash/docker bundles/$(VERSION)/tgz/amd64/docker/completion/bash/docker
	install -D docker-ce/components/cli/contrib/completion/zsh/_docker bundles/$(VERSION)/tgz/amd64/docker/completion/zsh/_docker
	install -D docker-ce/components/cli/contrib/completion/fish/docker.fish bundles/$(VERSION)/tgz/amd64/docker/completion/fish/docker.fish
	tar czf $@ bundles

docker-win.zip:
	cp docker-ce/components/packaging/static/build/win/docker-*.zip $@

docker-mac.tgz:
	cp docker-ce/components/packaging/static/build/mac/docker-*.tgz $@

docker-armel.tgz:
	docker run --rm -i -e VERSION=$(VERSION) -e GITCOMMIT=$(GITCOMMIT) -e GOARM=6 \
		-v $(CURDIR)/docker-ce/components/cli:/go/src/github.com/docker/cli \
		-w /go/src/github.com/docker/cli \
		$(DOCKER_CLI_GOLANG_IMG) make binary
	make -C docker-ce/components/engine DOCKER_RUN_DOCKER='$$(DOCKER_FLAGS) -e GOARM=6 "$$(DOCKER_IMAGE)"' VERSION=$(VERSION) binary
	$(RM) -r docker
	install -D docker-ce/components/cli/build/docker docker/docker
	for f in dockerd containerd ctr containerd-shim docker-init docker-proxy runc; do \
		install -D docker-ce/components/engine/bundles/binary-daemon/$$f docker/$$f; \
	done
	for binary in docker/*; do \
		if $(LDD_RUN) $$binary; then echo "$$binary is not static, exiting..."; exit 1; fi \
	done
	tar --numeric-owner --owner 0 -c -z -f $@ docker
	$(RM) -r docker

docker-%.tgz:
	$(MAKE) static-linux
	mv docker-ce/components/packaging/static/build/linux/docker-rootless-extras-*.tgz $(subst docker-,docker-rootless-extras-,$@)
	mv docker-ce/components/packaging/static/build/linux/docker-*.tgz $@

release:
	make -C docker-ce/components/packaging VERSION=$(VERSION) GITCOMMIT=$(GITCOMMIT) release

static_version:
	@$(MAKE) -s -C docker-ce/components/packaging print-STATIC_VERSION
