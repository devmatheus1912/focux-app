#!/usr/bin/env bash
# Alinha GIDClientID + URL scheme do Google Sign-In ao OAuth client iOS (nunca Web).
# Uso: GOOGLE_IOS_CLIENT_ID=... tools/ios/patch_google_signin_from_env.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
INFO="$ROOT/ios/Runner/Info.plist"
IOS_ID="${GOOGLE_IOS_CLIENT_ID:-}"

if [[ -z "$IOS_ID" ]]; then
  echo "error: GOOGLE_IOS_CLIENT_ID vazio (OAuth client tipo iOS, bundle com.focux.focuxApp)"
  exit 1
fi

if [[ "$IOS_ID" != *".apps.googleusercontent.com" ]]; then
  echo "error: GOOGLE_IOS_CLIENT_ID inválido: $IOS_ID"
  exit 1
fi

WEB_DEFAULT="868715549357-kjut1ja3ab79j6pp3pquk2nha48atbcs.apps.googleusercontent.com"
if [[ "$IOS_ID" == "$WEB_DEFAULT" ]]; then
  echo "error: GOOGLE_IOS_CLIENT_ID não pode ser o client Web ($WEB_DEFAULT)"
  exit 1
fi

PREFIX="${IOS_ID%.apps.googleusercontent.com}"
REVERSED="com.googleusercontent.apps.$PREFIX"

/usr/libexec/PlistBuddy -c "Set :GIDClientID $IOS_ID" "$INFO" 2>/dev/null \
  || /usr/libexec/PlistBuddy -c "Add :GIDClientID string $IOS_ID" "$INFO"

# Atualiza ou cria entrada GoogleSignIn em CFBundleURLTypes
IDX=0
GOOGLE_IDX=""
while /usr/libexec/PlistBuddy -c "Print :CFBundleURLTypes:$IDX" "$INFO" >/dev/null 2>&1; do
  NAME="$(/usr/libexec/PlistBuddy -c "Print :CFBundleURLTypes:$IDX:CFBundleURLName" "$INFO" 2>/dev/null || true)"
  if [[ "$NAME" == "GoogleSignIn" ]]; then
    GOOGLE_IDX="$IDX"
    break
  fi
  IDX=$((IDX + 1))
done

if [[ -z "$GOOGLE_IDX" ]]; then
  GOOGLE_IDX="$IDX"
  /usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:$GOOGLE_IDX dict" "$INFO"
  /usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:$GOOGLE_IDX:CFBundleTypeRole string Editor" "$INFO"
  /usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:$GOOGLE_IDX:CFBundleURLName string GoogleSignIn" "$INFO"
  /usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:$GOOGLE_IDX:CFBundleURLSchemes array" "$INFO"
  /usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:$GOOGLE_IDX:CFBundleURLSchemes:0 string $REVERSED" "$INFO"
else
  /usr/libexec/PlistBuddy -c "Set :CFBundleURLTypes:$GOOGLE_IDX:CFBundleURLSchemes:0 $REVERSED" "$INFO" 2>/dev/null \
    || /usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:$GOOGLE_IDX:CFBundleURLSchemes:0 string $REVERSED" "$INFO"
fi

echo "ok: GIDClientID=$IOS_ID"
echo "ok: URL scheme=$REVERSED"
