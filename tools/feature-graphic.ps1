# Draws the Play Store feature graphic (1024x500) from the brand mark.
# Copy is intentionally plain text so it can be re-run after a rename.
#   powershell -ExecutionPolicy Bypass -File .\tools\feature-graphic.ps1

param([string]$Out = '')

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$proj = Split-Path -Parent $PSScriptRoot
if (-not $Out) { $Out = Join-Path $proj 'store\feature-graphic-1024x500.png' }
New-Item -ItemType Directory -Force (Split-Path -Parent $Out) | Out-Null

$W = 1024
$H = 500

$bgStart = [System.Drawing.ColorTranslator]::FromHtml('#2A1758')
$bgEnd = [System.Drawing.ColorTranslator]::FromHtml('#0D0720')
$mint = [System.Drawing.ColorTranslator]::FromHtml('#5CF2C0')
$pink = [System.Drawing.ColorTranslator]::FromHtml('#FF5FA2')
$butter = [System.Drawing.ColorTranslator]::FromHtml('#FFD166')
$sky = [System.Drawing.ColorTranslator]::FromHtml('#5AC8FA')
$text = [System.Drawing.ColorTranslator]::FromHtml('#F4F0FF')
$dim = [System.Drawing.ColorTranslator]::FromHtml('#8A7AB8')

$bmp = New-Object System.Drawing.Bitmap($W, $H)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

# background
$rect = New-Object System.Drawing.RectangleF(0, 0, $W, $H)
$bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    $rect, $bgStart, $bgEnd, 20.0)
$g.FillRectangle($bg, $rect)
$bg.Dispose()

# soft aurora glows (stacked translucent ellipses, no blur needed)
function Add-Glow([double]$cx, [double]$cy, [double]$r, [System.Drawing.Color]$color, [int]$alpha) {
    for ($i = 6; $i -ge 1; $i--) {
        $rr = $r * ($i / 6.0)
        $a = [int]($alpha * (1.0 - ($i / 7.0)))
        $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($a, $color))
        $g.FillEllipse($brush, [float]($cx - $rr), [float]($cy - $rr), [float]($rr * 2), [float]($rr * 2))
        $brush.Dispose()
    }
}
Add-Glow 180 250 260 $mint 26
Add-Glow 820 120 300 $pink 18
Add-Glow 640 460 320 $sky 14

# faint board grid, bottom right
$gridPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(14, 244, 240, 255), 1.0)
$cell = 46
$gx0 = 560
$gy0 = 250
for ($i = 0; $i -le 6; $i++) {
    $g.DrawLine($gridPen, $gx0 + $i * $cell, $gy0, $gx0 + $i * $cell, $gy0 + 6 * $cell)
    $g.DrawLine($gridPen, $gx0, $gy0 + $i * $cell, $gx0 + 6 * $cell, $gy0 + $i * $cell)
}
$gridPen.Dispose()

# --- brand mark, drawn in the 512x512 design space, centred on the left ---
$state = $g.Save()
$g.TranslateTransform(210.0, 250.0)
$g.ScaleTransform(0.86, 0.86)
$g.TranslateTransform(-256.0, -256.0)

# refracted beams
$beams = @(
    @(120, 112, $mint),
    @(404, 130, $pink),
    @(112, 392, $butter),
    @(398, 396, $sky)
)
foreach ($b in $beams) {
    $pen = New-Object System.Drawing.Pen($b[2], 16.0)
    $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $g.DrawLine($pen, 256.0, 256.0, [float]$b[0], [float]$b[1])
    $pen.Dispose()
}

# shard
$points = [System.Drawing.PointF[]]@(
    (New-Object System.Drawing.PointF(256, 84)),
    (New-Object System.Drawing.PointF(356, 256)),
    (New-Object System.Drawing.PointF(256, 428)),
    (New-Object System.Drawing.PointF(156, 256))
)
$shardRect = New-Object System.Drawing.RectangleF(156, 84, 200, 344)
$shardBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    $shardRect, [System.Drawing.Color]::White, [System.Drawing.ColorTranslator]::FromHtml('#CFC4FF'), 70.0)
$g.FillPolygon($shardBrush, $points)
$shardBrush.Dispose()

$facetPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(140, [System.Drawing.ColorTranslator]::FromHtml('#B9A9FF')), 7.0)
$g.DrawLine($facetPen, 256.0, 84.0, 256.0, 428.0)
$facetPen.Dispose()
$g.Restore($state)

# --- copy ---
function Draw-Tracked([string]$str, [double]$x, [double]$y, [System.Drawing.Font]$font,
                      [System.Drawing.Brush]$brush, [double]$tracking) {
    $cx = $x
    foreach ($ch in $str.ToCharArray()) {
        $g.DrawString([string]$ch, $font, $brush, [float]$cx, [float]$y)
        $cx += $g.MeasureString([string]$ch, $font).Width + $tracking
    }
}

$studioFont = New-Object System.Drawing.Font('Segoe UI', 13, [System.Drawing.FontStyle]::Bold)
$titleFont = New-Object System.Drawing.Font('Segoe UI', 54, [System.Drawing.FontStyle]::Bold)
$tagFont = New-Object System.Drawing.Font('Segoe UI', 19, [System.Drawing.FontStyle]::Regular)

$textBrush = New-Object System.Drawing.SolidBrush($text)
$mintBrush = New-Object System.Drawing.SolidBrush($mint)
$dimBrush = New-Object System.Drawing.SolidBrush($dim)

Draw-Tracked 'AT8 STUDIOS' 372 150 $studioFont $dimBrush 3.2
Draw-Tracked 'SHARDWAVE' 369 178 $titleFont $textBrush 1.0

# rule under the title
$rulePen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(70, $mint), 2.0)
$g.DrawLine($rulePen, 372, 296, 700, 296)
$rulePen.Dispose()

$g.DrawString('Every clear shatters.', $tagFont, $mintBrush, 372, 312)
$g.DrawString('An 8x8 block puzzle built around Prism Resonance.', $tagFont, $dimBrush, 372, 352)

$studioFont.Dispose()
$titleFont.Dispose()
$tagFont.Dispose()
$textBrush.Dispose()
$mintBrush.Dispose()
$dimBrush.Dispose()

$g.Dispose()

# Play wants 24-bit PNG, and GDI+ gradients can leave alpha in the corners.
$flat = New-Object System.Drawing.Bitmap($W, $H, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
$fg = [System.Drawing.Graphics]::FromImage($flat)
$fg.Clear([System.Drawing.ColorTranslator]::FromHtml('#0D0720'))
$fg.DrawImage($bmp, 0, 0, $W, $H)
$fg.Dispose()
$bmp.Dispose()

$flat.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
$flat.Dispose()

Write-Host "wrote $Out"
