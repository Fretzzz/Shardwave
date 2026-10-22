# Shardwave — Play Store listing

Copy-paste source for the Play Console listing. Regenerate the images with
`.\tools\store-assets.ps1`.

## App identity

| Field | Value |
|---|---|
| Package | `com.at8studios.shardwave` |
| Category | Games → Puzzle |
| Tags | puzzle, block, offline, single player |
| Price | Free |
| Ads | No |
| In-app purchases | No |
| Content rating | Everyone / PEGI 3 (see questionnaire notes) |
| Contact email | `support@at8studios.com` _(confirm this mailbox exists)_ |
| Privacy policy URL | `https://at8studios.com/shardwave/privacy` _(host `privacy-policy.md` here)_ |

## Title (30 chars max)

```
Shardwave
```

## Short description (80 chars max)

```
An 8x8 block puzzle where charged Prisms fire cross-beams.
```

## Full description (4000 chars max)

```
Shardwave is an 8x8 block puzzle built around one idea: clearing a line is not the end of the job.

Fill rows and columns with glass shards. Every line you clear charges the Core. When the Core is full, a Prism joins your tray as a fourth piece. Place it, then clear its row or column — the Prism detonates in a cross and wipes everything in both directions at once.

Easy to learn. Nasty near the top of the board.

MODES
• Classic: one endless run, one best score to beat.
• Void Rush: 90 seconds on the clock. Every line buys 1.5 more, every Prism buys 4. How long can you keep it alive?
• Daily Shard: one seeded run a day, the same deal for everyone. Finish it to keep your streak.

FEATURES
• Core charges and Prism Resonance: one good clear sets up the next.
• Combo chains: keep clearing and every cascade pays more.
• One-thumb play: drag a piece, let go, it drops.
• Offline. No accounts, no ads, no in-app purchases.
• Haptics and sound can be switched off in the menu.

Made by AT8 Studios.
```

## Graphics

| Asset | File | Notes |
|---|---|---|
| App icon | `icons/store_icon_512.png` | 512x512, 24-bit, full bleed |
| Feature graphic | `store/feature-graphic-1024x500.png` | 1024x500, 24-bit |
| Phone 1 | `store/phone-01-menu.png` | 720x1280 (9:16) |
| Phone 2 | `store/phone-02-results.png` | 720x1280 |
| Phone 3 | `store/phone-03-board.png` | 720x1280 |
| Phone 4 | `store/phone-04-prism.png` | 720x1280 |
| Phone 5 | `store/phone-05-rush.png` | 720x1280, Void Rush clock |

720x1280 is inside Play's 320–3840 px range and exactly 9:16. Native 1080x1920
captures are a job for the art pass; device screen grabs are 1:2 and would be
rejected, so do not upload them as phone screenshots.

## Data safety

- Does the app collect or share required user data? **No.**
- No analytics, crash reporting, ads or third-party SDKs.
- No `INTERNET` permission: the APK requests `VIBRATE` only.
- Progress and settings live in app-private storage and go away on uninstall.
- Data deletion request: not applicable (nothing leaves the device).

## Content rating questionnaire notes

- No violence, blood, sexual content, profanity, drugs or gambling.
- No user-generated content, chat, or social features.
- No ads, no purchases, no data sharing.
- Haptics permission is used only for rumble feedback.

## Release checklist

1. `.\tools\version.ps1 -Version 0.3.0` (keeps both presets in sync).
2. `.\tools\test.ps1` — core + flow suites green.
3. `.\tools\build.ps1 -Bundle` — produces `build\shardwave-release.aab`.
4. Upload the AAB to **Internal testing** first; Play App Signing enrols the
   upload key (`C:\Keys\shardwave-release.jks`).
5. New personal developer accounts need a closed test with 12 testers for 14
   continuous days before production access. Start that track as soon as the
   internal build is clean.
6. Fill in the listing from this file, attach the five images, complete Data
   safety and the content rating questionnaire, then roll out.
