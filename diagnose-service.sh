#!/bin/bash
# 诊断服务启动问题

set -e

VPS_HOST="${VPS_HOST:-mx.go-lv.com}"
VPS_USER="${VPS_USER:-root}"
VPS_PATH="${VPS_PATH:-/root/hc-stack}"

SERVICE="${1:-message-service}"

echo "🔍 诊断服务: $SERVICE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

ssh "${VPS_USER}@${VPS_HOST}" << EOF
    set -e
    
    cd ${VPS_PATH}/infra
    
    echo "📊 1. 容器状态"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    docker compose ps $SERVICE
    echo ""
    
    echo "📝 2. 最近 50 行日志"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    docker compose logs --tail=50 $SERVICE
    echo ""
    
    echo "🔍 3. 容器详细信息"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    CONTAINER_ID=\$(docker compose ps -q $SERVICE)
    if [ -n "\$CONTAINER_ID" ]; then
        echo "容器 ID: \$CONTAINER_ID"
        echo ""
        echo "重启次数:"
        docker inspect \$CONTAINER_ID --format='{{.RestartCount}}'
        echo ""
        echo "健康状态:"
        docker inspect \$CONTAINER_ID --format='{{.State.Health.Status}}' 2>/dev/null || echo "未配置健康检查"
        echo ""
        echo "退出代码:"
        docker inspect \$CONTAINER_ID --format='{{.State.ExitCode}}'
    fi
    echo ""
    
    echo "🌐 4. 端口检查"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "检查端口 10092 (内部容器端口 3000):"
    netstat -tlnp | grep 10092 || echo "端口 10092 未监听"
    echo ""
    echo "检查端口 10081 (message-service API):"
    netstat -tlnp | grep 10081 || echo "端口 10081 未监听"
    echo ""
    
    echo "🔧 5. 服务配置"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    docker compose config | grep -A 20 "message-service:"
    echo ""
    
    echo "🧪 6. 健康检查测试"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "测试 healthz 端点:"
    curl -v http://127.0.0.1:10092/healthz 2>&1 | head -20 || echo "❌ 无法连接到 healthz"
    echo ""
    
    echo "✅ 诊断完成"
EOF

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "💡 建议："
echo "  1. 检查健康检查配置是否正确"
echo "  2. 确认端口映射是否冲突"
echo "  3. 查看上面的日志寻找错误"
echo "  4. 尝试重新构建: docker compose up -d --build message-service"

