ARG BASE

FROM ${BASE}

ARG AUTHOR
ARG VERSION

LABEL maintainer=${AUTHOR} version=${VERSION}

ARG TARGETOS
ARG TARGETARCH

COPY ${TARGETOS}/${TARGETARCH}/kube-scheduler /usr/local/bin/kube-scheduler