---
name: pre-push-check
description: Run before pushing to GitHub — validates branch, CI config, content integrity, and build
allowed-tools: Bash, Read, Grep
---

# Pre-Push Check

Run this skill before pushing to catch common issues that break CI or the live site.

## Checks

### 1. Branch vs CI trigger match

Verify the deploy workflow's branch matches the current git branch:

```bash
echo "Current branch:" && git branch --show-current && echo "CI triggers on:" && grep "branches:" .github/workflows/deploy.yml
```

Mismatch = CI won't run. Fix by aligning one to the other.

### 2. Section navigation integrity

Verify `_index.md` files exist for every content section. These define the sidebar hierarchy in Hugo-Book. Without them, that section's navigation disappears.

```bash
# Find directories in content.zh/posts that lack _index.md
find hugo/content.zh/posts -type d -mindepth 1 | while read dir; do
  [ -f "$dir/_index.md" ] || echo "MISSING: $dir/_index.md"
done
# Same for English
find hugo/content.en/posts -type d -mindepth 1 | while read dir; do
  [ -f "$dir/_index.md" ] || echo "MISSING: $dir/_index.md"
done
```

If any are missing, create them in `obsidian-vault/posts/` (the source of truth) with appropriate frontmatter. Run `bash scripts/sync.sh --force` after.

### 3. Config sanity

Quick configuration checks:

```bash
# Language switcher should be visible on all pages
grep "BookTranslatedOnly:" hugo/hugo.yaml

# Math rendering (KaTeX) should load globally
[ -f "hugo/layouts/partials/docs/inject/body.html" ] && echo "KaTeX inject OK" || echo "MISSING: KaTeX global inject"

# baseURL should match the actual GitHub Pages URL
grep "baseURL:" hugo/hugo.yaml
```

### 4. Build test

Do a clean production build (no drafts) to catch any errors:

```bash
cd hugo && hugo --minify --cleanDestinationDir 2>&1
```

If this fails, fix before pushing. Common causes:
- Missing `_index.md` in a section
- Broken frontmatter (unclosed quotes, bad YAML)
- Referenced files that don't exist

### 5. Translation status

Check if there are untranslated posts:

```bash
uv run python scripts/translate.py --detect
```

Untranslated posts won't break the build, but the English sidebar will be incomplete. Is this intentional?

### 6. Submodule check

```bash
git submodule status | grep -q "^-" && echo "WARNING: submodule not initialized" || echo "Submodule OK"
```

If the submodule shows `-` (not initialized), run `git submodule update --init`.

## Pass / Fail

- All 6 checks pass → safe to push
- Check 1 fails → **BLOCKER**, CI won't run
- Check 2 fails → **BLOCKER**, sidebar navigation broken
- Check 3 or 4 fails → **BLOCKER**, site may not render
- Check 5 fails → warning only (no English sidebar until translated)
- Check 6 fails → **BLOCKER**, theme missing in CI
