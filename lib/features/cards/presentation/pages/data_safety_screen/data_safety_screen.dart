import 'package:flutter/material.dart';

import '../../../../../core/ui/responsive_layout.dart';
import '../../widgets/section_card.dart';

/// Condensed, in-app version of docs/privacy-policy.html. Keep both in sync
/// whenever a new field or data flow is added — see the "Privacy policy and
/// Play Data Safety must match" gotcha in the project CLAUDE.md.
class DataSafetyScreen extends StatelessWidget {
  const DataSafetyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data & Privacy')),
      body: ResponsiveContent(
        child: ListView(
          padding: EdgeInsets.all(context.spacing(16)),
          children: [
            Text(
              'Your data stays on your device, encrypted. This app runs no '
              'servers and receives nothing you save here.',
              style: TextStyle(
                fontSize: context.font(13),
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: context.spacing(18)),
            const _Fact(
              icon: Icons.credit_card_outlined,
              title: 'What\'s stored',
              body:
                  'Card number, holder name, expiry, bank, and an optional '
                  'due day and notes — all encrypted on-device with AES-256. '
                  'No PINs or online-banking passwords are ever stored.',
            ),
            const _Fact(
              icon: Icons.password_outlined,
              title: 'Security code (CVV)',
              body:
                  'Entirely optional — leave it blank and nothing is stored. '
                  'When saved, it\'s encrypted with the rest of the card and '
                  'only visible after you unlock the app. It\'s never sent '
                  'anywhere.',
            ),
            const _Fact(
              icon: Icons.fingerprint,
              title: 'Biometric lock',
              body:
                  'Your fingerprint, face, or screen-lock credential is '
                  'checked entirely by Android — the app never sees, stores, '
                  'or transmits it.',
            ),
            const _Fact(
              icon: Icons.camera_alt_outlined,
              title: 'Camera (card scanning)',
              body:
                  'Photos are read on-device with on-device text recognition '
                  'and deleted immediately after — never stored or uploaded.',
            ),
            const _Fact(
              icon: Icons.cloud_outlined,
              title: 'Google Drive backup',
              body:
                  'Optional. If enabled, an AES-256-encrypted file is saved '
                  'to your own Drive\'s hidden app-data area — only this app '
                  'on your account can read it. Skip it and the app makes no '
                  'network calls with your card data.',
            ),
            const _Fact(
              icon: Icons.notifications_outlined,
              title: 'Reminders',
              body:
                  'Due-date notifications are scheduled and generated '
                  'entirely on your device.',
            ),
            SizedBox(height: context.spacing(4)),
            SectionLabel(label: 'WHAT WE DON\'T DO'),
            SizedBox(height: context.spacing(8)),
            SectionCard(children: [
              for (final line in const [
                'No accounts, registration, or servers of ours',
                'No analytics, tracking, or advertising SDKs',
                'No selling or sharing your data with anyone',
                'No storage of card PINs or banking passwords',
                'No use of your card data for payments',
              ])
                _BulletRow(text: line),
            ]),
            SizedBox(height: context.spacing(18)),
            Text(
              'The full privacy policy is linked from this app\'s Play Store '
              'listing.',
              style: TextStyle(
                fontSize: context.font(12),
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: context.spacing(14)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: context.spacing(36),
            height: context.spacing(36),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(context.spacing(10)),
            ),
            child: Icon(icon, size: context.spacing(20)),
          ),
          SizedBox(width: context.spacing(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: context.font(15),
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(body,
                    style: TextStyle(
                        fontSize: context.font(12.5),
                        color: scheme.onSurfaceVariant,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletRow extends StatelessWidget {
  const _BulletRow({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline, size: 16, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
