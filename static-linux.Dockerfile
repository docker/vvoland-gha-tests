FROM scratch AS linux-amd64
ARG VERSION

COPY ./docker-${VERSION}.tgz /static/${VERSION}/docker.tgz
COPY ./docker-rootless-extras-${VERSION}.tgz /static/${VERSION}/docker-rootless-extras.tgz

FROM scratch AS linux-other
ARG VERSION
ARG ARCH

COPY ./docker-${VERSION}.tgz /static/${VERSION}/docker-${ARCH}.tgz
COPY ./docker-rootless-extras-${VERSION}.tgz /static/${VERSION}/docker-rootless-extras-${ARCH}.tgz

FROM linux-other AS linux-aarch64
FROM linux-other AS linux-armel
FROM linux-other AS linux-armhf
