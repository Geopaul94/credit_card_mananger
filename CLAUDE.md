# credit_cards

Flutter card-wallet app: securely store payment cards, scan them via OCR, and get
due-date reminders. Local-first and encrypted; optional Google Drive backup.

## Stack
- Flutter (Dart SDK `^3.10.4`), clean architecture, BLoC + get_it (DI).
- `google_mlkit_text_recognition` + `image_picker` — card OCR scan.
- `flutter_secure_storage` + `encrypt`/`crypto` — encrypted local store.
- `local_auth` (biometric lock); `flutter_local_notifications` + `timezone` (reminders).
- `google_sign_in` + `googleapis` — Drive backup.

## Structure (`lib/`)
- `main.dart` — entrypoint.
- `core/` — shared infra: `theme/`, `di/` (get_it), `storage/`, `encryption/`, `auth/`,
  `notifications/`, `backup/`, `network/`, `error/`, `usecases/`, `ui/`, `utils/`.
- `features/<feature>/{data,domain,presentation}` — `cards` (full 3-layer);
  `backup` and `lock` (presentation only).

## Conventions
- Clean architecture: data / domain / presentation layers.
- State via BLoC; keep widgets dumb, logic in blocs/use cases.
- Prefer immutable models; avoid blocking the UI isolate.

## Theming
- Single design system in `core/theme/app_theme.dart` (Refined Fintech: indigo
  accent, neutral surfaces, hairline borders, bundled Inter font). Both light +
  dark are first-class. Screens read `ColorScheme` roles — never hardcode light
  colors for surfaces/text, or dark mode breaks.

## Key domain notes
- `PaymentCard`: has `bankName` + `cardName` (co-brand, e.g. "Flipkart");
  `displayTitle` formats "Bank - Card Name". `dueDay` is a day-of-month;
  `reminderInfo` gives the cycle-relative due date/delta (handles 1-day overdue).
- Paid status persists cycle-aware in `SecureCardStorage` (cardId → covered due
  date); reset automatically each new cycle. Bloc materialises
  `List<PaymentCard>` (data source returns models → `firstWhere(orElse:)` traps).
- Reminders fire 3 days before → 1 day after due; marking paid cancels the rest.

## Run
```bash
flutter pub get
flutter run            # use a physical Android device (see note below)
```

## Google Drive backup
- Auth: `google_sign_in` + `http` package. Uses `account.authHeaders` +
  `_GoogleAuthClient` wrapper (same pattern as debt_tracker_localdatabase).
  **NOT** `extension_google_sign_in_as_googleapis_auth` — removed.
- Backup file stored in Drive AppData (hidden, auto-deleted on uninstall).
  Encrypted JSON (AES-256, key derived from Google account ID).
- Auto-backup: daily (24h interval) while app is open, toggle in UI.
  Disables automatically on sign-out.
- Safety: empty-card guard before backup; empty-card check before auto-backup.
- **BLOCKER**: `android/app/google-services.json` has only a placeholder API key.
  Must add Android OAuth client for package `com.example.credit_cards` +
  SHA-1 `4F:8C:8B:70:CA:13:FF:6D:4C:4A:35:72:FA:33:CA:B8:90:92:3D:66` in
  Firebase Console (use existing project 694593410619 from debt_tracker).
  Download + replace google-services.json. Without this, sign-in fails (error 10).

## Current state / notes
- Branch `feature/scan-front-back-and-due-date-calendar`. Tested on a physical
  Android device; macOS/web blocked by the biometric lock gate.
- Open follow-ups: inline edit of `cardName` on the detail screen; dedupe the
  detail screen's private `_SwipeToConfirm` vs the shared `SwipeToConfirm`.
