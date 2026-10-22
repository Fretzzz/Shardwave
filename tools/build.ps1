# Build + install helpers for Shardwave.
# Usage:
#   .\tools\build.ps1            # debug APK
#   .\tools\build.ps1 -Release   # release APK (needs export_credentials.cfg)
#   .\tools\build.ps1 -Bundle    # release AAB for Play (needs Gradle template)
#   .\tools\build.ps1 -Install   # build debug, then adb install
#   .\tools\test.ps1             # core + flow tests

param(
    [switch]$Release,
    [switch]$Bundle,
    [switch]$Install
)

$ErrorActionPreference = 'Stop'

$godot = 'C:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe'
$adb = 'C:\Tools\android-sdk\platform-tools\adb.exe'
$jdk = 'C:\Tools\jdk17'
$sdk = 'C:\Tools\android-sdk'
$proj = Split-Path -Parent $PSScriptRoot
$buildDir = Join-Path $proj 'build'
New-Item -ItemType Directory -Force $buildDir | Out-Null

function Write-GodotCredentials {
    # Godot 4.7 only reads credentials from res://.godot/export_credentials.cfg,
    # in [preset.N.options] form. Our gitignored export_credentials.cfg is the
    # human-managed source; translate it on every release build.
    $src = Join-Path $proj 'export_credentials.cfg'
    if (-not (Test-Path $src)) {
        throw "release build needs $src (keystore path, alias, password)"
    }

    $values = @{}
    foreach ($line in Get-Content $src) {
        if ($line -match '^\s*([A-Za-z0-9_]+)\s*=\s*"(.*)"\s*$') {
            $values[$matches[1]] = $matches[2]
        }
    }
    foreach ($key in 'keystore', 'keystore_user', 'keystore_password') {
        if (-not $values.ContainsKey($key) -or [string]::IsNullOrWhiteSpace($values[$key])) {
            throw "export_credentials.cfg is missing $key"
        }
    }
    if (-not (Test-Path $values['keystore'])) {
        throw "keystore not found at $($values['keystore'])"
    }

    $content = @"
[preset.0.options]

keystore/release="$($values['keystore'])"
keystore/release_user="$($values['keystore_user'])"
keystore/release_password="$($values['keystore_password'])"

[preset.1.options]

keystore/release="$($values['keystore'])"
keystore/release_user="$($values['keystore_user'])"
keystore/release_password="$($values['keystore_password'])"

"@
    $godotDir = Join-Path $proj '.godot'
    New-Item -ItemType Directory -Force $godotDir | Out-Null
    $target = Join-Path $godotDir 'export_credentials.cfg'
    # ConfigFile is happy with plain UTF-8; a BOM is not worth the risk
    [System.IO.File]::WriteAllText($target, $content, (New-Object System.Text.UTF8Encoding($false)))
    Write-Host "credentials -> $target"
}

if ($Bundle) {
    Write-GodotCredentials
    if (-not (Test-Path (Join-Path $proj 'android\build\build.gradle'))) {
        throw "Gradle template missing; run .\tools\install-android-template.ps1"
    }
    # Gradle needs the JDK and SDK on the environment, and a portable cache.
    $env:JAVA_HOME = $jdk
    $env:ANDROID_HOME = $sdk
    $env:ANDROID_SDK_ROOT = $sdk
    if (-not $env:GRADLE_USER_HOME) { $env:GRADLE_USER_HOME = 'C:\Tools\gradle-home' }
    $out = Join-Path $buildDir 'shardwave-release.aab'
    Write-Host "exporting AAB -> $out"
    Write-Host "gradle cache: $env:GRADLE_USER_HOME"
    & $godot --headless --path $proj --export-release 'Android AAB' $out
} elseif ($Release) {
    Write-GodotCredentials
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
    # GodotApp is not exported; the launcher alias is the one Android can start.
    & $adb shell monkey -p 'com.at8studios.shardwave' -c android.intent.category.LAUNCHER 1 | Out-Null
}
