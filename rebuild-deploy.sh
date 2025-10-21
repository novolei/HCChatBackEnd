#!/usr/bin/env bash
# rebuild-deploy.sh
# 重新构建并部署服务（强制重建 Docker 镜像）

set -e

# ============ 配置区域 ============
VPS_HOST="${VPS_HOST:-mx.go-lv.com}"
VPS_USER="${VPS_USER:-root}"
VPS_PATH="${VPS_PATH:-/root/hc-stack}"
GITHUB_BRANCH="${GITHUB_BRANCH:-main}"

# ============ 颜色输出 ============
print_step() { echo -e "\033[0;34m[$(date +%H:%M:%S)]\033[0m $1"; }
print_success() { echo -e "\033[0;32m✅ $1\033[0m"; }
print_error() { echo -e "\033[0;31m❌ $1\033[0m"; }
print_warning() { echo -e "\033[1;33m⚠️  $1\033[0m"; }

# ============ 显示帮助 ============
show_usage() {
    cat << EOF

╔════════════════════════════════════════╗
║   🔨 HChat Backend 重建部署工具      ║
╚════════════════════════════════════════╝

用途：强制重新构建 Docker 镜像并部署

用法：
    $0 <service>

可用服务：
    chat-gateway      - WebSocket 聊天网关（需要重建）
    message-service   - REST API 服务（挂载模式，重启即可）
    all              - 重建所有服务

示例：
    $0 chat-gateway          # 重建 chat-gateway
    $0 message-service       # 重启 message-service
    $0 all                   # 重建所有

环境变量：
    VPS_HOST       VPS 主机 (default: mx.go-lv.com)
    VPS_USER       VPS 用户 (default: root)
    VPS_PATH       项目路径 (default: /root/hc-stack)
    GITHUB_BRANCH  分支名   (default: main)

EOF
}

# ============ 验证参数 ============
if [[ $# -lt 1 ]]; then
    show_usage
    exit 1
fi

service="$1"

if [[ "$service" != "chat-gateway" && "$service" != "message-service" && "$service" != "all" ]]; then
    print_error "无效的服务名: $service"
    show_usage
    exit 1
fi

# ============ 主逻辑 ============
main() {
    cat << EOF

╔════════════════════════════════════════╗
║   🔨 HChat Backend 重建部署工具      ║
╚════════════════════════════════════════╝

📋 部署信息:
   服务:   $service
   VPS:    ${VPS_USER}@${VPS_HOST}
   路径:   ${VPS_PATH}
   分支:   ${GITHUB_BRANCH}

EOF

    print_step "连接 VPS: ${VPS_USER}@${VPS_HOST}..."
    
    ssh "${VPS_USER}@${VPS_HOST}" << EOF
        set -e
        
        echo "📦 切换到项目目录..."
        cd ${VPS_PATH}
        
        echo "🔍 检查本地状态..."
        if [[ -n \$(git status -s) ]]; then
            echo "⚠️  检测到本地修改，自动保存..."
            git stash save "自动备份 - 重建前 \$(date +'%Y-%m-%d %H:%M:%S')" || true
        fi
        
        echo "🔄 拉取最新代码..."
        git fetch origin
        git reset --hard origin/${GITHUB_BRANCH}
        
        echo "🐳 进入 Docker 目录..."
        cd infra
        
        if [[ "$service" == "all" ]]; then
            echo "🔨 重新构建所有服务..."
            docker compose down
            docker compose build --no-cache
            docker compose up -d
        elif [[ "$service" == "chat-gateway" ]]; then
            echo "🔨 重新构建 chat-gateway..."
            docker compose stop chat-gateway
            docker compose rm -f chat-gateway
            docker compose build --no-cache chat-gateway
            docker compose up -d chat-gateway
        elif [[ "$service" == "message-service" ]]; then
            echo "🔄 重启 message-service（挂载模式，无需重建）..."
            docker compose restart message-service
        fi
        
        echo ""
        echo "✅ 部署完成！"
        echo ""
        
        echo "📊 服务状态:"
        docker compose ps
        
        echo ""
        echo "📊 最近 20 条日志:"
        docker compose logs --tail=20 $service
EOF

    if [[ $? -eq 0 ]]; then
        print_success "VPS 重建部署成功"
    else
        print_error "VPS 重建部署失败"
        exit 1
    fi
    
    cat << EOF

╔════════════════════════════════════════╗
║   🎉 重建部署成功！                   ║
╚════════════════════════════════════════╝

EOF
}

main "$@"

