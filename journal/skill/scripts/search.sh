#!/bin/bash
# 全局搜索开发日志（跨项目）
# 搜索全局数据库 articles_index 表

GLOBAL_DB="$HOME/.omp/journal.db"
KEYWORD="$1"

if [ -z "$KEYWORD" ]; then
  echo "用法：journal search <关键词>"
  exit 1
fi

if [ ! -f "$GLOBAL_DB" ]; then
  echo "⚠️ 全局数据库不存在"
  echo "   先运行 journal sync"
  exit 1
fi

echo "🔍 搜索：$KEYWORD"
echo ""

sqlite3 "$GLOBAL_DB" "
  SELECT p.name, a.filename, a.title, a.type, a.status, a.created_at
  FROM articles_index a
  LEFT JOIN projects p ON a.project_github = p.github_url
  WHERE a.title LIKE '%$KEYWORD%'
     OR a.tags LIKE '%$KEYWORD%'
  ORDER BY a.created_at DESC
  LIMIT 20;"
