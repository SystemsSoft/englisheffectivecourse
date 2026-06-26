#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# build_web.sh  –  Build Flutter Web for production (Netlify)
#
# Uso:  chmod +x build_web.sh && ./build_web.sh
#
# Fix Intl.v8BreakIterator deprecation warning:
#   O web/index.html contém um shim inline que usa Object.getOwnPropertyDescriptor
#   para inspecionar Intl.v8BreakIterator SEM invocar o getter deprecated do V8.
#   Se for um accessor nativo (getter), redefine como plain value (stub function).
#   Todos os scripts do Flutter (flutter.js, main.dart.js) carregam depois e
#   encontram a propriedade já substituída — sem acionar o UseCounter do Chrome.
#
# Por que não usar --wasm:
#   Pacotes como just_audio, video_player e chewie usam JS interop/FFI que só
#   funciona com dart2js. O compilador dart2wasm lança WebAssembly.Exception
#   em produção por incompatibilidade desses pacotes.
# ─────────────────────────────────────────────────────────────────────────────
set -e

echo "🏗️  Building Flutter web (release, dart2js)..."
flutter build web --release

echo "✅  Build concluído com sucesso."
echo "🚀  Arquivos de deploy em: build/web/"

