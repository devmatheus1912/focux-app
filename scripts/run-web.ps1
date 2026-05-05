# Run Focux app on Chrome (web) with Google Sign-In configured.
# Usage: .\scripts\run-web.ps1

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$envFile = Join-Path $root '.env.local'

if (-not (Test-Path $envFile)) {
    Write-Error ".env.local not found at $envFile"
    exit 1
}

Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*([^#=][^=]*)=(.*)$') {
        $name = $matches[1].Trim()
        $value = $matches[2].Trim().Trim('"').Trim("'")
        Set-Item -Path "env:$name" -Value $value
    }
}

if (-not $env:GOOGLE_WEB_CLIENT_ID) {
    Write-Error "GOOGLE_WEB_CLIENT_ID missing in .env.local"
    exit 1
}

$port = if ($env:WEB_PORT) { $env:WEB_PORT } else { '61791' }

Push-Location $root
try {
    $defines = @(
        "--dart-define=GOOGLE_WEB_CLIENT_ID=$env:GOOGLE_WEB_CLIENT_ID"
    )
    if ($env:API_URL) { $defines += "--dart-define=API_URL=$env:API_URL" }

    Write-Host "Running on Chrome :$port ..." -ForegroundColor Cyan
    & flutter run -d chrome --web-port $port @defines
} finally {
    Pop-Location
}
