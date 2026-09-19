# Helper local: fingerprints + validacao + base64 do google-services.json.
# Nao imprime a API key. Nao commita nada.
# Uso:
#   powershell -File tools/rotate_firebase_android_api_key.ps1
#   powershell -File tools/rotate_firebase_android_api_key.ps1 -EncodeForCi
#   powershell -File tools/rotate_firebase_android_api_key.ps1 -ExpectKeyPrefix API_KEY_PREFIX

param(
  [switch]$EncodeForCi,
  [string]$ExpectKeyPrefix = ""
)

$ErrorActionPreference = "Stop"
$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
if (-not (Test-Path (Join-Path $Root "pubspec.yaml"))) {
  Write-Host "ERRO: rode a partir do repo focux-app (pubspec.yaml ausente)." -ForegroundColor Red
  exit 1
}
Set-Location $Root

$Package = "com.focux.focux_app"
$JsonPath = "android/app/google-services.json"
$KeyProps = "android/key.properties"
$KeyPattern = [regex]'current_key"\s*:\s*"(AIza[^"]+)"'

function Get-Sha1FromKeytool([string[]]$KeytoolArgs) {
  $out = & keytool @KeytoolArgs 2>&1 | Out-String
  $m = [regex]::Match($out, "SHA1:\s*([0-9A-Fa-f:]+)")
  if (-not $m.Success) { return $null }
  return $m.Groups[1].Value.Trim()
}

Write-Host "== Focux: rotate Firebase Android API key =="
Write-Host "package: $Package"
Write-Host ""

$debugKs = Join-Path $env:USERPROFILE ".android\debug.keystore"
$debugSha = $null
if (Test-Path $debugKs) {
  $debugSha = Get-Sha1FromKeytool @(
    "-list", "-v",
    "-keystore", $debugKs,
    "-alias", "androiddebugkey",
    "-storepass", "android",
    "-keypass", "android"
  )
}
Write-Host "SHA-1 debug:"
if ($debugSha) { Write-Host "  $debugSha" } else { Write-Host "  (debug.keystore nao encontrado)" }

$releaseSha = $null
if (Test-Path $KeyProps) {
  $props = @{}
  Get-Content $KeyProps | ForEach-Object {
    if ($_ -match "^\s*#" -or $_ -notmatch "=") { return }
    $k, $v = $_.Split("=", 2)
    $props[$k.Trim()] = $v.Trim()
  }
  $store = $props["storeFile"]
  if ($store -and -not (Test-Path $store)) {
    $cand = Join-Path "android" ($store -replace "^\.\./", "")
    if (Test-Path $cand) { $store = $cand }
  }
  if (-not $store -or -not (Test-Path $store)) { $store = "android/focux.jks" }
  if ((Test-Path $store) -and $props["keyAlias"] -and $props["storePassword"]) {
    $ktArgs = @(
      "-list", "-v",
      "-keystore", $store,
      "-alias", $props["keyAlias"],
      "-storepass", $props["storePassword"]
    )
    if ($props["keyPassword"]) {
      $ktArgs += @("-keypass", $props["keyPassword"])
    }
    $releaseSha = Get-Sha1FromKeytool $ktArgs
  }
}
Write-Host "SHA-1 release (focux.jks):"
if ($releaseSha) { Write-Host "  $releaseSha" } else { Write-Host "  (keystore local nao lido)" }

Write-Host ""
Write-Host "Cole no Google Cloud > Credentials > Android apps:"
Write-Host "  1) $Package + SHA-1 debug"
Write-Host "  2) $Package + SHA-1 release"
Write-Host "  3) $Package + SHA-1 Play App Signing (Play Console)"
Write-Host ""

$tracked = (& git ls-files -- $JsonPath 2>$null | Out-String).Trim()
if ($tracked) {
  Write-Host "ERRO: google-services.json esta no indice git. Remova antes." -ForegroundColor Red
  exit 1
}
Write-Host "OK: google-services.json nao esta tracked."

if (-not (Test-Path $JsonPath)) {
  Write-Host "Falta android/app/google-services.json - baixe do Firebase e salve nesse path." -ForegroundColor Yellow
  exit 0
}

$raw = Get-Content $JsonPath -Raw
$km = $KeyPattern.Match($raw)
if (-not $km.Success) {
  Write-Host "ERRO: current_key AIza nao encontrado no json local." -ForegroundColor Red
  exit 1
}
$key = $km.Groups[1].Value
$prefix = $key.Substring(0, [Math]::Min(8, $key.Length))
Write-Host ("OK: local json presente (prefixo {0}... len {1}) - valor nao impresso." -f $prefix, $key.Length)

if ($ExpectKeyPrefix) {
  if ($key.StartsWith($ExpectKeyPrefix)) {
    Write-Host ("AVISO: current_key ainda comeca com {0} - parece a key antiga." -f $ExpectKeyPrefix) -ForegroundColor Yellow
    exit 2
  }
  Write-Host ("OK: current_key mudou (nao comeca mais com {0})." -f $ExpectKeyPrefix)
}

if ($EncodeForCi) {
  $b64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($raw))
  Set-Clipboard -Value $b64
  Write-Host ("OK: base64 do json copiado pro clipboard ({0} chars)." -f $b64.Length)
  Write-Host "Cole no GitHub secret GOOGLE_SERVICES_JSON_BASE64 (se o CI Android usar)."
}

Write-Host ""
Write-Host "Proximos passos manuais: README > Alert GitHub Google API Key."
