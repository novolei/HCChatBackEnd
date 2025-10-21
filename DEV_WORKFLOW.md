# HChat Backend 开发工作流

> 基于 GitHub + VPS 的远程开发指南

---

## 🚀 快速开始

### 一、首次配置

#### 1. 在 VPS 上克隆仓库（如果还没做）

```bash
ssh your-user@hc.go-lv.com

# 克隆代码
cd /root/hc-stack  # 或您的工作目录
git clone https://github.com/your-username/HCChatBackEnd.git
cd HCChatBackEnd

# 启动服务
cd infra
docker compose up -d
```

#### 2. 在本地 Mac 配置部署脚本

```bash
cd ~/DDCS/HChat/HCChatBackEnd

# 添加执行权限
chmod +x deploy.sh
chmod +x scripts/*.sh

# 配置 SSH（如果还没配置免密登录）
ssh-copy-id your-user@hc.go-lv.com

# 测试连接
ssh your-user@hc.go-lv.com "echo '✅ SSH 连接成功'"
```

---

## 📝 日常开发流程

### 方式一：使用部署脚本（推荐）

```bash
# 1. 在本地编辑代码
code chat-gateway/server.js

# 2. 一键部署
./deploy.sh chat-gateway "fix: 修复消息广播逻辑"

# 脚本会自动:
# - 提交代码到 GitHub
# - SSH 到 VPS
# - 拉取最新代码
# - 重启服务
# - 显示日志
```

### 方式二：手动流程

```bash
# === 本地 Mac ===
# 1. 编辑代码
vim chat-gateway/server.js

# 2. 提交到 GitHub
git add .
git commit -m "fix: 修复房间清理逻辑"
git push origin main

# === VPS ===
# 3. SSH 到 VPS 并拉取
ssh your-user@hc.go-lv.com
cd /root/hc-stack/HCChatBackEnd
git pull origin main

# 4. 重启服务
cd infra
docker compose restart chat-gateway

# 5. 查看日志
docker compose logs -f chat-gateway
```

### 方式三：VPS 端快捷脚本

```bash
# 在 VPS 上设置快捷命令
ssh your-user@hc.go-lv.com

# 添加到 ~/.bashrc
cat >> ~/.bashrc << 'EOF'
alias hc-update='cd /root/hc-stack/HCChatBackEnd && ./scripts/update-and-restart.sh'
alias hc-logs='cd /root/hc-stack/HCChatBackEnd/infra && docker compose logs -f'
alias hc-status='cd /root/hc-stack/HCChatBackEnd/infra && docker compose ps'
EOF

source ~/.bashrc

# 现在可以快速部署:
# 本地 push 后，在 VPS 执行:
hc-update chat-gateway
hc-logs chat-gateway
```

---

## 🛠️ 部署脚本详解

### deploy.sh 用法

```bash
# 基本用法
./deploy.sh <服务名> [commit消息]

# 部署单个服务
./deploy.sh chat-gateway "fix: 修复bug"
./deploy.sh message-service "feat: 新功能"

# 部署所有服务
./deploy.sh all "chore: 更新依赖"

# 只更新配置文件（不重启）
./deploy.sh config

# 查看帮助
./deploy.sh --help
```

### 环境变量配置

在 `~/.bashrc` 或 `~/.zshrc` 中添加:

```bash
# HChat Backend 部署配置
export VPS_HOST="hc.go-lv.com"
export VPS_USER="root"
export VPS_PATH="/root/hc-stack/HCChatBackEnd"
export GITHUB_BRANCH="main"
```

---

## 🔍 调试技巧

### 1. 查看实时日志

```bash
# 方式 A: 使用部署脚本
./deploy.sh chat-gateway "fix: xxx"
# 部署完成后会询问是否查看日志，输入 y

# 方式 B: 直接 SSH
ssh your-user@hc.go-lv.com
cd /root/hc-stack/HCChatBackEnd/infra
docker compose logs -f chat-gateway
```

### 2. 对比本地改动和 VPS 版本

```bash
# 查看本地未提交的改动
git diff

# 查看 VPS 当前版本
ssh your-user@hc.go-lv.com \
  "cd /root/hc-stack/HCChatBackEnd && git log -1 --oneline"

# 查看本地最新提交
git log -1 --oneline
```

### 3. 紧急回滚

```bash
# 如果部署后发现问题，立即回滚

# 方式 A: 回滚到上一个提交
git revert HEAD
git push origin main
./deploy.sh all "revert: 回滚上次部署"

# 方式 B: VPS 端直接回滚
ssh your-user@hc.go-lv.com << 'EOF'
  cd /root/hc-stack/HCChatBackEnd
  git reset --hard HEAD~1
  cd infra
  docker compose restart
EOF
```

### 4. 增强日志输出

在代码中添加详细日志：

```javascript
// chat-gateway/server.js

// 当前简单日志
console.log('message received');

// 改为详细日志
const timestamp = new Date().toISOString();
console.log(`[${timestamp}] 📥 收到消息:`, {
  type: msg.type,
  channel: msg.channel,
  nick: msg.nick,
  textLength: msg.text?.length
});
```

部署后查看效果：

```bash
./deploy.sh chat-gateway "debug: 添加详细日志"
# 选择 y 查看实时日志
```

---

## 📊 监控和维护

### 每日检查

```bash
# 快速健康检查脚本
ssh your-user@hc.go-lv.com << 'EOF'
  echo "🔍 服务状态:"
  cd /root/hc-stack/HCChatBackEnd/infra
  docker compose ps
  
  echo ""
  echo "💾 磁盘使用:"
  df -h | grep -E "Filesystem|/$"
  
  echo ""
  echo "🐳 Docker 占用:"
  docker system df
  
  echo ""
  echo "📊 最近错误:"
  docker compose logs --tail=100 | grep -i "error\|exception" | tail -10
EOF
```

### 清理 Docker 资源

```bash
ssh your-user@hc.go-lv.com

# 清理未使用的镜像和容器
docker system prune -a --volumes

# 或在 HCChatBackEnd/infra 目录
docker compose down
docker compose up -d
```

---

## 🔄 分支管理（进阶）

### 功能开发分支

```bash
# 本地创建功能分支
git checkout -b feature/new-broadcast-logic

# 编辑代码
vim chat-gateway/server.js

# 提交到功能分支
git add .
git commit -m "feat: 新的广播逻辑"
git push origin feature/new-broadcast-logic

# 在 VPS 上测试功能分支
ssh your-user@hc.go-lv.com << 'EOF'
  cd /root/hc-stack/HCChatBackEnd
  git fetch origin
  git checkout feature/new-broadcast-logic
  cd infra
  docker compose restart chat-gateway
EOF

# 测试通过后，合并到 main
git checkout main
git merge feature/new-broadcast-logic
git push origin main

# VPS 切回 main 并部署
./deploy.sh chat-gateway "feat: 新的广播逻辑"
```

---

## 🚨 常见问题

### 问题 1: 部署脚本权限错误

```bash
# 解决方法
chmod +x deploy.sh
chmod +x scripts/*.sh
```

### 问题 2: SSH 连接超时

```bash
# 检查 SSH 配置
cat ~/.ssh/config

# 添加 KeepAlive
cat >> ~/.ssh/config << 'EOF'
Host hc.go-lv.com
    ServerAliveInterval 60
    ServerAliveCountMax 3
EOF
```

### 问题 3: Git pull 冲突

```bash
# 在 VPS 上强制覆盖本地改动
ssh your-user@hc.go-lv.com << 'EOF'
  cd /root/hc-stack/HCChatBackEnd
  git fetch origin
  git reset --hard origin/main
EOF
```

### 问题 4: 服务启动失败

```bash
# 查看详细错误
ssh your-user@hc.go-lv.com
cd /root/hc-stack/HCChatBackEnd/infra
docker compose ps
docker compose logs chat-gateway

# 检查配置
docker compose config

# 重新构建并启动
docker compose up -d --build chat-gateway
```

---

## 💡 最佳实践

### 1. Commit 消息规范

遵循 [Conventional Commits](https://www.conventionalcommits.org/)：

```
feat: 新功能
fix: Bug 修复
docs: 文档更新
refactor: 重构
perf: 性能优化
test: 测试相关
chore: 构建/工具链

示例:
feat(chat): 添加消息去重逻辑
fix(minio): 修复预签名 URL 过期问题
docs: 更新部署文档
```

### 2. 小步提交

```bash
# ❌ 不好的做法
# 一天改了 10 个文件，一次性提交

# ✅ 好的做法
# 每完成一个小功能就提交
git add chat-gateway/server.js
git commit -m "feat: 添加房间人数统计"

git add message-service/server.js
git commit -m "feat: 添加健康检查端点"
```

### 3. 测试后再部署

```bash
# 1. 本地修改代码
# 2. iOS App 连接 VPS 测试（通过 DebugPanel）
# 3. 确认功能正常
# 4. 提交并部署
./deploy.sh chat-gateway "feat: xxx"
```

### 4. 保留关键日志

```bash
# 在部署前备份重要日志
ssh your-user@hc.go-lv.com << 'EOF'
  cd /root/hc-stack/HCChatBackEnd/infra
  docker compose logs > /tmp/backend-$(date +%Y%m%d-%H%M%S).log
EOF
```

---

## 🎯 工作流总结

**每日开发循环：**

```
1. 📝 本地编辑代码
2. 💾 提交到 GitHub
3. 🚀 部署到 VPS (./deploy.sh)
4. 📱 iOS App 测试
5. 📊 查看日志，验证功能
6. 🔄 循环迭代
```

**关键命令速记：**

```bash
# 部署单个服务
./deploy.sh chat-gateway "fix: xxx"

# 部署所有服务  
./deploy.sh all "chore: update"

# VPS 查看日志
ssh hc "cd /root/hc-stack/HCChatBackEnd/infra && docker compose logs -f chat-gateway"

# VPS 重启服务
ssh hc "cd /root/hc-stack/HCChatBackEnd/infra && docker compose restart chat-gateway"
```

---

**开发愉快！🎉**

