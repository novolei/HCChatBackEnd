#!/bin/bash
# AI 部署辅助脚本
# 用于 AI 自动部署时捕获输出并检查结果

set +e  # 允许命令失败，我们自己处理错误

# 创建临时文件保存输出
TEMP_OUTPUT=$(mktemp)
TEMP_ERROR=$(mktemp)

# 清理函数
cleanup() {
    rm -f "$TEMP_OUTPUT" "$TEMP_ERROR"
}
trap cleanup EXIT

# 执行部署，捕获输出
AI_MODE=true ./deploy.sh "$@" > "$TEMP_OUTPUT" 2> "$TEMP_ERROR"
EXIT_CODE=$?

# 显示输出
cat "$TEMP_OUTPUT"
cat "$TEMP_ERROR" >&2

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 AI 部署结果分析"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 检查退出码
if [[ $EXIT_CODE -ne 0 ]]; then
    echo "❌ 部署失败 (exit code: $EXIT_CODE)"
    echo ""
    echo "📋 错误信息："
    grep -i "error\|failed\|错误\|失败" "$TEMP_OUTPUT" "$TEMP_ERROR" || echo "  未找到明确的错误信息"
    exit $EXIT_CODE
fi

# 检查成功标志
if grep -q "✅ VPS 部署成功\|部署成功\|🎉 部署成功" "$TEMP_OUTPUT"; then
    echo "✅ 部署成功验证"
    
    # 检查服务是否正常启动
    if grep -q "Started\|listening on\|运行中" "$TEMP_OUTPUT"; then
        echo "✅ 服务已正常启动"
    else
        echo "⚠️  无法确认服务状态，请检查日志"
    fi
    
    # 提取最近日志
    echo ""
    echo "📊 最近日志摘要："
    grep -A 5 "最近.*条日志\|最近日志" "$TEMP_OUTPUT" | tail -8 | sed 's/^/  /'
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🎉 部署完成！所有检查通过"
    exit 0
else
    echo "⚠️  部署完成，但无法确认成功标志"
    echo ""
    echo "📋 输出摘要："
    tail -20 "$TEMP_OUTPUT" | sed 's/^/  /'
    echo ""
    echo "⚠️  建议手动检查服务状态"
    exit 2
fi

