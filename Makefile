SHELL:=/bin/bash

# The packaging repository and version to use for building:
DOCKER_PACKAGING_REPO?=git@github.com:docker/docker-ce-packaging.git
DOCKER_PACKAGING_REF?=HEAD

# These environment variables can be set to control parameters in the upstream
# docker-ce-packaging Makefile(s):
#
# - REF                  DEPRECATED: git reference to use for both cli and engine (e.g. 20.10 for the 20.10 branch on both)
#                        This is deprecated, and just for convenience, use the other variables below.
# - DOCKER_CLI_REPO      docker cli repository to build from (defaults to https://github.com/docker/cli.git)
# - DOCKER_CLI_REF       docker cli git reference to build from (defaults to HEAD of default branch)
# - DOCKER_ENGINE_REPO   docker engine repository to build from (defaults to https://github.com/docker/docker.git)
# - DOCKER_ENGINE_REF    docker engine git reference to build from (defaults to HEAD of default branch)
# - DOCKER_SCAN_REPO     docker scan plugin repository to build from (defaults to https://github.com/docker/scan-cli-plugin.git)
# - DOCKER_SCAN_REF      docker scan plugin git reference to build from (defaults to HEAD of default branch)
# - DOCKER_COMPOSE_REPO  docker compose repository to build from (defaults to https://github.com/docker/docker.git)
# - DOCKER_COMPOSE_REF   docker compose git reference to build from (defaults to HEAD of default branch (v2))
# - CONTAINERD_VERSION   git reference (usually a tag) of containerd to build for the static binary packages (defaults to the version specific in the docker engine's Dockerfile)
# - RUNC_VERSION         git reference (usually a tag) of runc to build for the static binary packages (defaults to the version specific in the docker engine's Dockerfile)
# - VERIFY_PACKAGE_REPO  Package repository to use for installing dependencies (containerd.io)
#                        This should normally only be used when building a new distro or architecture,
#                        for which containerd.io binaries are not yet available on download.docker.com,
#                        but (test) builds available on download-stage.docker.com.
#                        Set to "stage" to use download-stage.docker.com. Leave empty (or any value
#                        other than "stage") uses the default (download.docker.com).
# - VERIFY_PLATFORM      Optional flags like --platform=linux/armhf
#
# For a full list of available env-vars and make parameters, refer to the upstream
# repository, for example:
#
# - https://github.com/docker/docker-ce-packaging/blob/ad85fb059403230307ccd81888caba273d93dcbf/common.mk#L26
# - https://github.com/docker/docker-ce-packaging/blob/ad85fb059403230307ccd81888caba273d93dcbf/deb/Makefile#L3-L11
# - https://github.com/docker/docker-ce-packaging/blob/ad85fb059403230307ccd81888caba273d93dcbf/rpm/Makefile#L3-L11
# - https://github.com/docker/docker-ce-packaging/blob/ad85fb059403230307ccd81888caba273d93dcbf/static/Makefile#L3-L27

# Version to use for the packages and as version for the `--version` output.
# The default (0.0.0-dev) generates a "pseudo-version" based on commit sha and
# commit date.
VERSION?=0.0.0-dev

clean:
	-if [ -d "packaging" ]; then make -C packaging clean; fi
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
	make -C packaging checkout
	@echo checked out source

static-linux: packaging/src
	make -C packaging DOCKER_BUILD_PKGS=static-linux static

# TODO cross-mac should only need the CLI source code, but also calls "static"?
cross-mac: packaging/src
	make -C packaging DOCKER_BUILD_PKGS=cross-mac static

cross-win: packaging/src
	make -C packaging DOCKER_BUILD_PKGS=cross-win static

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
	make -C packaging/deb debbuild/$@
	mv packaging/deb/debbuild/$@ .

RPM_BUNDLES:=bundles-ce-fedora-%.tar.gz bundles-ce-centos-%.tar.gz bundles-ce-rhel-%.tar.gz

$(RPM_BUNDLES): packaging/src
	make -C packaging/rpm rpmbuild/$@
	mv packaging/rpm/rpmbuild/$@ .

# Bundle the completion files here are used by Docker Desktop
# https://github.com/docker/pinata/blob/553b07bebc444d493502e8ae9fe36cc2f490b793/tools/cmd/pinata/versionpacks/remotedependencies.go#L211-L229
# TODO consider including these with the CLI in the "cross-win", "cross-mac", and "static" bundles and/or embedding them in the CLI
bundles-ce-shell-completion.tar.gz: packaging
	make -C packaging checkout-cli

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
	rm packaging/static/build/linux/docker-buildx-*.tgz || true # FIXME: temp fix. will be solved by https://github.com/docker/release-packaging/pull/643
	mv packaging/static/build/linux/docker-rootless-extras-*.tgz docker-rootless-extras-$*.tgz
	mv packaging/static/build/linux/docker-*.tgz $@
