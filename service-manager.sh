#!/bin/bash
# HChat Backend 服务管理工具
# 用于查看服务状态、添加新服务等

set -e

VPS_HOST="${VPS_HOST:-mx.go-lv.com}"
VPS_USER="${VPS_USER:-root}"
VPS_PATH="${VPS_PATH:-/root/hc-stack}"

# 颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

show_usage() {
    cat << EOF
📊 HChat Backend 服务管理工具

用法:
    ./service-manager.sh <命令>

命令:
    list        列出所有服务状态
    logs        查看服务日志
    new         创建新服务模板
    test        测试服务健康状态
    help        显示此帮助

示例:
    ./service-manager.sh list
    ./service-manager.sh logs chat-gateway
    ./service-manager.sh new my-service
    ./service-manager.sh test
EOF
}

# 列出所有服务
list_services() {
    echo -e "${BLUE}📊 查询 VPS 服务状态...${NC}"
    echo ""
    
    ssh "${VPS_USER}@${VPS_HOST}" << 'EOF'
        cd /root/hc-stack/infra 2>/dev/null || cd /root/hc-stack/HCChatBackEnd/infra
        
        echo "🐳 Docker Compose 服务:"
        echo ""
        docker compose ps
        
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "💾 资源使用:"
        docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"
EOF
}

# 查看服务日志
show_logs() {
    local service="$1"
    
    if [[ -z "$service" ]]; then
        echo "请指定服务名"
        echo "示例: ./service-manager.sh logs chat-gateway"
        exit 1
    fi
    
    echo -e "${BLUE}📝 查看 $service 日志...${NC}"
    echo ""
    
    ssh -t "${VPS_USER}@${VPS_HOST}" "cd ${VPS_PATH}/infra && docker compose logs -f $service"
}

# 创建新服务模板
create_new_service() {
    local service_name="$1"
    
    if [[ -z "$service_name" ]]; then
        read -p "请输入服务名（例如: auth-service）: " service_name
    fi
    
    if [[ -z "$service_name" ]]; then
        echo "❌ 服务名不能为空"
        exit 1
    fi
    
    if [[ -d "$service_name" ]]; then
        echo "❌ 目录 $service_name 已存在"
        exit 1
    fi
    
    echo -e "${BLUE}🆕 创建新服务: $service_name${NC}"
    echo ""
    
    # 创建目录
    mkdir -p "$service_name"
    
    # 创建 package.json
    cat > "$service_name/package.json" << EOF
{
  "name": "$service_name",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.19.2",
    "cors": "^2.8.5"
  }
}
EOF
    
    # 创建 server.js
    cat > "$service_name/server.js" << 'EOF'
'use strict';
const express = require('express');
const cors = require('cors');

const PORT = Number(process.env.PORT || 3000);
const app = express();

app.use(express.json());
app.use(cors());

// 健康检查
app.get('/health', (req, res) => {
  res.json({ 
    ok: true, 
    service: process.env.npm_package_name,
    uptime: process.uptime(),
    timestamp: new Date().toISOString()
  });
});

// 示例 API
app.get('/api/hello', (req, res) => {
  res.json({ message: 'Hello from ' + process.env.npm_package_name });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`${process.env.npm_package_name} listening on :${PORT}`);
});
EOF
    
    # 创建 Dockerfile
    cat > "$service_name/Dockerfile" << 'EOF'
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
EOF
    
    echo -e "${GREEN}✅ 服务模板已创建: $service_name/${NC}"
    echo ""
    echo "下一步:"
    echo "  1. cd $service_name"
    echo "  2. 编辑 server.js 实现业务逻辑"
    echo "  3. 本地测试: npm install && npm start"
    echo "  4. 更新 deploy.sh 添加服务定义"
    echo "  5. 更新 infra/docker-compose.yml"
    echo "  6. 部署: ./deploy.sh $service_name \"feat: 添加 $service_name\""
    echo ""
    echo "📖 详细文档: ADD_SERVICE.md"
}

# 测试服务健康状态
test_health() {
    echo -e "${BLUE}🔍 测试服务健康状态...${NC}"
    echo ""
    
    ssh "${VPS_USER}@${VPS_HOST}" << 'EOF'
        echo "测试本地服务端点:"
        echo ""
        
        # chat-gateway
        echo -n "chat-gateway (10080): "
        if curl -s -f http://127.0.0.1:10080/chat-ws > /dev/null 2>&1; then
            echo "✅ 运行中"
        else
            echo "❌ 无响应"
        fi
        
        # message-service
        echo -n "message-service (10081): "
        if curl -s -f http://127.0.0.1:10081/healthz > /dev/null 2>&1; then
            echo "✅ 运行中"
        else
            echo "❌ 无响应"
        fi
        
        # MinIO
        echo -n "MinIO (10090): "
        if curl -s -f http://127.0.0.1:10090/minio/health/ready > /dev/null 2>&1; then
            echo "✅ 运行中"
        else
            echo "❌ 无响应"
        fi
        
        echo ""
        echo "测试公网域名:"
        echo ""
        
        # 公网测试
        echo -n "https://hc.go-lv.com: "
        if curl -s -f https://hc.go-lv.com > /dev/null 2>&1; then
            echo "✅ 可访问"
        else
            echo "❌ 无法访问"
        fi
        
        echo -n "https://s3.hc.go-lv.com: "
        if curl -s -f https://s3.hc.go-lv.com > /dev/null 2>&1; then
            echo "✅ 可访问"
        else
            echo "❌ 无法访问"
        fi
EOF
}

# 主程序
main() {
    local command="${1:-help}"
    
    case "$command" in
        list)
            list_services
            ;;
        logs)
            show_logs "$2"
            ;;
        new)
            create_new_service "$2"
            ;;
        test)
            test_health
            ;;
        help|-h|--help)
            show_usage
            ;;
        *)
            echo "❌ 未知命令: $command"
            echo ""
            show_usage
            exit 1
            ;;
    esac
}

main "$@"

