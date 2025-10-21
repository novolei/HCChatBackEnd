#!/bin/bash
# 修复 message-service 启动问题

set -e

VPS_HOST="${VPS_HOST:-mx.go-lv.com}"
VPS_USER="${VPS_USER:-root}"
VPS_PATH="${VPS_PATH:-/root/hc-stack}"

echo "🔧 修复 message-service"
echo ""

echo "常见问题及解决方案："
echo ""
echo "1️⃣ 健康检查失败 - wget 命令不存在"
echo "   解决：修改 docker-compose.yml 使用 curl"
echo ""
echo "2️⃣ 端口映射错误"
echo "   解决：确认端口 10092 映射到容器 3000"
echo ""
echo "3️⃣ 依赖服务未就绪"
echo "   解决：等待 minio/livekit 启动完成"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

read -p "选择修复方案 [1=重新构建, 2=修复健康检查, 3=查看日志, 4=全部]: " choice

ssh "${VPS_USER}@${VPS_HOST}" << EOF
    set -e
    cd ${VPS_PATH}/infra
    
    case "$choice" in
        1)
            echo "🔨 重新构建 message-service..."
            docker compose stop message-service
            docker compose rm -f message-service
            docker compose up -d --build message-service
            echo ""
            echo "✅ 重新构建完成"
            echo ""
            echo "📊 查看启动日志:"
            sleep 5
            docker compose logs --tail=30 message-service
            ;;
        2)
            echo "🔧 检查健康检查配置..."
            docker compose config | grep -A 8 "message-service:" | grep -A 3 "healthcheck:"
            echo ""
            echo "💡 如果使用 wget，确保 alpine 镜像有安装"
            echo "建议改为 curl 或直接 node 脚本"
            ;;
        3)
            echo "📝 查看详细日志..."
            docker compose logs --tail=100 message-service
            ;;
        4)
            echo "🔄 执行完整修复流程..."
            
            # 停止服务
            echo "1. 停止 message-service..."
            docker compose stop message-service
            
            # 删除容器
            echo "2. 删除旧容器..."
            docker compose rm -f message-service
            
            # 清理卷（可选）
            echo "3. 清理 node_modules..."
            rm -rf ../message-service/node_modules
            
            # 重新构建
            echo "4. 重新构建..."
            docker compose up -d --build message-service
            
            # 等待启动
            echo "5. 等待服务启动..."
            sleep 10
            
            # 查看日志
            echo "6. 查看启动日志:"
            docker compose logs --tail=50 message-service
            
            # 测试健康检查
            echo ""
            echo "7. 测试健康检查:"
            sleep 5
            curl -f http://127.0.0.1:10092/healthz && echo "✅ 健康检查成功" || echo "❌ 健康检查失败"
            
            echo ""
            echo "✅ 完整修复完成"
            ;;
        *)
            echo "❌ 无效选择"
            ;;
    esac
EOF

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 后续步骤："
echo "  1. 运行诊断: ./diagnose-service.sh message-service"
echo "  2. 查看实时日志: ./service-manager.sh logs message-service"
echo "  3. 如问题persist，检查 docker-compose.yml 健康检查配置"

