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

VERSION?=0.0.0-dev

help:
	@echo help

clean:
	-make -C docker-ce/packaging clean
	-$(RM) -r docker-ce/packaging
	-$(RM) -r bundles
	-$(RM) *.gz
	-$(RM) *.tgz

.PHONY: docker-ce/packaging/src
docker-ce/packaging/src: docker-ce/packaging docker-ce/packaging/src/github.com/docker/cli docker-ce/packaging/src/github.com/docker/docker
	@echo checked out source

docker-ce/packaging/src/github.com/docker/cli: docker-ce/packaging
	make -C docker-ce/packaging \
		DOCKER_CLI_REPO=$(DOCKER_CLI_REPO) \
		DOCKER_CLI_REF=$(DOCKER_CLI_REF) \
		checkout-cli

docker-ce/packaging/src/github.com/docker/docker: docker-ce/packaging
	make -C docker-ce/packaging \
		DOCKER_ENGINE_REPO=$(DOCKER_ENGINE_REPO) \
		DOCKER_ENGINE_REF=$(DOCKER_ENGINE_REF) \
		checkout-docker

docker-ce/packaging:
	mkdir -p $@
	git clone $(DOCKER_PACKAGING_REPO) $@
	git -C $@ checkout $(DOCKER_PACKAGING_REF)

static-linux: docker-ce/packaging/src
	make -C docker-ce/packaging VERSION=$(VERSION) DOCKER_BUILD_PKGS=static-linux static

# TODO cross-mac should only need the CLI source code, but also calls "static"?
cross-mac: docker-ce/packaging/src
	make -C docker-ce/packaging VERSION=$(VERSION) DOCKER_BUILD_PKGS=cross-mac static

cross-win: docker-ce/packaging/src
	make -C docker-ce/packaging VERSION=$(VERSION) DOCKER_BUILD_PKGS=cross-win static

debian-%: docker-ce/packaging/src
	make -C docker-ce/packaging/deb VERSION=$(VERSION) $@

raspbian-%: docker-ce/packaging/src
	make -C docker-ce/packaging/deb VERSION=$(VERSION) $@

ubuntu-%: docker-ce/packaging/src
	make -C docker-ce/packaging/deb VERSION=$(VERSION) $@

fedora-%: docker-ce/packaging/src
	docker rmi -f $(subst -,:,$@)
	docker pull $(subst -,:,$@)
	make -C docker-ce/packaging/rpm VERSION=$(VERSION) $@

centos-%: docker-ce/packaging/src
	make -C docker-ce/packaging/rpm VERSION=$(VERSION) $@

rhel-%: docker-ce/packaging/src
	make -C docker-ce/packaging/rpm VERSION=$(VERSION) $@

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

bundles-ce-rhel-%-s390x.tar.gz:
	mkdir -p bundles/$(VERSION)/build-rpm/rhel-$*
	cp -R docker-ce/packaging/rpm/rpmbuild/RPMS bundles/$(VERSION)/build-rpm/rhel-$*/
	cp -R docker-ce/packaging/rpm/rpmbuild/SRPMS bundles/$(VERSION)/build-rpm/rhel-$*/
	tar czf $@ bundles

# Bundle the completion files here are used by Docker Desktop
# https://github.com/docker/pinata/blob/553b07bebc444d493502e8ae9fe36cc2f490b793/tools/cmd/pinata/versionpacks/remotedependencies.go#L211-L229
# TODO consider including these with the CLI in the "cross-win", "cross-mac", and "static" bundles and/or embedding them in the CLI
bundles-ce-shell-completion.tar.gz: docker-ce/packaging/src/github.com/docker/cli
	install -D docker-ce/packaging/src/github.com/docker/cli/contrib/completion/bash/docker bundles/$(VERSION)/tgz/amd64/docker/completion/bash/docker
	install -D docker-ce/packaging/src/github.com/docker/cli/contrib/completion/zsh/_docker bundles/$(VERSION)/tgz/amd64/docker/completion/zsh/_docker
	install -D docker-ce/packaging/src/github.com/docker/cli/contrib/completion/fish/docker.fish bundles/$(VERSION)/tgz/amd64/docker/completion/fish/docker.fish
	tar czf $@ bundles

docker-win.zip:
	cp docker-ce/packaging/static/build/win/docker-*.zip $@

docker-mac.tgz:
	cp docker-ce/packaging/static/build/mac/docker-*.tgz $@

docker-%.tgz:
	$(MAKE) static-linux
	mv docker-ce/packaging/static/build/linux/docker-rootless-extras-*.tgz docker-rootless-extras-$*.tgz
	mv docker-ce/packaging/static/build/linux/docker-*.tgz $@

.PHONY: verify
verify:
	# to verify using packages from staging, use: make VERIFY_PACKAGE_REPO=stage IMAGE=ubuntu:focal verify
	docker run --rm -i -v "$$(pwd):/v" -e DEBIAN_FRONTEND=noninteractive -e PACKAGE_REPO=$(VERIFY_PACKAGE_REPO) -w /v $(IMAGE) ./verify

release:
	make -C docker-ce/packaging VERSION=$(VERSION) release
