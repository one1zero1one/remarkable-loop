#!/usr/bin/env python3
"""Convert markdown to PDF optimized for reMarkable e-ink display.

Usage:
    md2pdf.py <input.md> [output.pdf]

If output is omitted, writes to $REMARKABLE_LOOP_HOME/plans/<basename>.pdf
(default: ~/.remarkable-loop/plans/)

Environment:
    REMARKABLE_LOOP_HOME  Base directory (default: ~/.remarkable-loop)
"""

import os
import sys
from pathlib import Path

REMARKABLE_LOOP_HOME = Path(os.getenv("REMARKABLE_LOOP_HOME", Path.home() / ".remarkable-loop"))
STYLE_PATH = Path(__file__).parent.parent / "styles" / "remarkable.css"
DEFAULT_OUTPUT_DIR = REMARKABLE_LOOP_HOME / "plans"


def convert(md_path: str, pdf_path: str | None = None) -> str:
    """Convert markdown file to PDF. Returns output path."""
    import markdown
    from weasyprint import HTML

    md_file = Path(md_path)
    if not md_file.exists():
        print(f"Error: {md_file} not found", file=sys.stderr)
        sys.exit(1)

    if pdf_path is None:
        DEFAULT_OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
        pdf_path = str(DEFAULT_OUTPUT_DIR / f"{md_file.stem}.pdf")

    md_text = md_file.read_text(encoding="utf-8")

    # Strip YAML frontmatter if present
    if md_text.startswith("---"):
        parts = md_text.split("---", 2)
        if len(parts) >= 3:
            md_text = parts[2]

    html_body = markdown.markdown(
        md_text,
        extensions=["tables", "fenced_code", "codehilite", "toc", "md_in_html"],
    )

    css = ""
    if STYLE_PATH.exists():
        css = STYLE_PATH.read_text(encoding="utf-8")

    full_html = f"""<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>{css}</style>
</head>
<body>
{html_body}
</body>
</html>"""

    HTML(string=full_html).write_pdf(pdf_path)
    print(pdf_path)
    return pdf_path


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(__doc__.strip(), file=sys.stderr)
        sys.exit(1)

    input_path = sys.argv[1]
    output_path = sys.argv[2] if len(sys.argv) > 2 else None
    convert(input_path, output_path)
