param([int]$Port = 8787)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
Set-Location -LiteralPath $projectRoot
if (!(Get-Command node -ErrorAction SilentlyContinue)) { throw 'Install Node.js before starting the home server.' }
$bytes = New-Object byte[] 9
$rng = [Security.Cryptography.RandomNumberGenerator]::Create()
$rng.GetBytes($bytes)
$rng.Dispose()
$env:COUPLE_TEST_CODE = [Convert]::ToBase64String($bytes).Replace('+','x').Replace('/','y')
$env:HOST = '0.0.0.0'
$env:PORT = [string]$Port
Write-Host ('Private code for this session: ' + $env:COUPLE_TEST_CODE)
Write-Host ('This computer: http://127.0.0.1:' + $Port)
Write-Host 'Keep this window open while playing. Shared saves persist after closing.'
Write-Host 'Other networks need a reachable host address (private VPN or HTTPS hosting).'
try { & node server/server.mjs } finally {
    Remove-Item Env:COUPLE_TEST_CODE -ErrorAction SilentlyContinue
    Remove-Item Env:HOST -ErrorAction SilentlyContinue
    Remove-Item Env:PORT -ErrorAction SilentlyContinue
}
