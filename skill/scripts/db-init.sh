#!/bin/bash
# 初始化项目级数据库
# 创建表结构和触发器

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
PROJECT_DB="$PROJECT_ROOT/dev_docs/journal.db"

mkdir -p "$(dirname "$PROJECT_DB")"

sqlite3 "$PROJECT_DB" << 'EOF'
CREATE TABLE IF NOT EXISTS schema_version (
  version INTEGER PRIMARY KEY,
  applied_at TEXT DEFAULT (datetime('now'))
);
INSERT OR IGNORE INTO schema_version (version) VALUES (1);

CREATE TABLE IF NOT EXISTS project_info (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT,
  github_url TEXT UNIQUE,
  local_path TEXT,
  created_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS tech_decisions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  category TEXT,
  title TEXT,
  decision TEXT,
  reasoning TEXT,
  alternatives TEXT,
  created_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS articles (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  filename TEXT UNIQUE,
  title TEXT,
  content TEXT,
  type TEXT DEFAULT '主文章',
  status TEXT DEFAULT 'draft',
  commits TEXT,
  created_at TEXT DEFAULT (datetime('now')),
  updated_at TEXT DEFAULT (datetime('now')),
  published_at TEXT,
  tags TEXT DEFAULT '[]',
  source_id INTEGER,
  FOREIGN KEY (source_id) REFERENCES articles(id)
);

CREATE TABLE IF NOT EXISTS materials (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  article_id INTEGER,
  type TEXT,
  content TEXT,
  status TEXT DEFAULT 'pending',
  created_at TEXT DEFAULT (datetime('now')),
  FOREIGN KEY (article_id) REFERENCES articles(id)
);

CREATE TABLE IF NOT EXISTS processed_commits (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  commit_hash TEXT UNIQUE,
  article_id INTEGER,
  processed_at TEXT DEFAULT (datetime('now')),
  FOREIGN KEY (article_id) REFERENCES articles(id)
);
EOF

echo "✅ 项目数据库已初始化：$PROJECT_DB"
