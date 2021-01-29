SHELL:=/bin/bash
LDD_RUN=ldd >/dev/null 2>/dev/null

# Repositories to build from
DOCKER_CLI_REPO:=git@github.com:docker/cli.git
DOCKER_CLI_REF:=
DOCKER_ENGINE_REPO:=git@github.com:moby/moby.git
DOCKER_ENGINE_REF:=
DOCKER_PACKAGING_REPO:=git@github.com:docker/docker-ce-packaging.git
DOCKER_PACKAGING_REF:=

# Use stage to install dependencies from download-stage.docker.com during the verify
# step. Leave empty to install from download.docker.com
VERIFY_PACKAGE_REPO:=

# Optional flags like --platform=linux/armhf
VERIFY_PLATFORM:=

VERSION?=0.0.0-dev

help:
	@echo help

clean:
	-make -C packaging clean
	-$(RM) -r packaging
	-$(RM) -r bundles
	-$(RM) *.gz
	-$(RM) *.tgz

.PHONY: packaging/src
packaging/src: packaging packaging/src/github.com/docker/cli packaging/src/github.com/docker/docker
	@echo checked out source

packaging/src/github.com/docker/cli: packaging
	make -C packaging \
		DOCKER_CLI_REPO=$(DOCKER_CLI_REPO) \
		DOCKER_CLI_REF=$(DOCKER_CLI_REF) \
		checkout-cli

packaging/src/github.com/docker/docker: packaging
	make -C packaging \
		DOCKER_ENGINE_REPO=$(DOCKER_ENGINE_REPO) \
		DOCKER_ENGINE_REF=$(DOCKER_ENGINE_REF) \
		checkout-docker

packaging:
	mkdir -p $@
	git clone $(DOCKER_PACKAGING_REPO) $@
	git -C $@ checkout $(DOCKER_PACKAGING_REF)

static-linux: packaging/src
	make -C packaging VERSION=$(VERSION) DOCKER_BUILD_PKGS=static-linux static

# TODO cross-mac should only need the CLI source code, but also calls "static"?
cross-mac: packaging/src
	make -C packaging VERSION=$(VERSION) DOCKER_BUILD_PKGS=cross-mac static

cross-win: packaging/src
	make -C packaging VERSION=$(VERSION) DOCKER_BUILD_PKGS=cross-win static

debian-%: packaging/src
	make -C packaging/deb VERSION=$(VERSION) $@

raspbian-%: packaging/src
	make -C packaging/deb VERSION=$(VERSION) $@

ubuntu-%: packaging/src
	make -C packaging/deb VERSION=$(VERSION) $@

fedora-%: packaging/src
	docker rmi -f $(subst -,:,$@)
	docker pull $(subst -,:,$@)
	make -C packaging/rpm VERSION=$(VERSION) $@

centos-%: packaging/src
	make -C packaging/rpm VERSION=$(VERSION) $@

rhel-%: packaging/src
	make -C packaging/rpm VERSION=$(VERSION) $@

bundles-ce-cross-darwin.tar.gz:
	mkdir -p bundles/$(VERSION)/cross/darwin/amd64
	cp -r packaging/static/build/mac/docker/* bundles/$(VERSION)/cross/darwin/amd64/
	tar czf $@ bundles

bundles-ce-cross-windows.tar.gz:
	mkdir -p bundles/$(VERSION)/cross/windows/amd64
	cp -r packaging/static/build/win/docker/* bundles/$(VERSION)/cross/windows/amd64/
	tar czf $@ bundles

bundles-ce-debian-%-amd64.tar.gz:
	mkdir -p bundles/$(VERSION)/build-deb
	cp -R packaging/deb/debbuild/debian-$* bundles/$(VERSION)/build-deb/
	tar czf $@ bundles

bundles-ce-ubuntu-%-amd64.tar.gz:
	mkdir -p bundles/$(VERSION)/build-deb
	cp -R packaging/deb/debbuild/ubuntu-$* bundles/$(VERSION)/build-deb/
	tar czf $@ bundles

bundles-ce-fedora-%-amd64.tar.gz:
	mkdir -p bundles/$(VERSION)/build-rpm/fedora-$*
	cp -R packaging/rpm/rpmbuild/RPMS bundles/$(VERSION)/build-rpm/fedora-$*/
	cp -R packaging/rpm/rpmbuild/SRPMS bundles/$(VERSION)/build-rpm/fedora-$*/
	tar czf $@ bundles

bundles-ce-centos-%-amd64.tar.gz:
	mkdir -p bundles/$(VERSION)/build-rpm/centos-$*
	cp -R packaging/rpm/rpmbuild/RPMS bundles/$(VERSION)/build-rpm/centos-$*/
	cp -R packaging/rpm/rpmbuild/SRPMS bundles/$(VERSION)/build-rpm/centos-$*/
	tar czf $@ bundles

bundles-ce-debian-%-armhf.tar.gz:
	mkdir -p bundles/$(VERSION)/build-deb
	cp -R packaging/deb/debbuild/debian-$* bundles/$(VERSION)/build-deb/
	tar czf $@ bundles

bundles-ce-raspbian-%-armhf.tar.gz:
	mkdir -p bundles/$(VERSION)/build-deb
	cp -R packaging/deb/debbuild/raspbian-$* bundles/$(VERSION)/build-deb/
	tar czf $@ bundles

bundles-ce-ubuntu-%-armhf.tar.gz:
	mkdir -p bundles/$(VERSION)/build-deb
	cp -R packaging/deb/debbuild/ubuntu-$* bundles/$(VERSION)/build-deb/
	tar czf $@ bundles

bundles-ce-ubuntu-%-s390x.tar.gz:
	mkdir -p bundles/$(VERSION)/build-deb
	cp -R packaging/deb/debbuild/ubuntu-$* bundles/$(VERSION)/build-deb/
	tar czf $@ bundles

bundles-ce-ubuntu-%-ppc64le.tar.gz:
	mkdir -p bundles/$(VERSION)/build-deb
	cp -R packaging/deb/debbuild/ubuntu-$* bundles/$(VERSION)/build-deb/
	tar czf $@ bundles

bundles-ce-ubuntu-%-aarch64.tar.gz:
	mkdir -p bundles/$(VERSION)/build-deb
	cp -R packaging/deb/debbuild/ubuntu-$* bundles/$(VERSION)/build-deb/
	tar czf $@ bundles

bundles-ce-debian-%-aarch64.tar.gz:
	mkdir -p bundles/$(VERSION)/build-deb
	cp -R packaging/deb/debbuild/debian-$* bundles/$(VERSION)/build-deb/
	tar czf $@ bundles

bundles-ce-fedora-%-aarch64.tar.gz:
	mkdir -p bundles/$(VERSION)/build-rpm/fedora-$*
	cp -R packaging/rpm/rpmbuild/RPMS bundles/$(VERSION)/build-rpm/fedora-$*/
	cp -R packaging/rpm/rpmbuild/SRPMS bundles/$(VERSION)/build-rpm/fedora-$*/
	tar czf $@ bundles

bundles-ce-centos-%-aarch64.tar.gz:
	mkdir -p bundles/$(VERSION)/build-rpm/centos-$*
	cp -R packaging/rpm/rpmbuild/RPMS bundles/$(VERSION)/build-rpm/centos-$*/
	cp -R packaging/rpm/rpmbuild/SRPMS bundles/$(VERSION)/build-rpm/centos-$*/
	tar czf $@ bundles

bundles-ce-rhel-%-s390x.tar.gz:
	mkdir -p bundles/$(VERSION)/build-rpm/rhel-$*
	cp -R packaging/rpm/rpmbuild/RPMS bundles/$(VERSION)/build-rpm/rhel-$*/
	cp -R packaging/rpm/rpmbuild/SRPMS bundles/$(VERSION)/build-rpm/rhel-$*/
	tar czf $@ bundles

# Bundle the completion files here are used by Docker Desktop
# https://github.com/docker/pinata/blob/553b07bebc444d493502e8ae9fe36cc2f490b793/tools/cmd/pinata/versionpacks/remotedependencies.go#L211-L229
# TODO consider including these with the CLI in the "cross-win", "cross-mac", and "static" bundles and/or embedding them in the CLI
bundles-ce-shell-completion.tar.gz: packaging/src/github.com/docker/cli
	install -D packaging/src/github.com/docker/cli/contrib/completion/bash/docker bundles/$(VERSION)/tgz/amd64/docker/completion/bash/docker
	install -D packaging/src/github.com/docker/cli/contrib/completion/zsh/_docker bundles/$(VERSION)/tgz/amd64/docker/completion/zsh/_docker
	install -D packaging/src/github.com/docker/cli/contrib/completion/fish/docker.fish bundles/$(VERSION)/tgz/amd64/docker/completion/fish/docker.fish
	tar czf $@ bundles

docker-win.zip:
	cp packaging/static/build/win/docker-*.zip $@

docker-mac.tgz:
	cp packaging/static/build/mac/docker-*.tgz $@

docker-%.tgz:
	$(MAKE) static-linux
	mv packaging/static/build/linux/docker-rootless-extras-*.tgz docker-rootless-extras-$*.tgz
	mv packaging/static/build/linux/docker-*.tgz $@

.PHONY: verify
verify:
	# to verify using packages from staging, use: make VERIFY_PACKAGE_REPO=stage IMAGE=ubuntu:focal verify
	# FIXME: separating pull and run because of https://github.com/balena-io-library/resin-rpi-raspbian/issues/104
	docker pull $(VERIFY_PLATFORM) $(IMAGE)
	docker run --rm -i -v "$$(pwd):/v" -e DEBIAN_FRONTEND=noninteractive -e PACKAGE_REPO=$(VERIFY_PACKAGE_REPO) -w /v $(IMAGE) ./verify

release:
	make -C packaging VERSION=$(VERSION) release
