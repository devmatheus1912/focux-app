#!/usr/bin/env bash
# Falha o build se o leaf TLS ao vivo de API_URL não estiver em API_CERT_PINS
# (nem nos builtins embutidos no app). Evita shipar IPA com pin errado.
set -euo pipefail

API_URL="${API_URL:-https://api.focuxpersonal.com}"
HOST="$(python3 - <<PY
from urllib.parse import urlparse
print(urlparse("${API_URL}").hostname or "")
PY
)"

if [[ -z "$HOST" ]]; then
  echo "ERROR: não consegui extrair host de API_URL=$API_URL"
  exit 1
fi

LIVE_PIN="$(python3 - <<PY
import base64, hashlib, socket, ssl, sys
host = "$HOST"
ctx = ssl.create_default_context()
with socket.create_connection((host, 443), timeout=20) as sock:
    with ctx.wrap_socket(sock, server_hostname=host) as ssock:
        der = ssock.getpeercert(True)
digest = hashlib.sha256(der).digest()
print("sha256/" + base64.b64encode(digest).decode())
PY
)"

# Builtins do app (lib/core/config/env.dart) — sempre aceitos em prod.
BUILTIN_PINS=(
  "sha256/56ZylJhguSmnkPgt0hUNGj/AjFqCOm0Px/OmO5WdBRE="
  "sha256/BWjzG+rPlj+2cnDnbI+4LLj9z1hOazfNYvbzUZMkazA="
)

COMBINED="${API_CERT_PINS:-}"
for p in "${BUILTIN_PINS[@]}"; do
  COMBINED="${COMBINED},${p}"
done

NORM="$(printf '%s' "$COMBINED" | tr '[:upper:]' '[:lower:]')"
LIVE_LC="$(printf '%s' "$LIVE_PIN" | tr '[:upper:]' '[:lower:]')"

echo "API host: $HOST"
echo "Live leaf pin: $LIVE_PIN"

if [[ "$NORM" != *"$LIVE_LC"* ]]; then
  echo "ERROR: pin ao vivo NÃO está em API_CERT_PINS ∪ builtins."
  echo "Atualize o secret API_CERT_PINS (tools/release/fetch-api-cert-pin.ps1 $HOST)"
  echo "ou os builtins em lib/core/config/env.dart."
  exit 1
fi

echo "OK: live pin coberto pelo conjunto de pins do release."
