# 如何添加新服务

> 在 HChat Backend 中添加新的可部署服务

---

## 📝 快速指南

### 步骤 1：在项目中创建服务目录

```bash
cd /Users/ryanliu/DDCS/HChat/HCChatBackEnd

# 创建新服务目录
mkdir new-service

# 创建必要文件
cd new-service
touch server.js
touch package.json
touch Dockerfile
```

### 步骤 2：更新 deploy.sh

编辑 `deploy.sh` 文件，在 **服务定义区域** 添加新服务：

```bash
# ============ 服务定义 ============
# 格式: "服务名:描述:健康检查端点"
declare -A SERVICES=(
    ["chat-gateway"]="WebSocket 聊天网关:/chat-ws"
    ["message-service"]="REST API 服务:/api/healthz"
    ["new-service"]="新服务描述:/health"        # ← 添加这行
    ["minio"]="S3 对象存储:/minio/health/ready"
    ["livekit"]="WebRTC 音视频服务:"
    ["coturn"]="TURN/STUN 服务:"
)

# 可部署的服务（只包含我们的代码服务）
DEPLOYABLE_SERVICES=("chat-gateway" "message-service" "new-service")  # ← 添加到这里
```

### 步骤 3：更新 docker-compose.yml

编辑 `infra/docker-compose.yml`，添加新服务：

```yaml
services:
  # ... 现有服务 ...
  
  new-service:
    build: ../new-service
    restart: unless-stopped
    ports:
      - "127.0.0.1:10082:3000"
    environment:
      - NODE_ENV=production
    # 根据需要添加其他配置
```

### 步骤 4：测试部署

```bash
# 提交代码
git add .
git commit -m "feat: 添加 new-service"
git push origin main

# 部署到 VPS
./deploy.sh new-service "feat: 初始部署"
```

---

## 📊 完整示例：添加 auth-service

### 1. 创建服务代码

```bash
# 创建目录
mkdir auth-service

# 创建 package.json
cat > auth-service/package.json << 'EOF'
{
  "name": "auth-service",
  "version": "1.0.0",
  "private": true,
  "scripts": { "start": "node server.js" },
  "dependencies": {
    "express": "^4.19.2",
    "jsonwebtoken": "^9.0.2"
  }
}
EOF

# 创建 server.js
cat > auth-service/server.js << 'EOF'
const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

app.get('/health', (req, res) => {
  res.json({ ok: true, service: 'auth-service' });
});

app.post('/api/login', (req, res) => {
  // 认证逻辑
  res.json({ token: 'sample-token' });
});

app.listen(PORT, () => {
  console.log(`auth-service listening on :${PORT}`);
});
EOF

# 创建 Dockerfile
cat > auth-service/Dockerfile << 'EOF'
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
EOF
```

### 2. 更新 deploy.sh

```bash
# 编辑 deploy.sh
vim deploy.sh

# 找到 SERVICES 定义，添加：
["auth-service"]="用户认证服务:/health"

# 找到 DEPLOYABLE_SERVICES，添加：
DEPLOYABLE_SERVICES=("chat-gateway" "message-service" "auth-service")
```

### 3. 更新 docker-compose.yml

```yaml
# 编辑 infra/docker-compose.yml
vim infra/docker-compose.yml

# 添加服务定义：
services:
  # ... 现有服务 ...
  
  auth-service:
    build: ../auth-service
    restart: unless-stopped
    ports:
      - "127.0.0.1:10082:3000"
    environment:
      - NODE_ENV=production
      - JWT_SECRET=${JWT_SECRET}
```

### 4. 更新 Nginx 配置（如果需要对外暴露）

```nginx
# infra/fastpanel/nginx_snippets/hc.go-lv.com.conf

location ^~ /auth/ {
    proxy_pass http://127.0.0.1:10082/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
}
```

### 5. 部署

```bash
# 提交所有改动
git add .
git commit -m "feat: 添加 auth-service 认证服务"
git push origin main

# 部署
./deploy.sh auth-service "feat: 初始部署认证服务"

# 或一次性部署所有服务
./deploy.sh all "feat: 添加认证服务"
```

---

## 🔧 服务配置选项说明

### SERVICES 关联数组

```bash
["服务名"]="服务描述:健康检查路径"
```

**字段说明：**
- **服务名**: Docker Compose 中的服务名（必须匹配）
- **服务描述**: 在帮助信息中显示的说明
- **健康检查路径**: HTTP 健康检查端点（可选）

**示例：**
```bash
["chat-gateway"]="WebSocket 聊天网关:/chat-ws"
["message-service"]="REST API 服务:/api/healthz"
["auth-service"]="用户认证服务:/health"
```

### DEPLOYABLE_SERVICES 数组

只包含**我们自己开发的服务**（不包括 minio、livekit 等第三方服务）

```bash
DEPLOYABLE_SERVICES=("chat-gateway" "message-service" "auth-service")
```

---

## 🎯 常见场景

### 场景 1：添加纯 Node.js 服务

```bash
# 1. 创建服务
mkdir my-service && cd my-service
npm init -y
npm install express

# 2. 更新 deploy.sh
# 添加到 SERVICES 和 DEPLOYABLE_SERVICES

# 3. 更新 docker-compose.yml
# 添加服务定义

# 4. 部署
./deploy.sh my-service "feat: 添加新服务"
```

### 场景 2：添加 Python 服务

```bash
# 1. 创建服务
mkdir python-service && cd python-service

# 创建 requirements.txt
cat > requirements.txt << 'EOF'
flask==3.0.0
EOF

# 创建 app.py
cat > app.py << 'EOF'
from flask import Flask
app = Flask(__name__)

@app.route('/health')
def health():
    return {'ok': True}

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=3000)
EOF

# 创建 Dockerfile
cat > Dockerfile << 'EOF'
FROM python:3.11-alpine
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
EXPOSE 3000
CMD ["python", "app.py"]
EOF

# 2-4. 同上
```

### 场景 3：添加需要数据库的服务

```yaml
# docker-compose.yml
services:
  my-service:
    build: ../my-service
    depends_on:
      - postgres
    environment:
      - DATABASE_URL=postgresql://user:pass@postgres:5432/mydb
  
  postgres:
    image: postgres:16-alpine
    environment:
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=pass
      - POSTGRES_DB=mydb
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data: {}
```

---

## ✅ 检查清单

部署新服务前，请确认：

- [ ] 服务代码已创建并测试
- [ ] `deploy.sh` 中添加了服务定义
- [ ] `deploy.sh` 的 `DEPLOYABLE_SERVICES` 包含新服务
- [ ] `infra/docker-compose.yml` 添加了服务配置
- [ ] 环境变量已配置（如需要）
- [ ] 端口没有冲突
- [ ] 健康检查端点可访问
- [ ] Nginx 配置已更新（如需要对外暴露）
- [ ] 代码已提交到 GitHub

---

## 🚀 部署命令

```bash
# 部署单个服务
./deploy.sh new-service "feat: 添加新服务"

# 部署所有服务（包括新服务）
./deploy.sh all "feat: 添加新服务并更新所有服务"

# 只更新代码不重启（测试配置）
./deploy.sh config
```

---

## 📚 相关文档

- **[deploy.sh](deploy.sh)** - 部署脚本源码
- **[DEV_WORKFLOW.md](DEV_WORKFLOW.md)** - 开发工作流
- **[README.md](README.md)** - 项目总览

---

**添加新服务就是这么简单！** 🎉

