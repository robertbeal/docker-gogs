FROM golang:1.16.5-alpine3.12 AS builder

ARG VERSION=v0.12.9

# hadolint ignore=DL3018
RUN apk add --no-cache \
  alpine-sdk \
  curl \
  linux-pam-dev

WORKDIR /gopath/src/github.com/gogs/gogs

# hadolint ignore=DL4006
RUN curl -L https://github.com/gogs/gogs/archive/$VERSION.tar.gz | tar zx
RUN mv gogs-*/* .
RUN go get -v -tags "sqlite redis memcache cert pam"
RUN go build -tags "sqlite redis memcache cert pam"

FROM alpine:edge

ARG UID=801
ARG GID=801

LABEL maintainer="github.com/robertbeal" \
  org.label-schema.name="Gogs" \
  org.label-schema.description="Enhanced Docker image for Gogs" \
  org.label-schema.url="https://github.com/gogs/gogs" \
  org.label-schema.version=$VERSION \
  org.label-schema.vcs-ref=$COMMIT_ID \
  org.label-schema.vcs-url="https://github.com/robertbeal/docker-gogs" \
  org.label-schema.schema-version="1.0"

WORKDIR /app
COPY --from=builder /gopath/src/github.com/gogs/gogs/gogs .
COPY --from=builder /gopath/src/github.com/gogs/gogs/public ./public
COPY --from=builder /gopath/src/github.com/gogs/gogs/scripts ./scripts
COPY --from=builder /gopath/src/github.com/gogs/gogs/templates ./templates
COPY src /etc

# hadolint ignore=DL3018,DL4006
RUN apk add --no-cache --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing/ \
  bash \
  ca-certificates \
  git \
  linux-pam \
  openssh \
  shadow \
  s6-overlay \
  && addgroup -g $GID git \
  && adduser -s /bin/bash -D -h /data -u $UID -G git git \
  && usermod -p '*' git \
  && passwd -u git \
  && mkdir -p ./log \
  && chown -R git:git . \
  && chmod -R 550 . \
  && chmod 770  log

HEALTHCHECK --interval=30s --retries=3 CMD wget --spider http://localhost:3000 || exit 1
VOLUME /config /data
EXPOSE 22222 3000

ENTRYPOINT ["/init"]
