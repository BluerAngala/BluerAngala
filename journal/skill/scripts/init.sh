#!/bin/bash
# 初始化项目开发日志系统
# 用法：journal init

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
PROJECT_NAME=$(basename "$PROJECT_ROOT" 2>/dev/null)
DEV_DOCS_DIR="$PROJECT_ROOT/dev_docs"
SCRIPT_DIR="$(cd "$(dirname "$(readlink "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")")" && pwd)"

echo "🚀 初始化开发日志系统"
echo "项目：$PROJECT_NAME"

# 创建目录结构
mkdir -p "$DEV_DOCS_DIR/articles/internal" "$DEV_DOCS_DIR/images" "$DEV_DOCS_DIR/.drafts"
echo "✅ 目录结构已创建"

# 创建 INDEX.md
cat > "$DEV_DOCS_DIR/INDEX.md" << EOF
# $PROJECT_NAME — 开发日志
> Build in public 系列

## 文章
| 日期 | 标题 | 类型 |
|------|------|------|

## 命令
\`\`\`bash
journal push    # 生成草稿
journal status  # 查看状态
journal sync    # 同步到全局
journal search  # 全局搜索
\`\`\`
EOF
echo "✅ INDEX.md 已创建"

# 初始化数据库
sqlite3 "$PROJECT_DB" "INSERT OR IGNORE INTO project_info (name, github_url, local_path) VALUES ('$(echo "$PROJECT_NAME" | sed "s/'/''/g")', '$(echo "$GITHUB_URL" | sed "s/'/''/g")', '$(echo "$PROJECT_ROOT" | sed "s/'/''/g")');"
echo "✅ 项目信息已注册"

# .gitignore
if [ -f "$PROJECT_ROOT/.gitignore" ]; then
  grep -q "articles/internal/" "$PROJECT_ROOT/.gitignore" || {
    echo "" >> "$PROJECT_ROOT/.gitignore"
    echo "# 开发日志内部版（不公开）" >> "$PROJECT_ROOT/.gitignore"
    echo "dev_docs/articles/internal/" >> "$PROJECT_ROOT/.gitignore"
    echo "dev_docs/.drafts/" >> "$PROJECT_ROOT/.gitignore"
    echo "✅ .gitignore 已更新"
  }
else
  cat > "$PROJECT_ROOT/.gitignore" << 'GITEOF'
dev_docs/articles/internal/
dev_docs/.drafts/
node_modules/
dist/
*.log
.DS_Store
GITEOF
  echo "✅ .gitignore 已创建"
fi

# Git alias
git config alias.pub '!git push && journal push --main'
echo "✅ Git alias: git pub → git push + 自动生成草稿"

echo ""
echo "📋 初始化完成！"
echo ""
echo "开发 → git pub → 写开发日志 → journal sync"
