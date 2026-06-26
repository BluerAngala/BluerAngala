#!/bin/bash
# Git push 时自动生成草稿
# 检查 commits 是否已处理，避免重复
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
PROJECT_NAME=$(basename "$PROJECT_ROOT" 2>/dev/null)
PROJECT_DB="$PROJECT_ROOT/dev_docs/journal.db"
DRAFTS_DIR="$PROJECT_ROOT/dev_docs/.drafts"

# GitHub URL 归一化
normalize_url() {
  local url="$1"
  url=$(echo "$url" | sed 's|git@github.com:|https://github.com/|' | sed 's|\.git$||')
  echo "$url"
}
GITHUB_URL=$(normalize_url "$(git remote get-url origin 2>/dev/null || echo "")")

# 初始化项目数据库
~/.omp/agent/skills/dev-journal/scripts/db-init.sh

# 注册项目信息
sqlite3 "$PROJECT_DB" "INSERT OR IGNORE INTO project_info (name, github_url, local_path) VALUES ('$(echo "$PROJECT_NAME" | sed "s/'/''/g")', '$(echo "$GITHUB_URL" | sed "s/'/''/g")', '$(echo "$PROJECT_ROOT" | sed "s/'/''/g")');"

# 获取未处理的 commits（默认 30 条，可传参控制：journal push --all 或 journal push 50）
COUNT="${1:-30}"
FILTER="grep -v -E '^(On master:|index on master:)'"

if [ "$1" = "--all" ]; then
  COMMITS=$(git log --oneline --all 2>/dev/null | eval "$FILTER")
elif [ "$1" = "--main" ]; then
  COMMITS=$(git log --oneline origin/main..HEAD --all 2>/dev/null | eval "$FILTER" || git log --oneline -"$COUNT" | eval "$FILTER")
else
  COMMITS=$(git log --oneline -"$COUNT" 2>/dev/null | eval "$FILTER")
fi

if [ -z "$COMMITS" ]; then
  echo "⚠️ 没有新 commits"
  exit 0
fi

UNPROCESSED=""
while IFS= read -r line; do
  HASH=$(echo "$line" | cut -d' ' -f1)
  EXISTS=$(sqlite3 "$PROJECT_DB" "SELECT COUNT(*) FROM processed_commits WHERE commit_hash='$HASH';")
  if [ "$EXISTS" -eq 0 ]; then
    UNPROCESSED="$UNPROCESSED$line\n"
  fi
done <<< "$COMMITS"

if [ -z "$UNPROCESSED" ]; then
  echo "✅ 所有 commits 已处理"
  exit 0
fi

# 生成草稿
mkdir -p "$DRAFTS_DIR"

DATE=$(date +%Y-%m-%d)
TIME=$(date +%H%M%S)
DRAFT_FILE="$DRAFTS_DIR/$DATE-$TIME-draft.md"

# 检查是否有相似文章
SIMILAR=$(sqlite3 "$PROJECT_DB" "SELECT filename, title FROM articles WHERE created_at LIKE '$DATE%' LIMIT 5;")

cat > "$DRAFT_FILE" << EOF
# [待完善] 开发日志草稿

> 自动生成于 $(date '+%Y-%m-%d %H:%M:%S')
> 项目：$PROJECT_NAME
> GitHub：$GITHUB_URL

## 新 Commits（未处理）

\`\`\`
$(echo -e "$UNPROCESSED")
\`\`\`

## 关键改动

$(git diff --stat HEAD~5..HEAD 2>/dev/null | tail -20)

## 相关文章（数据库中已有）

$(if [ -n "$SIMILAR" ]; then echo "$SIMILAR"; else echo "无"; fi)

## 待补充

- [ ] 标题（抓眼球，不技术术语）
- [ ] 背景（为什么做这个）
- [ ] 问题（遇到什么困难，让读者共鸣）
- [ ] 方案（怎么解决的，讲思路不讲代码）
- [ ] 效果（数据说话）
- [ ] 下一步（留悬念）
- [ ] 互动引导（引导评论、关注）
EOF

echo "✅ 草稿已生成：$DRAFT_FILE"
echo ""
echo "📝 相关已有文章："
if [ -n "$SIMILAR" ]; then
  echo "$SIMILAR"
else
  echo "  无"
fi
