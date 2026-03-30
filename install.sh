#!/bin/sh
# remarkable-loop installer
# Sets up directories, config, rmapi binary, and poppler.
# Python deps are managed by uv via inline script metadata — no pip needed.
# Run from the repo root: ./install.sh

set -e

REMARKABLE_LOOP_HOME="${REMARKABLE_LOOP_HOME:-$HOME/.remarkable-loop}"
RMAPI_VERSION="v0.0.32"

echo "=== remarkable-loop installer ==="
echo "Home: $REMARKABLE_LOOP_HOME"
echo ""

# 1. Create directories
echo "[1/5] Creating directories..."
mkdir -p "$REMARKABLE_LOOP_HOME/plans" "$REMARKABLE_LOOP_HOME/raw" "$REMARKABLE_LOOP_HOME/bin"

# 2. Copy config if not exists
if [ ! -f "$REMARKABLE_LOOP_HOME/config.yaml" ]; then
    echo "[2/5] Creating config..."
    cp "$(dirname "$0")/config.example.yaml" "$REMARKABLE_LOOP_HOME/config.yaml"
else
    echo "[2/5] Config already exists, skipping."
fi

# 3. Check prerequisites
echo "[3/5] Checking prerequisites..."

# uv is required — Python deps are declared inline in each script
if ! command -v uv >/dev/null 2>&1; then
    echo "  Error: uv is required but not found."
    echo "  Install: curl -LsSf https://astral.sh/uv/install.sh | sh"
    exit 1
fi
echo "  uv: $(uv --version)"

# poppler (pdftoppm) for rendering annotation pages to images
OS="$(uname -s)"
if ! command -v pdftoppm >/dev/null 2>&1; then
    if [ "$OS" = "Darwin" ] && command -v brew >/dev/null 2>&1; then
        echo "  Installing poppler..."
        brew install poppler
    elif [ "$OS" = "Linux" ] && command -v apt-get >/dev/null 2>&1; then
        echo "  Installing poppler-utils..."
        sudo apt-get install -y poppler-utils
    elif [ "$OS" = "Linux" ] && command -v apk >/dev/null 2>&1; then
        echo "  Installing poppler-utils..."
        apk add --no-cache poppler-utils
    else
        echo "  Warning: pdftoppm (poppler) not found. Install it manually for annotation rendering."
    fi
fi

# 4. Install rmapi
echo "[4/5] Checking rmapi..."
if command -v rmapi >/dev/null 2>&1; then
    echo "  rmapi already in PATH: $(which rmapi)"
elif [ -f "$REMARKABLE_LOOP_HOME/bin/rmapi" ]; then
    echo "  rmapi already at $REMARKABLE_LOOP_HOME/bin/rmapi"
else
    ARCH="$(uname -m)"
    TMPDIR=$(mktemp -d)

    if [ "$OS" = "Darwin" ]; then
        case "$ARCH" in
            x86_64|amd64) RMAPI_LABEL="macos-intel" ;;
            aarch64|arm64) RMAPI_LABEL="macos-arm64" ;;
            *) echo "  Error: Unsupported architecture $ARCH"; exit 1 ;;
        esac
        RMAPI_URL="https://github.com/ddvk/rmapi/releases/download/${RMAPI_VERSION}/rmapi-${RMAPI_LABEL}.zip"
        echo "  Downloading rmapi ${RMAPI_VERSION}..."
        curl -fsSL "$RMAPI_URL" -o "$TMPDIR/rmapi.zip"
        unzip -q "$TMPDIR/rmapi.zip" -d "$TMPDIR"
    else
        case "$ARCH" in
            x86_64|amd64) RMAPI_LABEL="linux-amd64" ;;
            aarch64|arm64) RMAPI_LABEL="linux-arm64" ;;
            *) echo "  Error: Unsupported architecture $ARCH"; exit 1 ;;
        esac
        RMAPI_URL="https://github.com/ddvk/rmapi/releases/download/${RMAPI_VERSION}/rmapi-${RMAPI_LABEL}.tar.gz"
        echo "  Downloading rmapi ${RMAPI_VERSION}..."
        curl -fsSL "$RMAPI_URL" -o "$TMPDIR/rmapi.tar.gz"
        tar xzf "$TMPDIR/rmapi.tar.gz" -C "$TMPDIR"
    fi

    mv "$TMPDIR/rmapi" "$REMARKABLE_LOOP_HOME/bin/rmapi"
    chmod +x "$REMARKABLE_LOOP_HOME/bin/rmapi"
    rm -rf "$TMPDIR"
    echo "  Installed rmapi to $REMARKABLE_LOOP_HOME/bin/rmapi"
fi

# 5. Auth check
echo "[5/5] Checking authentication..."
RMAPI_BIN="$(command -v rmapi 2>/dev/null || echo "$REMARKABLE_LOOP_HOME/bin/rmapi")"
if [ -f "$REMARKABLE_LOOP_HOME/.rmapi" ]; then
    echo "  Auth token found."
else
    echo ""
    echo "  rmapi is not authenticated yet."
    echo "  To authenticate:"
    echo "    1. Go to https://my.remarkable.com/device/desktop/connect"
    echo "    2. Log in and copy the 8-character code"
    echo "    3. Run: RMAPI_CONFIG=$REMARKABLE_LOOP_HOME/.rmapi $RMAPI_BIN"
    echo "    4. Paste the code when prompted"
fi

echo ""
echo "=== Done ==="
echo ""
echo "Usage:"
echo "  bin/md2pdf.py <file.md>              # Convert markdown to PDF"
echo "  bin/remarkable-push.sh <file.pdf>    # Push PDF to reMarkable"
echo "  bin/remarkable-pull.sh <doc-name>    # Pull annotations back"
echo ""
echo "Or use the /remarkable-loop skill in Claude Code."
