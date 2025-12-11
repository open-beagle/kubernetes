#!/bin/bash 

set -ex

cd $PWD/.beagle/pause

export REGISTRY=registry.cn-qingdao.aliyuncs.com/wod
export KUBE_CROSS_IMAGE=registry.cn-qingdao.aliyuncs.com/wod/golang
export KUBE_CROSS_VERSION=1.24

make all ALL_ARCH.linux="amd64 arm64"
make push-manifest ALL_ARCH.linux="amd64 arm64"