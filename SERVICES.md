# HChat Backend 服务管理速查

> 快速参考：管理和部署所有后端服务

---

## 🎯 现有服务

### 可部署服务（我们的代码）

| 服务名 | 描述 | 端口 | 状态 |
|--------|------|------|------|
| **chat-gateway** | WebSocket 聊天网关 | 10080 | ✅ 运行中 |
| **message-service** | REST API 服务 | 10081 | ✅ 运行中 |

### 第三方服务

| 服务名 | 描述 | 端口 | 用途 |
|--------|------|------|------|
| **minio** | S3 对象存储 | 10090/10091 | 文件存储 |
| **livekit** | WebRTC 音视频服务 | 17880, 51000-52000 | 实时音视频 |
| **coturn** | TURN/STUN 服务 | 14788, 53100-53200 | NAT 穿透 |

---

## 🚀 快速命令

### 部署服务

```bash
# 部署单个服务
./deploy.sh chat-gateway "fix: 修复bug"
./deploy.sh message-service "feat: 新功能"

# 部署所有服务
./deploy.sh all "chore: 更新所有服务"

# 只更新代码（不重启）
./deploy.sh config
```

### 查看服务状态

```bash
# 列出所有服务
./service-manager.sh list

# 测试健康状态
./service-manager.sh test

# 查看实时日志
./service-manager.sh logs chat-gateway
./service-manager.sh logs message-service
```

### 创建新服务

```bash
# 使用模板创建
./service-manager.sh new auth-service

# 手动添加到 deploy.sh
vim deploy.sh
# 在 DEPLOYABLE_SERVICES 数组中添加:
# "auth-service:用户认证服务"
```

---

## 📝 服务详细信息

### chat-gateway

**功能**: WebSocket 消息路由
- 端口: 10080
- 协议: WebSocket (/chat-ws)
- 部署: `./deploy.sh chat-gateway "message"`
- 日志: `./service-manager.sh logs chat-gateway`
- 代码: `chat-gateway/server.js`

**关键特性**:
- 房间(channel)管理
- 消息广播
- 心跳保活
- 零解密（只转发密文）

**健康检查**:
```bash
curl http://127.0.0.1:10080/chat-ws
# 应返回 WebSocket 升级响应
```

---

### message-service

**功能**: REST API 服务
- 端口: 10081 (内部 10092)
- 协议: HTTP/HTTPS
- 部署: `./deploy.sh message-service "message"`
- 日志: `./service-manager.sh logs message-service`
- 代码: `message-service/server.js`

**API 端点**:
- `GET /healthz` - 健康检查
- `POST /api/attachments/presign` - 获取 MinIO 预签名 URL
- `POST /api/rtc/token` - 生成 LiveKit token

**健康检查**:
```bash
curl http://127.0.0.1:10081/healthz
# 应返回: {"ok":true}
```

---

## 🔧 添加新服务

### 方法 1：使用模板（推荐）

```bash
# 1. 创建服务模板
./service-manager.sh new my-service

# 2. 编辑代码
cd my-service
vim server.js

# 3. 更新 deploy.sh
vim deploy.sh
# 在 DEPLOYABLE_SERVICES 添加:
# "my-service:我的服务描述"

# 4. 更新 docker-compose.yml
vim infra/docker-compose.yml
# 添加服务定义

# 5. 部署
./deploy.sh my-service "feat: 添加新服务"
```

### 方法 2：手动创建

详见 [ADD_SERVICE.md](ADD_SERVICE.md)

---

## 📊 监控和维护

### 日常检查

```bash
# 查看所有服务状态
./service-manager.sh list

# 测试服务健康
./service-manager.sh test

# 查看资源使用
ssh root@mx.go-lv.com "cd /root/hc-stack/infra && docker stats --no-stream"
```

### 常用操作

```bash
# 重启服务
ssh root@mx.go-lv.com "cd /root/hc-stack/infra && docker compose restart chat-gateway"

# 查看日志
ssh root@mx.go-lv.com "cd /root/hc-stack/infra && docker compose logs -f chat-gateway"

# 查看服务配置
ssh root@mx.go-lv.com "cd /root/hc-stack/infra && docker compose config"
```

---

## 🆘 故障排查

### 服务启动失败

```bash
# 1. 查看日志
./service-manager.sh logs <service-name>

# 2. 检查配置
ssh root@mx.go-lv.com
cd /root/hc-stack/infra
docker compose config

# 3. 重新构建
docker compose up -d --build <service-name>
```

### 端口冲突

```bash
# 检查端口占用
ssh root@mx.go-lv.com "netstat -tlnp | grep 10080"

# 修改 docker-compose.yml 中的端口映射
```

### Git 同步失败

```bash
# VPS 强制同步
ssh root@mx.go-lv.com
cd /root/hc-stack
git fetch origin
git reset --hard origin/main
```

---

## 📚 相关文档

- **[deploy.sh](deploy.sh)** - 自动化部署脚本
- **[service-manager.sh](service-manager.sh)** - 服务管理工具
- **[ADD_SERVICE.md](ADD_SERVICE.md)** - 添加新服务指南
- **[DEV_WORKFLOW.md](DEV_WORKFLOW.md)** - 开发工作流
- **[README.md](README.md)** - 项目总览

---

## 🎯 快速参考卡片

```bash
# === 部署 ===
./deploy.sh chat-gateway "fix: xxx"        # 部署单个服务
./deploy.sh all "update"                   # 部署所有服务

# === 管理 ===
./service-manager.sh list                  # 查看状态
./service-manager.sh logs chat-gateway     # 查看日志
./service-manager.sh test                  # 健康检查
./service-manager.sh new my-service        # 创建服务

# === VPS 操作 ===
ssh root@mx.go-lv.com                      # SSH 连接
cd /root/hc-stack/infra                    # 进入目录
docker compose ps                          # 查看服务
docker compose restart <service>           # 重启服务
docker compose logs -f <service>           # 实时日志
```

---

**快速、简单、高效！** 🚀

