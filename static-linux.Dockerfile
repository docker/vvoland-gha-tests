FROM scratch
ARG VERSION
COPY ./arm64/docker-${VERSION}.tgz /static/${VERSION}/docker-aarch64.tgz
COPY ./arm64/docker-rootless-extras-${VERSION}.tgz /static/${VERSION}/docker-rootless-extras-aarch64.tgz

COPY ./amd64/docker-${VERSION}.tgz /static/${VERSION}/docker-amd64.tgz
COPY ./amd64/docker-rootless-extras-${VERSION}.tgz /static/${VERSION}/docker-rootless-extras-amd64.tgz

COPY ./armel/docker-${VERSION}.tgz /static/${VERSION}/docker-armel.tgz
COPY ./armel/docker-rootless-extras-${VERSION}.tgz /static/${VERSION}/docker-rootless-extras-armel.tgz

COPY ./armhf/docker-${VERSION}.tgz /static/${VERSION}/docker-armhf.tgz
COPY ./armhf/docker-rootless-extras-${VERSION}.tgz /static/${VERSION}/docker-rootless-extras-armhf.tgz
