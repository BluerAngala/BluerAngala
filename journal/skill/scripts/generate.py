#!/usr/bin/env python3
"""Sync dev journal articles to BluerAngala-journal/journal/dev/."""
import sqlite3, os, re, json
from pathlib import Path
from datetime import datetime

GLOBAL_DB = os.path.expanduser("~/.omp/journal.db")
JOURNAL = Path(os.path.expanduser("~/Documents/vibecoding/BluerAngala-journal/journal"))
DEV_DIR = JOURNAL / "dev"

con = sqlite3.connect(GLOBAL_DB)
projects = con.execute("SELECT name, local_path FROM projects").fetchall()

for proj_name, proj_path in projects:
    articles_dir = Path(proj_path) / "dev_docs" / "articles"
    if not articles_dir.exists():
        continue

    articles = con.execute("""
        SELECT filename, title, created_at, tags
        FROM articles_index
        WHERE project_github=(SELECT github_url FROM projects WHERE name=?)
        AND type='主文章' ORDER BY created_at DESC
    """, (proj_name,)).fetchall()

    if not articles:
        continue

    proj_out = DEV_DIR / proj_name
    proj_out.mkdir(parents=True, exist_ok=True)

    for fname, title, created, tags in articles:
        src = articles_dir / fname
        if not src.exists():
            continue

        content = src.read_text(encoding="utf-8")
        # 去掉封面图引用（图片在项目仓库，不在日志仓库）
        content = re.sub(r'^\!\[.*?\]\(.*?\)\s*\n*', '', content, count=1)

        try:
            tag_list = json.loads(tags) if tags else []
        except:
            tag_list = []

        date = created[:10] if created else datetime.now().strftime("%Y-%m-%d")
        safe_title = title.replace('"', "'")
        tag_str = ", ".join('"' + t + '"' for t in tag_list)

        fm = "---\n"
        fm += 'title: "' + safe_title + '"\n'
        fm += "date: " + date + "\n"
        fm += "project: " + proj_name + "\n"
        fm += "tags: [" + tag_str + "]\n"
        fm += "category: dev\n"
        fm += "status: draft\n"
        fm += "---\n\n"

        out_name = re.sub(r"^\d{4}-\d{2}-\d{2}-", "", fname)
        out_path = proj_out / out_name
        out_path.write_text(fm + content, encoding="utf-8")
        print(f"  ✅ {proj_name}/{out_name} ({len(content.splitlines())} 行)")

con.close()

# INDEX.md
index = "# 🔧 开发日志\n\n"
for d in sorted(DEV_DIR.iterdir()):
    if d.is_dir():
        files = list(d.glob("*.md"))
        if files:
            index += f"## [{d.name}]({d.name}/)\n\n"
            for f in sorted(files):
                index += f"- [{f.stem}]({d.name}/{f.name})\n"
            index += "\n"
manual = [f for f in DEV_DIR.glob("*.md") if f.is_file()]
if manual:
    index += "## 其他\n\n"
    for f in sorted(manual):
        index += f"- [{f.stem}]({f.name})\n"
(DEV_DIR / "INDEX.md").write_text(index, encoding="utf-8")
print("✅ INDEX.md 已更新")
