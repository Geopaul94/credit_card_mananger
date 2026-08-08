# Changelog

One line per user-visible change, newest version first.

## [1.0.2] — unreleased (versionCode 3)

### Added
- Optional CVV. You can save a card's security code if you want to; leaving the
  field blank stores nothing. Cards saved earlier can have one added later, and
  a saved code can be changed or removed from the card detail screen.
- Scanning the back of a card reads the security code into the CVV field.
- Cards show their payment network (Visa, Mastercard, RuPay, Amex, Discover,
  Diners) on the card face.
- Cards are coloured by their issuing bank, so different cards look different.
- The home header names the next bill due and how soon it is.
- Search (from 5 cards) by bank, card name, holder, type, or last 4 digits.
- Drag a card (long-press) to reorder the list; the order is remembered.
- Cards warn when they expire within 2 months, and show EXPIRED after.
- Empty vault screen now has an "Add your first card" button, and offers to
  restore your cards from a Google Drive backup if you have used the app before.
- Edit a card: a pencil on the card screen opens every field — bank, card name,
  holder, type, number, expiry, CVV, due date and notes. Fixing a typo no
  longer means deleting the card and losing its notes and history.
- Reminder notifications carry Paid, Snooze and Skip buttons, so a bill can be
  handled without opening the app.
- The Reminders tab shows how many bills need attention.
- Branded launch screen in light and dark, with no white flash on startup.
- Haptic feedback on copy, card open, save, drag, and swipe-to-pay.

### Changed
- Reminders now arrive in the **evening (9 PM)** instead of 9 AM.
- Notification permission is asked for when you set your first due date,
  instead of on the very first launch. If notifications are off, the Reminders
  screen now says so and offers to turn them on.
- Choosing a due date is one 1–31 grid everywhere. The old month calendar could
  not offer the 29th–31st in February, or the 31st in April, June, September
  and November, even though a due day repeats every month.
- Name fields start the keyboard capitalised; notes use sentence case.
- Loading shows card-shaped placeholders instead of a spinner.
- Font-size accessibility settings are honoured (bounded at 1.3x).
- Privacy policy updated to describe optional CVV storage. **The Play Console
  Data Safety form must be updated to match before this version is uploaded.**

### Fixed
- Indian RuPay cards were shown as "DISCOVER". Card networks are now read with
  Indian issuers in mind (Slice, Jupiter/CSB and most co-brands sit in the
  range US rules assign to Discover).
- Cards from issuers that use the same word for bank and product no longer
  read "Slice - Slice".
- Bank initialisms typed in lower case now display correctly ("csb" → "CSB").

### Removed
- The exact-alarm permissions. Reminders are scheduled inexactly, which is
  easier on battery and avoids a permission Google reserves for alarm clocks
  and calendars.

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
