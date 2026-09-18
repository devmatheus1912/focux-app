# Gera pin TLS no formato do app (sha256 do DER do certificado leaf).
# Uso: .\tools\release\fetch-api-cert-pin.ps1 [host]
param(
  [string]$HostName = "api.focuxpersonal.com"
)

$tcp = New-Object System.Net.Sockets.TcpClient($HostName, 443)
$ssl = New-Object System.Net.Security.SslStream($tcp.GetStream(), $false, ({ param($s,$c,$ch,$e) $true }))
$ssl.AuthenticateAsClient($HostName)
$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($ssl.RemoteCertificate)
$hash = [System.Security.Cryptography.SHA256]::Create().ComputeHash($cert.RawData)
$pin = "sha256/$([Convert]::ToBase64String($hash))"
$ssl.Close()
$tcp.Close()

Write-Host "Host: $HostName"
Write-Host "Subject: $($cert.Subject)"
Write-Host "Pin (use em API_CERT_PINS): $pin"
