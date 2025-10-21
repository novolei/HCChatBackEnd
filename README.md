# HChat Backend

> WebSocket 聊天网关 + REST API + MinIO 文件存储 + LiveKit 音视频

基于 Docker Compose 的自托管后端服务，支持端到端加密聊天。

---

## 🌐 生产环境

**域名映射：**
- `hc.go-lv.com` → Chat Gateway (WS) + Message Service API
- `livekit.hc.go-lv.com` → LiveKit 信令服务器
- `s3.hc.go-lv.com` → MinIO S3 API
- `mc.s3.hc.go-lv.com` → MinIO 控制台

**健康检查：**
```bash
curl -I http://127.0.0.1:10081/api/health
curl -I http://127.0.0.1:10090/minio/health/ready
```

---

## 🚀 快速开始

### 首次部署（VPS 上）

```bash
# 1. 克隆代码
git clone https://github.com/your-username/HCChatBackEnd.git
cd HCChatBackEnd

# 2. 配置环境变量
cd infra
cp .env.example .env
vim .env  # 填写 MINIO_*, LIVEKIT_* 等

# 3. 编辑 LiveKit 配置
vim livekit.yaml  # 替换 API 密钥

# 4. 启动所有服务
docker compose up -d

# 5. 检查服务状态
docker compose ps
docker compose logs
```

### 本地开发环境

```bash
# 1. 配置 SSH 免密登录
ssh-copy-id your-user@hc.go-lv.com

# 2. 设置部署工具
chmod +x deploy.sh
chmod +x scripts/*.sh

# 3. 一键部署（自动确认，推荐）
./deploy.sh chat-gateway -y

# 或手动确认模式
./deploy.sh chat-gateway
```

📖 **详细教程：** [QUICKSTART.md](./QUICKSTART.md)

---

## 📚 文档

- **[QUICKSTART.md](./QUICKSTART.md)** - 5 分钟快速设置指南
- **[DEV_WORKFLOW.md](./DEV_WORKFLOW.md)** - 完整开发工作流
- **[SERVICES.md](./SERVICES.md)** - 服务管理速查表
- **[ADD_SERVICE.md](./ADD_SERVICE.md)** - 添加新服务指南
- **[DEPLOY_AUTO_CONFIRM.md](./DEPLOY_AUTO_CONFIRM.md)** - 自动确认部署功能 🆕
- **[../Product.md](../Product.md)** - 完整架构和 API 文档
- **[../DEBUGGING.md](../DEBUGGING.md)** - iOS 客户端调试指南

---

## 🏗️ 服务架构

| 服务 | 端口 | 功能 |
|------|------|------|
| **chat-gateway** | 10080 | WebSocket 消息路由（零解密） |
| **message-service** | 10081 | REST API（预签名 URL + LiveKit token） |
| **minio** | 10090/10091 | S3 存储（加密文件） |
| **livekit** | 17880, 51000-52000 | WebRTC 音视频（帧级 E2EE） |
| **coturn** | 14788, 53100-53200 | TURN/STUN 服务 |

---

## 🛠️ 服务管理

### 使用服务管理工具（推荐）

```bash
# 查看所有服务状态
./service-manager.sh list

# 查看实时日志
./service-manager.sh logs chat-gateway
./service-manager.sh logs message-service

# 测试服务健康
./service-manager.sh test

# 创建新服务
./service-manager.sh new my-service
```

### 手动操作

```bash
# 查看日志
docker compose logs -f chat-gateway
docker compose logs --tail=100

# 重启服务
docker compose restart chat-gateway
docker compose restart  # 所有服务

# 重新构建
docker compose up -d --build chat-gateway

# 查看状态
docker compose ps
docker stats
```

---

## 🔧 开发部署

### 使用部署脚本（推荐）

```bash
# 在本地 Mac 编辑代码后

# 部署到 VPS
./deploy.sh chat-gateway "fix: 修复消息广播"

# 脚本自动完成：
# 1. Git commit + push
# 2. SSH 到 VPS
# 3. Git pull
# 4. 重启服务
# 5. 显示日志
```

### 手动部署

```bash
# 本地提交
git add .
git commit -m "fix: xxx"
git push origin main

# VPS 拉取
ssh your-user@hc.go-lv.com
cd /root/hc-stack/HCChatBackEnd
git pull origin main
cd infra
docker compose restart chat-gateway
```

---

## 🔐 安全配置

### 防火墙规则

```bash
# 开放必要端口
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 14788/tcp
sudo ufw allow 14788/udp
sudo ufw allow 51000:52000/udp
sudo ufw allow 53100:53200/tcp
sudo ufw allow 53100:53200/udp
sudo ufw enable
```

### Nginx 配置

在 FASTPANEL 或 Nginx 中为四个域名配置 SSL：

```bash
# 配置文件位置
infra/fastpanel/nginx_snippets/hc.go-lv.com.conf
infra/fastpanel/nginx_snippets/livekit.hc.go-lv.com.conf
infra/fastpanel/nginx_snippets/s3.hc.go-lv.com.conf
infra/fastpanel/nginx_snippets/mc.s3.hc.go-lv.com.conf
```

---

## 📊 监控维护

### 健康检查

```bash
# API 服务
curl https://hc.go-lv.com/api/health

# MinIO
curl http://127.0.0.1:10090/minio/health/ready

# 服务状态
docker compose ps
```

### 清理资源

```bash
# 清理未使用的 Docker 资源
docker system prune -a --volumes

# 查看磁盘占用
docker system df
df -h
```

---

## 🆘 故障排查

### 服务无法启动

```bash
# 查看详细日志
docker compose logs <service-name>

# 检查配置
docker compose config

# 重新构建
docker compose up -d --build
```

### Git 同步问题

```bash
# 强制同步到远程最新版本
git fetch origin
git reset --hard origin/main
```

### 端口占用

```bash
# 检查端口占用
sudo netstat -tlnp | grep 10080

# 停止冲突服务
docker compose down
```

---

## 📞 联系支持

遇到问题？查看：
- [DEV_WORKFLOW.md](./DEV_WORKFLOW.md) - 开发流程
- [../Product.md](../Product.md) - 完整架构文档
- [../DEBUGGING.md](../DEBUGGING.md) - 调试指南

---

**HChat Backend - 自托管的加密聊天服务** 🔐
