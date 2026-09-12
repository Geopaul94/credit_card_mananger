# AGENTS.md — credit_card_mananger

Universal project brief for **any** AI coding tool (Claude Code, Codex, Cursor, Copilot,
Gemini CLI, Aider, Windsurf, Zed…). Read this file first, then `CLAUDE.md`.

> `CLAUDE.md` in this folder is the **single source of truth** for current status, the sprint
> plan and the history. This file holds only the stable facts and the house rules. If the two
> disagree, `CLAUDE.md` wins — and this file needs updating.

## Project

| | |
|---|---|
| **App** | Card Vault — project notes |
| **Package / applicationId** | `com.geo.credit_cards` |
| **Stack** | Flutter (Dart) — Android first, iOS-capable |
| **SDK levels** | set by the Flutter toolchain (`flutter.*Version` in `android/app/build.gradle`) |
| **Version** | 1.0.5+7 |
| **Repo** | https://github.com/Geopaul94/credit_card_mananger.git |
| **Distribution** | Google Play — production quality from day one |
| **Owner** | Geo Paulson · geopaul94@gmail.com |

## Build & run

```bash
flutter pub get
flutter run                          # debug on the connected device
flutter test                         # unit + widget tests
flutter build appbundle --release    # Play upload artifact
```

Windows machine notes:
- `java` is **not** on PATH. Set `JAVA_HOME="C:\Program Files\Android\Android Studio\jbr"` (OpenJDK 21).
- adb: `C:\Users\geopa\AppData\Local\Android\Sdk\platform-tools\adb.exe`
- Test device: Redmi `24094RAD4I` over WiFi. It exposes **two** adb transports for the one phone —
  always target one with `adb -s <serial>`, and re-run `adb devices` first (the serial changes).

## Architecture rules

- Clean Architecture: `data` / `domain` / `presentation`, with use-cases and repositories.
- DRY, single responsibility, meaningful names. No empty `catch`. Null-safety at the edges.
- Screen file > 300 lines → extract into `components/` (Compose) or `widgets/` (Flutter). Split again at 150.
- No main-thread work — coroutines / isolates for DB, network and image work. Lazy-load lists.
- Sensitive data → `EncryptedSharedPreferences` / `flutter_secure_storage`, never plain SharedPreferences.

## UI rules

- Design tokens only, from `Theme.kt` / `theme.dart`. **Never** hardcode `16.dp` or `Color(0xFF…)`.
- Spacing 4/8/12/16/24/32/48 dp · Material 3 type scale · named color tokens · dark mode from day one.
- Every screen ships 4 states: Loading (skeleton) / Empty (illustration + CTA) / Error (message + retry) / Success.
- Motion 150–300 ms · touch targets ≥ 48 dp · ripple on every tap · haptics on destructive and confirm actions · respect insets.
- Icons: Material Symbols. Consistent corner radius and elevation.
- 3+ sections → bottom nav (3–5 tabs, icon + label, M3 pill), tab state surviving process death,
  per-tab scroll and back stack preserved. Home first, Settings last.

## Testing

- Every sprint: unit tests for the use-cases **plus** a manual pass on the real device.
- Edge cases that must be checked: empty state, no internet, first launch, very large input.
- Always smoke-test the **signed release** build before a Play upload — debug skips R8 and has
  hidden a launch crash before.

## Git rules

- **Never commit or push without asking Geo first.** Say what and why, wait for an explicit yes. Every time.
- **No AI attribution** in commits or PRs (no `Co-Authored-By`, no "Generated with…").
- Commit format: `type: short description`. Branch per sprint, merge to `main` after the checklist.
- Identity: `Geo Paulson` / `geopaul94@gmail.com`.
- Never commit `key.properties`, `*.jks`, API keys or AdMob IDs — `.gitignore` them from day one.
- `git fetch origin` when opening the repo.
- `versionName` = major.minor.patch · `versionCode` +1 per upload · keep `CHANGELOG.md`.

## Play Store rules

- Every upload ships a full ASO pack saved at `store/aso.md` — never a placeholder listing.
  Keyword-led title (30 chars, `Brand — Primary Keyword`), an 80-char benefit short description
  containing the primary keyword, and a 4000-char full description whose first 3 lines are the whole pitch.
- **Superlatives are banned** from the title, icon, developer name, feature graphic and screenshots:
  no `Best`, `#1`, `Top`, `Free`, `No Ads`, `Ad-Free`, `Sale`, or any price / ranking / performance claim.
  The same claim as a plain factual line inside the description **body** is fine. This exact mistake
  got a sibling app rejected.
- Never use film stills, posters or actor likenesses in the app or its store assets.
- Feature graphic 1024×500, 24-bit RGB, **no alpha channel**. Screenshots 1080×1920 portrait, 5–8, real app screens.
- Ask for a rating after a success moment — never on launch, never twice.

## Keystore & signing

- After creating a keystore, **stop** and confirm every detail with Geo before continuing:
  `.jks` path plus a backup in `D:\PlayStoreBackups`, alias, both passwords (in gitignored
  `key.properties`), validity ≥ 10000 days, SHA-1 + SHA-256 from `keytool -list -v`,
  `signingConfigs.release` actually wired into `buildTypes.release`, and a release AAB verified
  as signed by that key.
- **Never** regenerate or replace the keystore of an app already on Play — Play rejects a different
  key permanently.

## Ads

- **Never** add a personalised-ad consent form (Google UMP or any CMP).
- Therefore every ad-supported app is restricted to **India only** in Play Console. Shipping wider
  requires a CMP first — flag it, never ship worldwide without one.

## How to work here

- One sprint at a time. At sprint end: test with dummy data → build and verify on device →
  ask permission → commit → update `CLAUDE.md` → stop.
- Geo is a Kotlin beginner: explain a new concept with a tiny example before using it, and close
  each sprint with 3–5 "what you learned" bullets.
- Ask before deleting anything, force pushing, downgrading a dependency, regenerating a keystore
  or resetting gradle.
- Flag cross-module impact **before** changing it. On any doubt about architecture, naming or
  dependencies — ask, and recommend an option.
