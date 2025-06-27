FROM scratch
ARG VERSION
COPY ./amd64/docker-${VERSION}.zip /static/${VERSION}/docker-win-amd64.zip
# static/${VERSION}/win/amd64/
#COPY ./arm64/docker-${VERSION}.zip /static/${VERSION}/win/arm64/
