#!/usr/bin/env bash
set -euo pipefail

CACHE_ROOT="${CACHE_DIR:-/opt/build/cache}"
if ! mkdir -p "$CACHE_ROOT" 2>/dev/null; then
  CACHE_ROOT="${PWD}/.netlify_cache"
  mkdir -p "$CACHE_ROOT"
fi

FLUTTER_HOME="$CACHE_ROOT/flutter"
export PUB_CACHE="$CACHE_ROOT/pub"
mkdir -p "$PUB_CACHE"

if [ ! -x "$FLUTTER_HOME/bin/flutter" ]; then
  echo "[netlify] Descargando Flutter SDK en $FLUTTER_HOME (solo la primera vez)"
  rm -rf "$FLUTTER_HOME"
  git clone --depth 1 --branch stable https://github.com/flutter/flutter.git "$FLUTTER_HOME"
fi

export PATH="$FLUTTER_HOME/bin:$PATH"

echo "[netlify] Flutter: $(cd "$FLUTTER_HOME" && git log -1 --pretty=%h 2>/dev/null || echo 'desconocido')"
echo "[netlify] PUB_CACHE: $PUB_CACHE"

flutter --version

flutter build web --dart-define=API_URL=https://studyhub-rl5b.onrender.com --dart-define=SOCKET_URL=https://studyhub-rl5b.onrender.com