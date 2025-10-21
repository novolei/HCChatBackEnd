#!/bin/bash
# HChat Backend 快速部署脚本
# 用法: ./deploy.sh <服务名> [选项]
# 示例: ./deploy.sh chat-gateway -y
#      ./deploy.sh chat-gateway --yes  # 自动确认，不需要手动输入
#      AI_MODE=true ./deploy.sh chat-gateway  # AI 模式（完全自动化）

set -e  # 遇到错误立即退出

# ============ 配置区域 ============
VPS_HOST="${VPS_HOST:-mx.go-lv.com}"
VPS_USER="${VPS_USER:-root}"
VPS_PATH="${VPS_PATH:-/root/hc-stack}"
GITHUB_BRANCH="${GITHUB_BRANCH:-main}"
AUTO_CONFIRM=false  # 是否自动确认
AI_MODE="${AI_MODE:-false}"  # AI 模式（完全自动化，不询问任何问题）

# ============ 服务定义 ============
# 可部署的服务（我们自己开发的服务）
DEPLOYABLE_SERVICES=(
    "chat-gateway:WebSocket 聊天网关"
    "message-service:REST API 服务"
)

# 所有服务（包括第三方服务）
ALL_SERVICES=(
    "chat-gateway:WebSocket 聊天网关"
    "message-service:REST API 服务"
    "minio:S3 对象存储"
    "livekit:WebRTC 音视频服务"
    "coturn:TURN/STUN 服务"
)

# 特殊操作
SPECIAL_ACTIONS=("all" "config")

# 获取服务描述
get_service_desc() {
    local service_name="$1"
    for item in "${DEPLOYABLE_SERVICES[@]}"; do
        local name=$(echo "$item" | cut -d: -f1)
        local desc=$(echo "$item" | cut -d: -f2)
        if [[ "$name" == "$service_name" ]]; then
            echo "$desc"
            return
        fi
    done
}

# 检查服务是否可部署
is_deployable() {
    local service_name="$1"
    for item in "${DEPLOYABLE_SERVICES[@]}"; do
        local name=$(echo "$item" | cut -d: -f1)
        if [[ "$name" == "$service_name" ]]; then
            return 0
        fi
    done
    return 1
}

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
    echo "🚀 HChat Backend 部署脚本"
    echo ""
    echo "用法:"
    echo "    ./deploy.sh <服务名> [选项]"
    echo "    AI_MODE=true ./deploy.sh <服务名>  # AI 模式"
    echo ""
    echo "可部署的服务:"
    
    # 动态生成服务列表
    for item in "${DEPLOYABLE_SERVICES[@]}"; do
        local service=$(echo "$item" | cut -d: -f1)
        local desc=$(echo "$item" | cut -d: -f2)
        printf "    - %-18s %s\n" "$service" "$desc"
    done
    
    echo ""
    echo "特殊操作:"
    echo "    - all                 部署所有服务"
    echo "    - config              只更新配置文件（不重启）"
    echo ""
    echo "选项:"
    echo "    -y, --yes             自动确认部署，但仍询问日志查看"
    echo ""
    echo "示例:"
    echo "    ./deploy.sh chat-gateway -y          # 用户快速部署"
    echo "    AI_MODE=true ./deploy.sh chat-gateway # AI 完全自动化"
    echo "    ./ai-deploy.sh chat-gateway          # AI 智能部署（推荐）"
    echo ""
    echo "环境变量:"
    echo "    VPS_HOST    VPS 地址（默认: $VPS_HOST）"
    echo "    VPS_USER    SSH 用户（默认: $VPS_USER）"
    echo "    VPS_PATH    VPS 代码路径（默认: $VPS_PATH）"
    echo "    AI_MODE     AI 模式（true=完全自动化，false=用户模式）"
    echo ""
    echo "所有服务列表:"
    for item in "${ALL_SERVICES[@]}"; do
        local service=$(echo "$item" | cut -d: -f1)
        local desc=$(echo "$item" | cut -d: -f2)
        printf "    - %-18s %s\n" "$service" "$desc"
    done
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
        
        echo "🔍 检查本地状态..."
        if [[ -n \$(git status -s) ]]; then
            echo "⚠️  检测到本地修改，自动保存并同步..."
            git stash save "自动备份 - 部署前 \$(date +'%Y-%m-%d %H:%M:%S')" || true
        fi
        
        echo "🔄 拉取最新代码..."
        git fetch origin
        git reset --hard origin/${GITHUB_BRANCH}
        
        echo "🐳 进入 Docker 目录..."
        cd infra
        
        if [[ "$service" == "all" ]]; then
            echo "🔄 重新构建并重启所有服务..."
            docker compose up -d --build
        elif [[ "$service" == "config" ]]; then
            echo "📝 配置已更新（未重启服务）"
        else
            echo "🔄 重新构建并重启服务: $service..."
            docker compose up -d --build $service
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
    
    # AI 模式：完全自动化，不询问
    if [[ "$AI_MODE" == "true" ]]; then
        return
    fi
    
    # 用户模式：即使使用 -y，仍然询问是否查看实时日志
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
    local commit_msg=""
    
    # 处理帮助命令
    if [[ "$service" == "-h" || "$service" == "--help" ]]; then
        show_usage
        exit 0
    fi
    
    # 解析剩余参数，检查是否有 -y 或 --yes
    shift  # 跳过第一个参数（服务名）
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -y|--yes)
                AUTO_CONFIRM=true
                ;;
            *)
                commit_msg="$1"
                ;;
        esac
        shift
    done
    
    # 验证服务名
    local valid=false
    
    # 检查是否是可部署的服务
    if is_deployable "$service"; then
        valid=true
    fi
    
    # 检查是否是特殊操作
    for a in "${SPECIAL_ACTIONS[@]}"; do
        if [[ "$service" == "$a" ]]; then
            valid=true
            break
        fi
    done
    
    if [[ "$valid" == false ]]; then
        print_error "未知服务: $service"
        echo ""
        echo "可用的服务："
        for item in "${DEPLOYABLE_SERVICES[@]}"; do
            local s=$(echo "$item" | cut -d: -f1)
            echo "  - $s"
        done
        echo ""
        echo "特殊操作："
        for a in "${SPECIAL_ACTIONS[@]}"; do
            echo "  - $a"
        done
        echo ""
        echo "使用 --help 查看详细帮助"
        exit 1
    fi
    
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
    if [[ "$AI_MODE" == "true" ]]; then
        echo "🤖 AI 模式（完全自动化）"
        echo ""
    elif [[ "$AUTO_CONFIRM" != true ]]; then
        read -p "确认部署？[Y/n] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            print_warning "部署已取消"
            exit 0
        fi
    else
        echo "🤖 自动确认模式（-y/--yes）"
        echo ""
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

