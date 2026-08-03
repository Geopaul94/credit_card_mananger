import 'package:flutter/material.dart';

import '../../../../core/ui/responsive_layout.dart';
import '../pages/add_card_screen/add_card_screen.dart';

/// First thing a new user sees. It has to do more than describe the situation —
/// it offers the two ways in (scan or type) so the screen is never a dead end.
class EmptyCardView extends StatelessWidget {
  const EmptyCardView({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Center(
      child: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.all(context.spacing(24)),
          padding: EdgeInsets.all(context.spacing(24)),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(context.spacing(20)),
            border: Border.all(color: scheme.outline.withValues(alpha: 0.12)),
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
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => openAddCardScreen(context),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('Add your first card'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
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
      ),
    );
  }
}
