#!/usr/bin/env python3
"""Sync dev journal articles to BluerAngala-journal/journal/dev/."""
import sqlite3, os, re, json
from pathlib import Path
from datetime import datetime

GLOBAL_DB = os.path.expanduser("~/.omp/journal.db")
JOURNAL = Path(os.path.expanduser("~/Documents/vibecoding/BluerAngala-journal/journal"))
DEV_DIR = JOURNAL / "dev"
README = JOURNAL.parent / "README.md"

def extract_summary(content):
    body = re.sub(r'^---.*?---\s*', '', content, flags=re.DOTALL)
    body = re.sub(r'^\!\[.*?\]\(.*?\)\s*', '', body)
    for line in body.split('\n'):
        line = line.strip()
        if line and not line.startswith('#') and not line.startswith('>') and not line.startswith('<!--'):
            return line[:80] + ('...' if len(line) > 80 else '')
    return ""

# 1. 同步文章
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
        content = re.sub(r'^\!\[.*?\]\(.*?\)\s*\n*', '', content, count=1)

        try:
            tag_list = json.loads(tags) if tags else []
        except:
            tag_list = []

        date = created[:10] if created else datetime.now().strftime("%Y-%m-%d")
        safe_title = title.replace('"', "'")
        tag_str = ", ".join('"' + t + '"' for t in tag_list)
        summary = extract_summary(content).replace('"', "'")

        fm = "---\n"
        fm += 'title: "' + safe_title + '"\n'
        fm += "date: " + date + "\n"
        fm += "category: dev\n"
        fm += "tags: [" + tag_str + "]\n"
        fm += "status: draft\n"
        fm += 'summary: "' + summary + '"\n'
        fm += "---\n\n"

        out_name = re.sub(r"^\d{4}-\d{2}-\d{2}-", "", fname)
        out_path = proj_out / out_name
        out_path.write_text(fm + content, encoding="utf-8")
        print(f"  ✅ {proj_name}/{out_name} ({len(content.splitlines())} 行)")

con.close()

# 2. INDEX.md
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

# 3. README.md 日志区块
if README.exists():
    readme = README.read_text(encoding="utf-8")
    
    table = "| [思考](./journal/thinking/) | [实践](./journal/dev/) |\n"
    table += "|:---|:---|\n"
    
    thinking_files = sorted((JOURNAL / "thinking").glob("*.md")) if (JOURNAL / "thinking").exists() else []
    
    # 所有文章（不限每项目一篇）
    dev_entries = []
    for d in sorted(DEV_DIR.iterdir()):
        if d.is_dir():
            for f in sorted(d.glob("*.md")):
                dev_entries.append((d.name, f))
    
    max_rows = max(len(thinking_files), len(dev_entries), 1)
    for i in range(max_rows):
        t_col = ""
        d_col = ""
        if i < len(thinking_files):
            f = thinking_files[i]
            t_col = f"[{f.stem}](./journal/thinking/{f.name})"
        if i < len(dev_entries):
            proj, f = dev_entries[i]
            d_col = f"[{f.stem}](./journal/dev/{proj}/{f.name})"
        table += f"| {t_col} | {d_col} |\n"
    
    if "## 日志" in readme:
        readme = re.sub(
            r"\n## 日志\n.*?(?=\n## |\n---|\Z)",
            "\n## 日志\n\n[写作规范](./SPEC.md) · [全部文章](./journal/)\n\n" + table + "\n",
            readme, flags=re.DOTALL
        )
        README.write_text(readme, encoding="utf-8")
        print("✅ README.md 日志区块已更新")
