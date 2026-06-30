# Privacy Policy — CardMate

**Effective date:** 30 June 2026
**App:** CardMate (Android package `com.geo.credit_cards`)
**Developer contact:** geo.paulson@laennec.ai

This policy explains what data CardMate handles, why, where it is stored, and your choices. The short version: **all card data stays encrypted on your device**, and an optional backup goes only to *your own* Google Drive.

---

## 1. What CardMate is

CardMate is a personal credit-card wallet. You add cards manually or by scanning them with your camera, and the app reminds you when bills are due. No account is required to use the app.

## 2. Data we collect and why

CardMate only stores data **you** enter. We do not run any analytics, advertising, or tracking services.

| Data | Why we store it | Where it is stored |
|---|---|---|
| Card holder name, card number, expiry date, CVV, bank name, co-brand name, due day, notes | To show you your cards and remind you of due dates | On your device only, AES-256 encrypted |
| Card photos captured during scanning | Used only to extract text via on-device OCR | Discarded immediately after OCR; never uploaded |
| Paid-status records | Track which cards you have paid this billing cycle | On your device only |
| Google account email + ID (only if you sign in to Google Drive backup) | To authenticate you with Drive and derive a backup encryption key | Memory only; never written to disk by us |
| Encrypted backup file | Restore your cards on a new device | Your own Google Drive (`AppData` folder, hidden from regular Drive view) |

We do **not** collect: location, contacts, advertising IDs, IP addresses, usage analytics, crash reports, or any other personal data.

## 3. On-device security

- Card data is encrypted with **AES-256** using a random key stored in the Android Keystore (via Flutter Secure Storage).
- The app requires biometric or device PIN authentication on every launch.
- Screenshots and the recent-apps preview are blocked while the app is open.

## 4. Google Drive backup (optional)

If you enable Google Drive backup:
- You sign in with your Google account.
- The backup is **encrypted before upload** with a key derived from your Google account ID — only you can decrypt it after signing in on another device.
- The file is stored in the Drive **AppData** folder, which is hidden from your regular Drive view and is automatically deleted by Google if you uninstall the app.
- We use the minimum scope `drive.appdata` — we cannot see your other Drive files.

You can disable auto-backup, sign out, or delete the backup file from Drive at any time. Signing out disables automatic backup.

## 5. Third-party services

The only third-party service we use is **Google Sign-In + Google Drive**, governed by [Google's Privacy Policy](https://policies.google.com/privacy). No advertising or analytics SDKs are bundled.

OCR (text recognition on card photos) uses **Google ML Kit on-device** — no images leave your phone.

## 6. Permissions we request

| Permission | Used for |
|---|---|
| Camera | Scanning your card to autofill the form |
| Biometric / Fingerprint | App lock |
| Notifications | Due-date reminders |
| Vibration | Notification feedback |
| Receive Boot Completed / Schedule Exact Alarm | Rescheduling reminders after device restart |
| Internet | Google Sign-In and Drive backup/restore (only if you enable backup) |

## 7. Data retention and deletion

- Card data lives only on your device. Uninstalling the app removes it.
- The Drive backup remains in your Drive AppData folder until you delete it or uninstall the app (Google then auto-removes it).
- You can clear all data at any time by uninstalling the app or by deleting cards individually.

## 8. Children's privacy

CardMate is not directed at children under 13. We do not knowingly collect data from children.

## 9. Changes to this policy

If we change this policy, we will update the "Effective date" above and post the new version at the same URL. Continued use of the app means you accept the updated policy.

## 10. Contact

For privacy questions or to request deletion of any data we hold (we do not hold any server-side data, but feel free to ask):

**Email:** geo.paulson@laennec.ai
