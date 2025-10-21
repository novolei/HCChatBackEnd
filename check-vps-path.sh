#!/bin/bash
# 检查 VPS 上的目录结构

echo "🔍 检查 VPS 目录结构..."
echo ""

VPS_HOST="${VPS_HOST:-mx.go-lv.com}"
VPS_USER="${VPS_USER:-root}"

echo "连接到: ${VPS_USER}@${VPS_HOST}"
echo ""

ssh "${VPS_USER}@${VPS_HOST}" << 'EOF'
echo "📁 当前目录结构:"
echo ""

# 检查可能的路径
if [ -d "/root/hc-stack" ]; then
    echo "✅ /root/hc-stack 存在"
    echo "   内容："
    ls -la /root/hc-stack/ | head -20
    echo ""
    
    # 检查是否是 Git 仓库
    if [ -d "/root/hc-stack/.git" ]; then
        echo "✅ /root/hc-stack 是 Git 仓库"
        cd /root/hc-stack
        echo "   远程仓库："
        git remote -v
        echo "   当前分支："
        git branch --show-current
    fi
    
    # 检查 infra 目录
    if [ -d "/root/hc-stack/infra" ]; then
        echo ""
        echo "✅ /root/hc-stack/infra 存在"
    fi
    
    # 检查 chat-gateway
    if [ -d "/root/hc-stack/chat-gateway" ]; then
        echo "✅ /root/hc-stack/chat-gateway 存在"
    fi
else
    echo "❌ /root/hc-stack 不存在"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ -d "/root/hc-stack/HCChatBackEnd" ]; then
    echo "⚠️  发现 /root/hc-stack/HCChatBackEnd"
    echo "   这可能是嵌套的目录结构"
fi

echo ""
echo "🐳 Docker Compose 状态:"
if [ -f "/root/hc-stack/infra/docker-compose.yml" ]; then
    cd /root/hc-stack/infra
    docker compose ps
elif [ -f "/root/hc-stack/HCChatBackEnd/infra/docker-compose.yml" ]; then
    cd /root/hc-stack/HCChatBackEnd/infra
    docker compose ps
fi
EOF

echo ""
echo "✅ 检查完成"
echo ""
echo "建议的配置："
echo "  VPS_PATH=/root/hc-stack"

