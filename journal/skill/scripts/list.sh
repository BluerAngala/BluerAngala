#!/bin/bash
# 列出所有开发日志（跨项目）

GLOBAL_DB="$HOME/.omp/journal.db"

if [ ! -f "$GLOBAL_DB" ]; then
  echo "⚠️ 全局数据库不存在"
  echo "   先运行 journal sync"
  exit 0
fi

echo "📚 所有文章"
echo ""

sqlite3 "$GLOBAL_DB" "
  SELECT p.name, a.filename, a.title, a.type, a.status, a.created_at
  FROM articles_index a
  LEFT JOIN projects p ON a.project_github = p.github_url
  ORDER BY a.created_at DESC
  LIMIT 30;"
