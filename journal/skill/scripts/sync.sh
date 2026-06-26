#!/bin/bash
# 同步项目数据到全局数据库
# 由 sync.py 实际执行（Python sqlite3 避免 SQL 注入）

SCRIPT_DIR="$(cd "$(dirname "$(readlink "$0" 2>/dev/null || echo "$0")")" && pwd)"

if [ ! -d "$SCRIPT_DIR" ]; then
  echo "⚠️ 无法定位脚本目录"
  exit 1
fi

python3 "$SCRIPT_DIR/sync.py" "$@"
