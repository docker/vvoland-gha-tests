SHELL:=/bin/bash
DOCKER_CE_REPO:=git@github.com:docker/docker-ce
DOCKER_CE_REF:=
VERSION=$(shell cat docker-ce/VERSION)
GITCOMMIT=$(shell git -C docker-ce rev-parse --short HEAD)

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
	make -C docker-ce/components/packaging VERSION=$(VERSION) GITCOMMIT=$(GITCOMMIT) DOCKER_BUILD_PKGS=$@ deb

raspbian-%:
	make -C docker-ce/components/packaging VERSION=$(VERSION) GITCOMMIT=$(GITCOMMIT) DOCKER_BUILD_PKGS=$@ deb

ubuntu-%:
	make -C docker-ce/components/packaging VERSION=$(VERSION) GITCOMMIT=$(GITCOMMIT) DOCKER_BUILD_PKGS=$@ deb

fedora-%:
	make -C docker-ce/components/packaging VERSION=$(VERSION) GITCOMMIT=$(GITCOMMIT) DOCKER_BUILD_PKGS=$@ rpm

centos-%:
	make -C docker-ce/components/packaging VERSION=$(VERSION) GITCOMMIT=$(GITCOMMIT) DOCKER_BUILD_PKGS=$@ rpm

bundles-ce-binary.tar.gz:
	mkdir -p bundles/$(VERSION)/binary-client bundles/$(VERSION)/binary-daemon
	cp docker-ce/components/packaging/static/build/linux/docker/docker bundles/$(VERSION)/binary-client/
	for f in dockerd docker-init docker-proxy docker-runc docker-containerd docker-containerd-ctr docker-containerd-shim; do \
		cp docker-ce/components/packaging/static/build/linux/docker/$$f bundles/$(VERSION)/binary-daemon/; \
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

bundles-ce-shell-completion.tar.gz:
	install -D docker-ce/components/cli/contrib/completion/bash/docker bundles/$(VERSION)/tgz/amd64/docker/completion/bash/docker
	install -D docker-ce/components/cli/contrib/completion/zsh/_docker bundles/$(VERSION)/tgz/amd64/docker/completion/zsh/_docker
	install -D docker-ce/components/cli/contrib/completion/fish/docker.fish bundles/$(VERSION)/tgz/amd64/docker/completion/fish/docker.fish
	tar czf $@ bundles

docker-win.zip:
	cp docker-ce/components/packaging/static/build/win/docker-$(VERSION).zip $@

docker-mac.tgz:
	cp docker-ce/components/packaging/static/build/mac/docker-$(VERSION).tgz $@

docker-aarch64.tgz:
	docker run --rm -i -e VERSION=$(VERSION) -e GITCOMMIT=$(GITCOMMIT) \
		-v $(CURDIR)/docker-ce/components/cli:/go/src/github.com/docker/cli \
		-w /go/src/github.com/docker/cli \
		seemethere/golang-aarch64@sha256:4a83031cd2010c001a860fad43ee0f64d3bd2fe986af6416134dc896fbd5967c \
		make binary
	make -C docker-ce/components/engine binary
	$(RM) -r docker
	install -D docker-ce/components/cli/build/docker docker/docker
	for f in dockerd docker-containerd docker-containerd-ctr docker-containerd-shim docker-init docker-proxy docker-runc; do \
		install -D docker-ce/components/engine/bundles/binary-daemon/$$f docker/$$f; \
	done
	tar --numeric-owner --owner 0 -c -z -f $@ docker
	$(RM) -r docker

docker-s390x.tgz:
	docker run --rm -i -e VERSION=$(VERSION) -e GITCOMMIT=$(GITCOMMIT) \
		-v $(CURDIR)/docker-ce/components/cli:/go/src/github.com/docker/cli \
		-w /go/src/github.com/docker/cli \
		s390x/golang:1.8.3 make binary
	make -C docker-ce/components/engine binary
	$(RM) -r docker
	install -D docker-ce/components/cli/build/docker docker/docker
	for f in dockerd docker-containerd docker-containerd-ctr docker-containerd-shim docker-init docker-proxy docker-runc; do \
		install -D docker-ce/components/engine/bundles/binary-daemon/$$f docker/$$f; \
	done
	tar --numeric-owner --owner 0 -c -z -f $@ docker
	$(RM) -r docker

docker-ppc64le.tgz:
	docker run --rm -i -e VERSION=$(VERSION) -e GITCOMMIT=$(GITCOMMIT) \
		-v $(CURDIR)/docker-ce/components/cli:/go/src/github.com/docker/cli \
		-w /go/src/github.com/docker/cli \
		ppc64le/golang:1.8.3 make binary
	make -C docker-ce/components/engine binary
	$(RM) -r docker
	install -D docker-ce/components/cli/build/docker docker/docker
	for f in dockerd docker-containerd docker-containerd-ctr docker-containerd-shim docker-init docker-proxy docker-runc; do \
		install -D docker-ce/components/engine/bundles/binary-daemon/$$f docker/$$f; \
	done
	tar --numeric-owner --owner 0 -c -z -f $@ docker
	$(RM) -r docker

docker-armhf.tgz:
	docker run --rm -i -e VERSION=$(VERSION) -e GITCOMMIT=$(GITCOMMIT) \
		-v $(CURDIR)/docker-ce/components/cli:/go/src/github.com/docker/cli \
		-w /go/src/github.com/docker/cli \
		arm32v7/golang:1.8.3 make binary
	make -C docker-ce/components/engine binary
	$(RM) -r docker
	install -D docker-ce/components/cli/build/docker docker/docker
	for f in dockerd docker-containerd docker-containerd-ctr docker-containerd-shim docker-init docker-proxy docker-runc; do \
		install -D docker-ce/components/engine/bundles/binary-daemon/$$f docker/$$f; \
	done
	tar --numeric-owner --owner 0 -c -z -f $@ docker
	$(RM) -r docker

docker-armel.tgz:
	docker run --rm -i -e VERSION=$(VERSION) -e GITCOMMIT=$(GITCOMMIT) -e GOARM=6 \
		-v $(CURDIR)/docker-ce/components/cli:/go/src/github.com/docker/cli \
		-w /go/src/github.com/docker/cli \
		arm32v7/golang:1.8.3 make binary
	make -C docker-ce/components/engine DOCKER_RUN_DOCKER='$$(DOCKER_FLAGS) -e GOARM=6 "$$(DOCKER_IMAGE)"' binary
	$(RM) -r docker
	install -D docker-ce/components/cli/build/docker docker/docker
	for f in dockerd docker-containerd docker-containerd-ctr docker-containerd-shim docker-init docker-proxy docker-runc; do \
		install -D docker-ce/components/engine/bundles/binary-daemon/$$f docker/$$f; \
	done
	tar --numeric-owner --owner 0 -c -z -f $@ docker
	$(RM) -r docker

docker-amd64.tgz:
	docker run --rm -i -e VERSION=$(VERSION) -e GITCOMMIT=$(GITCOMMIT) \
		-v $(CURDIR)/docker-ce/components/cli:/go/src/github.com/docker/cli \
		-w /go/src/github.com/docker/cli \
		golang:1.8.3 make binary
	make -C docker-ce/components/engine binary
	$(RM) -r docker
	install -D docker-ce/components/cli/build/docker docker/docker
	for f in dockerd docker-containerd docker-containerd-ctr docker-containerd-shim docker-init docker-proxy docker-runc; do \
		install -D docker-ce/components/engine/bundles/binary-daemon/$$f docker/$$f; \
	done
	tar --numeric-owner --owner 0 -c -z -f $@ docker
	$(RM) -r docker
