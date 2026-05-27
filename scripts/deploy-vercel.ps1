# Build Flutter web + deploy na Vercel (um comando).
# Uso: .\scripts\deploy-vercel.ps1
#      ou clique duplo em deploy.bat na raiz do focux-app

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot '_load-env.ps1') -Root $root

function Test-Command($name) {
    $null -ne (Get-Command $name -ErrorAction SilentlyContinue)
}

if (-not (Test-Command flutter)) {
    throw 'Flutter nao encontrado. Instale: https://docs.flutter.dev/get-started/install'
}

if (-not (Test-Command npx)) {
    throw 'Node.js/npx nao encontrado. Instale: https://nodejs.org (so precisa 1x)'
}

Write-Host ''
Write-Host '=== Focux - deploy Vercel ===' -ForegroundColor Cyan
Write-Host "API:            $env:API_URL"
Write-Host "Links publicos: $env:PUBLIC_WEB_URL"
Write-Host ''

$defines = @(
    "--dart-define=GOOGLE_WEB_CLIENT_ID=$env:GOOGLE_WEB_CLIENT_ID",
    "--dart-define=API_URL=$env:API_URL",
    "--dart-define=PUBLIC_WEB_URL=$env:PUBLIC_WEB_URL"
)

Push-Location $root
try {
    Write-Host '[1/3] Build Flutter web...' -ForegroundColor Green
    & flutter build web --release @defines
    if ($LASTEXITCODE -ne 0) { throw "flutter build web falhou (exit $LASTEXITCODE)" }

    $out = Join-Path $root 'build\web'
    Copy-Item (Join-Path $root 'vercel.json') (Join-Path $out 'vercel.json') -Force

    Write-Host '[2/3] Enviando para Vercel...' -ForegroundColor Green
    Write-Host "(Projeto: $($env:VERCEL_PROJECT))" -ForegroundColor DarkGray

    & npx --yes vercel@latest link --project $env:VERCEL_PROJECT --yes 2>$null
    & npx --yes vercel@latest deploy $out --prod --yes --project $env:VERCEL_PROJECT
    if ($LASTEXITCODE -ne 0) { throw "vercel deploy falhou (exit $LASTEXITCODE)" }

    Write-Host ''
    Write-Host '[3/3] Pronto!' -ForegroundColor Green
    Write-Host ''
    Write-Host "App: https://$($env:VERCEL_PROJECT).vercel.app" -ForegroundColor Cyan
    Write-Host ''
    Write-Host 'Se o login der erro de CORS, adicione no Railway (Variables):' -ForegroundColor Yellow
    Write-Host '  CORS_EXTRA_ORIGINS=https://focuxpersonal.com,https://www.focuxpersonal.com,https://web-taupe-mu-61.vercel.app'
    Write-Host ''
} finally {
    Pop-Location
}
