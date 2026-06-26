---
name: dev-journal
description: Generate dev journal for build-in-public. Use when user says "写开发日志", "开发周报", "build in public". Reads git commits + memory, generates public article + internal tech doc, updates project and global databases.
tags: [devlog, writing]
---

# Dev Journal — 开发日志

从 git history 生成引流文章。**讲故事，不讲代码。**

## 架构

```
dev_docs/
├── articles/
│   ├── 2026-06-26-xxx.md              ← 公开版
│   └── internal/
│       └── 2026-06-26-xxx.md          ← 内部版（gitignore）
├── images/                               ← 配图（随 git 同步）
├── .drafts/                              ← 草稿（gitignore）
│   └── .shots/                          ← 截图建议（gitignore）
├── journal.db                            ← 项目数据库
└── INDEX.md
```

命令：`journal {init|push [--all|N]|series|check|status|sync|search|list|clean}`

**命令**：`journal {init|push [--all|N]|series|cover|check|status|sync|search|list|clean}`

### 1. 开发时记录
```bash
retain "对比了 A/B，选了 A 因为..."
retain "踩坑：macOS fs.watch 要加 debounce"
```

### 2. 生成草稿
```bash
journal push               # 最近 30 条
journal push 15            # 指定条数
journal push --all         # 全部（首次整理用）
journal series             # 自动分组（30+ commits 推荐）
```

### 3. 生成文章（每篇必做 6 步）

**① 写文章** → 公开版 + 内部版

**② 封面图** → 使用 baoyu-cover-image 框架：
- 分析内容 → 自动选 5 维（type/palette/rendering/text/mood）
- 构建结构化 prompt
- 调硅基流动 Qwen/Qwen-Image 出图
- 保存到 `images/{slug}-cover.png`

详见 [baoyu-cover-image 完整文档](skill://baoyu-cover-image)


**② 封面图** → 使用 baoyu-cover-image 完整框架：
1. 读取文章内容，自动选 5 维（type/palette/rendering/text/mood）
2. 用 baoyu base-prompt.md 构建完整的图文 prompt
3. 调硅基流动 Qwen/Qwen-Image 出图
4. 保存到 `images/{文件名}-cover.png`，插入文章首行

脚本：`cover-base/scripts/generate_cover.py`
自动化选择规则：`cover-base/references/auto-selection.md`
Prompt 模板：`cover-base/references/base-prompt.md`
**③ 截图建议** → 生成 `.drafts/.shots/{文件名}-suggestions.md`

**④ 提取素材** → INSERT INTO materials

**⑤ 标记 commits** → INSERT INTO processed_commits

**⑥ 同步** → `journal sync`

### 4. 串行规则
同一项目必须串行生成。不同项目可并行。

### 5. 规范变更后更新
```bash
journal check           # 检测问题
"更新开发日志"          # 逐篇修复
journal sync
```

## 公开版红线

| 类型 | 内部版 | 公开版 |
|------|--------|--------|
| API 地址 | ✅ 如实写 | ❌ "调了一个 API" |
| SDK 代码 | ✅ 如实写 | ❌ "实例化了 SDK" |
| 具体模型 | ✅ 如实写 | ❌ "某款模型" |
| 配置参数 | ✅ 如实写 | ❌ "调了个参数" |

## 自检
- [ ] 无 API 端点、SDK 名、模型名、代码块、架构细节
- [ ] 标题无夸大、无引流诱导
