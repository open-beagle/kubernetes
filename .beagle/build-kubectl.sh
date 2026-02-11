#!/bin/bash
set -e

BUILD_VERSION=${BUILD_VERSION:-"v1.32.10-beagle"}

echo "Building kubectl.exe (windows/amd64) ${BUILD_VERSION}"

export KUBE_GIT_VERSION=${BUILD_VERSION}
export KUBE_BUILD_PLATFORMS="windows/amd64"
export KUBE_GIT_TREE_STATE=archive
export FORCE_HOST_GO=1

make kubectl

OUTPUT="_output/local/bin/windows/amd64/kubectl.exe"
if [ ! -f "${OUTPUT}" ]; then
    echo "Error: kubectl.exe not found at ${OUTPUT}"
    exit 1
fi

echo "Build completed: ${OUTPUT}"
