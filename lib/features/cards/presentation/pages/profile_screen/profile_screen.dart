import 'package:flutter/material.dart';

import '../../../../../core/ui/responsive_layout.dart';
import '../../widgets/section_card.dart';
import '../data_safety_screen/data_safety_screen.dart';
import 'components/backup_tile.dart';
import 'components/lock_delay_tile.dart';
import 'components/profile_header.dart';
import 'components/settings_row_tile.dart';
import 'components/support_tiles.dart';
import 'components/text_size_tile.dart';
import 'components/theme_picker_tile.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ResponsiveContent(
        child: ListView(
          padding: EdgeInsets.all(context.spacing(16)),
          children: [
            const ProfileHeader(),
            SizedBox(height: context.spacing(14)),

            // ── Appearance ──────────────────────────────────────────────────
            SectionLabel(label: 'APPEARANCE'),
            SizedBox(height: context.spacing(8)),
            const ThemePickerTile(),
            SizedBox(height: context.spacing(8)),
            const TextSizeTile(),
            SizedBox(height: context.spacing(20)),

            // ── Backup ──────────────────────────────────────────────────────
            SectionLabel(label: 'BACKUP & RESTORE'),
            SizedBox(height: context.spacing(8)),
            const BackupTile(),
            SizedBox(height: context.spacing(20)),

            // ── Security ────────────────────────────────────────────────────
            SectionLabel(label: 'SECURITY'),
            SizedBox(height: context.spacing(8)),
            const SettingsRowTile(
              icon: Icons.fingerprint,
              title: 'App lock',
              subtitle: 'Biometric or device PIN required on every open',
              trailing: AlwaysOnBadge(),
            ),
            SizedBox(height: context.spacing(8)),
            const LockDelayTile(),
            SizedBox(height: context.spacing(8)),
            const SettingsRowTile(
              icon: Icons.shield_outlined,
              title: 'Encryption',
              subtitle: 'Card data is always AES-256 encrypted on this device',
              trailing: AlwaysOnBadge(),
            ),
            SizedBox(height: context.spacing(20)),

            // ── Privacy ─────────────────────────────────────────────────────
            SectionLabel(label: 'PRIVACY'),
            SizedBox(height: context.spacing(8)),
            SettingsRowTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Data & Privacy',
              subtitle: 'What the app stores, and what it never does',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DataSafetyScreen()),
              ),
            ),
            SizedBox(height: context.spacing(20)),

            // ── Support ─────────────────────────────────────────────────────
            SectionLabel(label: 'SUPPORT'),
            SizedBox(height: context.spacing(8)),
            const RateAppTile(),
            SizedBox(height: context.spacing(8)),
            const SendFeedbackTile(),
          ],
        ),
      ),
    );
  }
}
