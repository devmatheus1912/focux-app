# Build release Flutter web with Google Sign-In configured.
# Usage: .\scripts\build-web.ps1
# Output: build/web/

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot '_load-env.ps1') -Root $root

Push-Location $root
try {
    $defines = @(
        "--dart-define=GOOGLE_WEB_CLIENT_ID=$env:GOOGLE_WEB_CLIENT_ID",
        "--dart-define=API_URL=$env:API_URL",
        "--dart-define=PUBLIC_WEB_URL=$env:PUBLIC_WEB_URL"
    )

    Write-Host "Building release Flutter web..." -ForegroundColor Cyan
    & flutter build web --release @defines
} finally {
    Pop-Location
}
