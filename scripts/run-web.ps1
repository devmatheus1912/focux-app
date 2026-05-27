# Run Focux app on Chrome (web) with Google Sign-In configured.
# Usage: .\scripts\run-web.ps1

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot '_load-env.ps1') -Root $root

$port = if ($env:WEB_PORT) { $env:WEB_PORT } else { '61791' }

Push-Location $root
try {
    $defines = @(
        "--dart-define=GOOGLE_WEB_CLIENT_ID=$env:GOOGLE_WEB_CLIENT_ID",
        "--dart-define=API_URL=$env:API_URL",
        "--dart-define=PUBLIC_WEB_URL=$env:PUBLIC_WEB_URL"
    )

    Write-Host "Running on Chrome :$port ..." -ForegroundColor Cyan
    & flutter run -d chrome --web-port $port @defines
} finally {
    Pop-Location
}
