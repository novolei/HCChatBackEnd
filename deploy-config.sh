#!/bin/bash
# HChat Backend 部署配置快速设置
# 运行此脚本配置您的部署环境

echo "🔧 HChat Backend 部署配置向导"
echo ""

# 获取当前配置
CURRENT_VPS_HOST="${VPS_HOST:-mx.go-lv.com}"
CURRENT_VPS_USER="${VPS_USER:-root}"
CURRENT_VPS_PATH="${VPS_PATH:-/root/hc-stack/HCChatBackEnd}"

echo "当前配置："
echo "  VPS 主机: $CURRENT_VPS_HOST"
echo "  SSH 用户: $CURRENT_VPS_USER"
echo "  VPS 路径: $CURRENT_VPS_PATH"
echo ""

read -p "是否修改配置？[y/N] " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    read -p "VPS 主机地址 [$CURRENT_VPS_HOST]: " VPS_HOST
    VPS_HOST=${VPS_HOST:-$CURRENT_VPS_HOST}
    
    read -p "SSH 用户名 [$CURRENT_VPS_USER]: " VPS_USER
    VPS_USER=${VPS_USER:-$CURRENT_VPS_USER}
    
    read -p "VPS 代码路径 [$CURRENT_VPS_PATH]: " VPS_PATH
    VPS_PATH=${VPS_PATH:-$CURRENT_VPS_PATH}
fi

# 检测 shell
SHELL_RC="$HOME/.zshrc"
if [[ "$SHELL" == *"bash"* ]]; then
    SHELL_RC="$HOME/.bashrc"
fi

echo ""
echo "📝 将以下配置添加到 $SHELL_RC："
echo ""
cat << EOF
# HChat Backend 部署配置
export VPS_HOST="$VPS_HOST"
export VPS_USER="$VPS_USER"
export VPS_PATH="$VPS_PATH"
EOF
echo ""

read -p "是否自动添加到 $SHELL_RC？[y/N] " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    # 备份
    cp "$SHELL_RC" "${SHELL_RC}.backup.$(date +%Y%m%d)"
    
    # 删除旧配置（如果存在）
    sed -i.tmp '/# HChat Backend 部署配置/,/^export VPS_PATH=/d' "$SHELL_RC"
    rm -f "${SHELL_RC}.tmp"
    
    # 添加新配置
    cat >> "$SHELL_RC" << EOF

# HChat Backend 部署配置
export VPS_HOST="$VPS_HOST"
export VPS_USER="$VPS_USER"
export VPS_PATH="$VPS_PATH"
EOF
    
    echo "✅ 配置已添加到 $SHELL_RC"
    echo ""
    echo "运行以下命令使配置生效："
    echo "  source $SHELL_RC"
else
    echo "请手动添加上述配置到 $SHELL_RC"
fi

echo ""
echo "🎉 配置完成！"
echo ""
echo "下一步："
echo "  1. source $SHELL_RC"
echo "  2. ssh-copy-id $VPS_USER@$VPS_HOST  # 配置免密登录"
echo "  3. ./deploy.sh chat-gateway \"test: 测试部署\""

