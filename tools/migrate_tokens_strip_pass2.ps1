# TOKENS STRIP pass 2 — scaffold conversion + universal import + spacing tokens.
$root = Split-Path -Parent $PSScriptRoot
$features = Join-Path $root "lib\features"
$skip = @("tokens_strip_showcase_screen.dart")

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
    $matches = [regex]::Matches($content, "(?m)^import .+;\r?\n")
    if ($matches.Count -eq 0) { return "$line`n$content" }
    $insertAt = $matches[$matches.Count - 1].Index + $matches[$matches.Count - 1].Length
    return $content.Insert($insertAt, "$line`n")
}

$changed = 0
Get-ChildItem -Path $features -Recurse -Filter "*screen*.dart" | Sort-Object FullName | ForEach-Object {
    if ($skip -contains $_.Name) { return }
    $original = Get-Content $_.FullName -Raw -Encoding UTF8
    $content = $original

    # Flexible Scaffold -> FxShellScaffold when FxShellAppBar is used
    if ($content -match 'FxShellAppBar' -and $content -match 'return Scaffold\(' -and $content -notmatch 'return FxShellScaffold\(') {
        $content = [regex]::Replace(
            $content,
            'return Scaffold\(\s*extendBody:\s*true,\s*backgroundColor:\s*Colors\.transparent,\s*appBar:\s*(FxShellAppBar)',
            'return FxShellScaffold($([char]10)      useMesh: true,$([char]10)      appBar: $1',
            1
        )
        if ($content -match 'return Scaffold\(') {
            $content = [regex]::Replace(
                $content,
                'return Scaffold\(\s*backgroundColor:\s*Colors\.transparent,\s*(extendBody:\s*true,\s*)?appBar:\s*(FxShellAppBar)',
                'return FxShellScaffold($([char]10)      useMesh: true,$([char]10)      appBar: $2',
                1
            )
        }
    }

    # Universal tokens_strip import for all feature screens
    $content = Ensure-Import $content $_ "core/theme/tokens_strip.dart"

    # Spacing token pass (safe common paddings)
    $content = $content.Replace('EdgeInsets.fromLTRB(16,', 'EdgeInsets.fromLTRB(TokensStrip.s4,')
    $content = $content.Replace('EdgeInsets.fromLTRB(20,', 'EdgeInsets.fromLTRB(TokensStrip.s5,')
    $content = $content.Replace('EdgeInsets.all(16)', 'EdgeInsets.all(TokensStrip.s4)')
    $content = $content.Replace('EdgeInsets.all(24)', 'EdgeInsets.all(TokensStrip.s5)')
    $content = $content.Replace('const SizedBox(height: 16)', 'const SizedBox(height: TokensStrip.s4)')
    $content = $content.Replace('const SizedBox(height: 24)', 'const SizedBox(height: TokensStrip.s5)')

    if ($content -match 'FxShellScaffold\(') {
        $content = Ensure-Import $content $_ "core/widgets/fx_shell_scaffold.dart"
    }

    if ($content -ne $original) {
        Set-Content -Path $_.FullName -Value $content -Encoding UTF8 -NoNewline
        $changed++
        Write-Output "pass2: $($_.FullName.Substring($root.Length + 1))"
    }
}

Write-Output "`nPass 2 done. $changed files updated."
