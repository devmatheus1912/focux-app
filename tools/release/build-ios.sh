#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

API_URL="${API_URL:-https://focux-backend-production.up.railway.app}"
PUBLIC_WEB_URL="${PUBLIC_WEB_URL:-https://focux.app}"

echo "==> Focux iOS release build"
echo "    API_URL=$API_URL"

flutter pub get
(cd ios && pod install)

flutter build ipa --release \
  --dart-define=API_URL="$API_URL" \
  --dart-define=PUBLIC_WEB_URL="$PUBLIC_WEB_URL" \
  --export-options-plist=ios/ExportOptions.plist

echo "==> IPA: build/ios/ipa/*.ipa"
