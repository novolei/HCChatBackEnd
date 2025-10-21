# 🚀 部署最佳实践

## 📋 核心原则

### ✅ 应该做的

1. **所有代码修改在本地完成**
   - 在 Mac 上编辑代码
   - 本地测试通过后提交
   - 推送到 GitHub
   - 在 VPS 上拉取部署

2. **使用自动化部署脚本**
   - 使用 `deploy.sh` 部署
   - 脚本会自动处理冲突

3. **保持 VPS 代码只读**
   - VPS 只用于运行服务
   - 不在 VPS 上编辑文件

---

### ❌ 不应该做的

1. **不要在 VPS 上直接修改代码**
   - ❌ `vim server.js`
   - ❌ `nano server.js`
   - ❌ 直接 `git commit`

2. **不要手动 git pull**
   - 使用部署脚本代替

---

## 🔄 推荐的开发流程

### 方案 1: 使用自动化部署脚本（推荐）✅

```bash
# 在 Mac 本地
cd /Users/ryanliu/DDCS/HChat/HCChatBackEnd

# 1. 编辑代码
vim chat-gateway/server.js

# 2. 测试（可选）
# docker compose up chat-gateway

# 3. 提交
git add .
git commit -m "修复: xxx"
git push origin main

# 4. 一键部署到 VPS
./deploy.sh chat-gateway
```

**deploy.sh 会自动：**
- ✅ SSH 到 VPS
- ✅ 拉取最新代码（自动处理冲突）
- ✅ 重启服务
- ✅ 显示日志

---

### 方案 2: 手动部署（备用）

如果部署脚本有问题，手动操作：

```bash
# 在本地推送后
ssh root@mx.go-lv.com

# 在 VPS 上
cd /root/hc-stack
git fetch origin
git reset --hard origin/main  # 强制同步到远程版本
docker compose restart chat-gateway
docker compose logs -f chat-gateway
```

---

## 🛡️ 配置 Git 自动合并策略

在 VPS 上执行一次，以后 pull 会自动处理：

```bash
# 在 VPS 上执行
cd /root/hc-stack

# 配置为使用 rebase（推荐）
git config pull.rebase true

# 或者配置为 fast-forward only（更安全）
git config pull.ff only
```

这样配置后，如果有冲突会自动报错而不是卡住。

---

## 📦 改进后的部署脚本

我们的 `deploy.sh` 已经处理了大部分问题，但可以进一步改进：

```bash
# 在 VPS 上强制同步（不会有冲突）
git fetch origin
git reset --hard origin/main
```

---

## 🔍 检测和预防

### 定期检查 VPS 状态

```bash
# 在 VPS 上
cd /root/hc-stack
git status

# 应该显示：
# On branch main
# Your branch is up to date with 'origin/main'.
# nothing to commit, working tree clean
```

如果显示有修改或未提交的文件，说明有人在 VPS 上改了代码！

---

### 使用只读部署（高级）

如果团队协作，可以考虑：

1. **CI/CD 自动部署**
   - GitHub Actions
   - GitLab CI
   - Jenkins

2. **容器化部署**
   - 构建 Docker 镜像
   - 推送到镜像仓库
   - VPS 只拉取镜像

3. **文件权限控制**
   ```bash
   # 让代码目录只读（极端情况）
   chmod -R 555 /root/hc-stack/chat-gateway
   ```

---

## 🚨 紧急情况处理

### 如果不小心在 VPS 上改了代码

**方案 1: 保存修改到本地**
```bash
# 在 VPS 上
cd /root/hc-stack
git diff > ~/my-changes.patch

# 然后重置
git reset --hard origin/main

# 在本地应用补丁
scp root@mx.go-lv.com:~/my-changes.patch .
git apply my-changes.patch
```

**方案 2: 直接丢弃（不重要的修改）**
```bash
cd /root/hc-stack
git reset --hard origin/main
```

---

## 📊 团队协作建议

### 开发分支策略

```
main (生产) ← 只从 dev 合并
  ↑
dev (开发) ← 日常开发
  ↑
feature/xxx ← 功能分支
```

### 部署流程

1. **开发环境**
   ```bash
   git checkout dev
   # 开发...
   git push origin dev
   ./deploy.sh chat-gateway --branch dev --env staging
   ```

2. **生产环境**
   ```bash
   git checkout main
   git merge dev
   git push origin main
   ./deploy.sh chat-gateway
   ```

---

## ✅ 检查清单

部署前确认：

- [ ] 本地代码已提交
- [ ] 已推送到 GitHub
- [ ] 使用 deploy.sh 部署
- [ ] 部署后检查日志
- [ ] 测试功能正常

---

## 🎯 总结

### 黄金法则

```
┌─────────────────────────────────────────┐
│  永远不要在 VPS 上直接修改代码！       │
│                                         │
│  开发 → 提交 → 推送 → 部署             │
│  (本地) (Git) (GitHub) (VPS)           │
└─────────────────────────────────────────┘
```

### 一句话记住

**"VPS 是运行环境，不是开发环境"** 🎯

---

遵循这些实践，就不会再遇到 Git 冲突问题了！✨

