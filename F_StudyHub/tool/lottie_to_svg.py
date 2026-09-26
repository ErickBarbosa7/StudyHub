#!/usr/bin/env python3
"""Extrae un frame de la mascota (assets/Lottie/claude.json) a tool/logo.svg.

La mascota es pixel art: cada capa son grupos de rectángulos con opacidad por
fotograma (animación "hold"). Aquí se toma un fotograma, se dibujan solo los
grupos visibles y se recorta al cangrejo sobre un cuadrado redondeado.

Uso: python3 tool/lottie_to_svg.py [frame] [fondo] [zoom]
  frame  fotograma a extraer (0 por defecto)
  fondo  color hex del cuadrado (#F3F2EE por defecto)
  zoom   margen: 0.76 = el cangrejo ocupa el 76 % del lado (0.76 por defecto)
Luego render: ver tool/make_favicons.sh
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / 'assets' / 'Lottie' / 'claude.json'
OUT = Path(__file__).resolve().parent / 'logo.svg'

frame = int(sys.argv[1]) if len(sys.argv) > 1 else 0
bg = sys.argv[2] if len(sys.argv) > 2 else '#F3F2EE'
fill_ratio = float(sys.argv[3]) if len(sys.argv) > 3 else 0.76


def value_at(prop, t):
    """Valor de una propiedad Lottie en el fotograma t (estática o hold)."""
    if not prop.get('a'):
        return prop['k']
    current = None
    for kf in prop['k']:
        if kf['t'] <= t:
            current = kf['s']
    return current if current is not None else prop['k'][0]['s']


def hexcolor(rgba):
    return '#%02X%02X%02X' % tuple(round(c * 255) for c in rgba[:3])


data = json.loads(SRC.read_text())
polys = []  # (color, [(x, y), ...])
for layer in data['layers']:
    for group in layer['shapes']:
        items = group['it']
        fill = next(i for i in items if i['ty'] == 'fl')
        tr = next(i for i in items if i['ty'] == 'tr')
        opacity = value_at(fill['o'], frame)[0] if fill['o'].get('a') else fill['o']['k']
        opacity = min(opacity, value_at(tr['o'], frame) if not tr['o'].get('a') else value_at(tr['o'], frame)[0])
        if opacity < 50:
            continue
        color = hexcolor(fill['c']['k'])
        for it in items:
            if it['ty'] == 'sh':
                polys.append((color, [tuple(v) for v in it['ks']['k']['v']]))

xs = [x for _, p in polys for x, _ in p]
ys = [y for _, p in polys for _, y in p]
x0, x1, y0, y1 = min(xs), max(xs), min(ys), max(ys)
side = max(x1 - x0, y1 - y0) / fill_ratio
cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
vx, vy = cx - side / 2, cy - side / 2

paths = []
for color, pts in polys:
    d = 'M' + ' L'.join('%g %g' % p for p in pts) + 'Z'
    paths.append('<path fill="%s" d="%s"/>' % (color, d))

svg = (
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="%g %g %g %g" '
    'shape-rendering="crispEdges">\n'
    '<rect x="%g" y="%g" width="%g" height="%g" rx="%g" fill="%s"/>\n%s\n</svg>\n'
) % (vx, vy, side, side, vx, vy, side, side, side * 0.22, bg, '\n'.join(paths))
OUT.write_text(svg)
print('logo.svg: %d rects, frame %d, crab %gx%g' % (len(polys), frame, x1 - x0, y1 - y0))
