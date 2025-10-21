# 🚀 5 分钟快速设置

> 从 GitHub 代码到一键部署

---

## ✅ 检查清单

在开始之前，确保：

- [ ] 代码已推送到 GitHub
- [ ] 能够 SSH 连接到 VPS
- [ ] VPS 上已运行 Docker Compose

---

## 1️⃣ 配置 SSH 免密登录（2 分钟）

```bash
# 在本地 Mac 执行

# 生成 SSH 密钥（如果还没有）
if [ ! -f ~/.ssh/id_rsa ]; then
    ssh-keygen -t rsa -b 4096 -C "your-email@example.com"
fi

# 复制公钥到 VPS
ssh-copy-id your-user@hc.go-lv.com

# 测试连接
ssh your-user@hc.go-lv.com "echo '✅ SSH 免密登录成功！'"
```

**配置 SSH 别名**（可选但推荐）：

```bash
# 添加到 ~/.ssh/config
cat >> ~/.ssh/config << 'EOF'
Host hc
    HostName hc.go-lv.com
    User your-user
    ServerAliveInterval 60
EOF

# 现在可以用简短命令连接
ssh hc
```

---

## 2️⃣ 在 VPS 上设置代码仓库（1 分钟）

```bash
# SSH 到 VPS
ssh hc  # 或 ssh your-user@hc.go-lv.com

# 如果已有旧代码，先备份
cd /root/hc-stack
mv HCChatBackEnd HCChatBackEnd.backup  # 可选

# 克隆 GitHub 仓库
git clone https://github.com/your-username/HCChatBackEnd.git
cd HCChatBackEnd

# 启动服务（如果还没启动）
cd infra
docker compose up -d

# 检查服务状态
docker compose ps
```

---

## 3️⃣ 在本地配置部署工具（1 分钟）

```bash
# 在本地 Mac 的 HCChatBackEnd 目录

# 添加执行权限
chmod +x deploy.sh
chmod +x scripts/*.sh

# 配置环境变量（可选）
cat >> ~/.zshrc << 'EOF'
# HChat Backend 部署配置
export VPS_HOST="hc.go-lv.com"
export VPS_USER="your-user"  # 替换为实际用户名
export VPS_PATH="/root/hc-stack/HCChatBackEnd"
EOF

source ~/.zshrc

# 测试部署脚本
./deploy.sh --help
```

---

## 4️⃣ 第一次部署测试（1 分钟）

```bash
# 修改一个简单的东西测试
echo "// Test deployment" >> chat-gateway/server.js

# 执行部署
./deploy.sh chat-gateway "test: 测试部署流程"

# 如果成功，你会看到：
# ✅ 代码已推送到 GitHub
# ✅ VPS 部署成功
# 🎉 部署成功！

# 撤销测试改动
git reset --hard HEAD~1
git push --force origin main
```

---

## 🎉 完成！

现在您可以：

### 日常开发流程

```bash
# 1. 编辑代码
code chat-gateway/server.js

# 2. 一键部署
./deploy.sh chat-gateway "fix: 修复消息广播"

# 3. 查看日志（在提示时输入 y）
```

### 常用命令

```bash
# 部署服务
./deploy.sh chat-gateway "commit message"
./deploy.sh message-service "commit message"
./deploy.sh all "update all"

# 查看 VPS 日志
ssh hc "cd /root/hc-stack/HCChatBackEnd/infra && docker compose logs -f chat-gateway"

# 查看服务状态
ssh hc "cd /root/hc-stack/HCChatBackEnd/infra && docker compose ps"

# 重启服务
ssh hc "cd /root/hc-stack/HCChatBackEnd/infra && docker compose restart chat-gateway"
```

---

## 📚 下一步

- 阅读 [DEV_WORKFLOW.md](./DEV_WORKFLOW.md) 了解完整工作流
- 查看 iOS 客户端的 [DEBUGGING.md](../DEBUGGING.md) 了解调试技巧
- 阅读 [Product.md](../Product.md) 了解完整架构

---

## 🆘 遇到问题？

### SSH 连接失败
```bash
# 检查连接
ping hc.go-lv.com
ssh -v your-user@hc.go-lv.com  # 详细调试信息
```

### Git 推送失败
```bash
# 检查 GitHub 认证
git remote -v
git push origin main -v  # 详细信息
```

### 部署脚本权限错误
```bash
chmod +x deploy.sh
chmod +x scripts/*.sh
```

### VPS 服务启动失败
```bash
ssh hc
cd /root/hc-stack/HCChatBackEnd/infra
docker compose logs
docker compose ps
```

---

**祝开发顺利！** 🎊

