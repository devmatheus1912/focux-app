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
        if ($value -and $value -notmatch '^X+$') {
            Set-Item -Path "env:$name" -Value $value
        }
    }
}

if (-not $env:GOOGLE_WEB_CLIENT_ID) {
    $env:GOOGLE_WEB_CLIENT_ID =
        '868715549357-kjut1ja3ab79j6pp3pquk2nha48atbcs.apps.googleusercontent.com'
}

if (-not $env:API_URL) {
    $env:API_URL = 'https://focux-backend-production.up.railway.app'
}

if (-not $env:PUBLIC_WEB_URL) {
    $env:PUBLIC_WEB_URL = $env:API_URL
}

if (-not $env:VERCEL_PROJECT) {
    $env:VERCEL_PROJECT = 'focux-personal'
}
