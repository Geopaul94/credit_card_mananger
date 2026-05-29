import 'package:flutter/material.dart';

import '../../../../core/ui/responsive_layout.dart';

class EmptyCardView extends StatelessWidget {
  const EmptyCardView({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        margin: EdgeInsets.all(context.spacing(16)),
        padding: EdgeInsets.all(context.spacing(18)),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(context.spacing(18)),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.credit_card_off,
              size: context.spacing(54, tabletValue: 66),
              color: colorScheme.primary,
            ),
            SizedBox(height: context.spacing(12)),
            Text(
              'No cards yet',
              style: TextStyle(
                fontSize: context.font(18, tabletValue: 22),
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: context.spacing(6)),
            Text(
              'Add a card to start your secure wallet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: context.font(14),
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
