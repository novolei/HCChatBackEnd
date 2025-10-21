#!/bin/bash
# ===== VPS Git 配置脚本（一次性执行）=====
# 配置 VPS 上的 Git，避免以后出现冲突

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}═════════════════════════════════════════${NC}"
echo -e "${BLUE}  VPS Git 配置工具${NC}"
echo -e "${BLUE}═════════════════════════════════════════${NC}"
echo ""

# 加载配置
if [ -f "$(dirname "$0")/deploy-config.env" ]; then
    source "$(dirname "$0")/deploy-config.env"
else
    echo -e "${RED}❌ 错误: 未找到 deploy-config.env${NC}"
    echo -e "${YELLOW}💡 请先运行: ./deploy-config.sh${NC}"
    exit 1
fi

echo -e "${YELLOW}📋 将在 VPS 上配置 Git...${NC}"
echo -e "   VPS: ${GREEN}${VPS_USER}@${VPS_HOST}${NC}"
echo -e "   路径: ${GREEN}${VPS_PATH}${NC}"
echo ""

read -p "$(echo -e ${GREEN}是否继续？[Y/n]: ${NC})" -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ -n $REPLY ]]; then
    echo -e "${YELLOW}⏸️  已取消${NC}"
    exit 0
fi

echo -e "${BLUE}🔧 配置中...${NC}"

ssh "${VPS_USER}@${VPS_HOST}" << 'EOF'
    set -e
    
    cd /root/hc-stack
    
    echo ""
    echo "1️⃣ 配置 Git pull 策略（fast-forward only）..."
    git config pull.ff only
    
    echo "2️⃣ 配置自动清理..."
    git config --global gc.auto 0
    
    echo "3️⃣ 检查当前状态..."
    if [[ -n $(git status -s) ]]; then
        echo "⚠️  检测到本地修改，保存到 stash..."
        git stash save "配置前备份 - $(date +'%Y-%m-%d %H:%M:%S')"
    fi
    
    echo "4️⃣ 同步到远程最新版本..."
    git fetch origin
    git reset --hard origin/main
    
    echo ""
    echo "✅ Git 配置完成！"
    echo ""
    echo "📊 当前配置："
    git config --get pull.ff
    echo ""
    echo "📊 当前状态："
    git status
EOF

echo ""
echo -e "${GREEN}✅ VPS Git 配置完成！${NC}"
echo ""
echo -e "${BLUE}═════════════════════════════════════════${NC}"
echo -e "${YELLOW}💡 现在可以安全使用 ./deploy.sh 部署了${NC}"
echo -e "${BLUE}═════════════════════════════════════════${NC}"

