#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

API_URL="${API_URL:-https://api.focuxpersonal.com}"
PUBLIC_WEB_URL="${PUBLIC_WEB_URL:-https://focuxpersonal.com}"

echo "==> Focux iOS release build"
echo "    API_URL=$API_URL"

flutter pub get
(cd ios && pod install)

# Alinha GIDClientID + URL scheme com GoogleService-Info.plist (se presente no CI).
if [[ -x tools/ios/sync_google_signin_url_scheme.sh ]]; then
  tools/ios/sync_google_signin_url_scheme.sh || true
fi

GOOGLE_WEB_CLIENT_ID="${GOOGLE_WEB_CLIENT_ID:-}"
GOOGLE_IOS_CLIENT_ID="${GOOGLE_IOS_CLIENT_ID:-}"
if [[ -z "$GOOGLE_IOS_CLIENT_ID" ]]; then
  echo "ERROR: GOOGLE_IOS_CLIENT_ID obrigatório (OAuth client iOS, bundle com.focux.focuxApp)."
  exit 1
fi
bash tools/ios/patch_google_signin_from_env.sh
EXTRA_DEFINES=()
if [[ -n "$GOOGLE_WEB_CLIENT_ID" ]]; then
  EXTRA_DEFINES+=(--dart-define=GOOGLE_WEB_CLIENT_ID="$GOOGLE_WEB_CLIENT_ID")
fi
if [[ -n "$GOOGLE_IOS_CLIENT_ID" ]]; then
  EXTRA_DEFINES+=(--dart-define=GOOGLE_IOS_CLIENT_ID="$GOOGLE_IOS_CLIENT_ID")
fi

flutter build ipa --release \
  --dart-define=API_URL="$API_URL" \
  --dart-define=PUBLIC_WEB_URL="$PUBLIC_WEB_URL" \
  "${EXTRA_DEFINES[@]}" \
  --export-options-plist=ios/ExportOptions.plist

echo "==> IPA: build/ios/ipa/*.ipa"
