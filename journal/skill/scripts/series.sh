#!/bin/bash
# 系列文章草稿生成 — 自动按里程碑分组
# 用法：journal series
# 读取所有未处理 commits，按功能/模块分组，生成多个草稿

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
PROJECT_NAME=$(basename "$PROJECT_ROOT" 2>/dev/null)
PROJECT_DB="$PROJECT_ROOT/dev_docs/journal.db"
DRAFTS_DIR="$PROJECT_ROOT/dev_docs/.drafts"

# 获取所有未处理 commits（过滤 stash）
ALL_COMMITS=$(git log --oneline --all 2>/dev/null | grep -v -E '^(On master:|index on master:)' | head -200)

if [ -z "$ALL_COMMITS" ]; then
  echo "⚠️ 没有 commits"
  exit 0
fi

# 检查哪些还未处理
UNPROCESSED_FILE=$(mktemp)
while IFS= read -r line; do
  HASH=$(echo "$line" | awk '{print $1}')
  EXISTS=$(sqlite3 "$PROJECT_DB" "SELECT COUNT(*) FROM processed_commits WHERE commit_hash='$HASH';" 2>/dev/null)
  [ "$EXISTS" = "0" ] && echo "$line" >> "$UNPROCESSED_FILE"
done <<< "$ALL_COMMITS"

UNPROCESSED=$(cat "$UNPROCESSED_FILE" | head -100)
rm -f "$UNPROCESSED_FILE"

if [ -z "$UNPROCESSED" ]; then
  echo "✅ 所有 commits 已处理"
  exit 0
fi

DEPTH=$(echo "$UNPROCESSED" | wc -l | tr -d ' ')
echo "📊 未处理 commits：$DEPTH 个"
echo ""

# 定义分组规则
mkdir -p "$DRAFTS_DIR"
DATE=$(date +%Y-%m-%d)
INDEX_FILE="$DRAFTS_DIR/series-index.md"

echo "# 系列文章草稿索引" > "$INDEX_FILE"
echo "生成于 $DATE" >> "$INDEX_FILE"
echo "" >> "$INDEX_FILE"
echo "| # | 主题 | commits | 状态 |" >> "$INDEX_FILE"
echo "|---|------|---------|------|" >> "$INDEX_FILE"

SEQ=0
while IFS='|' read -r name pattern; do
  GROUP_COMMITS=$(echo "$UNPROCESSED" | grep -iE "$pattern")
  COMMIT_COUNT=$(echo "$GROUP_COMMITS" | wc -l | tr -d ' ')
  
  if [ "$COMMIT_COUNT" -ge 3 ]; then
    SEQ=$((SEQ + 1))
    TAG=$(printf "%02d" $SEQ)
    SAFE_NAME=$(echo "$name" | tr ' ' '-' | tr -d '"')
    DRAFT_FILE="$DRAFTS_DIR/series-$TAG-$SAFE_NAME.md"
    
    cat > "$DRAFT_FILE" << DRAFTEOF
# 系列文章 $TAG：$name

> 自动分组于 $DATE，包含 $COMMIT_COUNT 个 commits

## Commits

\`\`\`
$GROUP_COMMITS
\`\`\`

## 系列目录

查看 series-index.md 了解完整系列规划。

---

*生成后运行"写开发日志"生成文章*
DRAFTEOF

    echo "| $SEQ | $name | $COMMIT_COUNT | ⏳ 待生成 |" >> "$INDEX_FILE"
    echo "✅ [$TAG] $name — $COMMIT_COUNT commits"
  fi
done << GROUPS
项目启动|init|startup|bootstrap|心跳
事件驱动架构|event|v2|refactor|总线
LLM 迁移|llm|model|sdk|api|migration|mimo|max|flow|openai
听觉系统|hear|audio|voice|vad|mic|录音|speech|stt|语音
记忆系统|memory|记忆|search|compress|recall
基础设施|config|biome|lint|typescript|tool|工具
性能优化|perf|非阻塞|throttle|buffer
踩坑修复|fix|bug|重复|冲突|重试|容错
GROUPS

echo ""
echo "📋 系列索引：$INDEX_FILE"
echo "   包含 $SEQ 篇文章草稿"
echo ""
echo "运行 '写开发日志' 逐篇生成文章"
