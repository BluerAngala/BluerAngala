#!/bin/bash
# 检查现有文章是否符合最新规范
# 生成需要更新的清单

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
PROJECT_DB="$PROJECT_ROOT/dev_docs/journal.db"
ARTICLES_DIR="$PROJECT_ROOT/dev_docs/articles"
IMAGES_DIR="$PROJECT_ROOT/dev_docs/images"

echo "🔍 检查现有文章..."

ISSUES=0

# 遍历所有公开文章
for file in "$ARTICLES_DIR"/*.md; do
  [ -f "$file" ] || continue
  BASENAME=$(basename "$file" .md)
  INTERNAL="$ARTICLES_DIR/internal/$BASENAME.md"
  
  echo ""
  echo "=== $BASENAME ==="

  # 1. 检查内部版是否存在
  if [ -f "$INTERNAL" ]; then
    echo "  ✅ 内部版存在"
  else
    echo "  ⚠️ 缺少内部版"
    ISSUES=$((ISSUES + 1))
  fi

  # 2. 检查是否有封面图
  if [ -f "$IMAGES_DIR/$BASENAME-cover.png" ] || [ -f "$IMAGES_DIR/$BASENAME-cover.jpg" ]; then
    echo "  ✅ 封面图存在"
  else
    echo "  ⚠️ 缺少封面图"
    ISSUES=$((ISSUES + 1))
  fi

  # 3. 检查是否有截图建议
  SHOTS_FILE="$PROJECT_ROOT/dev_docs/.drafts/.shots/$BASENAME-suggestions.md"
  if [ -f "$SHOTS_FILE" ]; then
    echo "  ✅ 截图建议存在"
  else
    echo "  ⚠️ 缺少截图建议文件"
    ISSUES=$((ISSUES + 1))
  fi

  # 4. 检查是否有已提取的素材
  if [ -f "$PROJECT_DB" ]; then
    COUNT=$(sqlite3 "$PROJECT_DB" "SELECT COUNT(*) FROM materials m JOIN articles a ON m.article_id=a.id WHERE a.filename='$BASENAME.md';" 2>/dev/null)
    if [ "$COUNT" -gt 0 ]; then
      echo "  ✅ 素材已提取（$COUNT 条）"
    else
      echo "  ⚠️ 未提取素材"
      ISSUES=$((ISSUES + 1))
    fi
  fi
done

echo ""
echo "=========================="
if [ "$ISSUES" -eq 0 ]; then
  echo "✅ 所有文章符合最新规范"
else
  echo "⚠️ 发现 $ISSUES 个问题需要修复"
  echo "运行 '更新开发日志' 自动修复"
fi
