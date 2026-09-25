#!/usr/bin/env python3
"""Genera lib/core/app_icons.dart y assets/fonts/Lucide.ttf con SOLO los iconos usados.

Por qué: el paquete lucide_icons_flutter declara 7 fuentes (3.7 MB) y Flutter web
descarga todas las del manifiesto al arrancar. Con una fuente propia recortada
(~20 KB) se evita esa descarga.

Uso: escribe `AppIcons.nombreDelIcono` (camelCase del nombre Lucide, p. ej.
`AppIcons.circleHelp` = "circle-help") en cualquier archivo de lib/ o test/ y ejecuta:

    pip install fonttools
    python3 tool/gen_icons.py
"""
import json
import pathlib
import re
import sys

from fontTools import subset
from fontTools.ttLib import TTFont

ROOT = pathlib.Path(__file__).resolve().parent.parent
CODEPOINTS = json.loads((ROOT / "tool/lucide/codepoints.json").read_text())


def kebab(name: str) -> str:
    # camelCase -> kebab-case; los dígitos también separan (volume2 -> volume-2).
    return re.sub(r"(?<=[a-z])(?=[A-Z0-9])", "-", name).lower()


used = set()
for base in ("lib", "test"):
    for path in (ROOT / base).rglob("*.dart"):
        if path.name == "app_icons.dart":
            continue
        used.update(re.findall(r"\bAppIcons\.([a-zA-Z0-9]+)", path.read_text()))

missing = sorted(n for n in used if kebab(n) not in CODEPOINTS)
if missing:
    sys.exit(f"Iconos que no existen en Lucide: {missing}")

icons = sorted(used)
lines = [
    "// GENERADO por tool/gen_icons.py. No editar a mano.",
    "//",
    "// Solo los iconos Lucide (https://lucide.dev) que usa la app, en una fuente propia",
    "// (assets/fonts/Lucide.ttf) en lugar de las 7 fuentes del paquete lucide_icons_flutter.",
    "import 'package:flutter/widgets.dart';",
    "",
    "abstract final class AppIcons {",
    "  static const String _family = 'Lucide';",
    "",
]
for n in icons:
    lines.append(f"  /// {kebab(n)}")
    lines.append(f"  static const IconData {n} = IconData({CODEPOINTS[kebab(n)]}, fontFamily: _family);")
lines.append("}")
(ROOT / "lib/core/app_icons.dart").write_text("\n".join(lines) + "\n")

options = subset.Options()
options.layout_features = []
options.hinting = False
options.glyph_names = False
options.notdef_outline = True
font = TTFont(ROOT / "tool/lucide/lucide.ttf")
sub = subset.Subsetter(options)
sub.populate(unicodes=[CODEPOINTS[kebab(n)] for n in icons])
sub.subset(font)

# Al recalcular los límites de cada glifo (xMin) el margen lateral guardado en
# hmtx (lsb) queda desactualizado, y FreeType/Skia desplazan el dibujo esa
# diferencia: los iconos salían corridos a la izquierda. Se igualan lsb y xMin.
glyf = font["glyf"]
hmtx = font["hmtx"]
for name in font.getGlyphOrder():
    glyph = glyf[name]
    glyph.recalcBounds(glyf)
    if glyph.numberOfContours != 0:
        advance, _ = hmtx[name]
        hmtx[name] = (advance, glyph.xMin)

out = ROOT / "assets/fonts/Lucide.ttf"
font.save(out)
print(f"{len(icons)} iconos -> {out} ({out.stat().st_size} bytes)")
