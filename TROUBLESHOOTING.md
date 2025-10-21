# 故障排查指南

> message-service 启动问题及常见故障解决方案

---

## 🚨 问题：message-service 启动后立即退出

### 症状

```
message-service listening on :3000
npm error signal SIGTERM
npm error command failed
```

### 原因分析

服务启动成功但被 Docker 健康检查杀死，常见原因：

1. **健康检查命令错误** ⭐ 最常见
   - Alpine 镜像没有 `wget` 命令
   - 健康检查路径不对
   - 端口配置错误

2. **端口映射问题**
   - 容器内外端口不匹配
   - 健康检查使用错误的端口

3. **依赖服务未就绪**
   - MinIO 或 LiveKit 还未启动

---

## ✅ 解决方案

### 方案 1：快速诊断（推荐）

```bash
cd /Users/ryanliu/DDCS/HChat/HCChatBackEnd

# 运行诊断脚本
./diagnose-service.sh message-service

# 查看详细信息，特别注意：
# - 重启次数（如果很多说明一直失败）
# - 健康检查状态
# - 端口是否监听
```

### 方案 2：自动修复

```bash
# 运行修复脚本
./fix-message-service.sh

# 选择 4（全部修复）
```

### 方案 3：手动修复

#### 步骤 1：检查 docker-compose.yml

SSH 到 VPS：

```bash
ssh root@mx.go-lv.com
cd /root/hc-stack/infra
vim docker-compose.yml
```

找到 `message-service` 的健康检查部分，**修复前**：

```yaml
healthcheck:
  test: ["CMD", "wget", "-qO-", "http://127.0.0.1:3000/healthz"]
  interval: 30s
  timeout: 5s
  retries: 5
```

**修复后**（三种方案任选一个）：

**方案 A：使用 curl**
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://127.0.0.1:3000/healthz"]
  interval: 30s
  timeout: 5s
  retries: 5
  start_period: 10s  # 给服务 10 秒启动时间
```

**方案 B：使用 nc（netcat）**
```yaml
healthcheck:
  test: ["CMD", "nc", "-z", "127.0.0.1", "3000"]
  interval: 30s
  timeout: 5s
  retries: 5
  start_period: 10s
```

**方案 C：禁用健康检查（临时）**
```yaml
healthcheck:
  disable: true
```

#### 步骤 2：重新启动服务

```bash
# 应用配置
docker compose up -d message-service

# 查看日志
docker compose logs -f message-service
```

#### 步骤 3：验证

```bash
# 检查服务状态
docker compose ps message-service

# 测试健康检查端点
curl http://127.0.0.1:10092/healthz

# 应该返回: {"ok":true}
```

---

## 🔍 深度排查

### 检查健康检查命令是否可用

```bash
# 进入容器
docker compose exec message-service sh

# 测试健康检查命令
curl -f http://127.0.0.1:3000/healthz  # 如果有 curl
wget -qO- http://127.0.0.1:3000/healthz  # 如果有 wget
nc -z 127.0.0.1 3000  # 如果有 nc

# 如果命令不存在，安装
apk add curl  # Alpine
# 或修改 docker-compose.yml 使用存在的命令
```

### 检查端口映射

```bash
# VPS 上检查
netstat -tlnp | grep 10092  # 应该能看到监听
netstat -tlnp | grep 10081  # 如果有 nginx 代理

# 测试端口连通性
curl http://127.0.0.1:10092/healthz
```

### 查看详细日志

```bash
# 查看启动日志
docker compose logs --tail=100 message-service

# 查看容器详细信息
CONTAINER_ID=$(docker compose ps -q message-service)
docker inspect $CONTAINER_ID

# 查看重启次数
docker inspect $CONTAINER_ID --format='{{.RestartCount}}'

# 查看退出代码
docker inspect $CONTAINER_ID --format='{{.State.ExitCode}}'
```

---

## 🛠️ 常见问题

### Q1: Alpine 镜像没有 wget

**问题**：
```yaml
healthcheck:
  test: ["CMD", "wget", "-qO-", "http://127.0.0.1:3000/healthz"]
```

**解决**：改用 `curl` 或安装 `wget`

```yaml
# 方案 A: 改用 curl
healthcheck:
  test: ["CMD", "curl", "-f", "http://127.0.0.1:3000/healthz"]

# 方案 B: 在 Dockerfile 中安装 wget
# 如果使用独立 Dockerfile
RUN apk add --no-cache wget

# 方案 C: 修改 command 安装 wget
command: ["sh", "-c", "apk add --no-cache wget && npm ci && npm start"]
```

### Q2: 健康检查端口错误

**问题**：健康检查使用外部端口而非容器内部端口

**错误**：
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://127.0.0.1:10092/healthz"]  # ❌
```

**正确**：
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://127.0.0.1:3000/healthz"]  # ✅
```

### Q3: 服务启动需要时间

**问题**：健康检查在服务完全启动前就开始

**解决**：添加 `start_period`

```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://127.0.0.1:3000/healthz"]
  interval: 30s
  timeout: 5s
  retries: 5
  start_period: 15s  # ← 添加这行，给服务 15 秒启动时间
```

### Q4: 依赖服务未就绪

**问题**：MinIO 或 LiveKit 还未启动完成

**解决**：使用 `depends_on` 的条件等待

```yaml
message-service:
  depends_on:
    minio:
      condition: service_healthy  # 等待健康检查通过
    livekit:
      condition: service_started  # 或至少等待启动
```

---

## 📋 完整修复流程

```bash
# 1. 诊断问题
./diagnose-service.sh message-service

# 2. SSH 到 VPS
ssh root@mx.go-lv.com

# 3. 修改健康检查
cd /root/hc-stack/infra
vim docker-compose.yml

# 找到 message-service，修改 healthcheck:
healthcheck:
  test: ["CMD", "curl", "-f", "http://127.0.0.1:3000/healthz"]
  interval: 30s
  timeout: 5s
  retries: 5
  start_period: 15s  # 重要！给启动时间

# 4. 重启服务
docker compose stop message-service
docker compose rm -f message-service
docker compose up -d message-service

# 5. 验证
docker compose ps message-service  # 应该显示 healthy
curl http://127.0.0.1:10092/healthz  # 应该返回 {"ok":true}

# 6. 查看日志确认
docker compose logs --tail=50 message-service
```

---

## 🎯 预防措施

### 1. 使用可靠的健康检查命令

**推荐**：
```yaml
# 最可靠：使用 curl
healthcheck:
  test: ["CMD", "curl", "-f", "http://127.0.0.1:3000/healthz"]
  interval: 30s
  timeout: 5s
  retries: 5
  start_period: 15s
```

### 2. 确保镜像包含健康检查工具

如果使用 Alpine 镜像，在 Dockerfile 中：

```dockerfile
FROM node:20-alpine
RUN apk add --no-cache curl
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
```

### 3. 添加健康检查端点日志

在 `server.js` 中：

```javascript
app.get('/healthz', (req, res) => {
  console.log('[Health] Health check requested');
  res.json({ 
    ok: true, 
    uptime: process.uptime(),
    timestamp: new Date().toISOString()
  });
});
```

---

## 📞 获取帮助

如果问题仍未解决：

1. 运行诊断并保存输出：
   ```bash
   ./diagnose-service.sh message-service > diagnosis.log
   ```

2. 查看完整日志：
   ```bash
   ssh root@mx.go-lv.com "cd /root/hc-stack/infra && docker compose logs --tail=200 message-service" > service.log
   ```

3. 分享以上日志文件寻求帮助

---

**相关文档**：
- [SERVICES.md](SERVICES.md) - 服务管理速查
- [DEV_WORKFLOW.md](DEV_WORKFLOW.md) - 开发工作流
- [README.md](README.md) - 项目总览

