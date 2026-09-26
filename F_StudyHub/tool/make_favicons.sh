#!/usr/bin/env bash
# Genera los iconos web a partir de la mascota (assets/Lottie/claude.json).
# Requiere: python3, rsvg-convert, magick.
set -euo pipefail
cd "$(dirname "$0")/.."

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# Icono normal: cuadrado redondeado, cangrejo grande para leerse a 16 px.
python3 tool/lottie_to_svg.py 0 '#F3F2EE' 0.82
cp tool/logo.svg web/favicon.svg

# Maskable: fondo a sangre (el SO recorta) y cangrejo en la zona segura (60 %).
python3 tool/lottie_to_svg.py 0 '#F3F2EE' 0.6
sed -E 's/ rx="[0-9.]+"//' tool/logo.svg > "$tmp/maskable.svg"

# Versión normal como fuente canónica (la última ejecución deja logo.svg).
python3 tool/lottie_to_svg.py 0 '#F3F2EE' 0.82

for s in 192 512; do
  rsvg-convert -w $s -h $s web/favicon.svg -o web/icons/Icon-$s.png
  rsvg-convert -w $s -h $s "$tmp/maskable.svg" -o web/icons/Icon-maskable-$s.png
done
for s in 16 32 48; do
  rsvg-convert -w $s -h $s web/favicon.svg -o "$tmp/f$s.png"
done
cp "$tmp/f48.png" web/favicon.png
magick "$tmp/f16.png" "$tmp/f32.png" "$tmp/f48.png" web/favicon.ico
echo "favicons listos"
