#!/bin/sh
# Pull an annotated document from reMarkable Cloud and render annotations to PDF.
#
# Usage:
#   remarkable-pull.sh <document-name>
#
# Environment:
#   REMARKABLE_LOOP_HOME  Base directory (default: ~/.remarkable-loop)
#   RMAPI_CONFIG          Auth token path (default: $REMARKABLE_LOOP_HOME/.rmapi)

set -e

REMARKABLE_LOOP_HOME="${REMARKABLE_LOOP_HOME:-$HOME/.remarkable-loop}"
RMAPI="${RMAPI:-$(command -v rmapi 2>/dev/null || echo "$REMARKABLE_LOOP_HOME/bin/rmapi")}"
export RMAPI_CONFIG="${RMAPI_CONFIG:-$REMARKABLE_LOOP_HOME/.rmapi}"
RENDERER="$(dirname "$0")/render_annotations.py"
REMOTE_FOLDER="/Plans"
OUTPUT_DIR="$REMARKABLE_LOOP_HOME/plans"
RAW_DIR="$REMARKABLE_LOOP_HOME/raw"

if [ -z "$1" ]; then
    echo "Usage: remarkable-pull.sh <document-name>" >&2
    exit 1
fi

DOC_NAME="$1"

if [ ! -f "$RMAPI" ]; then
    echo "Error: rmapi not found. Run install.sh or set RMAPI env var." >&2
    exit 1
fi

mkdir -p "$RAW_DIR" "$OUTPUT_DIR"

# Download raw archive
echo "Pulling $REMOTE_FOLDER/$DOC_NAME from reMarkable..."
cd "$RAW_DIR"
$RMAPI get "$REMOTE_FOLDER/$DOC_NAME"

# Find the downloaded file
RAW_FILE=""
for ext in rmdoc zip; do
    if [ -f "$RAW_DIR/${DOC_NAME}.${ext}" ]; then
        RAW_FILE="$RAW_DIR/${DOC_NAME}.${ext}"
        break
    fi
done

if [ -z "$RAW_FILE" ]; then
    echo "Error: No downloaded file found for $DOC_NAME" >&2
    ls -la "$RAW_DIR" >&2
    exit 1
fi

# Render annotations onto base PDF
echo "Rendering annotations..."
python3 "$RENDERER" "$RAW_FILE" "$OUTPUT_DIR/${DOC_NAME}.pdf"

# Clean up
rm -f "$RAW_FILE"

echo "Done: $OUTPUT_DIR/${DOC_NAME}.pdf"
