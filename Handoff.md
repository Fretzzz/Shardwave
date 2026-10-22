# Shardwave — Agent Handoff

**Updated:** 2026-10-23
**Repo:** https://github.com/Fretzzz/Shardwave (private, branch `master`)
**Engine:** Godot **4.7.2 stable**, GL Compatibility
**Package:** `com.at8studios.shardwave`
**Studio:** AT8 Studios

---

## 1. What this project is

Shardwave is an 8×8 block puzzle for Android with one signature rule:

> Complete lines to charge the Core. At 3 charges the next tray refill deals a **Prism**.
> A Prism is a wildcard; clearing its row or column fires a cross-beam that cascades
> through every Prism it touches.

Modes:

- **Classic** — endless score attack.
- **Void Rush** — 90 seconds, starts on first placement; lines buy 1.5 s, Prisms buy 4 s.
- **Daily Shard** — one seeded run per local day, locked on finish, consecutive-day streak.

The current mission is a **complete crystalline sci-fi visual overhaul**, not a gameplay
rewrite. Gameplay, scoring, cascade order, persistence, and all modes must remain intact.

---

## 2. Read these first

| File | Why it matters |
|---|---|
| `README.md` | Build, signing, test, and architecture overview |
| `store/reference/Shardwave_ Neon Crystal Puzzle UI.png` | Visual target (6-screen UI board) |
| `store/listing.md` | Play listing, data safety, upload checklist |
| `tests/CoreTests.gd`, `tests/FlowTest.gd` | The contract; 54 core + 39 flow checks |
| `core/*.gd` | Pure logic — **do not edit for visual work** |
| `meta/Transition.gd` | Scene fade; now fixed and wired |

### Reference-image caveat

The previous agent **could not view images directly** (model limitation). The reference
was decoded with Windows OCR for text and k-means/colour analysis for palette. Fine
shapes, gradients, and iconography were **not** visually inspected. If you have vision,
open the reference and refine the details. The extracted palette and copy below are
reliable; the exact composition is the current agent’s best reconstruction.

---

## 3. Reference extraction (use these values)

### Palette (k-means from the reference)

| Role | Hex | Notes |
|---|---|---|
| Ground (deepest) | `#01031F` | Near-black navy |
| Ground | `#020427`, `#04072F`, `#06093B` | Background steps |
| Surface | `#0A0D32` | Panels |
| Surface raised | `#0D103B`, `#111863` | Cards / board panel |
| Indigo | `#191C87`, `#2D26B8` | Deep accent / outlines |
| **Primary violet** | `#5443EA` | Buttons, active borders, beams |
| Lilac | `#A07DF0` | Secondary highlight / crystal 4 |
| Ice white | `#DBE3F8` | Text, Prism body |
| Cyan | `#34B7EE` | Secondary accent / crystal 2 |
| Gold | `#E9AA40` | Warm accent / crystal 3 / NEW BEST |
| Danger (not in ref) | `#FF5470` | Invalid placement / low time only |

The old mint/pink scheme (`#5CF2C0`, `#FF5FA2`) is **not** in the reference and should be
retired from primary UI. Cyan replaces mint; gold replaces butter; lilac replaces pink
for positive highlights. Danger red is a functional exception.

### Copy from the reference

- Tagline: **“Place. Charge. Detonate.”** (replaces “Every clear shatters.”)
- Mode cards: **VOID RUSH / Beat the clock**, **DAILY SHARD / One run a day**
- Menu section label: **GAME MODES**
- HUD: **SCORE**, **CORE 2/3**, **COMBO x1.5**
- Prism cascade banner: **PRISM RESONANCE!**
- Prism explainer: **EVERY 3 CHARGES, GET A PRISM!** / “A Prism clears its row and column,
  triggering a Resonance Cascade.”
- Settings: **SETTINGS**, **AUDIO** rows **Music**, **SFX**, **Haptics**, **Reduced Effects**,
  **ABOUT**, **Shardwave v0.5.0**, **AT8 Studios**
- Game over: **GAME OVER**, big score, **BEST 48,720**, **RETRY**, **HOME**

The reference is a 3×2 board of six phone screens: menu, gameplay, prism gameplay,
settings/how-to-play, game-over, and a modes/menu variant. Our app has four scenes
(`Boot`, `Menu`, `Game`, `Results`), so the settings/how-to-play content belongs in a
Menu overlay rather than a new scene unless the team decides otherwise.

---

## 4. Current implementation state

### Completed and verified

- **M0 toolchain** — portable Godot/JDK/SDK, signed debug APK, device verified.
- **M1 gameplay** — 8×8 board, tray, clears, Prism cascade, Core, combo, seeded deals.
- **Shell** — Boot → Menu → Game → Results, persistence, pause, synthesized SFX.
- **v0.2.0** — Play-ready AAB path, focus-loss pause, save migrations, icons, store kit.
- **v0.3.0** — Void Rush + Daily Shard, per-mode bests, daily lock/streak.
- **v0.4.0 (staged, not committed)** — streak strip, stats overlay, “to go” target,
  copy score, rush countdown ticks/time-up SFX, focus-loss hardening.
- **Stage 0 of visual overhaul** — fixed `meta/Transition.gd` (it previously created an
  **opaque** full-screen overlay and was never played, hiding every scene), wired
  `Transition.play()` into Boot/Menu/Game/Results, added `skip()`/`enabled`.

**Last verified test run:** after Stage 0, `tools/test.ps1` → **54 core + 39 flow pass**
(with a benign `2 ObjectDB instances leaked at exit` warning).

### Stage 1 in progress (unfinished)

- `fonts/SpaceGrotesk-Variable.ttf` + `fonts/OFL.txt` added (SIL OFL, 136 KB).
- `present/TypeKit.gd` added — cached `FontVariation` weights (`body`, `medium`, `bold`,
  `display`, `micro`, `number`). **Not yet wired into `Ui.gd` or any scene.**
- `present/Ui.gd` still has the old mint/pink palette and fallback font.
- Backdrop scene, refreshed aurora shader, Boot/Menu branding, board/HUD/tray views,
  Prism shader, Results celebration, responsive layout, and store-shot regen are **not done**.
- The reference image was moved to `store/reference/` so it is **not exported** into the APK
  (`store/` is in `export_presets.cfg`’s exclude filter).

### Font API notes

- Space Grotesk’s default instance is Light 300. Set weight explicitly.
- `FontVariation.variation_opentype` **ignores string keys** (`{"wght": 700}`). Use the
  OpenType integer tag:
  ```gdscript
  var ts := TextServerManager.get_primary_interface()
  fv.variation_opentype = { ts.name_to_tag("wght"): 650 }
  ```
- `spacing_glyph` works for tracked uppercase labels.
- `opentype_features = {"tnum": true}` is accepted (tabellars are not guaranteed by the face).

---

## 5. Architecture (do not break)

```
core/       pure logic, no nodes, unit tested
present/    draw helpers, FX director, future views
meta/       autoloads: Haptics, Save, Audio, Session, Transition
scenes/     Boot, Menu, Game, Results
shaders/    aurora (+ future prism shader)
tests/      core + flow tests and dev screenshot harnesses (not shipped)
tools/      build/test/store scripts (not shipped)
store/      listing, screenshots, reference board (not shipped)
fonts/      bundled typeface + license (shipped)
```

Rules:

- `core/` never imports a visual node. Visuals subscribe to or read state; they never write it.
- Nothing outside `meta/Haptics.gd` may call `Input.vibrate_handheld()`.
- Scene paths, package ID, input semantics, and scoring are frozen for this pass.
- `FlowTest` calls `Menu._tap`, `Game._press`, `Game._on_cleared`, `Game._on_game_over`,
  `Game.state`, `Game.paused`, `Game.rush_time`, `Results._tap`, `Results.copied`.
  Preserve those and the design-size hit rects.

### Key geometry at 720×1280 (must remain exact for tests)

- Board origin `(72, 300)`, cell `72`, board `576×576`.
- Tray slots `208×168`, gap `24`, `TRAY_Y = 1010`.
- Pause: `RESUME_RECT (130,620,460,110)`, `QUIT_RECT (130,760,460,96)`.
- Menu: PLAY `(130,540,460,116)`, VOID `(130,700,460,96)`, DAILY `(130,816,460,96)`,
  HAPTICS `(130,980,220,80)`, SOUND `(370,980,220,80)`, BEST `(160,356,400,112)`.
- Results: AGAIN `(130,880,460,116)`, MENU `(130,1026,460,96)`,
  COPY `(130,1148,460,60)`.

`FlowTest` taps: PLAY `(360,598)`, VOID `(360,748)`, DAILY `(360,864)`,
BEST `(360,412)`, stats close `(360,640)`, resume `(360,675)`, quit `(360,808)`,
results AGAIN `(360,938)`, results MENU `(360,1074)`, copy `(360,1178)`.

---

## 6. Planned visual overhaul (approved plan)

Follow these stages in order. Run import + tests after each.

### Stage 1 — foundation + branding (IN PROGRESS)

1. Rewrite `present/Ui.gd` with the reference palette, shard panels, `TypeKit` labels,
   tracked micro-labels, diamonds, hairlines. Keep `panel()` / `label()` signatures
   (add optional `font` param at the end).
2. Create `present/Backdrop.tscn` + `Backdrop.gd`: full-rect aurora + sparse ice motes
   (CPUParticles2D, additive, radial GradientTexture2D, no external textures). Respect
   `Save.reduced_fx`.
3. Refresh `shaders/aurora.gdshader`: navy → violet nebula, cyan rim, subtle grain,
   vignette, low cost. Keep GL Compatibility.
4. Replace the four scenes’ `Aurora` ColorRect with the Backdrop instance; add it to Boot.
5. Rebrand Boot (wordmark, tagline, faceted shard mark, `Transition.play()`).
6. Rebrand Menu: wordmark + “PLACE. CHARGE. DETONATE.”, BEST, GAME MODES label,
   PLAY, VOID RUSH / DAILY SHARD cards, HAPTICS/SOUND toggles, settings gear, streak strip,
   footer. Add a settings overlay: PRISM RESONANCE explainer, AUDIO rows (Music / SFX /
   Haptics / Reduced Effects), ABOUT. Keep all hit rects above.
7. Save schema **4**: add `music` and `reduced_fx` (defaults true / false) with migration;
   add real `Audio` ambient loop (synthesized, seamless, no assets) and
   `Audio.set_music_enabled()`. No fake toggles.
8. Add tests: font loads, palette/shader load, settings open/toggle/persist, layout at
   720×1280 exact.

### Stage 2 — board and crystal system

- `present/Crystal.gd`: reusable faceted crystal body/ghost/empty-well/prism-base drawing.
  Crystals: `#5443EA`, `#34B7EE`, `#E9AA40`, `#A07DF0`; Prism `#DBE3F8`.
- `present/BoardView.gd`: board panel, 8×8 wells, crystals, ghost/invalid tint, placement
  pop, clearing shard dissolve driven by `ClearResult.waves`. Read-only on `RunState`.
- `present/PrismCell.gd` + `shaders/prism.gdshader`: pooled iridescent Prism overlays
  (shared shader, per-cell seed), GL-compatible beveled mask.
- Wire into `Game.tscn`; keep `Fx` above views and `Game`’s public fields/methods.
- Input and `RunState.place()` stay synchronous and untouched.

### Stage 3 — HUD, tray, Core

- `present/HudView.gd`: SCORE top-left, COMBO panel top-right, CORE `2/3` pips,
  mode chip (RUSH time / DAILY shard), best line, score popups, low-time treatment.
- `present/TrayView.gd`: glass slots, piece previews, drag piece, Prism spawn.
- `PRISM RESONANCE!` banner in HUD on `result.prisms > 0`.
- Preserve tray geometry and `_slot_rect` math at 720×1280.

### Stage 4 — motion, resonance, cascades

- Upgrade `present/Fx.gd`: layered violet/cyan/white beams, rings, gold sparks, shard
  debris, per-wave stagger, restrained shake (≤10 px), reduced-effects path.
- Placement settle/pop, line bands, charge pulse, Prism generation, time-up flash.
- Animations are presentation-only: no `await` in input, no state delay, no input blocking.

### Stage 5 — Results celebration

- New-best rays/sparkles, count-up score, “GAME OVER” headline, BEST / TO GO, RETRY / HOME
  labels, keep COPY SCORE functional. Keep Results rects.
- Regenerate all store screenshots (720×1280, 24-bit PNG, no alpha).

### Stage 6 — responsive + polish + release

- `present/Layout.gd`: exact current geometry at 720×1280; tray anchored near the bottom;
  board centered in the play area; content horizontally centered on wide viewports;
  safe-area insets on Android. Verify 720×1280, 720×1600, 600×1280, 1080×2400.
- Performance pass on Pixel 3 class hardware; cap particles; prewarm shaders.
- Bump to 0.5.0, rebuild APK + AAB, verify signer/versionCode/bundletool, device sanity.
- Update README/store listing. Flag invented placeholders (support email, privacy URL)
  before any Play upload.

---

## 7. Commands and environment

Godot console:

```powershell
C:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe
```

```powershell
# Reimport after adding class_name scripts or fonts
& 'C:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --import

# Tests: 54 core + 39 flow (scratch save, real streak safe)
.\tools\test.ps1

# Desktop visual run
& 'C:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe' --path . --rendering-method gl_compatibility --rendering-driver opengl3

# Debug install / release / bundle
.\tools\build.ps1 -Install
.\tools\build.ps1 -Release
.\tools\build.ps1 -Bundle
.\tools\version.ps1 -Version 0.5.0

# Store assets (needs a rendering context, not --headless)
.\tools\store-assets.ps1
```

Signing:

- Keystore `C:\Keys\shardwave-release.jks`, alias `shardwave`, password in
  `C:\Keys\shardwave-signing.txt`.
- `export_credentials.cfg` is gitignored; never commit it.
- Debug and release APKs have different signers; `adb uninstall` before switching.

Device used previously: `896X05Z5J` (1080×2160). Coordinates:
PLAY `(540,897)`, VOID `(540,1122)`, DAILY `(540,1296)`, BEST `(540,618)`,
pause RESUME `(540,1012)`, QUIT `(540,1212)`, results MENU `(540,1074)`.

---

## 8. Known issues / gotchas

- **Model vision limitation:** reference image could not be inspected visually. Use the
  extracted palette/copy, then confirm shapes and spacing against the image.
- `Transition` autoload must stay transparent at rest. It now starts alpha 0 and fades in
  on `play()`. Do not make it opaque by default again.
- `StoreShots` renders into a `SubViewport`; the global Transition overlay does not appear
  there, but scene animations/count-ups still need settle frames.
- `FontVariation.variation_opentype` string keys are silently ignored — use integer tags.
- `--headless` cannot render store shots. Use the GL command above.
- `--script` mode has no autoloads; use scene harnesses for Save/Audio.
- PowerShell 5.1: read UTF-8 with `[System.IO.File]::ReadAllText(..., UTF8)`; `adb exec-out >`
  corrupts binary (use screencap/pull).
- Gradle AAB path needs the gitignored `android/` template and `C:\Tools\gradle-home`.
- `jarsigner` notes on the AAB are benign; `jar verified` is the pass signal.
- Current FlowTest exit prints `2 ObjectDB instances were leaked at exit`; tests still pass.
  Investigate if it grows.

---

## 9. Git / GitHub status

- **Published:** https://github.com/Fretzzz/Shardwave — private, default branch `master`.
- Remote `origin` is configured; `master` tracks `origin/master`.
- Handoff checkpoint: `5494532 v0.4.0 retention + visual overhaul checkpoint`.
- History: `5494532` → `daa8278 v0.3.0` → `c968610 v0.2.0` → earlier M0/M1 commits.
- `gh` is authenticated as **Fretzzz** with `repo` scope.
- No signing material is tracked. Verified absent: `export_credentials.cfg`, `*.jks`,
  `*.keystore`, `.godot/`, `build/`, signing notes.
- 99 tracked files at the checkpoint.

```powershell
# Fresh clone
git clone https://github.com/Fretzzz/Shardwave.git
cd Shardwave

# Continue work
git pull --rebase
git add -A
git commit -m "<stage>: <what changed>"
git push
```

---

## 10. Immediate next steps

1. Open the reference image and sanity-check the reconstructed palette/spacing.
2. Finish Stage 1: `Ui.gd`, Backdrop, aurora shader, Boot, Menu, Save schema 4, Audio music,
   settings overlay, tests.
3. Run `--headless --import` and `tools/test.ps1`; fix regressions.
4. Proceed to Stage 2 (crystal/board) only after the menu/branding pass is visually reviewed.
5. Regenerate store assets at the end; do not upload to Play until support email and
   privacy-policy hosting URL are real (currently placeholders in `store/listing.md`).
