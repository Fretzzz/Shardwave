# Runs the pure-core unit tests headlessly.
$ErrorActionPreference = 'Stop'

$godot = 'C:\Tools\Godot\Godot_v4.7.2-stable_win64.exe'
$proj = Split-Path -Parent $PSScriptRoot

& $godot --headless --path $proj --script res://tests/CoreTests.gd
exit $LASTEXITCODE
