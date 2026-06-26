#!/usr/bin/env python3
"""同步项目数据到全局数据库。用 Python sqlite3 避免 shell 注入。"""

import sqlite3, os, sys, subprocess
from pathlib import Path

GLOBAL_DB = os.path.expanduser("~/.omp/journal.db")

try:
    root = subprocess.run(["git", "rev-parse", "--show-toplevel"],
                         capture_output=True, text=True, check=True).stdout.strip()
except subprocess.CalledProcessError:
    print("⚠️ 不在 git 项目中")
    sys.exit(1)

name = Path(root).name
project_db = Path(root) / "dev_docs" / "journal.db"
if not project_db.exists():
    print(f"⚠️ 项目数据库不存在：{project_db}")
    sys.exit(1)

url_raw = subprocess.run(["git", "remote", "get-url", "origin"],
                         capture_output=True, text=True).stdout.strip()
github_url = url_raw.replace("git@github.com:", "https://github.com/").replace(".git", "")

global_con = sqlite3.connect(GLOBAL_DB)
global_con.execute("CREATE TABLE IF NOT EXISTS schema_version (version INTEGER PRIMARY KEY, applied_at TEXT DEFAULT (datetime('now')))")
global_con.execute("INSERT OR IGNORE INTO schema_version (version) VALUES (1)")
global_con.execute("CREATE TABLE IF NOT EXISTS projects (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, github_url TEXT UNIQUE, local_path TEXT, last_synced TEXT, created_at TEXT DEFAULT (datetime('now')))")
global_con.execute("CREATE TABLE IF NOT EXISTS articles_index (id INTEGER PRIMARY KEY AUTOINCREMENT, project_github TEXT, filename TEXT, title TEXT, type TEXT, status TEXT, created_at TEXT, tags TEXT DEFAULT '[]')")
global_con.execute("CREATE TABLE IF NOT EXISTS materials_index (id INTEGER PRIMARY KEY AUTOINCREMENT, project_github TEXT, type TEXT, content TEXT, status TEXT)")

global_con.execute("INSERT OR REPLACE INTO projects (name, github_url, local_path, last_synced) VALUES (?, ?, ?, datetime('now'))", (name, github_url, root))

proj_con = sqlite3.connect(str(project_db))

global_con.execute("DELETE FROM articles_index WHERE project_github=?", (github_url,))
for row in proj_con.execute("SELECT filename, title, type, status, created_at, tags FROM articles"):
    global_con.execute("INSERT INTO articles_index (project_github, filename, title, type, status, created_at, tags) VALUES (?, ?, ?, ?, ?, ?, ?)", (github_url, *row))

global_con.execute("DELETE FROM materials_index WHERE project_github=?", (github_url,))
for row in proj_con.execute("SELECT type, content, status FROM materials"):
    global_con.execute("INSERT INTO materials_index (project_github, type, content, status) VALUES (?, ?, ?, ?)", (github_url, *row))

global_con.commit()
articles = global_con.execute("SELECT COUNT(*) FROM articles_index WHERE project_github=?", (github_url,)).fetchone()[0]
materials = global_con.execute("SELECT COUNT(*) FROM materials_index WHERE project_github=?", (github_url,)).fetchone()[0]
global_con.close()
proj_con.close()

print(f"✅ 已同步到全局数据库")
print(f"   项目：{name} ({github_url})")
print(f"   文章：{articles} 篇")
print(f"   素材：{materials} 个")
print(f"   位置：{GLOBAL_DB}")
