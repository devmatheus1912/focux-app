# Run Focux app on Android emulator with Google Sign-In configured.
# Usage: .\scripts\run-android.ps1 [-OptionalClean]

param(
    [switch]$OptionalClean
)

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot '_load-env.ps1') -Root $root

function Invoke-FlutterRun {
    param([string[]]$DartDefines)
    & flutter run -d emulator-5554 @DartDefines
    if ($LASTEXITCODE -ne 0) {
        throw "flutter run failed with exit code $LASTEXITCODE"
    }
}

$fixScript = Join-Path $PSScriptRoot 'fix-android-build.ps1'

Push-Location $root
try {
    if ($OptionalClean) {
        Write-Host 'OptionalClean: running fix-android-build.ps1...' -ForegroundColor Yellow
        & $fixScript
    }

    $defines = @(
        "--dart-define=GOOGLE_WEB_CLIENT_ID=$env:GOOGLE_WEB_CLIENT_ID"
    )
    if ($env:API_URL) {
        $defines += "--dart-define=API_URL=$env:API_URL"
    }

    Write-Host 'Running on Android emulator...' -ForegroundColor Cyan
    $idPreview = $env:GOOGLE_WEB_CLIENT_ID.Substring(0, [Math]::Min(20, $env:GOOGLE_WEB_CLIENT_ID.Length))
    Write-Host "GOOGLE_WEB_CLIENT_ID: ${idPreview}..." -ForegroundColor DarkGray

    try {
        Invoke-FlutterRun -DartDefines $defines
    }
    catch {
        Write-Host 'flutter run failed - running fix-android-build.ps1 and retrying...' -ForegroundColor Yellow
        & $fixScript
        Invoke-FlutterRun -DartDefines $defines
    }
}
finally {
    Pop-Location
}
