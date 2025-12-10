#!/bin/bash 

set -ex

cd $PWD/.beagle/pause

export REGISTRY=registry.cn-qingdao.aliyuncs.com/wod
export KUBE_CROSS_IMAGE=registry.cn-qingdao.aliyuncs.com/wod/golang
export KUBE_CROSS_VERSION=1.20

make all
make push-manifest