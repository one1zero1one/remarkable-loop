#!/bin/sh
# Push a PDF to reMarkable Cloud under /Plans/
#
# Usage:
#   remarkable-push.sh <pdf-file>
#
# Environment:
#   REMARKABLE_LOOP_HOME  Base directory (default: ~/.remarkable-loop)
#   RMAPI_CONFIG          Auth token path (default: $REMARKABLE_LOOP_HOME/.rmapi)

set -e

REMARKABLE_LOOP_HOME="${REMARKABLE_LOOP_HOME:-$HOME/.remarkable-loop}"
RMAPI="${RMAPI:-$(command -v rmapi 2>/dev/null || echo "$REMARKABLE_LOOP_HOME/bin/rmapi")}"
export RMAPI_CONFIG="${RMAPI_CONFIG:-$REMARKABLE_LOOP_HOME/.rmapi}"
REMOTE_FOLDER="/Plans"

if [ -z "$1" ]; then
    echo "Usage: remarkable-push.sh <pdf-file>" >&2
    exit 1
fi

PDF_FILE="$1"

if [ ! -f "$PDF_FILE" ]; then
    echo "Error: $PDF_FILE not found" >&2
    exit 1
fi

if [ ! -f "$RMAPI" ]; then
    echo "Error: rmapi not found. Run install.sh or set RMAPI env var." >&2
    exit 1
fi

if [ ! -f "$RMAPI_CONFIG" ]; then
    echo "Error: rmapi not authenticated. Run: RMAPI_CONFIG=$RMAPI_CONFIG $RMAPI" >&2
    exit 1
fi

# Ensure /Plans/ folder exists on reMarkable
$RMAPI mkdir "$REMOTE_FOLDER" 2>/dev/null || true

# Upload
echo "Pushing $(basename "$PDF_FILE") to reMarkable $REMOTE_FOLDER/"
$RMAPI put "$PDF_FILE" "$REMOTE_FOLDER/"
echo "Done."
