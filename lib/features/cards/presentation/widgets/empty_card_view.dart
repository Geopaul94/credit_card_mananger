import 'package:flutter/material.dart';

import '../../../../core/ui/responsive_layout.dart';
import '../pages/add_card_screen/add_card_screen.dart';

/// First thing a new user sees — and, just as importantly, the first thing
/// someone sees after reinstalling. Two ways forward: start a fresh card, or
/// bring back an encrypted Drive backup. Without the second option a
/// returning user has no way to discover that their cards can come back.
///
/// Purely presentational: the backup state is handed in rather than read from
/// a cubit, so this can be rendered and tested on its own.
class EmptyCardView extends StatelessWidget {
  const EmptyCardView({this.onRestore, this.connectedEmail, super.key});

  /// Opens backup & restore. Null hides the restore button entirely.
  final VoidCallback? onRestore;

  /// Google account already connected, if any. Changes the button from
  /// "Restore from Drive" to "Restore my cards" — nothing left to connect.
  final String? connectedEmail;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final signedIn = connectedEmail != null;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: context.spacing(32)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Soft two-tone glow — no literal meaning, just a calm focal
            // point above the headline instead of an empty page.
            Container(
              width: context.spacing(120, tabletValue: 140),
              height: context.spacing(120, tabletValue: 140),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.3, -0.4),
                  colors: [
                    scheme.primary.withValues(alpha: 0.9),
                    scheme.secondary.withValues(alpha: 0.55),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.25),
                    blurRadius: 40,
                    spreadRadius: 6,
                  ),
                ],
              ),
            ),
            SizedBox(height: context.spacing(28)),
            Text(
              'Your vault is empty',
              textAlign: TextAlign.center,
              style: text.headlineSmall,
            ),
            SizedBox(height: context.spacing(10)),
            Text(
              'Add a card to keep it safely encrypted on your device — '
              'never in the cloud unless you choose.',
              textAlign: TextAlign.center,
              style: text.bodySmall,
            ),
            SizedBox(height: context.spacing(36)),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => openAddCardScreen(context),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: const Text('Add your first card'),
              ),
            ),
            if (onRestore != null) ...[
              SizedBox(height: context.spacing(12)),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onRestore,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    foregroundColor: scheme.onSurface,
                    side: BorderSide(
                      color: scheme.outline.withValues(alpha: 0.4),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Text(
                    signedIn ? 'Restore my cards' : 'Restore from Drive',
                  ),
                ),
              ),
            ],
            SizedBox(height: context.spacing(32)),
          ],
        ),
      ),
    );
  }
}
