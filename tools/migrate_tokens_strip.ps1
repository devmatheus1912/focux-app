# Batch TOKENS STRIP v1.0.0 migration for feature screens.
$root = Split-Path -Parent $PSScriptRoot
$features = Join-Path $root "lib\features"
$skip = @("tokens_strip_showcase_screen.dart")

$replacements = @(
    @{ From = '\bEagleTokens\.ink\b'; To = 'TokensStrip.textPrimary' },
    @{ From = '\bEagleTokens\.inkMute\b'; To = 'TokensStrip.textSecondary' },
    @{ From = '\bEagleTokens\.paper\b'; To = 'TokensStrip.pageBg' },
    @{ From = '\bEagleTokens\.card\b'; To = 'TokensStrip.cardBg' },
    @{ From = '\bEagleTokens\.lineSoft\b'; To = 'TokensStrip.borderDefault' },
    @{ From = '\bEagleTokens\.line\b'; To = 'TokensStrip.borderDefault' },
    @{ From = '\bEagleTokens\.brandInk\b'; To = 'TokensStrip.primaryHover' },
    @{ From = '\bEagleTokens\.brand\b'; To = 'TokensStrip.primary' },
    @{ From = '\bEagleTokens\.radiusXs\b'; To = 'TokensStrip.rInput' },
    @{ From = '\bEagleTokens\.radiusSm\b'; To = 'TokensStrip.rCard' },
    @{ From = '\bEagleTokens\.radiusMd\b'; To = 'TokensStrip.rXl' },
    @{ From = '\bEagleTokens\.radiusLg\b'; To = 'TokensStrip.r2xl' }
)

$scaffoldPatterns = @(
    @{
        Old = "return Scaffold(`r`n      extendBody: true,`r`n      backgroundColor: Colors.transparent,`r`n      appBar:"
        New = "return FxShellScaffold(`r`n      useMesh: true,`r`n      appBar:"
    },
    @{
        Old = "return Scaffold(`r`n      backgroundColor: Colors.transparent,`r`n      extendBody: true,`r`n      appBar:"
        New = "return FxShellScaffold(`r`n      useMesh: true,`r`n      appBar:"
    },
    @{
        Old = "return Scaffold(`r`n      backgroundColor: Colors.transparent,`r`n      appBar:"
        New = "return FxShellScaffold(`r`n      useMesh: true,`r`n      appBar:"
    }
)

function Get-ImportPath($file, $suffix) {
    $libRoot = Join-Path $root "lib"
    $rel = $file.FullName.Substring($libRoot.Length + 1)
    $depth = ($rel -split '\\').Count - 1
    $prefix = ('../' * $depth)
    return "import '$prefix$suffix';"
}

function Ensure-Import($content, $file, $suffix) {
    if ($content -match [regex]::Escape($suffix)) { return $content }
    $line = Get-ImportPath $file $suffix
    if ($content -match [regex]::Escape($line)) { return $content }
    $idx = $content.LastIndexOf("import ")
    if ($idx -lt 0) { return "$line`n$content" }
    $end = $content.IndexOf("`n", $idx)
    while ($true) {
        $next = $content.IndexOf("import ", $end + 1)
        if ($next -lt 0) { break }
        $end = $content.IndexOf("`n", $next)
    }
    return $content.Insert($end + 1, "$line`n")
}

$changed = 0
Get-ChildItem -Path $features -Recurse -Filter "*screen*.dart" | Sort-Object FullName | ForEach-Object {
    if ($skip -contains $_.Name) { return }
    $original = Get-Content $_.FullName -Raw -Encoding UTF8
    $content = $original

    foreach ($r in $replacements) {
        $content = [regex]::Replace($content, $r.From, $r.To)
    }
    foreach ($p in $scaffoldPatterns) {
        $content = $content.Replace($p.Old, $p.New)
    }

    if ($content -match 'TokensStrip\.') {
        $content = Ensure-Import $content $_ "core/theme/tokens_strip.dart"
    }
    if ($content -match 'FxShellScaffold\(') {
        $content = Ensure-Import $content $_ "core/widgets/fx_shell_scaffold.dart"
    }
    if ($content -match 'FxStrip(Card|SectionTitle|SectionLabel)\(') {
        $content = Ensure-Import $content $_ "core/widgets/fx_strip_components.dart"
    }
    if ($content -match 'FxLiquidPrimaryButton\(' -and $content -notmatch 'fx_motion\.dart') {
        $content = Ensure-Import $content $_ "core/widgets/fx_motion.dart"
    }

    if ($content -ne $original) {
        Set-Content -Path $_.FullName -Value $content -Encoding UTF8 -NoNewline
        $changed++
        Write-Output "migrated: $($_.FullName.Substring($root.Length + 1))"
    }
}

Write-Output "`nDone. $changed files updated."
