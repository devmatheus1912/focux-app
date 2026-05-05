# Build release APK with Google Sign-In configured.
# Usage: .\scripts\build-android.ps1
# Output: build/app/outputs/flutter-apk/app-release.apk

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

Push-Location $root
try {
    $defines = @(
        "--dart-define=GOOGLE_WEB_CLIENT_ID=$env:GOOGLE_WEB_CLIENT_ID"
    )
    if ($env:API_URL) { $defines += "--dart-define=API_URL=$env:API_URL" }

    Write-Host "Building release APK..." -ForegroundColor Cyan
    & flutter build apk --release @defines

    $apk = Join-Path $root 'build\app\outputs\flutter-apk\app-release.apk'
    if (Test-Path $apk) {
        Write-Host ""
        Write-Host "APK ready: $apk" -ForegroundColor Green
    }
} finally {
    Pop-Location
}
