# Regenerates every Play Store image in one shot.
#   powershell -ExecutionPolicy Bypass -File .\tools\store-assets.ps1
#
# Console screenshots come from the game itself (tests/StoreShots.gd),
# so they stay in sync with the UI. Listing copy lives in store/listing.md.

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$godot = 'C:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe'
$proj = Split-Path -Parent $PSScriptRoot

Write-Host 'rendering phone screenshots...'
& $godot --path $proj --rendering-method gl_compatibility --rendering-driver opengl3 `
    res://tests/StoreShots.tscn 2>&1 | Select-String -Pattern 'shot '
if ($LASTEXITCODE -ne 0) { throw "StoreShots failed ($LASTEXITCODE)" }

Write-Host 'rendering icons + feature graphic...'
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'icons.ps1')
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'feature-graphic.ps1')

# Play requires 24-bit PNG (no alpha) for screenshots and graphics.
Write-Host 'flattening to 24-bit...'
$targets = @(
    (Join-Path $proj 'store\phone-01-menu.png'),
    (Join-Path $proj 'store\phone-02-results.png'),
    (Join-Path $proj 'store\phone-03-board.png'),
    (Join-Path $proj 'store\phone-04-prism.png'),
    (Join-Path $proj 'icons\store_icon_512.png')
)
foreach ($path in $targets) {
    $src = [System.Drawing.Bitmap]::FromFile($path)
    $tmp = "$path.tmp"
    $flat = New-Object System.Drawing.Bitmap($src.Width, $src.Height,
        [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
    $g = [System.Drawing.Graphics]::FromImage($flat)
    $g.Clear([System.Drawing.ColorTranslator]::FromHtml('#120A2A'))
    $g.DrawImage($src, 0, 0, $src.Width, $src.Height)
    $g.Dispose()
    $src.Dispose()
    $flat.Save($tmp, [System.Drawing.Imaging.ImageFormat]::Png)
    $flat.Dispose()
    Move-Item -Force $tmp $path
    Write-Host "  ok $path"
}

Write-Host 'done'
