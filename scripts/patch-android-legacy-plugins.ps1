# Patches pub-cache Android build.gradle for unmaintained plugins (AGP 8+).
# Idempotent: skips files that already contain FOCUX_ANDROID_PATCH.

$ErrorActionPreference = 'Stop'
$pubRoot = Join-Path $env:LOCALAPPDATA 'Pub\Cache\hosted\pub.dev'
if (-not (Test-Path $pubRoot)) {
    Write-Host "Pub cache not found: $pubRoot" -ForegroundColor Yellow
    exit 0
}

function Patch-IfNeeded {
    param([string]$Path, [scriptblock]$Patch)
    if (-not (Test-Path $Path)) { return }
    $text = Get-Content -Path $Path -Raw
    if ($text -match 'FOCUX_ANDROID_PATCH') { return }
    $newText = & $Patch $text
    if ($newText -ne $text) {
        Set-Content -Path $Path -Value $newText -NoNewline
        Write-Host "  patched: $Path" -ForegroundColor DarkGray
    }
}

Get-ChildItem -Path (Join-Path $pubRoot 'flutter_windowmanager-*\android\build.gradle') -ErrorAction SilentlyContinue | ForEach-Object {
    Patch-IfNeeded $_.FullName {
        param($t)
        $t = $t -replace 'compileSdkVersion\s+28', 'compileSdkVersion 34'
        if ($t -notmatch 'namespace\s') {
            $t = $t -replace 'android\s*\{', @"
android {
    namespace "io.adaptant.labs.flutter_windowmanager"
"@
        }
        if ($t -notmatch 'compileOptions') {
            $t = $t -replace 'lintOptions\s*\{', @"
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_11
        targetCompatibility JavaVersion.VERSION_11
    }
    lintOptions {
"@
        }
        if ($t -notmatch 'FOCUX_ANDROID_PATCH') {
            $t = "// FOCUX_ANDROID_PATCH`r`n" + $t
        }
        $t
    }
}

Get-ChildItem -Path (Join-Path $pubRoot 'flutter_jailbreak_detection-*\android\build.gradle') -ErrorAction SilentlyContinue | ForEach-Object {
    Patch-IfNeeded $_.FullName {
        param($t)
        $t = $t -replace 'compileSdkVersion\s+33', 'compileSdkVersion 34'
        if ($t -notmatch 'namespace\s') {
            $t = $t -replace 'android\s*\{', @"
android {
    namespace "appmire.be.flutterjailbreakdetection"
"@
        }
        if ($t -notmatch 'compileOptions') {
            $t = $t -replace 'defaultConfig\s*\{', @"
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_11
        targetCompatibility JavaVersion.VERSION_11
    }
    defaultConfig {
"@
        }
        if ($t -notmatch 'kotlinOptions\.jvmTarget') {
            $t = $t.TrimEnd() + @"

tasks.withType(org.jetbrains.kotlin.gradle.tasks.KotlinCompile).configureEach {
    kotlinOptions.jvmTarget = "11"
}
"@
        }
        if ($t -notmatch 'FOCUX_ANDROID_PATCH') {
            $t = "// FOCUX_ANDROID_PATCH`r`n" + $t
        }
        $t
    }
}
