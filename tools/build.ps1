# Build + install helpers for Shardwave.
# Usage:
#   .\tools\build.ps1            # debug APK
#   .\tools\build.ps1 -Release   # release APK (needs export_credentials.cfg)
#   .\tools\build.ps1 -Install   # build debug, then adb install
#   .\tools\test.ps1             # core unit tests

param(
    [switch]$Release,
    [switch]$Install
)

$ErrorActionPreference = 'Stop'

$godot = 'C:\Tools\Godot\Godot_v4.7.2-stable_win64.exe'
$adb = 'C:\Tools\android-sdk\platform-tools\adb.exe'
$proj = Split-Path -Parent $PSScriptRoot
$buildDir = Join-Path $proj 'build'
New-Item -ItemType Directory -Force $buildDir | Out-Null

if ($Release) {
    $out = Join-Path $buildDir 'shardwave-release.apk'
    Write-Host "exporting release -> $out"
    & $godot --headless --path $proj --export-release 'Android' $out
} else {
    $out = Join-Path $buildDir 'shardwave-debug.apk'
    Write-Host "exporting debug -> $out"
    & $godot --headless --path $proj --export-debug 'Android' $out
}

if ($LASTEXITCODE -ne 0) { throw "export failed ($LASTEXITCODE)" }
Write-Host "ok: $([math]::Round((Get-Item $out).Length / 1MB, 1)) MB"

if ($Install) {
    & $adb install -r $out
    if ($LASTEXITCODE -ne 0) { throw "adb install failed ($LASTEXITCODE)" }
    & $adb shell am start -n 'com.at8studios.shardwave/com.godot.game.GodotApp'
}
