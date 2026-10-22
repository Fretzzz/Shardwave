# Shardwave

An 8×8 block puzzle with one extra rule: **Prism Resonance**.
Charge the Core by clearing lines. At 3 charges you're dealt a Prism.
A Prism counts as any block, and when its line clears it fires a
cross-beam that cascades through everything it touches.

**Studio:** AT8 Studios
**Package:** `com.at8studios.shardwave`
**Engine:** Godot 4.7 (GDScript, mobile renderer)
**Modes:** Classic · Void Rush · Daily Shard

## Toolchain

Everything is portable, nothing touches the registry:

| Tool | Location |
|---|---|
| Godot 4.7.2 | `C:\Tools\Godot\Godot_v4.7.2-stable_win64.exe` |
| Temurin JDK 17 | `C:\Tools\jdk17` |
| Android SDK | `C:\Tools\android-sdk` |

Godot editor settings must point at the JDK and SDK:
`Editor > Editor Settings > Export > Android`.

## Build

```powershell
# debug APK
C:\Tools\Godot\Godot_v4.7.2-stable_win64.exe --headless --path C:\Projects\Shardwave `
  --export-debug "Android" build/shardwave-debug.apk
```

Install on a connected device:

```powershell
C:\Tools\android-sdk\platform-tools\adb.exe install -r build\shardwave-debug.apk
```

## Signing

The release keystore lives **outside** this repo (see `C:\Keys\shardwave-release.jks`)
and is backed up separately. Losing it means never updating the app on Play.

## Structure

```
core/     pure logic, no nodes — unit tested
present/  views, FX, camera, HUD
meta/     save, audio, haptics, missions
scenes/   boot, menu, game, results
shaders/  aurora bg, glass blocks, beams
```

Rule: `core/` never imports a visual node. Visuals subscribe to signals.
