FROM scratch
ARG VERSION
COPY ./arm64/docker-${VERSION}.tgz /static/${VERSION}/docker-mac-aarch64.tgz
COPY ./amd64/docker-${VERSION}.tgz /static/${VERSION}/docker-mac-amd64.tgz
