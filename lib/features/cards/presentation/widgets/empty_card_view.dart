import 'package:flutter/material.dart';

import '../../../../core/ui/responsive_layout.dart';
import '../pages/add_card_screen/add_card_screen.dart';

/// First thing a new user sees — and, just as importantly, the first thing
/// someone sees after reinstalling. It offers both ways forward: start a fresh
/// card, or bring back an encrypted Drive backup. Without the second option a
/// returning user has no way to discover that their cards can come back.
///
/// Purely presentational: the backup state is handed in rather than read from
/// a cubit, so this can be rendered and tested on its own.
class EmptyCardView extends StatelessWidget {
  const EmptyCardView({this.onRestore, this.connectedEmail, super.key});

  /// Opens backup & restore. Null hides the restore prompt entirely.
  final VoidCallback? onRestore;

  /// Google account already connected, if any. Changes the wording from
  /// "connect an account" to "restore from this one".
  final String? connectedEmail;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(vertical: context.spacing(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Start fresh ────────────────────────────────────────────────
            Container(
              margin: EdgeInsets.symmetric(horizontal: context.spacing(24)),
              padding: EdgeInsets.all(context.spacing(24)),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(context.spacing(20)),
                border: Border.all(
                  color: scheme.outline.withValues(alpha: 0.12),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: context.spacing(76, tabletValue: 88),
                    height: context.spacing(76, tabletValue: 88),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          scheme.primary.withValues(alpha: 0.16),
                          scheme.secondary.withValues(alpha: 0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Icon(
                      Icons.add_card_outlined,
                      size: context.spacing(36, tabletValue: 42),
                      color: scheme.primary,
                    ),
                  ),
                  SizedBox(height: context.spacing(18)),
                  Text('Your vault is empty', style: text.headlineSmall),
                  SizedBox(height: context.spacing(8)),
                  Text(
                    'Add your first card and it will be encrypted on this '
                    'device — no account, nothing uploaded.',
                    textAlign: TextAlign.center,
                    style: text.bodySmall,
                  ),
                  SizedBox(height: context.spacing(22)),
                  FilledButton.icon(
                    onPressed: () => openAddCardScreen(context),
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text('Add your first card'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                  SizedBox(height: context.spacing(10)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt_outlined,
                        size: context.spacing(14),
                        color: scheme.onSurfaceVariant,
                      ),
                      SizedBox(width: context.spacing(6)),
                      Flexible(
                        child: Text(
                          'You can scan it with the camera instead of typing',
                          textAlign: TextAlign.center,
                          style: text.labelSmall,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Bring an old vault back ────────────────────────────────────
            if (onRestore != null) ...[
              SizedBox(height: context.spacing(20)),
              const _OrSeparator(),
              SizedBox(height: context.spacing(20)),
              _RestorePrompt(
                onRestore: onRestore!,
                connectedEmail: connectedEmail,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── "or" separator ───────────────────────────────────────────────────────────

class _OrSeparator extends StatelessWidget {
  const _OrSeparator();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final line = Expanded(
      child: Divider(color: scheme.outline.withValues(alpha: 0.25)),
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.spacing(40)),
      child: Row(
        children: [
          line,
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.spacing(12)),
            child: Text('or', style: Theme.of(context).textTheme.labelSmall),
          ),
          line,
        ],
      ),
    );
  }
}

// ─── Restore prompt ───────────────────────────────────────────────────────────

/// Invites a returning user to reconnect their Google account and pull back an
/// encrypted backup. The wording follows what the app already knows: if the
/// account is still connected there is nothing to "connect", only to restore.
class _RestorePrompt extends StatelessWidget {
  const _RestorePrompt({required this.onRestore, this.connectedEmail});

  final VoidCallback onRestore;
  final String? connectedEmail;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final signedIn = connectedEmail != null;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: context.spacing(24)),
      padding: EdgeInsets.all(context.spacing(18)),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(context.spacing(18)),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.22)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: context.spacing(40),
                height: context.spacing(40),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(context.spacing(12)),
                ),
                child: Icon(
                  Icons.cloud_download_outlined,
                  size: context.spacing(21),
                  color: scheme.primary,
                ),
              ),
              SizedBox(width: context.spacing(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Used Card Vault before?', style: text.titleSmall),
                    SizedBox(height: context.spacing(3)),
                    Text(
                      signedIn
                          ? 'Restore your cards from the backup in '
                                '$connectedEmail.'
                          : 'Connect your Google account to restore cards '
                                'from your last backup.',
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: context.spacing(14)),
          OutlinedButton.icon(
            onPressed: onRestore,
            icon: Icon(
              signedIn ? Icons.restore : Icons.account_circle_outlined,
              size: 19,
            ),
            label: Text(
              signedIn ? 'Restore my cards' : 'Connect Google account',
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              foregroundColor: scheme.primary,
              side: BorderSide(color: scheme.primary.withValues(alpha: 0.45)),
            ),
          ),
          SizedBox(height: context.spacing(10)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lock_outline,
                size: context.spacing(13),
                color: scheme.onSurfaceVariant,
              ),
              SizedBox(width: context.spacing(6)),
              Expanded(
                child: Text(
                  'Backups are encrypted — only this app on your account '
                  'can open them. Skip this if you are starting fresh.',
                  style: text.labelSmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
