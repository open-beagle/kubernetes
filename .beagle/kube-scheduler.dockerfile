ARG BASE

FROM ${BASE}

ARG AUTHOR
ARG VERSION
ARG TARGETOS
ARG TARGETARCH

LABEL maintainer=${AUTHOR} version=${VERSION}

COPY ${TARGETOS}/${TARGETARCH}/kube-scheduler /usr/local/bin/kube-scheduler
