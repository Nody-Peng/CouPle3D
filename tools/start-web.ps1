param([int]$Port=8787,[switch]$Lan)
$ErrorActionPreference='Stop'
$projectRoot=Split-Path $PSScriptRoot -Parent
Set-Location -LiteralPath $projectRoot
$env:PORT="$Port"
$env:HOST=if($Lan){'0.0.0.0'}else{'127.0.0.1'}
Write-Host "Open http://localhost:$Port ; test code: together-local"
& node server/server.mjs
