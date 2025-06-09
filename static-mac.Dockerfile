FROM scratch
ARG VERSION
COPY ./arm64/docker-${VERSION}.tgz /static/${VERSION}/mac/arm64/
COPY ./amd64/docker-${VERSION}.tgz /static/${VERSION}/mac/amd64/