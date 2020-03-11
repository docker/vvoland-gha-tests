SHELL:=/bin/bash
LDD_RUN=ldd >/dev/null 2>/dev/null

# Repositories to build from
DOCKER_CLI_REPO:=git@github.com:docker/cli.git
DOCKER_CLI_REF:=
DOCKER_ENGINE_REPO:=git@github.com:moby/moby.git
DOCKER_ENGINE_REF:=
DOCKER_PACKAGING_REPO:=git@github.com:docker/docker-ce-packaging.git
DOCKER_PACKAGING_REF:=

# TODO: cli and engine packages should get their own git-commit listed. Temporarily using the "engine" commit
GITCOMMIT=$(shell git -C docker-ce/engine rev-parse --short HEAD)

# TODO: either get version for cli and engine packages separately, or require a version to be set. Temporarily using the "cli" version file
VERSION=$(shell cat docker-ce/cli/VERSION)

help:
	@echo help

clean:
	make -C docker-ce/cli clean
	make -C docker-ce/engine clean
	make -C docker-ce/packaging clean
	$(RM) -r bundles
	$(RM) *.gz
	$(RM) *.tgz

docker-ce/cli:
	mkdir -p $@
	git clone $(DOCKER_CLI_REPO) $@
	git -C $@ checkout $(DOCKER_CLI_REF)

docker-ce/engine:
	mkdir -p $@
	git clone $(DOCKER_ENGINE_REPO) $@
	git -C $@ checkout $(DOCKER_ENGINE_REF)

docker-ce/packaging:
	mkdir -p $@
	git clone $(DOCKER_PACKAGING_REPO) $@
	git -C $@ checkout $(DOCKER_PACKAGING_REF)

docker-ce: docker-ce/cli docker-ce/engine docker-ce/packaging

docker-ce.tar.gz: docker-ce
	tar czf $@ $<

static-linux:
	make -C docker-ce/packaging VERSION=$(VERSION) GITCOMMIT=$(GITCOMMIT) DOCKER_BUILD_PKGS=static-linux static

cross-mac:
	make -C docker-ce/packaging VERSION=$(VERSION) GITCOMMIT=$(GITCOMMIT) DOCKER_BUILD_PKGS=cross-mac static

cross-win:
	make -C docker-ce/packaging VERSION=$(VERSION) GITCOMMIT=$(GITCOMMIT) DOCKER_BUILD_PKGS=cross-win static

debian-%:
	make -C docker-ce/packaging/deb VERSION=$(VERSION) GITCOMMIT=$(GITCOMMIT) $@

raspbian-%:
	make -C docker-ce/packaging/deb VERSION=$(VERSION) GITCOMMIT=$(GITCOMMIT) $@

ubuntu-%:
	make -C docker-ce/packaging/deb VERSION=$(VERSION) GITCOMMIT=$(GITCOMMIT) $@

fedora-%:
	docker rmi -f $(subst -,:,$@)
	docker pull $(subst -,:,$@)
	make -C docker-ce/packaging/rpm VERSION=$(VERSION) GITCOMMIT=$(GITCOMMIT) $@

centos-%:
	make -C docker-ce/packaging/rpm VERSION=$(VERSION) GITCOMMIT=$(GITCOMMIT) $@

bundles-ce-binary.tar.gz:
	mkdir -p bundles/$(VERSION)/binary-client bundles/$(VERSION)/binary-daemon
	cp docker-ce/packaging/static/build/linux/docker/docker bundles/$(VERSION)/binary-client/
	for f in dockerd docker-init docker-proxy runc containerd ctr containerd-shim; do \
		cp docker-ce/packaging/static/build/linux/docker/$$f bundles/$(VERSION)/binary-daemon/; \
		if $(LDD_RUN) bundles/$(VERSION)/binary-daemon/$$f; then echo "$$f is not static, exiting..."; exit 1; fi \
	done
	tar czf $@ bundles

bundles-ce-cross-darwin.tar.gz:
	mkdir -p bundles/$(VERSION)/cross/darwin/amd64
	cp -r docker-ce/packaging/static/build/mac/docker/* bundles/$(VERSION)/cross/darwin/amd64/
	tar czf $@ bundles

bundles-ce-cross-windows.tar.gz:
	mkdir -p bundles/$(VERSION)/cross/windows/amd64
	cp -r docker-ce/packaging/static/build/win/docker/* bundles/$(VERSION)/cross/windows/amd64/
	tar czf $@ bundles

bundles-ce-debian-%-amd64.tar.gz:
	mkdir -p bundles/$(VERSION)/build-deb
	cp -R docker-ce/packaging/deb/debbuild/debian-$* bundles/$(VERSION)/build-deb/
	tar czf $@ bundles

bundles-ce-ubuntu-%-amd64.tar.gz:
	mkdir -p bundles/$(VERSION)/build-deb
	cp -R docker-ce/packaging/deb/debbuild/ubuntu-$* bundles/$(VERSION)/build-deb/
	tar czf $@ bundles

bundles-ce-fedora-%-amd64.tar.gz:
	mkdir -p bundles/$(VERSION)/build-rpm/fedora-$*
	cp -R docker-ce/packaging/rpm/rpmbuild/RPMS bundles/$(VERSION)/build-rpm/fedora-$*/
	cp -R docker-ce/packaging/rpm/rpmbuild/SRPMS bundles/$(VERSION)/build-rpm/fedora-$*/
	tar czf $@ bundles

bundles-ce-centos-%-amd64.tar.gz:
	mkdir -p bundles/$(VERSION)/build-rpm/centos-$*
	cp -R docker-ce/packaging/rpm/rpmbuild/RPMS bundles/$(VERSION)/build-rpm/centos-$*/
	cp -R docker-ce/packaging/rpm/rpmbuild/SRPMS bundles/$(VERSION)/build-rpm/centos-$*/
	tar czf $@ bundles

bundles-ce-debian-%-armhf.tar.gz:
	mkdir -p bundles/$(VERSION)/build-deb
	cp -R docker-ce/packaging/deb/debbuild/debian-$* bundles/$(VERSION)/build-deb/
	tar czf $@ bundles

bundles-ce-raspbian-%-armhf.tar.gz:
	mkdir -p bundles/$(VERSION)/build-deb
	cp -R docker-ce/packaging/deb/debbuild/raspbian-$* bundles/$(VERSION)/build-deb/
	tar czf $@ bundles

bundles-ce-ubuntu-%-armhf.tar.gz:
	mkdir -p bundles/$(VERSION)/build-deb
	cp -R docker-ce/packaging/deb/debbuild/ubuntu-$* bundles/$(VERSION)/build-deb/
	tar czf $@ bundles

bundles-ce-ubuntu-%-s390x.tar.gz:
	mkdir -p bundles/$(VERSION)/build-deb
	cp -R docker-ce/packaging/deb/debbuild/ubuntu-$* bundles/$(VERSION)/build-deb/
	tar czf $@ bundles

bundles-ce-ubuntu-%-ppc64le.tar.gz:
	mkdir -p bundles/$(VERSION)/build-deb
	cp -R docker-ce/packaging/deb/debbuild/ubuntu-$* bundles/$(VERSION)/build-deb/
	tar czf $@ bundles

bundles-ce-ubuntu-%-aarch64.tar.gz:
	mkdir -p bundles/$(VERSION)/build-deb
	cp -R docker-ce/packaging/deb/debbuild/ubuntu-$* bundles/$(VERSION)/build-deb/
	tar czf $@ bundles

bundles-ce-debian-%-aarch64.tar.gz:
	mkdir -p bundles/$(VERSION)/build-deb
	cp -R docker-ce/packaging/deb/debbuild/debian-$* bundles/$(VERSION)/build-deb/
	tar czf $@ bundles

bundles-ce-fedora-%-aarch64.tar.gz:
	mkdir -p bundles/$(VERSION)/build-rpm/fedora-$*
	cp -R docker-ce/packaging/rpm/rpmbuild/RPMS bundles/$(VERSION)/build-rpm/fedora-$*/
	cp -R docker-ce/packaging/rpm/rpmbuild/SRPMS bundles/$(VERSION)/build-rpm/fedora-$*/
	tar czf $@ bundles

bundles-ce-centos-%-aarch64.tar.gz:
	mkdir -p bundles/$(VERSION)/build-rpm/centos-$*
	cp -R docker-ce/packaging/rpm/rpmbuild/RPMS bundles/$(VERSION)/build-rpm/centos-$*/
	cp -R docker-ce/packaging/rpm/rpmbuild/SRPMS bundles/$(VERSION)/build-rpm/centos-$*/
	tar czf $@ bundles

bundles-ce-shell-completion.tar.gz:
	install -D docker-ce/cli/contrib/completion/bash/docker bundles/$(VERSION)/tgz/amd64/docker/completion/bash/docker
	install -D docker-ce/cli/contrib/completion/zsh/_docker bundles/$(VERSION)/tgz/amd64/docker/completion/zsh/_docker
	install -D docker-ce/cli/contrib/completion/fish/docker.fish bundles/$(VERSION)/tgz/amd64/docker/completion/fish/docker.fish
	tar czf $@ bundles

docker-win.zip:
	cp docker-ce/packaging/static/build/win/docker-*.zip $@

docker-mac.tgz:
	cp docker-ce/packaging/static/build/mac/docker-*.tgz $@

docker-%.tgz:
	$(MAKE) static-linux
	mv docker-ce/packaging/static/build/linux/docker-rootless-extras-*.tgz docker-rootless-extras-$*.tgz
	mv docker-ce/packaging/static/build/linux/docker-*.tgz $@

release:
	make -C docker-ce/packaging VERSION=$(VERSION) GITCOMMIT=$(GITCOMMIT) release
