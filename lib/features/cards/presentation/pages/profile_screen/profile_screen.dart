import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/backup/backup_cubit.dart';
import '../../../../../core/theme/theme_cubit.dart';
import '../../../../../core/ui/responsive_layout.dart';
import '../../../../../features/backup/presentation/backup_screen.dart';
import '../../widgets/section_card.dart';

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
            const _ProfileHeader(),
            SizedBox(height: context.spacing(14)),

            // ── Appearance ──────────────────────────────────────────────────
            SectionLabel(label: 'APPEARANCE'),
            SizedBox(height: context.spacing(8)),
            const _ThemeModeTile(),
            SizedBox(height: context.spacing(20)),

            // ── Backup ──────────────────────────────────────────────────────
            SectionLabel(label: 'BACKUP & RESTORE'),
            SizedBox(height: context.spacing(8)),
            _BackupTile(),
            SizedBox(height: context.spacing(20)),

            // ── Security ────────────────────────────────────────────────────
            SectionLabel(label: 'SECURITY'),
            SizedBox(height: context.spacing(8)),
            _ProfileTile(
              icon: Icons.fingerprint,
              title: 'App lock',
              subtitle: 'Biometric or device PIN required on every open',
              trailing: const _AlwaysOnBadge(),
            ),
            SizedBox(height: context.spacing(8)),
            _ProfileTile(
              icon: Icons.shield_outlined,
              title: 'Encryption',
              subtitle: 'Card data is always AES-256 encrypted on this device',
              trailing: const _AlwaysOnBadge(),
            ),
          ],
        ),
      ),
    );
  }

}

// ─── Backup tile ──────────────────────────────────────────────────────────────

class _BackupTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BlocBuilder<BackupCubit, BackupState>(
      builder: (context, state) {
        final account = state.account;
        final lastBackup = state.lastDriveBackup;

        String subtitle;
        if (account == null) {
          subtitle = 'Tap to connect Google Drive';
        } else if (lastBackup != null) {
          final diff = DateTime.now().difference(lastBackup);
          if (diff.inMinutes < 1) {
            subtitle = 'Last backup: just now';
          } else if (diff.inHours < 1) {
            subtitle = 'Last backup: ${diff.inMinutes}m ago';
          } else if (diff.inDays < 1) {
            subtitle = 'Last backup: ${diff.inHours}h ago';
          } else {
            subtitle =
                'Last backup: ${lastBackup.day}/${lastBackup.month}/${lastBackup.year}';
          }
        } else {
          subtitle = 'Signed in as ${account.email} — no backup yet';
        }

        return GestureDetector(
          onTap: () => openBackupScreen(context),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.spacing(14),
              vertical: context.spacing(12),
            ),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(context.spacing(14)),
              border:
                  Border.all(color: scheme.outline.withValues(alpha: 0.12)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(children: [
              Container(
                width: context.spacing(40),
                height: context.spacing(40),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(context.spacing(10)),
                ),
                child: Icon(
                  account != null
                      ? Icons.cloud_done_outlined
                      : Icons.cloud_off_outlined,
                  size: context.spacing(22),
                  color: account != null ? Colors.green : scheme.primary,
                ),
              ),
              SizedBox(width: context.spacing(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Google Drive Backup',
                        style: TextStyle(
                            fontSize: context.font(15),
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: context.font(12),
                            color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ]),
          ),
        );
      },
    );
  }
}

// ─── Profile tile ─────────────────────────────────────────────────────────────

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing(14),
        vertical: context.spacing(6),
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(context.spacing(14)),
        border:
            Border.all(color: colorScheme.outline.withValues(alpha: 0.12)),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          width: context.spacing(36),
          height: context.spacing(36),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(context.spacing(10)),
          ),
          child: Icon(icon, size: context.spacing(20)),
        ),
        title: Text(title,
            style: TextStyle(fontSize: context.font(15),
                fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle,
            style: TextStyle(fontSize: context.font(12))),
        trailing: trailing ?? const Icon(Icons.chevron_right),
      ),
    );
  }
}

// ─── Always-on indicator ──────────────────────────────────────────────────────
// A non-interactive "Always on" marker — communicates that a protection is
// mandatory and can't be toggled off (avoids reading like an optional setting).

class _AlwaysOnBadge extends StatelessWidget {
  const _AlwaysOnBadge();

  @override
  Widget build(BuildContext context) {
    final green = Colors.green.shade600;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.lock, size: 13, color: green),
        const SizedBox(width: 5),
        Text(
          'Always on',
          style: TextStyle(
            color: Colors.green.shade700,
            fontWeight: FontWeight.w600,
            fontSize: 11.5,
          ),
        ),
      ],
    );
  }
}

// ─── Theme tile ───────────────────────────────────────────────────────────────

class _ThemeModeTile extends StatelessWidget {
  const _ThemeModeTile();

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeCubit>().state == ThemeMode.dark;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing(14),
        vertical: context.spacing(10),
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(context.spacing(14)),
        border:
            Border.all(color: colorScheme.outline.withValues(alpha: 0.12)),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text('Dark theme',
            style: TextStyle(
                fontSize: context.font(15), fontWeight: FontWeight.w600)),
        subtitle: Text(
          isDark ? 'Enabled for low-light use' : 'Switch to dark appearance',
          style: TextStyle(fontSize: context.font(12)),
        ),
        secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
        value: isDark,
        onChanged: (v) => context.read<ThemeCubit>().setDarkMode(v),
      ),
    );
  }
}

// ─── Profile header ───────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.spacing(16)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(context.spacing(16)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: context.spacing(24),
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: const Icon(Icons.person, color: Colors.white),
          ),
          SizedBox(width: context.spacing(12)),
          Expanded(
            child: Text(
              'Card Vault',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: context.font(20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
