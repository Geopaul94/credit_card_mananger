import 'package:flutter/material.dart';

import '../../../../../../core/ui/responsive_layout.dart';

class SettingsRowTile extends StatelessWidget {
  const SettingsRowTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(context.spacing(14));
    // The surface colour has to live on the Material, not on a DecoratedBox
    // above the ListTile: a ListTile paints its ink on the nearest Material
    // ancestor, so a coloured box in between hides the ripple entirely
    // (Flutter asserts on exactly this in debug). The Container keeps only
    // the border, which is safe to draw over the ink.
    return Material(
      color: colorScheme.surface,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.spacing(14),
          vertical: context.spacing(6),
        ),
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.12),
          ),
        ),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          onTap: onTap,
          leading: Container(
            width: context.spacing(36),
            height: context.spacing(36),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(context.spacing(10)),
            ),
            child: Icon(icon, size: context.spacing(20)),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: context.font(15),
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(fontSize: context.font(12)),
          ),
          trailing: trailing ?? const Icon(Icons.chevron_right),
        ),
      ),
    );
  }
}

/// A non-interactive "Always on" marker — communicates that a protection is
/// mandatory and can't be toggled off (avoids reading like an optional
/// setting).
class AlwaysOnBadge extends StatelessWidget {
  const AlwaysOnBadge({super.key});

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
