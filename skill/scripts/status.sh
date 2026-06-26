#!/bin/bash
# 查看开发日志状态

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
PROJECT_NAME=$(basename "$PROJECT_ROOT" 2>/dev/null)
PROJECT_DB="$PROJECT_ROOT/dev_docs/journal.db"
DRAFTS_DIR="$PROJECT_ROOT/dev_docs/.drafts"
ARTICLES_DIR="$PROJECT_ROOT/dev_docs/articles"

echo "📊 开发日志状态"
echo "项目：$PROJECT_NAME"
echo ""

if [ ! -f "$PROJECT_DB" ]; then
  echo "⚠️ 项目数据库未初始化"
  echo "   运行 git push 自动初始化"
  exit 0
fi

# 项目信息
GITHUB_URL=$(sqlite3 "$PROJECT_DB" "SELECT github_url FROM project_info LIMIT 1;")
echo "📂 GitHub：$GITHUB_URL"
echo ""

# 待处理草稿
if [ -d "$DRAFTS_DIR" ] && [ "$(ls -A $DRAFTS_DIR 2>/dev/null)" ]; then
  echo "📝 待处理草稿："
  ls -la "$DRAFTS_DIR"
else
  echo "✅ 没有待处理草稿"
fi

echo ""

# 文章统计
echo "📚 文章统计："
sqlite3 "$PROJECT_DB" "SELECT type, COUNT(*) FROM articles GROUP BY type;" 2>/dev/null || echo "  无"

echo ""

# 最新文章
echo "📄 最新文章："
sqlite3 "$PROJECT_DB" "SELECT filename, title, status, created_at FROM articles ORDER BY created_at DESC LIMIT 5;" 2>/dev/null || echo "  无"

echo ""

# Commits 统计
TOTAL=$(sqlite3 "$PROJECT_DB" "SELECT COUNT(*) FROM processed_commits;" 2>/dev/null || echo "0")
echo "✅ 已处理 commits：$TOTAL 个"
