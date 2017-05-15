SHELL:=/bin/bash

tgz:
	git clone -b $${DOCKER_BRANCH} $${DOCKER_REPO} docker-ce
	make -C docker-ce tgz
