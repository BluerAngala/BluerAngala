#!/bin/bash
# 推送开发日志到主页仓库
# journal generate + git commit + git push

BLOG_DIR="$HOME/Documents/vibecoding/BluerAngala-journal"
SKILL_DIR="$BLOG_DIR/journal/skill"

echo "📝 同步开发日志到主页仓库..."

# 1. generate
python3 "$SKILL_DIR/scripts/generate.py"

# 2. commit + push
cd "$BLOG_DIR"
if [ -n "$(git status --porcelain)" ]; then
    git add journal/dev/
    git commit -m "chore: 更新开发日志"
    git push 2>&1 | tail -3
    echo ""
    echo "✅ 已推送到 GitHub 主页仓库"
else
    echo "✅ 无变更，已是最新"
fi
