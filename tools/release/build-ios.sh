#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

API_URL="${API_URL:-https://focux-backend-production.up.railway.app}"
PUBLIC_WEB_URL="${PUBLIC_WEB_URL:-https://focuxpersonal.com}"

if [[ -z "${API_CERT_PINS:-}" ]]; then
  echo "ERROR: API_CERT_PINS obrigatório no release (SHA-256 do cert da API)."
  echo "Ex.: export API_CERT_PINS='sha256/<base64>,sha256/<backup>'"
  exit 1
fi

echo "==> Focux iOS release build"
echo "    API_URL=$API_URL"
echo "    API_CERT_PINS set (${#API_CERT_PINS} chars)"

flutter pub get
(cd ios && pod install)

flutter build ipa --release \
  --dart-define=API_URL="$API_URL" \
  --dart-define=PUBLIC_WEB_URL="$PUBLIC_WEB_URL" \
  --dart-define=API_CERT_PINS="$API_CERT_PINS" \
  --dart-define=REQUIRE_API_CERT_PINS=true \
  --export-options-plist=ios/ExportOptions.plist

echo "==> IPA: build/ios/ipa/*.ipa"
