# remarkable-loop

Feedback loop between Claude Code and reMarkable tablet.

Claude writes markdown → converts to PDF → pushes to reMarkable Cloud → human annotates → pulls annotations back → Claude reads with vision → revises → repeat.

## Setup

```bash
./install.sh
```

## Discovery

```bash
# Check auth
RMAPI_CONFIG=~/.remarkable-loop/.rmapi rmapi ls /Plans/

# Check deps
which rmapi && which weasyprint && python3 -c "import rmscene; print('ok')"

# List local PDFs
ls ~/.remarkable-loop/plans/

# List what's on the tablet
RMAPI_CONFIG=~/.remarkable-loop/.rmapi rmapi ls /Plans/
```

## Paths

Everything lives under `~/.remarkable-loop/` (override with `REMARKABLE_LOOP_HOME`):

| What | Where |
|------|-------|
| Auth token | `~/.remarkable-loop/.rmapi` |
| PDFs | `~/.remarkable-loop/plans/` |
| Temp downloads | `~/.remarkable-loop/raw/` |
| Config | `~/.remarkable-loop/config.yaml` |

## Usage

The `/remarkable-loop` skill handles everything. Say "send to remarkable" or "pull my annotations".

Manual:
```bash
bin/md2pdf.py path/to/plan.md                    # convert
bin/remarkable-push.sh ~/.remarkable-loop/plans/plan.pdf  # push
bin/remarkable-pull.sh plan                       # pull + render
```
