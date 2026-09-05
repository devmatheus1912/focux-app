#!/usr/bin/env bash
# Garante que Info.plist tenha o REVERSED_CLIENT_ID do GoogleService-Info.plist.
# Uso: tools/ios/sync_google_signin_url_scheme.sh
# Ideal como Run Script no Xcode (antes de Compile Sources) ou no build-ios.sh.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PLIST="$ROOT/ios/Runner/GoogleService-Info.plist"
INFO="$ROOT/ios/Runner/Info.plist"

if [[ ! -f "$PLIST" ]]; then
  echo "warn: GoogleService-Info.plist ausente — usando GIDClientID commitado no Info.plist."
  echo "      Bundle esperado: com.focux.focuxApp"
  exit 0
fi

BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print :BUNDLE_ID' "$PLIST" 2>/dev/null || true)"
CLIENT_ID="$(/usr/libexec/PlistBuddy -c 'Print :CLIENT_ID' "$PLIST" 2>/dev/null || true)"
REVERSED="$(/usr/libexec/PlistBuddy -c 'Print :REVERSED_CLIENT_ID' "$PLIST" 2>/dev/null || true)"

if [[ -z "$CLIENT_ID" || -z "$REVERSED" ]]; then
  echo "error: GoogleService-Info.plist sem CLIENT_ID/REVERSED_CLIENT_ID"
  exit 1
fi

if [[ -n "$BUNDLE_ID" && "$BUNDLE_ID" != "com.focux.focuxApp" ]]; then
  echo "error: BUNDLE_ID=$BUNDLE_ID (esperado com.focux.focuxApp)"
  exit 1
fi

# Atualiza GIDClientID
/usr/libexec/PlistBuddy -c "Set :GIDClientID $CLIENT_ID" "$INFO" 2>/dev/null \
  || /usr/libexec/PlistBuddy -c "Add :GIDClientID string $CLIENT_ID" "$INFO"

# Garante URL scheme do reversed client id
if ! /usr/libexec/PlistBuddy -c 'Print :CFBundleURLTypes' "$INFO" >/dev/null 2>&1; then
  /usr/libexec/PlistBuddy -c 'Add :CFBundleURLTypes array' "$INFO"
fi

FOUND=0
COUNT="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleURLTypes' "$INFO" | grep -c 'Dict' || true)"
# Busca scheme existente
if grep -q "$REVERSED" "$INFO"; then
  FOUND=1
fi

if [[ "$FOUND" -eq 0 ]]; then
  IDX=0
  while /usr/libexec/PlistBuddy -c "Print :CFBundleURLTypes:$IDX" "$INFO" >/dev/null 2>&1; do
    IDX=$((IDX + 1))
  done
  /usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:$IDX dict" "$INFO"
  /usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:$IDX:CFBundleTypeRole string Editor" "$INFO"
  /usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:$IDX:CFBundleURLName string GoogleSignIn" "$INFO"
  /usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:$IDX:CFBundleURLSchemes array" "$INFO"
  /usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:$IDX:CFBundleURLSchemes:0 string $REVERSED" "$INFO"
  echo "ok: adicionou URL scheme $REVERSED e GIDClientID=$CLIENT_ID"
else
  echo "ok: URL scheme $REVERSED já presente; GIDClientID=$CLIENT_ID"
fi

echo "checklist Google Cloud Console:"
echo "  - OAuth client tipo iOS com Bundle ID com.focux.focuxApp"
echo "  - CLIENT_ID do plist = esse client iOS (ou Web só se URL scheme bater)"
echo "  - Web client ($CLIENT_ID ou GOOGLE_WEB_CLIENT_ID) autorizado no backend"
