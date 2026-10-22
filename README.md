# Shardwave

An 8×8 block puzzle with one extra rule: **Prism Resonance**.
Charge the Core by clearing lines. At 3 charges you're dealt a Prism.
A Prism counts as any block, and when its line clears it fires a
cross-beam that cascades through everything it touches.

**Studio:** AT8 Studios
**Package:** `com.at8studios.shardwave`
**Engine:** Godot 4.7 (GDScript, GL Compatibility)
**Modes:** Classic · Void Rush* · Daily Shard*

\* menu placeholders until their rules ship.

## Toolchain

Everything is portable, nothing touches the registry:

| Tool | Location |
|---|---|
| Godot 4.7.2 | `C:\Tools\Godot\Godot_v4.7.2-stable_win64.exe` |
| Temurin JDK 17 | `C:\Tools\jdk17` |
| Android SDK | `C:\Tools\android-sdk` |

Godot editor settings must point at the JDK and SDK:
`Editor > Editor Settings > Export > Android`.
The Android preset also requires `import_etc2_astc=true` in `project.godot`
(Android exports hard-fail without it).

## Build

```powershell
.\tools\build.ps1              # debug APK -> build\shardwave-debug.apk
.\tools\build.ps1 -Install     # build, adb install -r, launch
.\tools\build.ps1 -Release     # release APK (needs export_credentials.cfg)
```

`tests/`, `tools/` and `build/` are stripped from the exported APK by
`exclude_filter` in `export_presets.cfg`.

## Test

```powershell
.\tools\test.ps1
```

Runs the pure-core suite (`tests/CoreTests.gd`) and the scene-shell flow
(`tests/FlowTest.tscn`): menu → game → results → pause → menu.
Dev screenshot helpers: `tests/Shot.gd`, `tests/FxShot.gd`, `tests/ShotScene.tscn`.

## Signing

The release keystore lives **outside** this repo at
`C:\Keys\shardwave-release.jks` (alias `shardwave`), with the password in
`C:\Keys\shardwave-signing.txt` and `export_credentials.cfg` (gitignored).
Both are backed up separately. Losing them means never updating the app on Play.

Widgets: `icons/` holds the Android launcher/adaptive icons, regenerated with
`.\tools\icons.ps1`.

## Controls

- Touch a tray piece and drag it onto the board; release to place.
- Android back pauses the run (Resume / Quit to menu).
- Menu toggles haptics and sound; both persist in `user://save.cfg`.

## Structure

```
core/     pure logic, no nodes — unit tested
present/  FX director + shared UI tokens
meta/     haptics, save, audio, session
scenes/   boot, menu, game, results
shaders/  aurora background
tests/    core + flow tests, dev screenshots (not shipped)
tools/    build, test, icon scripts (not shipped)
```

Rule: `core/` never imports a visual node. Visuals subscribe to signals.
Rule: nothing outside `meta/Haptics.gd` calls `Input.vibrate_handheld()`.

## Current state

- **M0** — portable toolchain, signed debug APK, launch/render/haptics verified on device.
- **M1** — playable Classic loop: 8×8 board, tray of 3, clears, Prism cascade,
  Core charges, combo scoring, seeded deals.
- **Shell** — Boot → Menu → Game → Results, persistence, pause, synthesized SFX.
- **Next** — real art/feel pass on the Prism cascade, Void Rush + Daily Shard,
  missions, store assets.
