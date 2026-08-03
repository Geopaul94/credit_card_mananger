# Card Vault — project notes

Flutter app (not Kotlin). Personal credit/debit/prepaid card organiser, on-device
encrypted, biometric-locked. Live on the Play Store.

| | |
|---|---|
| applicationId | `com.geo.credit_cards` — **never change this** |
| App name | Card Vault |
| Current version | 1.0.2+3 (unreleased; 1.0.1+2 is live) |
| Keystore backup | `D:\PlayStoreBackups\cardvault_drive_playstore_backup` |
| Privacy policy | `docs/privacy-policy.html` |

## Architecture

Clean Architecture + BLoC/Cubit, with `get_it` for DI (`lib/core/di/service_locator.dart`).

```
lib/
  core/         auth (biometrics), backup (Drive), encryption, storage,
                notifications, theme, ui, utils
  features/
    cards/
      domain/       PaymentCard entity, repository interface, use cases
      data/         models, local data source, repository impl, OCR scan service
      presentation/ blocs (card_overview, add_card), pages, widgets
    backup/ lock/
```

Data flows: screen → `CardOverviewBloc` event → use case → repository →
`SecureCardStorage` (AES-encrypted JSON blob in SharedPreferences).

## Completed sprints

- **Core vault** — add/view/delete cards, AES-256 storage, biometric app lock.
- **Scanning** — ML Kit on-device OCR, front + back capture, photo deleted after reading.
- **Due dates** — reminder scheduling (3/2/1 days before + on the day), swipe-to-mark-paid.
- **Drive backup** — optional encrypted backup/restore to the user's own Drive appdata.
- **Play readiness** — release signing via `key.properties`, R8 + resource shrinking,
  privacy policy, launcher icon, input validation. Shipped 1.0.0 and 1.0.1.
- **CVV removal** (1.0.1) — CVV was stripped from the app entirely to get through review.
- **CVV restore** (1.0.2, current) — brought back as an **optional**, biometric-gated field.

## Next sprint (proposed)

Verify 1.0.2 on a real device (biometric reveal, auto-hide, restore of an old
card with no CVV), update the Play Console Data Safety form, then upload.

## Known issues / TODO

- `flutter build appbundle --release` **exits with code 1** — "failed to strip debug
  symbols". The bundle is still produced and is fine; Flutter verifies stripping with
  `apkanalyzer` from the Android **cmdline-tools** component, which is not installed on
  this machine. Fix: Android Studio → SDK Manager → SDK Tools → "Android SDK
  Command-line Tools".
- `test/widget_test.dart` is still Flutter's default counter-app scaffold and **fails**.
  It needs replacing with a real smoke test.
- Android `namespace` is still `com.example.credit_cards` (cosmetic — applicationId is
  correct). An orphan `android/app/src/main/kotlin/com/geo/credit_cards/MainActivity.kt`
  is left over from the reverted applicationId change and is untracked.
- `store/` listing assets: screenshots and feature graphic are only in Play Console,
  not in the repo or the backup folder yet.

## Gotchas — read before changing things

- **`PaymentCard.cvv` is nullable and must stay nullable.** Every card saved before
  1.0.2 has no CVV; making it required would break loading them. Same for the
  `'cvv'` key in `SecureCardStorage` and the Drive backup payload — always
  read it as `String?`.
- **Any biometric prompt must be wrapped in `AuthCubit.beginTrustedInterruption()` /
  `endTrustedInterruption()`.** The Android prompt backgrounds the activity, which
  otherwise trips the app lock and bounces the user to the lock screen. See
  `_confirmIdentity()` in `card_detail_screen.dart` and the scan flow in
  `add_card_screen.dart`.
- **Privacy policy and Play Data Safety must match what the app actually stores.**
  The 1.0.1 policy claimed no CVV was ever stored; that had to be rewritten for 1.0.2.
  Update both whenever a new field is persisted.
- **Never change `applicationId`.** It was changed once (b35ca4d) and had to be
  reverted (f3e602c) because the Play record is permanently bound to it.
- `android/key.properties`, `*.jks`, and `android/app/src/main/google-services.json`
  are gitignored — never commit them.
- Release builds behave differently from debug (R8, real signing). Always test the
  release build before uploading.
- CVV OCR (`CardScanService.parseCvv`) is deliberately conservative: labelled codes
  first, then the "last-four + code" signature-panel pattern, then a lone 3-digit
  line. A bare 4-digit group is ignored — it is almost always card-number digits.
