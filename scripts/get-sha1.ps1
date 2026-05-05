# Helper to extract Android debug SHA-1 fingerprint for Firebase OAuth setup.
# Run from focux-app root: .\scripts\get-sha1.ps1

# Suppress PowerShell 5.1 quirk where native stderr lines get wrapped as errors.
$ErrorActionPreference = 'Continue'
$PSNativeCommandUseErrorActionPreference = $false

$root = Split-Path -Parent $PSScriptRoot
$androidDir = Join-Path $root 'android'

if (-not (Test-Path $androidDir)) {
    Write-Error "android/ folder not found. Run from focux-app root."
    exit 1
}

Push-Location $androidDir
try {
    Write-Host "Running gradle signingReport..." -ForegroundColor Cyan
    # Capture both streams without PowerShell wrapping stderr as ErrorRecord.
    $reportFile = New-TemporaryFile
    $process = Start-Process -FilePath '.\gradlew.bat' `
        -ArgumentList @('signingReport', '--no-daemon', '-q') `
        -NoNewWindow -Wait -PassThru `
        -RedirectStandardOutput $reportFile.FullName

    $output = Get-Content $reportFile.FullName -Raw
    Remove-Item $reportFile.FullName -ErrorAction SilentlyContinue

    if ($process.ExitCode -ne 0) {
        Write-Error "gradlew signingReport failed (exit $($process.ExitCode))."
        Write-Host $output
        exit 1
    }

    # Find debug variant SHA-1
    $debugIdx = $output.IndexOf('Variant: debug')
    if ($debugIdx -lt 0) {
        Write-Error "Could not find 'Variant: debug' in signingReport output."
        Write-Host $output
        exit 1
    }
    $debugSection = $output.Substring($debugIdx)

    if ($debugSection -match 'SHA1:\s*([0-9A-F:]+)') {
        $sha1 = $matches[1]
        Write-Host ""
        Write-Host "Debug SHA-1 fingerprint:" -ForegroundColor Green
        Write-Host $sha1 -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Cyan
        Write-Host "  1. Open https://console.firebase.google.com/project/focux-personal/settings/general"
        Write-Host "  2. Find Android app 'com.focux.focux_app'"
        Write-Host "  3. Add fingerprint -> paste the SHA-1 above -> Save"
        Write-Host "  4. Download fresh google-services.json -> replace android/app/google-services.json"

        try {
            $sha1 | Set-Clipboard
            Write-Host ""
            Write-Host "(SHA-1 copied to clipboard.)" -ForegroundColor DarkGray
        } catch { }
    } else {
        Write-Error "SHA1 not found in debug variant section."
        Write-Host $debugSection
    }
} finally {
    Pop-Location
}
