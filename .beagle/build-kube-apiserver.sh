#!/bin/bash
set -e

# 配置变量
BUILD_VERSION=${BUILD_VERSION:-"v1.30.14-beagle"}
GOLANG_IMAGE=${GOLANG_IMAGE:-"registry.cn-qingdao.aliyuncs.com/wod/golang:1.24"}
BASE_IMAGE=${BASE_IMAGE:-"registry.cn-qingdao.aliyuncs.com/wod/debian-base:v1.3.0"}
REGISTRY=${REGISTRY:-"registry.cn-qingdao.aliyuncs.com/wod"}

echo "=========================================="
echo "Building kube-apiserver ${BUILD_VERSION}"
echo "=========================================="

# 应用 kubectl patch（包含 uptime 功能）
echo "Applying kubectl patch..."
PATCH_APPLIED=0
if [ -f .beagle/v1.30-kubectl.patch ]; then
    if git apply .beagle/v1.30-kubectl.patch 2>/dev/null; then
        echo "Patch applied successfully"
        PATCH_APPLIED=1
    else
        echo "Warning: Patch may already be applied or conflicts exist"
    fi
else
    echo "Warning: Patch file not found, skipping..."
fi

# 清理旧的构建产物
echo "Cleaning old build artifacts..."
sudo rm -rf _output

# 使用 Docker 容器编译 kube-apiserver
echo "Cross-compiling kube-apiserver for linux/amd64 and linux/arm64..."
docker run --rm \
    -v $(pwd):/go/src/k8s.io/kubernetes \
    -w /go/src/k8s.io/kubernetes \
    -e KUBE_GIT_VERSION=${BUILD_VERSION} \
    -e KUBE_BUILD_PLATFORMS="linux/amd64 linux/arm64" \
    ${GOLANG_IMAGE} \
    bash -c "git config --global --add safe.directory /go/src/k8s.io/kubernetes && make kube-apiserver"

# 回退 patch
if [ ${PATCH_APPLIED} -eq 1 ]; then
    echo "Reverting patch..."
    git apply -R .beagle/v1.30-kubectl.patch
    echo "Patch reverted successfully"
fi

# 检查编译产物
if [ ! -f _output/local/bin/linux/amd64/kube-apiserver ]; then
    echo "Error: kube-apiserver binary not found for amd64"
    exit 1
fi

if [ ! -f _output/local/bin/linux/arm64/kube-apiserver ]; then
    echo "Error: kube-apiserver binary not found for arm64"
    exit 1
fi

echo "Build completed successfully!"
echo "Binaries location:"
echo "  - _output/local/bin/linux/amd64/kube-apiserver"
echo "  - _output/local/bin/linux/arm64/kube-apiserver"

# 构建 Docker 镜像
echo ""
echo "=========================================="
echo "Building Docker images"
echo "=========================================="

# 构建 amd64 镜像
echo "Building amd64 image..."
docker build \
    -f .beagle/kube-apiserver.dockerfile \
    -t ${REGISTRY}/kube-apiserver:${BUILD_VERSION}-amd64 \
    --build-arg BASE=${BASE_IMAGE}-amd64 \
    --build-arg VERSION=${BUILD_VERSION} \
    --build-arg TARGETOS=linux \
    --build-arg TARGETARCH=amd64 \
    _output/local/bin

# 构建 arm64 镜像
echo "Building arm64 image..."
docker build \
    -f .beagle/kube-apiserver.dockerfile \
    -t ${REGISTRY}/kube-apiserver:${BUILD_VERSION}-arm64 \
    --build-arg BASE=${BASE_IMAGE}-arm64 \
    --build-arg VERSION=${BUILD_VERSION} \
    --build-arg TARGETOS=linux \
    --build-arg TARGETARCH=arm64 \
    _output/local/bin

echo ""
echo "=========================================="
echo "Build completed!"
echo "=========================================="
echo "Images built:"
echo "  - ${REGISTRY}/kube-apiserver:${BUILD_VERSION}-amd64"
echo "  - ${REGISTRY}/kube-apiserver:${BUILD_VERSION}-arm64"
echo ""
echo "To push images, run:"
echo "  docker push ${REGISTRY}/kube-apiserver:${BUILD_VERSION}-amd64"
echo "  docker push ${REGISTRY}/kube-apiserver:${BUILD_VERSION}-arm64"
echo ""
echo "To create multi-arch manifest:"
echo "  docker manifest create ${REGISTRY}/kube-apiserver:${BUILD_VERSION} \\"
echo "    ${REGISTRY}/kube-apiserver:${BUILD_VERSION}-amd64 \\"
echo "    ${REGISTRY}/kube-apiserver:${BUILD_VERSION}-arm64"
echo "  docker manifest push ${REGISTRY}/kube-apiserver:${BUILD_VERSION}"
