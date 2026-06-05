# Loads focux-app/.env.local into process env. Dot-source from other scripts.
param(
    [string]$Root = (Split-Path -Parent $PSScriptRoot)
)

$envFile = Join-Path $Root '.env.local'
$example = Join-Path $Root '.env.local.example'

if (-not (Test-Path $envFile)) {
    if (Test-Path $example) {
        Copy-Item $example $envFile
        Write-Host "Criado .env.local a partir do exemplo. Revise se precisar." -ForegroundColor Yellow
    } else {
        throw ".env.local nao encontrado em $envFile"
    }
}

Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*([^#=][^=]*)=(.*)$') {
        $name = $matches[1].Trim()
        $value = $matches[2].Trim().Trim('"').Trim("'")
        if ($value -and $value -notmatch '^X+$' -and $value -notmatch '^your-') {
            Set-Item -Path "env:$name" -Value $value
        }
    }
}

if (-not $env:GOOGLE_WEB_CLIENT_ID) {
    throw 'GOOGLE_WEB_CLIENT_ID ausente. Copie .env.local.example para .env.local e preencha.'
}

if (-not $env:API_URL) {
    throw 'API_URL ausente. Copie .env.local.example para .env.local e preencha.'
}

if (-not $env:PUBLIC_WEB_URL) {
    $env:PUBLIC_WEB_URL = $env:API_URL
}
