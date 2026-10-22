# Bumps the app version in one place, keeping version/code and version/name in
# sync across every Android preset (APK and AAB), plus config/version.
# Usage:
#   .\tools\version.ps1 -Version 0.2.0          # version code +1
#   .\tools\version.ps1 -Version 0.2.0 -Code 7  # explicit version code

param(
    [Parameter(Mandatory = $true)][string]$Version,
    [int]$Code = 0
)

$ErrorActionPreference = 'Stop'

if ($Version -notmatch '^\d+\.\d+\.\d+$') {
    throw "version must look like 1.2.3 (got '$Version')"
}

$proj = Split-Path -Parent $PSScriptRoot
$presetPath = Join-Path $proj 'export_presets.cfg'
$projectPath = Join-Path $proj 'project.godot'

foreach ($file in $presetPath, $projectPath) {
    if (-not (Test-Path $file)) { throw "missing $file" }
}

$utf8 = New-Object System.Text.UTF8Encoding($false)

# Read as UTF-8 explicitly: Windows PowerShell would otherwise decode the
# non-ASCII brand line in project.godot as ANSI and write it back mangled.
$preset = [System.IO.File]::ReadAllText($presetPath, [System.Text.Encoding]::UTF8)
$project = [System.IO.File]::ReadAllText($projectPath, [System.Text.Encoding]::UTF8)
$codeMatch = [regex]::Match($preset, '(?m)^version/code=(\d+)[ \t]*$')
if (-not $codeMatch.Success) { throw "export_presets.cfg has no version/code line" }

if ($Code -le 0) {
    $Code = [int]$codeMatch.Groups[1].Value + 1
}

$preset = [regex]::Replace($preset, '(?m)^version/code=\d+[ \t]*$', "version/code=$Code")
$preset = [regex]::Replace($preset, '(?m)^version/name="[^"]*"[ \t]*$', 'version/name="' + $Version + '"')

if ($project -notmatch '(?m)^config/version="[^"]*"[ \t]*$') {
    throw "project.godot has no config/version line"
}
$project = [regex]::Replace($project, '(?m)^config/version="[^"]*"[ \t]*$', 'config/version="' + $Version + '"')

[System.IO.File]::WriteAllText($presetPath, $preset, $utf8)
[System.IO.File]::WriteAllText($projectPath, $project, $utf8)

Write-Host "version $Version (code $Code)"
