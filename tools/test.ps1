# Runs the test suite headlessly: pure-core checks, then the scene-shell flow.
$ErrorActionPreference = 'Stop'

$godot = 'C:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe'
$proj = Split-Path -Parent $PSScriptRoot

& $godot --headless --path $proj --script res://tests/CoreTests.gd
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& $godot --headless --path $proj res://tests/FlowTest.tscn --quit-after 900
exit $LASTEXITCODE
