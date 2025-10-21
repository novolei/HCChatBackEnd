#!/bin/bash
# VPS 端脚本 - 拉取最新代码并重启服务
# 在 VPS 上使用: ./update-and-restart.sh <服务名>

set -e

SERVICE="${1:-all}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

echo "📦 拉取最新代码..."
git pull origin main

echo "🔄 重启服务: $SERVICE..."
cd infra

if [[ "$SERVICE" == "all" ]]; then
    docker compose restart
else
    docker compose restart "$SERVICE"
fi

echo "✅ 完成！"
echo ""
echo "📊 服务状态:"
docker compose ps

echo ""
echo "📝 最近日志:"
if [[ "$SERVICE" == "all" ]]; then
    docker compose logs --tail=10
else
    docker compose logs --tail=20 "$SERVICE"
fi

