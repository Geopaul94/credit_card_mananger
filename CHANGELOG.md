# Changelog

One line per user-visible change, newest version first.

## [1.0.2] — unreleased (versionCode 3)

### Added
- Optional CVV. You can save a card's security code if you want to; leaving the
  field blank stores nothing.
- Viewing or copying a saved CVV asks for your fingerprint, face, or device PIN
  every time, and a revealed code hides itself again after 30 seconds.
- Cards saved earlier can have a CVV added later from the card detail screen,
  and a saved code can be changed or removed there.
- Scanning the back of a card reads the security code into the CVV field.

### Changed
- Privacy policy updated to describe optional CVV storage and how it is
  protected. **The Play Console Data Safety form must be updated to match
  before this version is uploaded.**

## [1.0.1] — versionCode 2

### Added
- Card number, expiry, and holder-name validation with clear error messages,
  Luhn checksum and expired-card warnings at save time.
- Privacy policy page for the Play Store listing.

### Fixed
- Biometric unlock deadlocks; upgraded `local_auth` to 3.0.2.
- Keyboard now dismisses when tapping outside a text field, app-wide.
- applicationId kept as `com.geo.credit_cards` — the Play record is bound to it.

## [1.0.0] — versionCode 1

First Play Store release.

- Add, view, and delete credit, debit, and prepaid cards.
- AES-256 encrypted on-device storage; app locked behind biometrics.
- Camera card scanning with on-device OCR (ML Kit), photo deleted after reading.
- Payment due dates with reminders 3 days, 2 days, and 1 day before, and on the
  day; swipe to mark a bill paid.
- Private notes per card.
- Optional encrypted Google Drive backup and restore.
- 3D card flip animation and light/dark theming.
