# kubectl

## uptime

为 kubectl get node 命令增加显示 uptime

### 重要说明

**kubectl get node 的表格输出是由 API Server 生成的，而不是 kubectl 客户端！**

这意味着要看到 UPTIME 列，你需要：

1. 重新编译 **kube-apiserver**（不仅仅是 kubectl）
2. 部署新版本的 kube-apiserver 到集群中
3. 然后使用任何版本的 kubectl 都能看到 UPTIME 列

### 快速构建（推荐）

使用提供的构建脚本一键构建 kube-apiserver 镜像：

```bash
# 使用默认配置构建
.beagle/build-kube-apiserver.sh

# 或自定义配置
BUILD_VERSION=v1.32.10-beagle \
.beagle/build-kube-apiserver.sh
```

构建脚本会自动：

1. 应用 `.beagle/v1.30-kubectl.patch` 补丁
2. 使用 Docker 容器编译 kube-apiserver（amd64 + arm64）
3. 构建 Docker 镜像

### 手动编译方法

如果需要手动编译，使用当前系统的 Go 环境：

```bash
# 应用补丁
git apply .beagle/v1.30-kubectl.patch

# 清理并编译
rm -rf _output && \
export KUBE_GIT_VERSION=v1.32.10-beagle && \
export KUBE_BUILD_PLATFORMS="linux/amd64 linux/arm64" && \
FORCE_HOST_GO=1 \
make kube-apiserver kubectl
```

**说明**：

- `FORCE_HOST_GO=1` 强制使用系统当前的 Go 版本，避免下载 `.go-version` 中指定的 Go 1.23.10
- 必须编译 `kube-apiserver`，因为表格列定义是由 API Server 返回的
- kubectl 可选，任何版本的 kubectl 都能显示 API Server 返回的新列

### 构建 Docker 镜像

```bash
# 构建 amd64 镜像
docker build \
  -f .beagle/kube-apiserver.dockerfile \
  -t registry.cn-qingdao.aliyuncs.com/wod/kube-apiserver:v1.32.10-beagle-amd64 \
  --build-arg BASE=registry.cn-qingdao.aliyuncs.com/wod/debian-base:v1.3.0-amd64 \
  --build-arg VERSION=v1.32.10-beagle \
  --build-arg TARGETOS=linux \
  --build-arg TARGETARCH=amd64 \
  _output/local/bin

# 构建 arm64 镜像
docker build \
  -f .beagle/kube-apiserver.dockerfile \
  -t registry.cn-qingdao.aliyuncs.com/wod/kube-apiserver:v1.32.10-beagle-arm64 \
  --build-arg BASE=registry.cn-qingdao.aliyuncs.com/wod/debian-base:v1.3.0-arm64 \
  --build-arg VERSION=v1.32.10-beagle \
  --build-arg TARGETOS=linux \
  --build-arg TARGETARCH=arm64 \
  _output/local/bin

# 推送镜像
docker push registry.cn-qingdao.aliyuncs.com/wod/kube-apiserver:v1.32.10-beagle-amd64
docker push registry.cn-qingdao.aliyuncs.com/wod/kube-apiserver:v1.32.10-beagle-arm64

# 创建并推送 multi-arch manifest
docker manifest create registry.cn-qingdao.aliyuncs.com/wod/kube-apiserver:v1.32.10-beagle \
  registry.cn-qingdao.aliyuncs.com/wod/kube-apiserver:v1.32.10-beagle-amd64 \
  registry.cn-qingdao.aliyuncs.com/wod/kube-apiserver:v1.32.10-beagle-arm64
docker manifest push registry.cn-qingdao.aliyuncs.com/wod/kube-apiserver:v1.32.10-beagle
```

### 修改内容

#### 1. pkg/printers/internalversion/printers.go

- 在 `nodeColumnDefinitions` 中添加了 UPTIME 列定义
- 在 `printNode` 函数中添加了 uptime 计算逻辑，基于 NodeReady 条件的 LastTransitionTime

#### 2. pkg/printers/internalversion/printers_test.go

- 更新了所有相关测试用例，在期望值中添加了 uptime 字段

### 使用效果

```bash
# 查看节点信息（包含 UPTIME 字段）
kubectl get nodes

# 输出示例：
# NAME     STATUS   ROLES    AGE   VERSION   UPTIME
# node-1   Ready    master   10d   v1.30.0   9d
# node-2   Ready    worker   10d   v1.30.0   8d
```

### 部署到集群

构建完成后，需要更新集群中的 kube-apiserver：

```bash
# 1. 备份当前的 kube-apiserver 配置
kubectl -n kube-system get pod -l component=kube-apiserver -o yaml > kube-apiserver-backup.yaml

# 2. 更新镜像（根据你的集群部署方式）
# 如果是 kubeadm 部署，编辑 /etc/kubernetes/manifests/kube-apiserver.yaml
# 将镜像改为: registry.cn-qingdao.aliyuncs.com/wod/kube-apiserver:v1.32.10-beagle

# 3. 等待 kube-apiserver 重启完成
kubectl -n kube-system get pod -l component=kube-apiserver -w

# 4. 验证 UPTIME 列
kubectl get nodes
```

### UPTIME 字段说明

- **UPTIME** 显示节点自从最后一次进入 Ready 状态以来的时间
- 如果节点当前不是 Ready 状态，显示 `<unknown>`
- 如果无法获取 NodeReady 条件信息，显示 `<unknown>`
- 时间格式与 AGE 字段相同（例如：1d, 2h, 30m）

### 故障排查

如果看不到 UPTIME 列：

1. **确认 kube-apiserver 版本**

```bash
kubectl version --short
# Server Version 应该显示 v1.32.10-beagle
```

2. **检查 kube-apiserver 日志**

```bash
kubectl -n kube-system logs -l component=kube-apiserver --tail=100
```

3. **验证 patch 是否应用**

```bash
# 在源码目录检查
git diff pkg/printers/internalversion/printers.go | grep Uptime
```

4. **重新构建**

```bash
# 清理并重新构建
git reset --hard
git apply .beagle/v1.30-kubectl.patch
.beagle/build-kube-apiserver.sh
```
