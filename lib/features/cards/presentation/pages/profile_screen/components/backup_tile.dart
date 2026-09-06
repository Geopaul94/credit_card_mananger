import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/backup/backup_cubit.dart';
import '../../../../../../core/ui/responsive_layout.dart';
import '../../../../../backup/presentation/backup_screen.dart';

class BackupTile extends StatelessWidget {
  const BackupTile({super.key});

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
              border: Border.all(color: scheme.outline.withValues(alpha: 0.12)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
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
                      Text(
                        'Google Drive Backup',
                        style: TextStyle(
                          fontSize: context.font(15),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: context.font(12),
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        );
      },
    );
  }
}
