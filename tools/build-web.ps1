$ErrorActionPreference='Stop'
$projectRoot=Split-Path $PSScriptRoot -Parent
Set-Location -LiteralPath $projectRoot
$env:APPDATA=Join-Path $projectRoot '.runtime'
$env:LOCALAPPDATA=$env:APPDATA
$engine=Join-Path $projectRoot 'Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe'
$template=Join-Path $projectRoot '.runtime/Godot/export_templates/4.7.2.stable/web_nothreads_release.zip'
if(!(Test-Path -LiteralPath $template)){throw 'Install the Godot 4.7.2 Web export templates into .runtime/Godot/export_templates/4.7.2.stable first.'}
New-Item -ItemType Directory -Force -Path 'web/game' | Out-Null
& $engine --headless --path $projectRoot --export-release Web web/game/index.html
if($LASTEXITCODE -ne 0){throw 'Godot Web export failed.'}
& node tools/compress-web.mjs
if($LASTEXITCODE -ne 0){throw 'Web compression failed.'}
