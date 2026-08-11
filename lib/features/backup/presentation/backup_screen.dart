import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/backup/backup_cubit.dart';
import '../../../core/ui/responsive_layout.dart';
import '../../cards/presentation/bloc/card_overview/card_overview_bloc.dart';
import '../../cards/presentation/bloc/card_overview/card_overview_event.dart';
import '../../cards/presentation/bloc/card_overview/card_overview_state.dart';
import '../../cards/presentation/widgets/section_card.dart';

/// Opens backup & restore, carrying the cubits it needs across the route
/// boundary. Shared by the profile tile and the empty-vault restore prompt, so
/// there is one definition of how this screen is reached.
Future<void> openBackupScreen(BuildContext context) {
  return Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<BackupCubit>()),
          BlocProvider.value(value: context.read<CardOverviewBloc>()),
        ],
        child: const BackupScreen(),
      ),
    ),
  );
}

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  @override
  void initState() {
    super.initState();
    context.read<BackupCubit>().initialize();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: BlocConsumer<BackupCubit, BackupState>(
        listener: (context, state) {
          if (state.phase == BackupPhase.success) {
            if (state.restoredCount != null) {
              // Reload cards after restore
              context
                  .read<CardOverviewBloc>()
                  .add(const LoadCardsRequested());
            }
            ScaffoldMessenger.of(context)
              ..clearSnackBars()
              ..showSnackBar(SnackBar(
                content: Row(children: [
                  const Icon(Icons.check_circle_outline,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(state.restoredCount != null
                      ? '${state.restoredCount} cards restored!'
                      : 'Backup uploaded to Google Drive ✓'),
                ]),
                backgroundColor: Colors.green.shade700,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                duration: const Duration(seconds: 3),
              ));
            final cubit = context.read<BackupCubit>();
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) cubit.dismiss();
            });
          } else if (state.phase == BackupPhase.error &&
              state.errorMessage != null) {
            ScaffoldMessenger.of(context)
              ..clearSnackBars()
              ..showSnackBar(SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: scheme.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ));
            context.read<BackupCubit>().dismiss();
          }
        },
        builder: (context, backupState) {
          return ResponsiveContent(
            child: ListView(
              padding: EdgeInsets.all(context.spacing(16)),
              children: [
                // ── Header banner ──────────────────────────────────────────
                _HeaderBanner(scheme: scheme),
                SizedBox(height: context.spacing(14)),

                // ── Offline-first reassurance ────────────────────────────────
                // Read before deciding whether to bother connecting at all —
                // states plainly that this is optional and what's actually at
                // stake either way, not just what the feature does.
                _OfflineNote(scheme: scheme),
                SizedBox(height: context.spacing(20)),

                // ── Google account section ─────────────────────────────────
                SectionLabel(label: 'GOOGLE ACCOUNT'),
                SizedBox(height: context.spacing(8)),
                _AccountCard(backupState: backupState, scheme: scheme),
                SizedBox(height: context.spacing(20)),

                // ── Auto-backup section ────────────────────────────────────
                SectionLabel(label: 'AUTOMATIC BACKUP'),
                SizedBox(height: context.spacing(8)),
                _AutoBackupCard(backupState: backupState, scheme: scheme),
                SizedBox(height: context.spacing(20)),

                // ── Backup section ─────────────────────────────────────────
                SectionLabel(label: 'BACKUP'),
                SizedBox(height: context.spacing(8)),
                _BackupCard(backupState: backupState, scheme: scheme),
                SizedBox(height: context.spacing(20)),

                // ── Restore section ────────────────────────────────────────
                SectionLabel(label: 'RESTORE'),
                SizedBox(height: context.spacing(8)),
                _RestoreCard(backupState: backupState, scheme: scheme),
                SizedBox(height: context.spacing(20)),

                // ── Danger zone ───────────────────────────────────────────
                // Only worth showing once there's actually a cloud copy to
                // remove — an option to delete nothing is just clutter.
                if (backupState.account != null &&
                    backupState.lastDriveBackup != null) ...[
                  SectionLabel(label: 'DANGER ZONE'),
                  SizedBox(height: context.spacing(8)),
                  _DeleteBackupRow(backupState: backupState, scheme: scheme),
                  SizedBox(height: context.spacing(20)),
                ],

                // ── Info card ──────────────────────────────────────────────
                _InfoCard(scheme: scheme),
              ],
            ),
          );
        },
      ),
    );
  }

}

// ─── Header banner ────────────────────────────────────────────────────────────

class _HeaderBanner extends StatelessWidget {
  const _HeaderBanner({required this.scheme});
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.cloud_sync_rounded,
              color: Colors.white, size: 26),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Secure Cloud Backup',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16)),
              const SizedBox(height: 4),
              Text(
                'AES-256 encrypted. Only you can read it.',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

// ─── Offline-first note ───────────────────────────────────────────────────────

/// States the actual tradeoff plainly, before the user decides whether
/// connecting is worth it: the app works fully offline and the data is
/// already encrypted either way, but skipping backup means a lost or wiped
/// phone takes the cards with it.
class _OfflineNote extends StatelessWidget {
  const _OfflineNote({required this.scheme});
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.wifi_off_rounded, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'This app works fully offline — connecting Google Drive is '
              'optional. Your cards are already encrypted on this device, so '
              'no one else can read them either way. The only reason to '
              'connect: if the app is deleted or the phone is reset without '
              'a backup, that data is gone for good.',
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Account card ─────────────────────────────────────────────────────────────

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.backupState, required this.scheme});
  final BackupState backupState;
  final ColorScheme scheme;

  /// Signs in, then surfaces an existing Drive backup if one turns up.
  ///
  /// No "do you want to back up?" question: the user just tapped sign-in on
  /// the backup screen, so that is already answered, and [BackupCubit.signIn]
  /// protects the device silently when there is nothing to lose. The moment
  /// that genuinely needs a decision is the opposite one — Drive already holds
  /// a backup, and only the user knows which copy is the good one.
  Future<void> _connect(BuildContext context) async {
    final cubit = context.read<BackupCubit>();
    final cardsBloc = context.read<CardOverviewBloc>();
    final cardsBefore = cardsBloc.state.cards.length;

    await cubit.signIn(cards: cardsBloc.state.cards);
    if (!context.mounted) return;

    final backedUpAt = cubit.state.lastDriveBackup;
    if (cubit.state.account == null || backedUpAt == null) return;

    // A backup made moments ago is the one signIn just took for this device —
    // nothing to offer.
    if (cardsBefore == 0 || backedUpAt.isBefore(DateTime.now().subtract(
          const Duration(minutes: 1),
        ))) {
      await _offerRestore(context, backedUpAt, cardsBefore);
    }
  }

  Future<void> _offerRestore(
    BuildContext context,
    DateTime backedUpAt,
    int cardsOnDevice,
  ) async {
    final date = '${backedUpAt.day}/${backedUpAt.month}/${backedUpAt.year}';
    final replaces = cardsOnDevice > 0;

    final restore = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Backup found'),
        content: Text(
          replaces
              ? 'Google Drive has a backup from $date.\n\n'
                  'This device has $cardsOnDevice '
                  '${cardsOnDevice == 1 ? 'card' : 'cards'}. Restoring '
                  'replaces them with the backup — anything added on this '
                  'device since then would be lost.'
              : 'Google Drive has a backup from $date. '
                  'Restore your cards to this device?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(replaces ? 'Replace with backup' : 'Restore my cards'),
          ),
        ],
      ),
    );

    if (restore != true || !context.mounted) return;
    // The screen's BlocConsumer reloads the card list and shows the
    // confirmation once the restore succeeds, so this only has to start it.
    await context.read<BackupCubit>().restore();
  }

  @override
  Widget build(BuildContext context) {
    final account = backupState.account;

    return _SectionCard(children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: account == null
            ? Column(children: [
                Icon(Icons.account_circle_outlined,
                    size: 48, color: scheme.onSurfaceVariant),
                const SizedBox(height: 10),
                Text('Connect your Google account to enable backup.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed:
                        backupState.isLoading ? null : () => _connect(context),
                    icon: backupState.phase == BackupPhase.signingIn
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.login),
                    label: Text(backupState.phase == BackupPhase.signingIn
                        ? 'Signing in…'
                        : 'Sign in with Google'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ])
            : Row(children: [
                CircleAvatar(
                  radius: 22,
                  backgroundImage: account.photoUrl != null
                      ? NetworkImage(account.photoUrl!)
                      : null,
                  backgroundColor: scheme.primary.withValues(alpha: 0.15),
                  child: account.photoUrl == null
                      ? Icon(Icons.person, color: scheme.primary)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(account.displayName ?? 'Google Account',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15)),
                      Text(account.email,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => context.read<BackupCubit>().signOut(),
                  style: TextButton.styleFrom(
                      foregroundColor: scheme.error,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6)),
                  child: const Text('Sign out'),
                ),
              ]),
      ),
    ]);
  }
}

// ─── Auto-backup card ─────────────────────────────────────────────────────────

class _AutoBackupCard extends StatelessWidget {
  const _AutoBackupCard({required this.backupState, required this.scheme});
  final BackupState backupState;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(children: [
      SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        secondary: Icon(Icons.autorenew_rounded,
            color: backupState.autoEnabled ? scheme.primary : scheme.onSurfaceVariant),
        title: Text(
          'Daily automatic backup',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          backupState.autoEnabled
              ? 'Backs up once a day when you open the app.'
              : 'Automatic backup is off.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        value: backupState.autoEnabled,
        onChanged: backupState.isLoading
            ? null
            : (v) => context.read<BackupCubit>().setAutoBackup(v),
      ),
    ]);
  }
}

// ─── Backup card ──────────────────────────────────────────────────────────────

class _BackupCard extends StatelessWidget {
  const _BackupCard({required this.backupState, required this.scheme});
  final BackupState backupState;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final lastDrive = backupState.lastDriveBackup;
    final isSignedIn = backupState.account != null;

    return _SectionCard(children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.backup_rounded,
                  size: 20, color: scheme.primary),
              const SizedBox(width: 8),
              Text('Back up to Google Drive',
                  style: Theme.of(context).textTheme.titleSmall),
            ]),
            const SizedBox(height: 6),
            Text(
              lastDrive != null
                  ? 'Last backup: ${_formatDate(lastDrive)}'
                  : 'No backup yet',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            BlocBuilder<CardOverviewBloc, CardOverviewState>(
              builder: (context, cardState) => SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: (isSignedIn && !backupState.isLoading)
                      ? () => context
                          .read<BackupCubit>()
                          .backupNow(cardState.cards)
                      : null,
                  icon: backupState.phase == BackupPhase.backingUp
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.cloud_upload_outlined),
                  label: Text(backupState.phase == BackupPhase.backingUp
                      ? 'Uploading…'
                      : 'Backup Now  (${cardState.cards.length} cards)'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),
            if (!isSignedIn) ...[
              const SizedBox(height: 8),
              Text('Sign in above to enable backup.',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    ]);
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ─── Restore card ─────────────────────────────────────────────────────────────

class _RestoreCard extends StatelessWidget {
  const _RestoreCard({required this.backupState, required this.scheme});
  final BackupState backupState;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final isSignedIn = backupState.account != null;

    return _SectionCard(children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.restore_rounded, size: 20, color: scheme.primary),
              const SizedBox(width: 8),
              Text('Restore from backup',
                  style: Theme.of(context).textTheme.titleSmall),
            ]),
            const SizedBox(height: 6),
            Text(
              'Downloads your encrypted backup from Drive and replaces the current cards.',
              style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 12,
                  height: 1.4),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: (isSignedIn && !backupState.isLoading)
                    ? () => _confirmRestore(context)
                    : null,
                icon: backupState.phase == BackupPhase.restoring
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: scheme.primary),
                      )
                    : const Icon(Icons.cloud_download_outlined),
                label: Text(backupState.phase == BackupPhase.restoring
                    ? 'Restoring…'
                    : 'Restore from Drive'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    ]);
  }

  Future<void> _confirmRestore(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore backup?'),
        content: const Text(
          'This will replace all current cards with the ones from your Google Drive backup. This cannot be undone.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<BackupCubit>().restore();
    }
  }
}

// ─── Delete cloud backup ──────────────────────────────────────────────────────

/// A single tappable row — icon, title, subtitle, chevron — matching the
/// shared design. Deletes only the Drive copy; the device's own cards are
/// untouched, which the subtitle and the confirmation dialog both say
/// explicitly, since "delete" next to "backup" invites the wrong assumption.
class _DeleteBackupRow extends StatelessWidget {
  const _DeleteBackupRow({required this.backupState, required this.scheme});
  final BackupState backupState;
  final ColorScheme scheme;

  Future<void> _confirmAndDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete cloud backup?'),
        content: const Text(
          'This removes the encrypted backup from Google Drive only. Your '
          'cards stay exactly as they are on this device — there is nothing '
          'to restore from afterwards until you back up again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: scheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    final cubit = context.read<BackupCubit>();
    await cubit.deleteCloudBackup();
    if (!context.mounted) return;
    if (cubit.state.phase != BackupPhase.error) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(
          content: Text('Cloud backup deleted. Local cards are unchanged.'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = backupState.phase == BackupPhase.deletingCloud;

    return _SectionCard(children: [
      InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: busy ? null : () => _confirmAndDelete(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: scheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: busy
                  ? Padding(
                      padding: const EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.onErrorContainer,
                      ),
                    )
                  : Icon(Icons.delete_outline,
                      color: scheme.onErrorContainer, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Delete cloud backup',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text('Local vault stays',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
          ]),
        ),
      ),
    ]);
  }
}

// ─── Info card ────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.scheme});
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.shield_outlined, size: 16, color: scheme.primary),
            const SizedBox(width: 8),
            Text('How it works',
                style: Theme.of(context).textTheme.titleSmall),
          ]),
          const SizedBox(height: 10),
          ...[
            '🔐  Cards are encrypted with AES-256 before upload.',
            '🔑  Encryption key is derived from your Google account — only you can decrypt.',
            '📁  Stored in Drive AppData (hidden from regular Drive view).',
            '🔄  Auto-backup runs silently every 7 days when you open the app.',
            '📲  To restore on a new phone, install the app, sign in with the same Google account, and tap Restore.',
          ].map((line) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(line,
                    style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                        height: 1.4)),
              )),
        ],
      ),
    );
  }
}

// ─── Shared card container ────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }
}
