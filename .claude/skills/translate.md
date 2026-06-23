---
name: translate
description: Incremental bilingual translation — sync, detect changed Chinese posts, and translate to English
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
---

# Incremental Translation Skill

Translate new or modified Chinese WLAN technical posts to English. Only files with
changes since last translation are processed — unchanged files are skipped.

## Workflow

### Step 1: Sync

Run sync to copy content from Obsidian vault into Hugo:

```bash
bash scripts/sync.sh --force
```

### Step 2: Detect changed files

```bash
uv run python scripts/translate.py --detect
```

This outputs JSON like:
```json
[
  {"rel": "dive-into-wlan/phy-layer/VHT协议精读.md", "reason": "modified"},
  {"rel": "dive-into-wlan/mac-layer/new-post.md", "reason": "new"}
]
```

If the output says "All files up to date", report that and stop.

If files need translation, tell the user how many (new vs modified) and proceed to Step 3.

### Step 3: Translate each file

For each file in the detection list, do the following:

1. **Read the source file** from `hugo/content.zh/posts/<rel>`
2. **Extract frontmatter**: The YAML block between `---` delimiters at the top. Parse it to get `title`, `date`, `tags`, `categories`, `slug`, etc.
3. **Identify protected blocks** and mentally note them:
   - Fenced code blocks: ` ```...``` `
   - Math blocks: `$$...$$`
   - Inline math: `$...$`
   - Inline code: `` `...` ``
   - HTML comments: `<!-- ... -->`
4. **Translate the body text** from Chinese to English, following these rules:
   - Output ONLY the translated Markdown — no chat, no explanations
   - Preserve ALL Markdown formatting exactly (headers, lists, links, emphasis, tables)
   - NEVER translate or modify anything inside: `` ```...``` ``, `$$...$$`, `$...$`, `` `...` ``, `<!-- ... -->`
   - NEVER modify URLs, image paths, or link references
   - Use the standard IEEE/WLAN terminology from the glossary below
   - Keep proper nouns (802.11ax, OFDM, MIMO, etc.) as-is
   - Translate H1 headings: "X 协议精读" → "X Protocol Deep Dive"
   - Paragraph count must match source paragraph count
   - Translate naturally for a technical English-speaking audience — prefer concise, direct style
5. **Build the translated file** with frontmatter:
   ```yaml
   ---
   title: "<translated title>"
   date: <same as source>
   lastmod: <same as source>
   tags: <same as source>
   categories: <same as source>
   slug: <same as source>
   type: docs
   BookToC: true
   ---
   ```
   The body is the translated Markdown.
6. **Write the translated file** to `hugo/content.en/posts/<rel>` — preserve the same relative path (including subdirectories)
7. **Fix asset paths for EN depth**: EN pages live under `/en/posts/`, one level deeper than ZH pages. After writing the translated file, add one more `../` to asset paths:
   ```bash
   sed -i 's|\(\.\./\)\+assets/|../&|g' hugo/content.en/posts/<rel>
   ```
   Example: `../../../../assets/` (ZH) → `../../../../../assets/` (EN)

### Step 4: Mark translations as done

After ALL files are translated, run:

```bash
uv run python scripts/translate.py --mark-done <rel-path-1> <rel-path-2> ...
```

This updates the cache so these files won't be re-translated next time.

### Step 5: Report

Tell the user:
- How many files were translated
- Suggest running `bash scripts/publish.sh --no-push` to build and preview locally

## WLAN Terminology Glossary

When translating, use these standard English equivalents. Keep acronyms in ALL CAPS.

### Protocol & Standards
| Chinese | English |
|---------|---------|
| 协议精读 | Protocol Deep Dive |
| 物理层 | PHY (Physical Layer) |
| 媒体接入控制层 | MAC (Medium Access Control) Layer |
| 正交频分复用 | OFDM |
| 多入多出 | MIMO |
| 波束成形 | Beamforming |
| 空时分组码 | STBC (Space-Time Block Code) |
| 低密度奇偶校验 | LDPC |
| 调制与编码策略 | MCS (Modulation and Coding Scheme) |
| 前导码 | Preamble |
| 导频 | Pilot |
| 保护间隔 | Guard Interval (GI) |
| 循环前缀 | Cyclic Prefix (CP) |

### PPDU & Frame Structure
| Chinese | English |
|---------|---------|
| 物理层协议数据单元 | PPDU (PLCP Protocol Data Unit) |
| 传统短训练字段 | L-STF (Legacy Short Training Field) |
| 传统长训练字段 | L-LTF (Legacy Long Training Field) |
| 传统信号字段 | L-SIG (Legacy Signal Field) |
| 高效信号字段 | HE-SIG (High Efficiency Signal Field) |
| 甚高吞吐量 | VHT (Very High Throughput) |
| 高吞吐量 | HT (High Throughput) |
| 非高吞吐量 | NON-HT |

### 802.11 Standards
| Chinese | English |
|---------|---------|
| 802.11b 协议 | 802.11b Standard |
| 802.11a/g 协议 | 802.11a/g Standard |
| 802.11n 协议 | 802.11n (HT) Standard |
| 802.11ac 协议 | 802.11ac (VHT) Standard |
| 802.11ax 协议 | 802.11ax (HE) Standard |
| 802.11be 协议 | 802.11be (EHT) Standard |

### Channel & RF
| Chinese | English |
|---------|---------|
| 信道估计 | Channel Estimation |
| 信道均衡 | Channel Equalization |
| 频偏估计 | Frequency Offset Estimation |
| 采样率频偏 | SFO (Sampling Frequency Offset) |
| 载波频率偏移 | CFO (Carrier Frequency Offset) |
| 信噪比 | SNR (Signal-to-Noise Ratio) |
| 误差向量幅度 | EVM (Error Vector Magnitude) |
| 接收灵敏度 | Receiver Sensitivity |
| 邻道干扰 | ACI (Adjacent Channel Interference) |
| 瑞利衰落 | Rayleigh Fading |
| 莱斯衰落 | Rician Fading |
| 多径效应 | Multipath Effect |

### Algorithms & Techniques
| Chinese | English |
|---------|---------|
| 快速傅里叶变换 | FFT |
| 逆快速傅里叶变换 | IFFT |
| 最小均方误差 | MMSE (Minimum Mean Square Error) |
| 最大似然估计 | MLE (Maximum Likelihood Estimation) |
| 迫零均衡 | ZF (Zero Forcing) Equalization |
| 最小方差无失真响应 | MVDR |
| 线性约束最小方差 | LCMV |

### General
| Chinese | English |
|---------|---------|
| 子载波 | Subcarrier |
| 带宽 | Bandwidth |
| 吞吐量 | Throughput |
| 鲁棒性 | Robustness |
| 星座图 | Constellation Diagram |
| 编码速率 | Code Rate |
| 空间流 | Spatial Stream |
| 分组检测 | Packet Detection |
| 自动增益控制 | AGC (Automatic Gain Control) |
| 精频偏估计 | Fine Frequency Offset Estimation |
| 粗频偏估计 | Coarse Frequency Offset Estimation |

## Important Notes

- The skill operates on `hugo/content.zh/posts/` and `hugo/content.en/posts/` (after sync), NOT directly on `obsidian-vault/posts/`
- Always run sync first so the detection works on the latest content
- The `--mark-done` step is critical — without it, files will be re-translated every time
- Cache is stored in `scripts/.translate_cache/` (gitignored)
- If the user says "translate everything" or "force translate", run `translate.py --reset` first to clear cache, then proceed
