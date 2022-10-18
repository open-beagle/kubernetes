ARG BASE

FROM ${BASE}

ARG AUTHOR
ARG VERSION

LABEL maintainer=${AUTHOR} version=${VERSION}

ARG TARGETOS
ARG TARGETARCH

COPY ${TARGETOS}/${TARGETARCH}/kube-controller-manager /usr/local/bin/kube-controller-manager