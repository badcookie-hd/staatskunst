"""Build the offline relief texture from Natural Earth SR_HR.tif (public domain).
Usage: python tools/build_relief.py /path/to/SR_HR.tif
Requires Pillow. Geographic extent: -180..180 longitude, 90..-90 latitude.
"""
from pathlib import Path
import sys
from PIL import Image

Image.MAX_IMAGE_PIXELS = None
source = Image.open(sys.argv[1]).convert("L")
source = source.resize((10800, 5400), Image.Resampling.LANCZOS)
# Increase hillshade contrast while preserving light plains and highlights.
source = source.point([max(85, min(255, round((v - 200) * 1.6 + 220))) for v in range(256)])
target = Path(__file__).resolve().parents[1] / "assets" / "world-relief.png"
source.save(target, optimize=True)
print(f"Relief: {source.size}, {target.stat().st_size} bytes")
