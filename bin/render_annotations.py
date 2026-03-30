#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "rmscene",
#     "reportlab",
#     "pdfrw",
# ]
# ///
"""Render reMarkable annotations from .rmdoc onto the base PDF.

Uses rmscene to read v6 scene format + reportlab/pdfrw to overlay strokes.
This replaces rmrl which cannot handle the newer .rm format.

Usage:
    render_annotations.py <input.rmdoc> [output.pdf]
"""

import io
import json
import os
import sys
import tempfile
import zipfile

import rmscene
from pdfrw import PageMerge, PdfReader, PdfWriter
from reportlab.lib.pagesizes import A4
from reportlab.pdfgen import canvas as pdfcanvas

# reMarkable display dimensions (in rm units)
RM_WIDTH = 1404
RM_HEIGHT = 1872

# A4 in points
A4_W, A4_H = A4

# Scale factors
SCALE_X = A4_W / RM_WIDTH
SCALE_Y = A4_H / RM_HEIGHT


def render(rmdoc_path: str, output_path: str | None = None) -> str:
    """Render annotations from rmdoc onto base PDF. Returns output path."""
    with zipfile.ZipFile(rmdoc_path) as z:
        names = z.namelist()

        # Find base PDF and UUID
        pdf_name = [n for n in names if n.endswith(".pdf")][0]
        uuid = pdf_name.replace(".pdf", "")

        # Find .rm annotation files
        rm_files = sorted([n for n in names if n.endswith(".rm")])

        if not rm_files:
            # No annotations — just extract the base PDF
            if output_path:
                with open(output_path, "wb") as f:
                    f.write(z.read(pdf_name))
                return output_path
            return ""

        # Read content.json for page mapping
        content_data = json.loads(z.read(uuid + ".content"))
        pages = content_data.get("cPages", {}).get("pages", [])
        page_ids = [p.get("id", "") for p in pages]

        # Extract base PDF
        tmpdir = tempfile.mkdtemp()
        base_pdf_path = os.path.join(tmpdir, "base.pdf")
        with open(base_pdf_path, "wb") as f:
            f.write(z.read(pdf_name))

        base_pdf = PdfReader(base_pdf_path)

        # Render each annotation file as overlay
        for rm_name in rm_files:
            rm_page_id = rm_name.split("/")[-1].replace(".rm", "")
            try:
                page_idx = page_ids.index(rm_page_id)
            except ValueError:
                page_idx = 0

            rm_data = z.read(rm_name)
            blocks = list(rmscene.read_blocks(io.BytesIO(rm_data)))

            overlay_buf = io.BytesIO()
            c = pdfcanvas.Canvas(overlay_buf, pagesize=A4)

            for block in blocks:
                if not (hasattr(block, "item") and hasattr(block.item, "value")):
                    continue
                line = block.item.value
                if not (hasattr(line, "points") and line.points and len(line.points) >= 2):
                    continue

                width = getattr(line, "thickness_scale", 2.0)
                c.setStrokeColorRGB(0, 0, 0)
                c.setLineWidth(max(0.5, width * SCALE_X * 0.8))

                path = c.beginPath()
                pts = line.points
                path.moveTo(pts[0].x * SCALE_X, A4_H - (pts[0].y * SCALE_Y))
                for pt in pts[1:]:
                    path.lineTo(pt.x * SCALE_X, A4_H - (pt.y * SCALE_Y))
                c.drawPath(path, stroke=1, fill=0)

            c.save()

            if page_idx < len(base_pdf.pages):
                overlay_buf.seek(0)
                overlay_pdf = PdfReader(overlay_buf)
                if overlay_pdf.pages:
                    merger = PageMerge(base_pdf.pages[page_idx])
                    merger.add(overlay_pdf.pages[0]).render()

        # Write output
        if output_path is None:
            output_path = rmdoc_path.rsplit(".", 1)[0] + ".pdf"

        writer = PdfWriter(output_path)
        writer.addpages(base_pdf.pages)
        writer.write()

        # Cleanup
        os.unlink(base_pdf_path)
        os.rmdir(tmpdir)

        return output_path


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(__doc__.strip(), file=sys.stderr)
        sys.exit(1)

    rmdoc = sys.argv[1]
    out = sys.argv[2] if len(sys.argv) > 2 else None
    result = render(rmdoc, out)
    print(result)
