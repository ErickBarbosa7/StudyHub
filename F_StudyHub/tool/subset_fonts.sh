#!/usr/bin/env bash
# Regenera assets/fonts/* a partir de tool/fonts/original/*.
#
# Por qué: las fuentes originales pesan 3.1 MB y en web se descargan antes de
# pintar texto. La app solo usa los ejes wght y slnt de Recursive, y texto en
# español (Latin), así que se fijan los ejes sin uso y se recortan los glifos.
#
# Requiere: pip install fonttools brotli
# Uso: bash tool/subset_fonts.sh
set -euo pipefail
cd "$(dirname "$0")/.."

ORIG=tool/fonts/original
OUT=assets/fonts
TMP="$(mktemp -d)"

# Basic Latin, Latin-1, Latin Extendido A/B, puntuación general, flechas.
UNICODES="U+0020-007E,U+00A0-00FF,U+0100-024F,U+1E00-1EFF,U+2010-2027,U+2030-203A,U+20AC,U+2190-2193,U+2212"
# rvrn es imprescindible: elige las variantes de glifos según los ejes (p. ej. el cero liso).
FEATURES="kern,liga,calt,ccmp,locl,mark,mkmk,tnum,lnum,onum,pnum,case,rvrn"

# Recursive: se fijan MONO, CASL y CRSV (no se usan); se conservan wght y slnt.
fonttools varLib.instancer "$ORIG/Recursive-VF.ttf" \
  MONO=0 CASL=0 CRSV=0.5 wght=300:900 slnt=-15:0 -o "$TMP/Recursive.ttf"
pyftsubset "$TMP/Recursive.ttf" --unicodes="$UNICODES" \
  --layout-features="$FEATURES" --no-hinting --output-file="$OUT/Recursive-VF.ttf"

# Cascadia Code: solo cifras y texto corto (reloj, código de sala, horas).
pyftsubset "$ORIG/CascadiaCode.ttf" --unicodes="U+0020-007E,U+00A0-00FF" \
  --layout-features="$FEATURES" --no-hinting --output-file="$OUT/CascadiaCode.ttf"

rm -rf "$TMP"
ls -la "$OUT"
