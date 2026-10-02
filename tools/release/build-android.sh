#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

API_URL="${API_URL:-https://api.focuxpersonal.com}"
PUBLIC_WEB_URL="${PUBLIC_WEB_URL:-https://focuxpersonal.com}"

echo "==> Focux Android release build"
echo "    API_URL=$API_URL"

flutter pub get

flutter build appbundle --release \
  --dart-define=API_URL="$API_URL" \
  --dart-define=PUBLIC_WEB_URL="$PUBLIC_WEB_URL"

echo "==> AAB: build/app/outputs/bundle/release/*.aab"
