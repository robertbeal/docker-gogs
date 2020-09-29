FROM golang:1.15-alpine3.12 AS builder

RUN apk add --no-cache \
  alpine-sdk \
  curl \
  linux-pam-dev

WORKDIR /gopath/src/github.com/gogs/gogs

RUN curl -L https://github.com/gogs/gogs/archive/v0.12.2.tar.gz | tar zx
RUN mv gogs-0.12.2/* .
RUN go get -v -tags "sqlite redis memcache cert pam"
RUN go build -tags "sqlite redis memcache cert pam"

FROM alpine:3.12.0
LABEL maintainer="github.com/robertbeal"

ARG OVERLAY_VERSION=2.1.0.0
ARG OVERLAY_ARCH=amd64

ARG UID=801
ARG GID=801

WORKDIR /app
COPY --from=builder /gopath/src/github.com/gogs/gogs/gogs .
COPY --from=builder /gopath/src/github.com/gogs/gogs/public ./public
COPY --from=builder /gopath/src/github.com/gogs/gogs/scripts ./scripts
COPY --from=builder /gopath/src/github.com/gogs/gogs/templates ./templates
COPY src /etc

RUN apk add --no-cache \
    bash \
    ca-certificates \
    git \
    linux-pam \
    openssh \
    shadow \
    && addgroup -g $GID git \
    && adduser -s /bin/bash -D -h /data -u $UID -G git git \
    && usermod -p '*' git \
    && passwd -u git \
    && wget -qO- "https://github.com/just-containers/s6-overlay/releases/download/v${OVERLAY_VERSION}/s6-overlay-${OVERLAY_ARCH}.tar.gz" | tar vxz -C / \
    && mkdir -p ./log \
    && chown -R git:git . \
    && chmod -R 550 . \
    && chmod 770  log

HEALTHCHECK --interval=30s --retries=3 CMD wget --spider http://localhost:3000/healthcheck || exit 1
VOLUME /config /data
EXPOSE 22 3000

ENTRYPOINT ["/init"]
