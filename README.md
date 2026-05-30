# Diving into WLAN: An Algo Perspective

WLAN 技术博客，中英文双语。Markdown 源文件在 Obsidian 中编辑，通过 Hugo + GitHub Pages 自动发布为静态网站。

## 目录结构

```text
./
├── obsidian-vault/              # Obsidian 写作库（唯一编辑区）
│   ├── .obsidian/               # Obsidian 配置（跨机器共享）
│   ├── posts/                   # 中文原文（手写源）
│   │   └── dive-into-wlan/
│   │       ├── phy-layer/       # 物理层
│   │       ├── mac-layer/       # MAC 层
│   │       └── algo/            # 算法
│   ├── assets/                  # 图片、附件
│   └── templates/               # Obsidian 文章模板
│
├── code/                        # 独立代码库
│   ├── matlab/                  # MATLAB 实现
│   ├── cpp/                     # C++ 实现
│   ├── python/                  # Python 实现
│   └── README.md
│
├── hugo/                        # Hugo 网站项目
│   ├── content.zh/posts/   ←── sync.sh 从 obsidian-vault/posts/ 拷贝
│   ├── content.en/posts/   ←── translate skill 生成
│   ├── static/{code,assets}/ ←── sync.sh 从 code/ 和 assets/ 拷贝
│   ├── themes/hugo-book/       # git submodule
│   └── hugo.yaml
│
├── scripts/
│   ├── setup.sh                 # 新机器一键初始化
│   ├── sync.sh                  # 同步 Obsidian/code → Hugo
│   ├── translate.py             # 增量翻译检测 + 缓存管理
│   ├── translate.sh             # 翻译入口（提示使用 /translate skill）
│   ├── publish.sh               # 构建 + 推送
│   └── glossary.md              # WLAN 术语对照表
│
├── .claude/skills/
│   ├── translate.md             # 翻译 skill
│   └── publish.md               # 发布 skill
├── .github/workflows/deploy.yml # CI 自动部署
└── .gitignore
```

## 设计原则

1. **写作与发布分离**：Obsidian Vault 是唯一编辑区，网站项目 (`hugo/`) 为生成物
2. **增量翻译**：MD5 缓存检测变更，仅翻译新增或修改的文章，不改动的不翻译
3. **跨机器无感**：`bash scripts/setup.sh` 一键初始化新电脑，主题通过 git submodule 管理
4. **Claude Code 驱动**：翻译 (`/translate`) 和发布 (`/publish`) 通过 skill 在对话中完成
5. **数学公式**：Hugo-Book 主题内置 KaTeX，`$...$` 行内 + `$$...$$` 块级

## 快速开始

### 新机器初始化

```bash
# 1. 克隆（含主题子模块）
git clone --recurse-submodules <repo-url>
cd diving-into-wlan

# 2. 一键安装环境（Hugo + uv + 子模块）
bash scripts/setup.sh
```

### 日常写作

```bash
# Obsidian 中打开 obsidian-vault/，编辑 posts/ 目录下的文章
# 正常 git commit / git push 即可，不触发翻译或构建
```

### 发布上线

在 Claude Code 中直接说：

| 命令 | 效果 |
|------|------|
| `translate` | 增量翻译（仅翻译新增/修改的文章） |
| `publish` | 完整发布：翻译 → 构建 → 推送到 GitHub |
| `publish --no-push` | 构建预览，不推送 |

### 本地预览

```bash
cd hugo && hugo server --buildDrafts
# 访问 http://localhost:1313
```

### 脚本参考

```bash
bash scripts/sync.sh --force       # 同步 Obsidian → Hugo
bash scripts/translate.sh          # 检测待翻译文件
bash scripts/publish.sh --no-push  # 构建（不推送）
uv run python scripts/translate.py --status  # 查看翻译覆盖率
```

## 技术栈

- **编辑器**：Obsidian
- **静态站点**：Hugo + Hugo-Book 主题（git submodule）
- **翻译**：Claude Code skill（底层 DeepSeek API，术语表保证一致性）
- **数学渲染**：KaTeX
- **托管**：GitHub Pages（via Actions）
- **Python 工具链**：uv 管理
