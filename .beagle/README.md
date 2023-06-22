# version

<https://github.com/kubernetes/kubernetes>

```bash
git remote add upstream git@github.com:kubernetes/kubernetes.git

git fetch upstream

git merge v1.20.15
```

## images

```bash
# gitlab.wodcloud.com/cloud/kubernetes-release
registry.cn-qingdao.aliyuncs.com/wod/debian-base:v1.3.0-$ARCH
registry.cn-qingdao.aliyuncs.com/wod/debian-iptables:v1.4.0-$ARCH

# pause
# registry.cn-qingdao.aliyuncs.com/wod/pause:3.7-$ARCH
bash .beagle/build.sh
```

## build

```bash
# build debug
# docker run -it \
# --rm \
# --entrypoint bash \
# -v $PWD/:/go/src/k8s.io/kubernetes \
# -w /go/src/k8s.io/kubernetes \
# -e KUBE_GIT_VERSION=v1.20.15-beagle \
# -e KUBE_BUILD_PLATFORMS="linux/amd64 linux/arm64 linux/ppc64le linux/mips64le" \
# -e GOPROXY=https://goproxy.cn \
# registry.cn-qingdao.aliyuncs.com/wod/golang:1.16
# git apply .beagle/v1.20.1-PATCH-k8s-add-mips64le-support.patch

docker run -it \
--rm \
--entrypoint bash \
-v $PWD/:/go/src/k8s.io/kubernetes \
-w /go/src/k8s.io/kubernetes \
-e KUBE_GIT_VERSION=v1.20.15-beagle \
-e KUBE_BUILD_PLATFORMS="linux/amd64 linux/arm64 linux/ppc64le" \
-e KUBE_STATIC_OVERRIDES="cmd/kubelet" \
-e GOPROXY=https://goproxy.cn \
registry.cn-qingdao.aliyuncs.com/wod/golang:1.16

make all WHAT=cmd/kube-apiserver GOFLAGS=-v
make all WHAT=cmd/kube-controller-manager GOFLAGS=-v
make all WHAT=cmd/kube-scheduler GOFLAGS=-v
make all WHAT=cmd/kube-proxy GOFLAGS=-v
make all WHAT=cmd/kubectl GOFLAGS=-v
make all WHAT=cmd/kubelet GOFLAGS=-v

# docker debug
docker run -it --rm \
-w /go/src/k8s.io/kubernetes \
-v /var/run/docker.sock:/var/run/docker.sock \
-v $PWD/:/go/src/k8s.io/kubernetes \
-e CI_WORKSPACE=/go/src/k8s.io/kubernetes \
-e PLUGIN_BASE=registry.cn-qingdao.aliyuncs.com/wod/debian-base:v1.3.0 \
-e PLUGIN_DOCKERFILE=.beagle/kube-apiserver.dockerfile \
-e PLUGIN_REPO=wod/kube-apiserver \
-e PLUGIN_VERSION='v1.20.15-beagle' \
-e PLUGIN_ARGS='TARGETOS=linux,TARGETARCH=amd64' \
-e PLUGIN_REGISTRY=registry.cn-qingdao.aliyuncs.com \
-e REGISTRY_USER=<USER> \
-e REGISTRY_PASSWORD=<PASSWORD> \
registry.cn-qingdao.aliyuncs.com/wod/devops-docker:1.0
```

## patch

```bash
git apply .beagle/v1.20.1-PATCH-k8s-add-mips64le-support.patch
```

## cache

```bash
# 构建缓存-->推送缓存至服务器
docker run --rm \
  -e PLUGIN_REBUILD=true \
  -e PLUGIN_ENDPOINT=$PLUGIN_ENDPOINT \
  -e PLUGIN_ACCESS_KEY=$PLUGIN_ACCESS_KEY \
  -e PLUGIN_SECRET_KEY=$PLUGIN_SECRET_KEY \
  -e PLUGIN_PATH="/cache/open-beagle/kubernetes" \
  -e PLUGIN_MOUNT="./.git" \
  -v $(pwd):$(pwd) \
  -w $(pwd) \
  registry.cn-qingdao.aliyuncs.com/wod/devops-s3-cache:1.0

# 读取缓存-->将缓存从服务器拉取到本地
docker run --rm \
  -e PLUGIN_RESTORE=true \
  -e PLUGIN_ENDPOINT=$PLUGIN_ENDPOINT \
  -e PLUGIN_ACCESS_KEY=$PLUGIN_ACCESS_KEY \
  -e PLUGIN_SECRET_KEY=$PLUGIN_SECRET_KEY \
  -e PLUGIN_PATH="/cache/open-beagle/kubernetes" \
  -v $(pwd):$(pwd) \
  -w $(pwd) \
  registry.cn-qingdao.aliyuncs.com/wod/devops-s3-cache:1.0
```
