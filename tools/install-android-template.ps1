# Installs Godot's Android Gradle build template into android\build (gitignored).
# Only needed for AAB exports (build.ps1 -Bundle). Safe to re-run.
#
#   powershell -ExecutionPolicy Bypass -File .\tools\install-android-template.ps1

param([string]$TemplateVersion = '4.7.2.stable')

$ErrorActionPreference = 'Stop'

$proj = Split-Path -Parent $PSScriptRoot
$zip = Join-Path $env:APPDATA "Godot\export_templates\$TemplateVersion\android_source.zip"
$dest = Join-Path $proj 'android\build'

if (-not (Test-Path $zip)) {
    throw "missing export template: $zip (install Godot $TemplateVersion export templates)"
}

if (Test-Path (Join-Path $dest 'build.gradle')) {
    Write-Host "template already installed at $dest"
    exit 0
}

New-Item -ItemType Directory -Force $dest | Out-Null
Expand-Archive -Path $zip -DestinationPath $dest -Force

# Godot identifies an installed Gradle template by res://android/.build_version
# and keeps the importer out with a .gdignore inside the build directory.
New-Item -ItemType File -Force (Join-Path $dest '.gdignore') | Out-Null
[System.IO.File]::WriteAllText(
    (Join-Path $proj 'android\.build_version'),
    "$TemplateVersion`n",
    (New-Object System.Text.UTF8Encoding($false)))

Write-Host "android template -> $dest"
