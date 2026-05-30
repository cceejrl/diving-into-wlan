---
name: publish
description: Full publish pipeline — translate changed posts, then build, commit, and push to GitHub
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
---

# Publish Skill

Orchestrate the full bilingual blog publish pipeline:

1. Run the **translate** skill to pick up any new or modified posts
2. Run `publish.sh` to build and push to GitHub (which auto-deploys via Actions)

## Workflow

### Step 1: Invoke the translate skill

Call the `translate` skill to handle incremental translation:

```
Skill("translate")
```

This syncs content, detects changed files, translates them, and updates the cache. Unchanged files are skipped. If nothing needs translation, it reports "All files up to date" and exits cleanly.

### Step 2: Publish

Run the publish script:

```bash
bash scripts/publish.sh
```

If the user said `publish --no-push`, use `bash scripts/publish.sh --no-push` instead (build only, skip git push). This is useful for local preview.

### Step 3: Report

Summarize what happened:
- How many files were translated (from the translate step)
- Whether the build succeeded
- Whether changes were pushed to GitHub
- The GitHub Pages URL where the site will be live
