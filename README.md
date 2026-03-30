# remarkable-loop

A feedback loop between [Claude Code](https://claude.ai/code) and the [reMarkable](https://remarkable.com) tablet.

Claude writes a document. It appears on your tablet as a PDF. You read and annotate with a pen. The annotations come back. Claude reads them with vision — handwriting, diagrams, arrows, everything. Claude revises. Repeat.

## How it works

```
Claude writes plan.md
       |
  md2pdf.py (markdown -> e-ink PDF)
       |
  remarkable-push.sh (upload to reMarkable Cloud)
       |
  You read + annotate on tablet
       |
  remarkable-pull.sh (download + render annotations)
       |
  Claude reads annotated pages (vision model)
       |
  Claude writes plan-v2.md -> repeat
```

## Install

```bash
git clone https://github.com/one1zero1one/remarkable-loop.git
cd remarkable-loop
./install.sh
```

The installer:
- Creates `~/.remarkable-loop/` with config and directories
- Downloads the [rmapi](https://github.com/ddvk/rmapi) binary (reMarkable Cloud CLI)
- Installs Python dependencies (weasyprint, rmscene, reportlab)
- Detects your OS (macOS, Alpine, Debian/Ubuntu)

### One-time auth

After install, authenticate with reMarkable Cloud:

1. Go to https://my.remarkable.com/device/desktop/connect
2. Copy the 8-character code
3. Run: `RMAPI_CONFIG=~/.remarkable-loop/.rmapi rmapi`
4. Paste the code

## Usage

### As a Claude Code skill

The plugin includes a `/remarkable-loop` skill. In any Claude Code session:

- **"Send this to reMarkable"** — converts markdown to PDF and uploads
- **"Pull my annotations"** — downloads annotated PDF and shows it to Claude

### Manual

```bash
# Convert markdown to reMarkable-optimized PDF
bin/md2pdf.py path/to/document.md

# Push PDF to reMarkable Cloud
bin/remarkable-push.sh ~/.remarkable-loop/plans/document.pdf

# Pull annotated version back
bin/remarkable-pull.sh document
```

## Install as Claude Code plugin

```bash
claude plugin add --from one1zero1one/remarkable-loop
```

Or manually: clone the repo and the skill at `skills/remarkable-loop/SKILL.md` will be auto-discovered when you work inside the repo directory.

## Configuration

Config lives at `~/.remarkable-loop/config.yaml` (created by `install.sh`).

Override the base directory with `REMARKABLE_LOOP_HOME`:

```bash
export REMARKABLE_LOOP_HOME=/custom/path
```

## Dependencies

| Tool | Purpose | Install |
|------|---------|---------|
| [rmapi](https://github.com/ddvk/rmapi) | reMarkable Cloud CLI | `install.sh` handles this |
| [weasyprint](https://weasyprint.org) | HTML/CSS to PDF | brew/apt/apk |
| [rmscene](https://github.com/ricklupton/rmscene) | Read reMarkable v6 annotations | pip |
| [reportlab](https://pypi.org/project/reportlab/) | Render annotations onto PDF | pip |
| [pdfrw](https://pypi.org/project/pdfrw/) | Merge annotation overlay with base PDF | pip |
| pdftoppm | Render PDF pages to PNG for vision | poppler-utils |

## How annotations work

The reMarkable stores pen strokes in a proprietary v6 `.rm` format. The standard tool (rmrl) can't read this format. This project includes `render_annotations.py` which uses [rmscene](https://github.com/ricklupton/rmscene) to parse the strokes and [reportlab](https://pypi.org/project/reportlab/) + [pdfrw](https://pypi.org/project/pdfrw/) to overlay them onto the original PDF.

## Limitations

- **reMarkable Cloud API is unofficial.** rmapi is reverse-engineered. Firmware updates can break it.
- **Annotations are images, not text.** Claude reads them with vision. No OCR.
- **Push is one-way for text.** The reMarkable can't edit markdown. It's a read-and-annotate device.

## License

MIT
