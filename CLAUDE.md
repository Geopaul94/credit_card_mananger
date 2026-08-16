# Card Vault — project notes

Flutter app (not Kotlin). Personal credit/debit/prepaid card organiser, on-device
encrypted, biometric-locked. Live on the Play Store.

| | |
|---|---|
| applicationId | `com.geo.credit_cards` — **never change this** |
| App name | Card Vault |
| Current version | 1.0.3+4 (unreleased; 1.0.1+2 is live) |
| Keystore backup | `D:\PlayStoreBackups\cardvault_drive_playstore_backup` |
| Privacy policy | `docs/privacy-policy.html` |

## Architecture

Clean Architecture + BLoC/Cubit, with `get_it` for DI (`lib/core/di/service_locator.dart`).

```
lib/
  core/
    auth/         biometrics (AuthCubit, BiometricService)
    backup/       Drive backup/restore (BackupCubit, GoogleDriveService)
    di/           service_locator.dart
    encryption/   AES for local storage + backup payloads
    notifications/ NotificationService — scheduling + Paid/Snooze/Skip actions
    storage/      SecureCardStorage (encrypted local persistence)
    theme/        AppTheme (indigo), WarmTheme (cream/terracotta, default),
                  ThemeCubit (variant + mode), CardPalette (per-card colour)
    ui/           responsive_layout.dart (context.spacing/font helpers)
    utils/        card_input.dart (validators, formatters)
  features/
    cards/
      domain/       PaymentCard entity, repository interface, use cases
      data/         models, local data source, repository impl, OCR scan service
      presentation/
        bloc/       card_overview, add_card, bottom_navigation
        pages/      home, add_card, edit_card, card_detail, reminder, profile
        widgets/    card_tile (CardFrontFace/CardBackFace), card_chip, card_brand,
                    card_form_field, section_card, empty_card_view, card_skeleton,
                    bottom_navigation_bar, swipe_to_confirm, due_date_calendar
    backup/       BackupScreen (own bottom-nav tab, not nested in Profile)
    lock/         LockScreen
```

Data flows: screen → `CardOverviewBloc` event → use case → repository →
`SecureCardStorage` (AES-encrypted JSON blob in SharedPreferences).

## Completed sprints

- **Core vault** — add/view/delete cards, AES-256 storage, biometric app lock.
- **Scanning** — ML Kit on-device OCR, front + back capture, photo deleted after reading.
- **Due dates** — reminder scheduling, swipe-to-mark-paid.
- **Drive backup** — optional encrypted backup/restore to the user's own Drive appdata.
- **Play readiness** — release signing, R8 + resource shrinking, privacy policy,
  launcher icon, input validation. Shipped 1.0.0 and 1.0.1.
- **CVV removal** (1.0.1) — stripped entirely to get through review.
- **CVV restore** (1.0.2) — brought back as an **optional** field, shown plainly
  (Geo's call: the app lock is the gate; no per-view biometric prompt).
- **UI overhaul, round 1** (1.0.2) — brand marks + per-bank colours on card faces,
  useful home header, search, drag-to-reorder, expiry warnings, empty-state CTA,
  skeleton loading, branded splash, haptics, typography onto the theme's type
  scale, text-scale support, heavy dedup (detail screen 1587 → ~700 lines).
- **Reminders & editing** (1.0.2) — notification actions (Paid/Snooze/Skip) in a
  background isolate, reminders moved to 9 PM, inexact alarms (exact-alarm
  permissions dropped), permission asked in context, reminders-tab badge, a
  single edit screen owning every field, one 1–31 due-day picker.
- **Warm theme + redesign, round 2** (1.0.3) — full second visual pass against
  reference mockups, screen by screen, on top of everything above:
  - `WarmTheme`: cream/terracotta/olive palette, selectable via `ThemeCubit`
    alongside the original indigo `AppTheme` (defaults to Warm). Bundled
    **Playfair Display** (OFL, `assets/fonts/`) for headline text only
    (`displaySmall`/`headlineMedium`/`headlineSmall`); everything else stays Inter.
  - Bottom nav rebuilt: 4 equal tabs (Cards/Reminders/Backup/You), no centre
    slot; add-card moved to a `FloatingActionButton` on Home. Selected tab is a
    solid `inverseSurface`/`onInverseSurface` pill.
  - Home: new header (greeting + "My cards" + search toggle) and a next-bill
    hero card; the card list itself is unchanged (still full `CardTile` gradient
    cards, reorderable) — a deliberate choice, see Gotchas.
  - Reminders: only the Upcoming/Paid rows restyled (bank-code `CardChip` +
    full date + a real **Snooze** button via `NotificationService.snoozeFromList()`).
    The summary header and the DUE NOW swipe-to-pay card were left alone.
  - Card detail: auto-flip-to-back-on-entry removed (stays on front until
    tapped). Edit/Delete moved out of the app bar into a **Copy / Edit / Share
    / Delete** action row. Copy and Share both read from one `_detailsText()`
    (number, holder, expiry, CVV if stored); Share confirms before opening the
    OS share sheet (`share_plus`), since it can leave a full number + CVV.
  - Backup: added **Delete cloud backup** (Drive file only, device untouched —
    stated three times: row subtitle, confirm dialog, toast) and an
    offline-first note above the account section.
  - Empty vault + lock screens simplified to match their mockups, keeping all
    existing logic (Drive-aware restore copy; auth error/retry/lockout states).
    Lock screen deliberately says "Tap to unlock", not "Face ID" — that's an
    iOS term and this is Android.

## Next sprint (proposed)

1. **The You/Settings screen was never redesigned or extended.** Early in the
   round-2 work Geo asked for four real features there — a theme picker, a text-size
   setting, an app-lock delay setting, a "Data safety" info screen — and said
   "build all as real features." Only the *backing* infrastructure for one of
   them shipped (`ThemeCubit` already supports variant + mode); there is no
   picker UI, and the other three don't exist at all. `profile_screen.dart` is
   still on the plain indigo-adjacent styling from before this round.
2. **The app's actual launcher icon is still the old indigo design**
   (`assets/icon/ic_full.png` / `ic_fg.png` / `ic_bg.png`), never regenerated to
   match Warm. Surfaced while placing the icon inside the empty-vault circle —
   `ic_fg.png`'s glyph itself (not just backgrounds) is indigo/white, so even
   the in-app placement is a deliberate mismatch, not a real fix. This is what
   shows on the phone's home screen and app drawer, so it's a first-impression
   issue, not a cosmetic detail.
3. **Device-test the reminder notification actions** (Paid/Snooze/Skip) with the
   app fully closed — still unverified. Claude cannot tap through this device
   (input injection blocked, no INJECT_EVENTS permission over this ADB
   connection) and cannot force the app to stay backgrounded for a real
   notification-tap test; this needs a human pass.
4. Update the Play Console **Data Safety** form (CVV storage), then upload.
5. Install Android **cmdline-tools** to fix the cosmetic `flutter build
   appbundle` exit-1 (see Known issues).

## Known issues / TODO

- `flutter build appbundle --release` **exits with code 1** — "failed to strip debug
  symbols". The bundle is still produced and correctly signed; Flutter verifies
  stripping with `apkanalyzer` from the Android **cmdline-tools** component, which
  isn't installed on this machine. Fix: Android Studio → SDK Manager → SDK Tools →
  "Android SDK Command-line Tools". (Debug builds exit 0.) Every release bundle
  built so far has been manually verified (signature, versionCode, ABIs) despite
  this — see `D:\PlayStoreBackups\cardvault_drive_playstore_backup\README-CARDVAULT.md`.
- Flutter warns the project should migrate to **Built-in Kotlin** (Kotlin Gradle
  Plugin deprecation) — not urgent, but will break on a future Flutter upgrade.
- Android `namespace` is still `com.example.credit_cards` (cosmetic — applicationId
  is correct). An orphan `android/app/src/main/kotlin/com/geo/credit_cards/MainActivity.kt`
  is left over from the reverted applicationId change and is untracked.
- `store/` listing assets: screenshots and feature graphic are only in Play Console,
  not in the repo or the backup folder yet.
- Splash colours in `android/.../res/values*/colors.xml` are copies of `WarmTheme`'s
  background tokens — change both together if the palette moves again.
- The wireless-debug ADB serial for Geo's phone sometimes grows a `(2)` suffix
  (`adb-BECMMVFMNBYPMBOR-K8fLht (2)._adb-tls-connect._tcp`) when a second
  wireless-debug session registers — `adb devices` shows both; use whichever is
  currently listed, quoted (the serial contains a literal space).
- `test/widget_test.dart` file name is legacy — it now holds `EmptyCardView` /
  `CardFrontFace` / `CardListSkeleton` smoke tests, not a counter-app test.

## Gotchas — read before changing things

- **`PaymentCard.cvv` is nullable and must stay nullable.** Every card saved before
  1.0.2 has no CVV; making it required would break loading them. Same for the
  `'cvv'` key in `SecureCardStorage` and the Drive backup payload — always
  read it as `String?`.
- **Any biometric prompt must be wrapped in `AuthCubit.beginTrustedInterruption()` /
  `endTrustedInterruption()`.** The Android prompt backgrounds the activity, which
  otherwise trips the app lock and bounces the user to the lock screen. See the
  scan flow in `add_card_screen.dart`.
- **Privacy policy and Play Data Safety must match what the app actually stores.**
  The 1.0.1 policy claimed no CVV was ever stored; rewritten for 1.0.2. Update
  both whenever a new field is persisted.
- **Never change `applicationId`.** Changed once (b35ca4d), had to be reverted
  (f3e602c) because the Play record is permanently bound to it.
- `android/key.properties`, `*.jks`, and `android/app/src/main/google-services.json`
  are gitignored — never commit them.
- Release builds behave differently from debug (R8, real signing). Always test the
  release build before uploading.
- CVV OCR (`CardScanService.parseCvv`) is deliberately conservative: labelled codes
  first, then the "last-four + code" signature-panel pattern, then a lone 3-digit
  line. A bare 4-digit group is ignored — it is almost always card-number digits.
- **A card's colour comes from exactly one place: `CardPalette.forCard(card)`.**
  Used by the full gradient face, `CardChip` (Home hero, Reminders rows), and the
  detail screen — never invent a second colour source, or a card will show two
  different colours in two places.
- **`CardChip` needs `card.bankName` to show a recognisable code**, otherwise it
  falls back to `typeLabel` ("Credit"/"Debit"/"Prepaid"), which looks generic on
  a list of several unbanked cards. Not a bug, just a UX ceiling worth knowing.
- **Two different "snooze" methods exist on `NotificationService` on purpose.**
  `snoozeFromList()` (Reminders screen, days/weeks before due — own copy, doesn't
  touch real due-date reminders) vs. the private `_applySnooze()` used when an
  already-fired notification's Snooze button is tapped (copy assumes "yesterday").
  Don't merge them; the copy would be wrong in one direction or the other.
- **`ic_full.png` (the launcher icon composite) still has the old indigo theme
  baked into its background — do not drop it into a Warm-themed screen as-is.**
  Use `ic_fg.png` (transparent background) if you need the glyph somewhere in
  Warm UI, and know that the glyph's own fill colours are still indigo/white
  until the icon itself is regenerated (see Next sprint #2).
- **`pubspec.yaml`'s `assets:` list must name the exact file used in code.**
  Got this wrong once this session — registered `ic_full.png` while the widget
  loaded `ic_fg.png`, which fails silently in a running app (`Image.asset`
  degrades to a render error) and loudly in `flutter test` ("Unable to load
  asset"). The test failure is what caught it — if a newly added `Image.asset`
  call isn't covered by any widget test, this class of bug can ship silently.
