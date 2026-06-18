# credit_cards

Card wallet app — Flutter.

## Stack
- Flutter / Dart
- Clean architecture, BLoC (state management)
- ML Kit OCR for card scanning

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

## Current state / notes
- Branch `feature/scan-front-back-and-due-date-calendar`. Tested on a physical
  Android device; macOS/web blocked by the biometric lock gate.
- Open follow-ups: inline edit of `cardName` on the detail screen; dedupe the
  detail screen's private `_SwipeToConfirm` vs the shared `SwipeToConfirm`.
