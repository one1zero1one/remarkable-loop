#!/bin/sh
# remarkable-loop installer
# Sets up dependencies, directories, and rmapi binary.
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

# 3. Install system dependencies
echo "[3/5] Checking system dependencies..."

install_python_deps() {
    # pip deps needed: rmscene, reportlab, pdfrw, weasyprint (or system package)
    local MISSING=""
    python3 -c "import rmscene" 2>/dev/null || MISSING="$MISSING rmscene"
    python3 -c "import reportlab" 2>/dev/null || MISSING="$MISSING reportlab"
    python3 -c "import pdfrw" 2>/dev/null || MISSING="$MISSING pdfrw"
    python3 -c "import markdown" 2>/dev/null || MISSING="$MISSING markdown"

    if [ -n "$MISSING" ]; then
        echo "  Installing Python packages:$MISSING"
        pip3 install --break-system-packages $MISSING 2>/dev/null || \
        pip3 install $MISSING 2>/dev/null || \
        echo "  Warning: Failed to install some Python packages. Install manually: pip install$MISSING"
    fi
}

OS="$(uname -s)"
if [ "$OS" = "Darwin" ]; then
    # macOS
    if command -v brew >/dev/null 2>&1; then
        command -v weasyprint >/dev/null 2>&1 || { echo "  Installing weasyprint..."; brew install weasyprint; }
        command -v pdftoppm >/dev/null 2>&1 || { echo "  Installing poppler..."; brew install poppler; }
    else
        echo "  Warning: Homebrew not found. Install weasyprint and poppler manually."
    fi
    install_python_deps

elif [ "$OS" = "Linux" ]; then
    if command -v apk >/dev/null 2>&1; then
        # Alpine
        for pkg in weasyprint py3-markdown py3-pygments font-noto poppler-utils cairo-dev freetype-dev; do
            apk info -e "$pkg" >/dev/null 2>&1 || { echo "  Installing $pkg..."; apk add --no-cache "$pkg" 2>/dev/null; }
        done
        install_python_deps
    elif command -v apt-get >/dev/null 2>&1; then
        # Debian/Ubuntu
        dpkg -l weasyprint >/dev/null 2>&1 || { echo "  Installing weasyprint..."; sudo apt-get install -y weasyprint; }
        dpkg -l poppler-utils >/dev/null 2>&1 || { echo "  Installing poppler-utils..."; sudo apt-get install -y poppler-utils; }
        dpkg -l fonts-noto >/dev/null 2>&1 || { echo "  Installing fonts-noto..."; sudo apt-get install -y fonts-noto; }
        install_python_deps
    else
        echo "  Unknown Linux distro. Install manually: weasyprint, poppler-utils, fonts-noto"
        install_python_deps
    fi
fi

# Check weasyprint
if ! command -v weasyprint >/dev/null 2>&1 && ! python3 -c "from weasyprint import HTML" 2>/dev/null; then
    echo "  Warning: weasyprint not found. PDF conversion won't work."
fi

# 4. Install rmapi
echo "[4/5] Checking rmapi..."
if command -v rmapi >/dev/null 2>&1; then
    echo "  rmapi already in PATH: $(which rmapi)"
elif [ -f "$REMARKABLE_LOOP_HOME/bin/rmapi" ]; then
    echo "  rmapi already at $REMARKABLE_LOOP_HOME/bin/rmapi"
else
    ARCH="$(uname -m)"
    case "$ARCH" in
        x86_64|amd64) RMAPI_ARCH="amd64" ;;
        aarch64|arm64) RMAPI_ARCH="arm64" ;;
        *) echo "  Error: Unsupported architecture $ARCH"; exit 1 ;;
    esac

    RMAPI_URL="https://github.com/ddvk/rmapi/releases/download/${RMAPI_VERSION}/rmapi-linux-${RMAPI_ARCH}.tar.gz"
    if [ "$OS" = "Darwin" ]; then
        RMAPI_URL="https://github.com/ddvk/rmapi/releases/download/${RMAPI_VERSION}/rmapi-macos-${RMAPI_ARCH}.tar.gz"
    fi

    echo "  Downloading rmapi ${RMAPI_VERSION}..."
    TMPDIR=$(mktemp -d)
    curl -fsSL "$RMAPI_URL" -o "$TMPDIR/rmapi.tar.gz"
    tar xzf "$TMPDIR/rmapi.tar.gz" -C "$TMPDIR"
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
