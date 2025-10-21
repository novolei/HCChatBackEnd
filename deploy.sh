#!/bin/bash
# HChat Backend 快速部署脚本
# 用法: ./deploy.sh <服务名> <commit消息>
# 示例: ./deploy.sh chat-gateway "fix: 修复消息广播问题"

set -e  # 遇到错误立即退出

# ============ 配置区域 ============
VPS_HOST="${VPS_HOST:-mx.go-lv.com}"
VPS_USER="${VPS_USER:-root}"
VPS_PATH="${VPS_PATH:-/root/hc-stack}"
GITHUB_BRANCH="${GITHUB_BRANCH:-main}"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============ 函数定义 ============

print_step() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $1"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

show_usage() {
    cat << EOF
🚀 HChat Backend 部署脚本

用法:
    ./deploy.sh <服务名> [commit消息]

服务名:
    - chat-gateway      WebSocket 聊天网关
    - message-service   REST API 服务
    - all              部署所有服务
    - config           只更新配置文件

示例:
    ./deploy.sh chat-gateway "fix: 修复房间清理逻辑"
    ./deploy.sh message-service "feat: 添加健康检查端点"
    ./deploy.sh all "chore: 更新依赖"
    ./deploy.sh config  # 只更新配置，不重启服务

环境变量:
    VPS_HOST    VPS 地址（默认: hc.go-lv.com）
    VPS_USER    SSH 用户（默认: root）
    VPS_PATH    VPS 代码路径（默认: /root/hc-stack/HCChatBackEnd）
EOF
}

# 检查 Git 状态
check_git_status() {
    print_step "检查 Git 状态..."
    
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_error "当前目录不是 Git 仓库"
        exit 1
    fi
    
    # 检查是否有未提交的改动
    if [[ -n $(git status -s) ]]; then
        print_warning "有未提交的改动:"
        git status -s
        return 1
    fi
    
    print_success "Git 状态正常"
    return 0
}

# 提交代码
commit_and_push() {
    local message="$1"
    
    print_step "提交代码到 GitHub..."
    
    git add .
    
    if [[ -z $(git status -s) ]]; then
        print_warning "没有改动需要提交"
        return 0
    fi
    
    if [[ -z "$message" ]]; then
        message="deploy: 部署更新 ($(date +'%Y-%m-%d %H:%M'))"
    fi
    
    git commit -m "$message"
    git push origin "$GITHUB_BRANCH"
    
    print_success "代码已推送到 GitHub"
}

# 在 VPS 上执行部署
deploy_to_vps() {
    local service="$1"
    
    print_step "连接 VPS: ${VPS_USER}@${VPS_HOST}..."
    
    ssh "${VPS_USER}@${VPS_HOST}" << EOF
        set -e
        
        echo "📦 切换到项目目录..."
        cd ${VPS_PATH}
        
        echo "🔄 拉取最新代码..."
        git pull origin ${GITHUB_BRANCH}
        
        echo "🐳 进入 Docker 目录..."
        cd infra
        
        if [[ "$service" == "all" ]]; then
            echo "🔄 重启所有服务..."
            docker compose restart
        elif [[ "$service" == "config" ]]; then
            echo "📝 配置已更新（未重启服务）"
        else
            echo "🔄 重启服务: $service..."
            docker compose restart $service
        fi
        
        echo ""
        echo "✅ 部署完成！"
        echo ""
        
        if [[ "$service" != "config" && "$service" != "all" ]]; then
            echo "📊 最近 20 条日志:"
            docker compose logs --tail=20 $service
        fi
EOF
    
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        print_success "VPS 部署成功"
        return 0
    else
        print_error "VPS 部署失败 (exit code: $exit_code)"
        return 1
    fi
}

# 显示部署后的日志
show_logs() {
    local service="$1"
    
    if [[ "$service" == "all" || "$service" == "config" ]]; then
        return
    fi
    
    echo ""
    read -p "是否实时查看日志？[y/N] " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_step "实时日志 (Ctrl+C 退出)..."
        ssh -t "${VPS_USER}@${VPS_HOST}" "cd ${VPS_PATH}/infra && docker compose logs -f $service"
    fi
}

# ============ 主程序 ============

main() {
    # 参数解析
    if [[ $# -lt 1 ]]; then
        show_usage
        exit 1
    fi
    
    local service="$1"
    local commit_msg="$2"
    
    # 验证服务名
    case "$service" in
        chat-gateway|message-service|all|config)
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "未知服务: $service"
            echo ""
            show_usage
            exit 1
            ;;
    esac
    
    echo ""
    echo "╔════════════════════════════════════════╗"
    echo "║   🚀 HChat Backend 部署工具           ║"
    echo "╚════════════════════════════════════════╝"
    echo ""
    echo "📋 部署信息:"
    echo "   服务:   $service"
    echo "   VPS:    ${VPS_USER}@${VPS_HOST}"
    echo "   分支:   $GITHUB_BRANCH"
    [[ -n "$commit_msg" ]] && echo "   消息:   $commit_msg"
    echo ""
    
    # 确认部署
    read -p "确认部署？[Y/n] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        print_warning "部署已取消"
        exit 0
    fi
    
    # 步骤 1: 检查 Git 状态
    if check_git_status; then
        # 没有改动，直接部署
        print_warning "跳过提交步骤"
    else
        # 有改动，需要提交
        commit_and_push "$commit_msg"
    fi
    
    # 步骤 2: 部署到 VPS
    if deploy_to_vps "$service"; then
        echo ""
        echo "╔════════════════════════════════════════╗"
        echo "║   🎉 部署成功！                       ║"
        echo "╚════════════════════════════════════════╝"
        echo ""
        
        # 步骤 3: 查看日志（可选）
        show_logs "$service"
        
        exit 0
    else
        echo ""
        print_error "部署失败，请检查错误信息"
        exit 1
    fi
}

# 执行主程序
main "$@"

