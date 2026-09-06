import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../../core/di/service_locator.dart';
import '../../../../../../core/feedback/feedback_service.dart';
import '../../../../../../core/ui/responsive_layout.dart';
import 'settings_row_tile.dart';

/// "Rate this app" — a full-width card with a row of stars underneath.
///
/// Every star opens the same Play listing. That is not laziness about which
/// star was tapped: Play's ratings policy forbids "review gating", i.e.
/// sending people who tap 5 to the store and people who tap 1 somewhere
/// quieter. Apps get pulled for it. The stars are an affordance; the rating
/// itself is chosen on the Play page, which is also the only place it *can*
/// be chosen — no Play deep link accepts a preset rating.
class RateAppTile extends StatelessWidget {
  const RateAppTile({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(context.spacing(14));
    // Colour on the Material, border on the box inside it — same reason as
    // SettingsRowTile: ink painted on a Material *below* a coloured box is
    // invisible, so the tap would land with no ripple.
    return Material(
      color: colorScheme.surface,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: radius,
        onTap: () {
          HapticFeedback.selectionClick();
          runSupportAction(
            context,
            sl<FeedbackService>().rateApp,
            'Could not open the Play Store',
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.12),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            context.spacing(14),
            context.spacing(12),
            context.spacing(14),
            context.spacing(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: context.spacing(36),
                    height: context.spacing(36),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(context.spacing(10)),
                    ),
                    child: Icon(
                      Icons.star_rate_rounded,
                      size: context.spacing(20),
                    ),
                  ),
                  SizedBox(width: context.spacing(14)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rate this app',
                          style: TextStyle(
                            fontSize: context.font(15),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: context.spacing(2)),
                        Text(
                          'Tap to rate Card Vault on the Play Store',
                          style: TextStyle(
                            fontSize: context.font(12),
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.spacing(6)),
              const _StarRow(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Purely decorative. The whole card is one tap target, so the stars must not
/// take taps themselves — a nested InkWell here would swallow the press and
/// paint a second ripple inside the card's own.
class _StarRow extends StatelessWidget {
  const _StarRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        5,
        (_) => Padding(
          padding: EdgeInsets.all(context.spacing(5)),
          child: Icon(
            Icons.star_rounded,
            size: context.spacing(32),
            color: Colors.amber.shade600,
          ),
        ),
      ),
    );
  }
}

/// "Send feedback" — opens a mail draft to support with the app version
/// already appended.
class SendFeedbackTile extends StatelessWidget {
  const SendFeedbackTile({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsRowTile(
      icon: Icons.feedback_outlined,
      title: 'Send feedback',
      subtitle: 'Report a problem or suggest a feature',
      onTap: () {
        HapticFeedback.selectionClick();
        runSupportAction(
          context,
          sl<FeedbackService>().sendFeedback,
          'No email app found. Write to ${FeedbackService.supportEmail} '
          'instead.',
        );
      },
    );
  }
}

/// Both support actions hand off to another app, which can simply not be
/// there — no Play Store on some builds, no mail client on a fresh phone.
/// Say so rather than letting the tap do nothing.
@visibleForTesting
Future<void> runSupportAction(
  BuildContext context,
  Future<bool> Function() action,
  String failureMessage,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final ok = await action();
  if (!ok) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(failureMessage),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
