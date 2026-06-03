# Limpa caches corrompidos (Gradle GZIP, rive CMake, build stale Windows).
# Usage: .\scripts\fix-android-build.ps1

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

Write-Host "Limpando caches Android/Flutter..." -ForegroundColor Cyan

Push-Location $root
try {
    & flutter clean | Out-Null

    foreach ($path in @('build', '.dart_tool\flutter_build', 'android\.gradle', 'android\app\build')) {
        $full = Join-Path $root $path
        if (Test-Path $full) {
            Remove-Item -Recurse -Force $full -ErrorAction SilentlyContinue
            Write-Host "  removido: $path" -ForegroundColor DarkGray
        }
    }

    $gradleCaches = Join-Path $env:USERPROFILE '.gradle\caches\build-cache-1'
    if (Test-Path $gradleCaches) {
        Remove-Item -Recurse -Force $gradleCaches -ErrorAction SilentlyContinue
        Write-Host "  removido: ~/.gradle/caches/build-cache-1" -ForegroundColor DarkGray
    }

    $riveCxx = Join-Path $env:LOCALAPPDATA 'Pub\Cache\hosted\pub.dev\rive_common-0.4.15\android\.cxx'
    if (Test-Path $riveCxx) {
        Remove-Item -Recurse -Force $riveCxx -ErrorAction SilentlyContinue
        Write-Host "  removido: rive_common .cxx" -ForegroundColor DarkGray
    }

    $gradleEap = $ErrorActionPreference
    $ErrorActionPreference = 'SilentlyContinue'
    Push-Location (Join-Path $root 'android')
    try {
        # Gradle/Java escreve avisos em stderr; no PowerShell isso não deve falhar o script.
        & .\gradlew.bat --stop *>$null
    } finally {
        Pop-Location
        $ErrorActionPreference = $gradleEap
    }

    & flutter pub get | Out-Null

    $patchScript = Join-Path $PSScriptRoot 'patch-android-legacy-plugins.ps1'
    if (Test-Path $patchScript) {
        & $patchScript
    }

    Write-Host "Pronto. Rode: .\scripts\run-android.ps1" -ForegroundColor Green
} finally {
    Pop-Location
}
