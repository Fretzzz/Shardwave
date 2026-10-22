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
.\tools\build.ps1 -Bundle      # release AAB for Play (needs Gradle template)
.\tools\version.ps1 -Version 0.2.0   # bump version name, code +1, both presets
```

The version tool updates `project.godot` and every Android preset together,
so the title screen and the store never disagree.

`tests/`, `tools/`, `build/`, `store/` and `*.md` are stripped from exports by
`exclude_filter` in `export_presets.cfg`.

### AAB (Play) builds

Play only accepts AABs for new apps, and Godot can only produce them through
its Gradle path — the prebuilt templates are APK-only. One-time setup:

```powershell
.\tools\install-android-template.ps1   # unzips android_source.zip to android\build
```

`android/` is gitignored and disposable. `-Bundle` runs Gradle with a portable
cache at `C:\Tools\gradle-home` (override with `GRADLE_USER_HOME`), JDK 17 from
`C:\Tools\jdk17` and the SDK from `C:\Tools\android-sdk`. The first build
downloads Gradle 8.11.1 + AGP 8.6.1 (~1.2 GB, a few minutes); after that a
bundle takes about a minute. Output: `build\shardwave-release.aab`.

`tools/store-assets.ps1` regenerates the Play screenshots, icons and feature
graphic; listing copy and the upload checklist live in `store/listing.md`.

## Test

```powershell
.\tools\test.ps1
```

Runs the pure-core suite (`tests/CoreTests.gd`, 43 checks) and the scene-shell
flow (`tests/FlowTest.tscn`, 18 checks): menu → game → results → pause →
focus-loss → menu, plus save-schema checks.
Dev screenshot helpers: `tests/Shot.gd`, `tests/FxShot.gd`,
`tests/ShotScene.tscn`, `tests/StoreShots.tscn`.

## Signing

The release keystore lives **outside** this repo at
`C:\Keys\shardwave-release.jks` (alias `shardwave`); the password is in
`C:\Keys\shardwave-signing.txt`. Back both up off this machine — losing them
means never updating the app on Play.

`export_credentials.cfg` in the project root holds the same values for local
builds and is gitignored. `build.ps1 -Release` translates it into
`.godot/export_credentials.cfg`, which is the only file Godot 4.7 reads
signing credentials from.

Android treats debug and release APKs as different signers, so switching
between them needs `adb uninstall com.at8studios.shardwave` first.

## Icons

`icons/` holds the launcher icon, adaptive foreground, background and
monochrome (Android 13+ themed) layers, plus the 512 px store icon. They are
drawn from the same geometry as `icon.svg` and can be regenerated with:

```powershell
.\tools\icons.ps1
```

The prebuilt-APK export path in Godot 4.7 writes `icon.xml` but drops
`themed_icon.xml`, so `aapt2 dump` prints a harmless missing-resource warning
for APKs. Gradle AABs (what Play receives) contain both files. Themed icons
work either way through the `<monochrome>` layer.

## Controls

- Touch a tray piece and drag it onto the board; release to place.
- Android back pauses the run (Resume / Quit to menu).
- Backgrounding the app (home, notification shade, screen off) auto-pauses.
- Menu toggles haptics and sound; both persist in `user://save.cfg`.

## Structure

```
core/     pure logic, no nodes — unit tested
present/  FX director + shared UI tokens
meta/     haptics, save, audio, session
scenes/   boot, menu, game, results
shaders/  aurora background
tests/    core + flow tests, dev screenshots (not shipped)
tools/    build, test, icon, store scripts (not shipped)
store/    Play listing copy, privacy policy, store images (not shipped)
```

Rule: `core/` never imports a visual node. Visuals subscribe to signals.
Rule: nothing outside `meta/Haptics.gd` calls `Input.vibrate_handheld()`.

## Current state

- **M0** — portable toolchain, signed debug APK, launch/render/haptics verified on device.
- **M1** — playable Classic loop: 8×8 board, tray of 3, clears, Prism cascade,
  Core charges, combo scoring, seeded deals.
- **Shell** — Boot → Menu → Game → Results, persistence, pause, synthesized SFX.
- **M2 (v0.2.0)** — Play-ready: AAB build path, focus-loss auto-pause, versioned
  save with migrations, adaptive + themed icons, store kit and privacy policy.
- **Next** — Play internal testing → Void Rush + Daily Shard → missions, streaks,
  share card → art/music pass.
