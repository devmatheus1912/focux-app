# Run Focux app on Android emulator with Google Sign-In configured.
# Usage: .\scripts\run-android.ps1 [-OptionalClean]

param(
    [switch]$OptionalClean
)

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$envFile = Join-Path $root '.env.local'

if (-not (Test-Path $envFile)) {
    Write-Error @"
.env.local not found at $envFile
Create it with at least:
  GOOGLE_WEB_CLIENT_ID=868715549357-XXXX.apps.googleusercontent.com
"@
    exit 1
}

# Load .env.local
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

$fixScript = Join-Path $PSScriptRoot 'fix-android-build.ps1'

Push-Location $root
try {
    if ($OptionalClean) {
        Write-Host "OptionalClean: executando fix-android-build.ps1..." -ForegroundColor Yellow
        & $fixScript
    }

    $defines = @(
        "--dart-define=GOOGLE_WEB_CLIENT_ID=$env:GOOGLE_WEB_CLIENT_ID"
    )
    if ($env:API_URL) { $defines += "--dart-define=API_URL=$env:API_URL" }

    Write-Host "Running on Android emulator..." -ForegroundColor Cyan
    Write-Host "GOOGLE_WEB_CLIENT_ID: $($env:GOOGLE_WEB_CLIENT_ID.Substring(0, [Math]::Min(20, $env:GOOGLE_WEB_CLIENT_ID.Length)))..." -ForegroundColor DarkGray

    try {
        & flutter run -d emulator-5554 @defines
        if ($LASTEXITCODE -ne 0) { throw "flutter run exit $LASTEXITCODE" }
    } catch {
        Write-Host "flutter run falhou — executando fix-android-build.ps1 e tentando novamente..." -ForegroundColor Yellow
        & $fixScript
        & flutter run -d emulator-5554 @defines
        if ($LASTEXITCODE -ne 0) { throw "flutter run exit $LASTEXITCODE" }
    }
} finally {
    Pop-Location
}
