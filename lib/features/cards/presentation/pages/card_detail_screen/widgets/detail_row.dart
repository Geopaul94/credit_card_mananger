import 'package:flutter/material.dart';

import '../../../widgets/section_card.dart';

/// One labelled field on the card detail screen, with a copy button and an
/// optional trailing action.
class DetailRow extends StatelessWidget {
  const DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onCopy,
    this.trailing,
    this.valueColor,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onCopy;
  final Widget? trailing;

  /// Tints the value — used to flag an expired or soon-to-expire card.
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: scheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[trailing!, const SizedBox(width: 6)],
          IconBox(icon: Icons.copy, onTap: onCopy),
        ],
      ),
    );
  }
}
