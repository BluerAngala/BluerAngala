#!/bin/bash
# 清理过期草稿（默认超过7天）
# 用法：journal clean [天数]

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
DRAFTS_DIR="$PROJECT_ROOT/dev_docs/.drafts"
DAYS="${1:-7}"

if [ ! -d "$DRAFTS_DIR" ] || [ -z "$(ls -A "$DRAFTS_DIR" 2>/dev/null)" ]; then
  echo "✅ 没有待处理草稿"
  exit 0
fi

echo "📝 清理 $DAYS 天前的草稿..."
echo ""

find "$DRAFTS_DIR" -name "*.md" -mtime "+$DAYS" -exec echo "  🗑️  删除: {}" \; -delete

REMAINING=$(find "$DRAFTS_DIR" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
echo ""
echo "✅ 清理完成，剩余 $REMAINING 个草稿"
