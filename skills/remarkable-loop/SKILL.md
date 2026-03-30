---
name: remarkable-loop
description: Use when user says "send to remarkable", "push to remarkable", "pull my annotations", "put this on my tablet", "get my notes", or after creating a spec/plan that should be reviewed on the reMarkable tablet. Handles the full feedback loop — push, pull, versioning, cleanup.
---

# reMarkable Feedback Loop

Iterate on documents between Claude and a reMarkable tablet. Claude produces a document, it goes to the tablet as PDF, the human annotates (text + drawings), annotations come back, Claude revises, repeat.

## Setup

All paths resolve from `REMARKABLE_LOOP_HOME` (default: `~/.remarkable-loop`).

```bash
REMARKABLE_LOOP_HOME="${REMARKABLE_LOOP_HOME:-$HOME/.remarkable-loop}"
```

Find the plugin's `bin/` directory by locating this skill file's parent:
- Plugin install: `~/.claude/plugins/cache/.../remarkable-loop/bin/`
- Local clone: wherever the repo is checked out

To find bin path at runtime:
```bash
# Find where the plugin is installed
PLUGIN_DIR=$(dirname "$(dirname "$(find ~/.claude/plugins -path '*/remarkable-loop/skills/remarkable-loop/SKILL.md' 2>/dev/null | head -1)")" 2>/dev/null)
# Or if working in the repo directly
PLUGIN_DIR=$(git -C "$(dirname "$0")" rev-parse --show-toplevel 2>/dev/null)
```

## Auth check

Before any push or pull:
```bash
RMAPI_CONFIG="${REMARKABLE_LOOP_HOME:-$HOME/.remarkable-loop}/.rmapi" rmapi ls /Plans/ 2>&1
```

If not authenticated, tell the user:
> Run `! RMAPI_CONFIG=~/.remarkable-loop/.rmapi rmapi` and enter the code from https://my.remarkable.com/device/desktop/connect

## Source documents

The skill knows where superpowers puts documents:
- **Design specs**: `{project}/docs/superpowers/specs/YYYY-MM-DD-{topic}-design.md`
- **Implementation plans**: `{project}/docs/superpowers/plans/YYYY-MM-DD-{topic}.md`

But it works with **any markdown file**.

## The cycle

### 1. PUSH — send document to tablet

```bash
# Convert markdown to e-ink-optimized PDF
{plugin_bin}/md2pdf.py <markdown-file>

# Upload to reMarkable Cloud
{plugin_bin}/remarkable-push.sh <pdf-path>
```

Tell the user: "Pushed `<name>` to reMarkable. Should appear on your tablet shortly."

### 2. WAIT — human reads and annotates on tablet

Nothing to do.

### 3. PULL — get annotations back

```bash
# Download and render annotations
{plugin_bin}/remarkable-pull.sh <document-name>

# Render ALL pages to PNG for vision
pdftoppm -png -r 200 ~/.remarkable-loop/plans/<name>.pdf /tmp/remarkable-review
```

Then **view EVERY page** using Read on each `/tmp/remarkable-review-*.png`.

You are a vision model. You SEE handwriting, diagrams, arrows, circles, sketches. Do not skip pages. Describe what you see.

### 4. REVISE — Claude writes next version

Based on annotations, write the revised markdown:
- First version: `topic-design.md` (no suffix)
- Revision: `topic-design-v2.md`
- Next: `topic-design-v3.md`

### 5. HOUSEKEEPING — clean up previous version

After pushing a new version, always ask:

> "We're now on v{n} of `<topic>`. Remove v{n-1} from reMarkable and local PDF folder?"

If user confirms:
```bash
RMAPI_CONFIG=~/.remarkable-loop/.rmapi rmapi rm /Plans/<old-name>
rm ~/.remarkable-loop/plans/<old-name>.pdf
```

### 6. REPEAT

## Rules

- Markdown is the source of truth. PDFs are derivatives.
- PDFs live in `~/.remarkable-loop/plans/`, never in the vault.
- Annotated PDF overwrites clean PDF at the same path.
- Never push a duplicate name without versioning.
- Always view all pages when pulling. The human draws diagrams.
- Track which version we're on. State it clearly.
