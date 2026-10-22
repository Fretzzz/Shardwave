# Rasterizes the Shardwave mark into Android launcher icon PNGs.
# Same geometry as icon.svg, drawn with System.Drawing so the build has no
# extra dependency. Re-run after changing the brand mark:
#   powershell -ExecutionPolicy Bypass -File .\tools\icons.ps1

param([string]$OutDir = (Join-Path (Split-Path -Parent $PSScriptRoot) 'icons'))

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$mint = [System.Drawing.ColorTranslator]::FromHtml('#5CF2C0')
$pink = [System.Drawing.ColorTranslator]::FromHtml('#FF5FA2')
$butter = [System.Drawing.ColorTranslator]::FromHtml('#FFD166')
$sky = [System.Drawing.ColorTranslator]::FromHtml('#5AC8FA')
$facet = [System.Drawing.ColorTranslator]::FromHtml('#B9A9FF')

function New-BrandImage {
    param(
        [int]$Size,
        [double]$ContentScale,
        [bool]$WithBackground,
        [bool]$Rounded,
        [bool]$Monochrome = $false
    )

    $bmp = New-Object System.Drawing.Bitmap($Size, $Size)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.Clear([System.Drawing.Color]::Transparent)

    # work in the 512x512 design space, then scale into place
    $s = ($Size / 512.0) * $ContentScale
    $g.TranslateTransform($Size / 2.0, $Size / 2.0)
    $g.ScaleTransform($s, $s)
    $g.TranslateTransform(-256.0, -256.0)

    if ($WithBackground) {
        $rect = New-Object System.Drawing.RectangleF(0, 0, 512, 512)
        $bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
            $rect,
            [System.Drawing.ColorTranslator]::FromHtml('#2A1758'),
            [System.Drawing.ColorTranslator]::FromHtml('#120A2A'),
            45.0)
        if ($Rounded) {
            $path = New-Object System.Drawing.Drawing2D.GraphicsPath
            $r = 112.0
            $path.AddArc(0, 0, 2 * $r, 2 * $r, 180, 90)
            $path.AddArc(512 - 2 * $r, 0, 2 * $r, 2 * $r, 270, 90)
            $path.AddArc(512 - 2 * $r, 512 - 2 * $r, 2 * $r, 2 * $r, 0, 90)
            $path.AddArc(0, 512 - 2 * $r, 2 * $r, 2 * $r, 90, 90)
            $path.CloseFigure()
            $g.FillPath($bg, $path)
            $path.Dispose()
        } else {
            $g.FillRectangle($bg, $rect)
        }
        $bg.Dispose()
    }

    # refracted beams, same angles as the SVG
    $beams = @(
        @(120, 112, $mint),
        @(404, 130, $pink),
        @(112, 392, $butter),
        @(398, 396, $sky)
    )
    if ($Monochrome) {
        $white = [System.Drawing.Color]::White
        $beams = @(
            @(120, 112, $white),
            @(404, 130, $white),
            @(112, 392, $white),
            @(398, 396, $white)
        )
    }
    foreach ($b in $beams) {
        $pen = New-Object System.Drawing.Pen($b[2], 14.0)
        $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
        $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
        $g.DrawLine($pen, 256.0, 256.0, [float]$b[0], [float]$b[1])
        $pen.Dispose()
    }

    # shard body
    $points = [System.Drawing.PointF[]]@(
        (New-Object System.Drawing.PointF(256, 84)),
        (New-Object System.Drawing.PointF(356, 256)),
        (New-Object System.Drawing.PointF(256, 428)),
        (New-Object System.Drawing.PointF(156, 256))
    )
    $shardRect = New-Object System.Drawing.RectangleF(156, 84, 200, 344)
    if ($Monochrome) {
        $shardBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    } else {
        $shardBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
            $shardRect,
            [System.Drawing.Color]::White,
            [System.Drawing.ColorTranslator]::FromHtml('#CFC4FF'),
            70.0)
    }
    $g.FillPolygon($shardBrush, $points)
    $shardBrush.Dispose()

    # facet line
    if (-not $Monochrome) {
        $facetPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(140, $facet), 6.0)
        $g.DrawLine($facetPen, 256.0, 84.0, 256.0, 428.0)
        $facetPen.Dispose()
    }

    $g.Dispose()
    return $bmp
}

New-Item -ItemType Directory -Force $OutDir | Out-Null

$jobs = @(
    @{ Name = 'icon_192.png'; Size = 192; Scale = 1.0; Bg = $true; Rounded = $true },
    @{ Name = 'adaptive_fg_432.png'; Size = 432; Scale = 0.62; Bg = $false; Rounded = $false },
    @{ Name = 'adaptive_bg_432.png'; Size = 432; Scale = 1.0; Bg = $true; Rounded = $false },
    # Android 13+ themed icon: a flat white silhouette the launcher tints
    @{ Name = 'adaptive_mono_432.png'; Size = 432; Scale = 0.62; Bg = $false; Rounded = $false; Mono = $true },
    # Play Store listing icon: full bleed, no rounded mask baked in
    @{ Name = 'store_icon_512.png'; Size = 512; Scale = 1.0; Bg = $true; Rounded = $false }
)

foreach ($job in $jobs) {
    $bmp = New-BrandImage -Size $job.Size -ContentScale $job.Scale -WithBackground $job.Bg -Rounded $job.Rounded -Monochrome ([bool]$job.Mono)
    $out = Join-Path $OutDir $job.Name
    $bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Host "wrote $out"
}
