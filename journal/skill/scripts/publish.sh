#!/bin/bash
# journal publish — 全自动：generate + commit + push
BLOG_DIR="$HOME/Documents/vibecoding/BluerAngala-journal"
SKILL_DIR="$BLOG_DIR/journal/skill"

echo "📝 同步开发日志..."

# 1. generate（文章 + INDEX + README）
python3 "$SKILL_DIR/scripts/generate.py"

# 2. commit 所有变更
cd "$BLOG_DIR"
if [ -n "$(git status --porcelain)" ]; then
    git add -A
    git commit -m "chore: 更新开发日志 $(date +%Y-%m-%d)"
    git push 2>&1 | tail -3
    echo "✅ 已推送到 GitHub"
else
    echo "✅ 无变更"
fi
