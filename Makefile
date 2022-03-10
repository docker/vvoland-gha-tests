SHELL:=/bin/bash

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

packaging:
	mkdir -p $@
	git clone $(DOCKER_PACKAGING_REPO) $@
	git -C $@ checkout $(DOCKER_PACKAGING_REF)

.PHONY: packaging/src
packaging/src: packaging
	make -C packaging \
		DOCKER_CLI_REPO=$(DOCKER_CLI_REPO) \
		DOCKER_CLI_REF=$(DOCKER_CLI_REF) \
		DOCKER_ENGINE_REPO=$(DOCKER_ENGINE_REPO) \
		DOCKER_ENGINE_REF=$(DOCKER_ENGINE_REF) \
		checkout
	@echo checked out source

static-linux: packaging/src
	make -C packaging \
		VERSION=$(VERSION) \
		DOCKER_BUILD_PKGS=static-linux \
		TARGETPLATFORM=$(TARGETPLATFORM) \
		CONTAINERD_VERSION=$(CONTAINERD_VERSION) \
		RUNC_VERSION=$(RUNC_VERSION) \
		static

# TODO cross-mac should only need the CLI source code, but also calls "static"?
cross-mac: packaging/src
	make -C packaging VERSION=$(VERSION) DOCKER_BUILD_PKGS=cross-mac static

cross-win: packaging/src
	make -C packaging VERSION=$(VERSION) DOCKER_BUILD_PKGS=cross-win static

# Note that this is consumed by pinata, thus assuming arch suffix is in GOARCH format, unlike in docker-mac-$arch.tgz
bundles-ce-cross-darwin-%.tar.gz:
	mkdir -p bundles/$(VERSION)/cross/darwin/$*
	cp -r packaging/static/build/mac/$*/docker/* bundles/$(VERSION)/cross/darwin/$*/
	tar czf $@ bundles

bundles-ce-cross-windows-%.tar.gz:
	mkdir -p bundles/$(VERSION)/cross/windows/$*
	cp -r packaging/static/build/win/$*/docker/* bundles/$(VERSION)/cross/windows/$*/
	tar czf $@ bundles

DEB_BUNDLES:=bundles-ce-ubuntu-%.tar.gz bundles-ce-debian-%.tar.gz bundles-ce-raspbian-%.tar.gz

$(DEB_BUNDLES): packaging/src
	make -C packaging/deb VERSION=$(VERSION) debbuild/$@
	mv packaging/deb/debbuild/$@ .

RPM_BUNDLES:=bundles-ce-fedora-%.tar.gz bundles-ce-centos-%.tar.gz bundles-ce-rhel-%.tar.gz

$(RPM_BUNDLES): packaging/src
	make -C packaging/rpm VERSION=$(VERSION) rpmbuild/$@
	mv packaging/rpm/rpmbuild/$@ .

# Bundle the completion files here are used by Docker Desktop
# https://github.com/docker/pinata/blob/553b07bebc444d493502e8ae9fe36cc2f490b793/tools/cmd/pinata/versionpacks/remotedependencies.go#L211-L229
# TODO consider including these with the CLI in the "cross-win", "cross-mac", and "static" bundles and/or embedding them in the CLI
bundles-ce-shell-completion.tar.gz: packaging
	make -C packaging DOCKER_CLI_REF=$(DOCKER_CLI_REF) checkout-cli

	install -D packaging/src/github.com/docker/cli/contrib/completion/bash/docker bundles/$(VERSION)/tgz/amd64/docker/completion/bash/docker
	install -D packaging/src/github.com/docker/cli/contrib/completion/zsh/_docker bundles/$(VERSION)/tgz/amd64/docker/completion/zsh/_docker
	install -D packaging/src/github.com/docker/cli/contrib/completion/fish/docker.fish bundles/$(VERSION)/tgz/amd64/docker/completion/fish/docker.fish
	tar czf $@ bundles

docker-win-amd64.zip:
	cp packaging/static/build/win/amd64/docker-*.zip $@

docker-mac-amd64.tgz:
	cp packaging/static/build/mac/amd64/docker-*.tgz $@

docker-mac-aarch64.tgz:
	cp packaging/static/build/mac/arm64/docker-*.tgz $@

docker-%.tgz:
	arch=$*; if test $$arch = armhf; then arch=arm/v7; \
		elif test $$arch = armel; then arch=arm/v6; \
		elif test $$arch = aarch64; then arch=arm64; fi; \
		$(MAKE) TARGETPLATFORM=linux/$$arch static-linux
	mv packaging/static/build/linux/docker-rootless-extras-*.tgz docker-rootless-extras-$*.tgz
	mv packaging/static/build/linux/docker-*.tgz $@

.PHONY: verify
verify:
	# to verify using packages from staging, use: make VERIFY_PACKAGE_REPO=stage IMAGE=ubuntu:focal verify
	docker run $(VERIFY_PLATFORM) --rm -i -v "$$(pwd):/v" -e DEBIAN_FRONTEND=noninteractive -e PACKAGE_REPO=$(VERIFY_PACKAGE_REPO) -w /v $(IMAGE) ./verify
