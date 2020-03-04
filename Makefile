SHELL:=/bin/bash
DOCKER_CE_REPO:=git@github.com:docker/docker-ce
DOCKER_CE_REF:=
VERSION=$(shell cat docker-ce/VERSION)
ARCH=$(shell uname -m)
GITCOMMIT=$(shell git -C docker-ce rev-parse --short HEAD)
LDD_RUN=ldd >/dev/null 2>/dev/null

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

cross-mac:
	make -C docker-ce/components/packaging VERSION=$(VERSION) GITCOMMIT=$(GITCOMMIT) DOCKER_BUILD_PKGS=cross-mac static

cross-win:
	make -C docker-ce/components/packaging VERSION=$(VERSION) GITCOMMIT=$(GITCOMMIT) DOCKER_BUILD_PKGS=cross-win static

debian-%:
	make -C docker-ce/components/packaging/deb VERSION=$(VERSION) GITCOMMIT=$(GITCOMMIT) IMAGE_TAG=$(STATIC_VERSION) $@

raspbian-%:
	make -C docker-ce/components/packaging/deb VERSION=$(VERSION) GITCOMMIT=$(GITCOMMIT) IMAGE_TAG=$(STATIC_VERSION) $@

ubuntu-%:
	make -C docker-ce/components/packaging/deb VERSION=$(VERSION) GITCOMMIT=$(GITCOMMIT) IMAGE_TAG=$(STATIC_VERSION) $@

fedora-%:
	docker rmi -f $(subst -,:,$@)
	docker pull $(subst -,:,$@)
	make -C docker-ce/components/packaging/rpm VERSION=$(VERSION) GITCOMMIT=$(GITCOMMIT) IMAGE_TAG=$(STATIC_VERSION) $@

centos-%:
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
	cp -r docker-ce/components/packaging/static/build/mac/docker/* bundles/$(VERSION)/cross/darwin/amd64/
	tar czf $@ bundles

bundles-ce-cross-windows.tar.gz:
	mkdir -p bundles/$(VERSION)/cross/windows/amd64
	cp -r docker-ce/components/packaging/static/build/win/docker/* bundles/$(VERSION)/cross/windows/amd64/
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

docker-%.tgz:
	$(MAKE) static-linux
	mv docker-ce/components/packaging/static/build/linux/docker-rootless-extras-*.tgz docker-rootless-extras-$*.tgz
	mv docker-ce/components/packaging/static/build/linux/docker-*.tgz $@

release:
	make -C docker-ce/components/packaging VERSION=$(VERSION) GITCOMMIT=$(GITCOMMIT) release

static_version:
	@$(MAKE) -s -C docker-ce/components/packaging print-STATIC_VERSION
