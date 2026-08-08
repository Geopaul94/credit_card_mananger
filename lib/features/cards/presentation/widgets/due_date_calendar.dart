import 'package:flutter/material.dart';

/// Inline picker for a billing **due day** — a day of the month, 1–31.
///
/// Deliberately not a calendar. A due day repeats every month, so weekday
/// columns and a month header are noise, and worse, a real month grid hides
/// valid answers: rendered in February it would offer no way to pick 29, 30 or
/// 31, and in April no way to pick 31. Every day is always selectable here.
///
/// Days 29–31 simply fall back to the last day of shorter months when the
/// reminder is scheduled, which the footnote explains.
class DueDayPicker extends StatelessWidget {
  const DueDayPicker({
    super.key,
    required this.selectedDay,
    required this.onSelectDay,
    required this.onNoReminder,
  });

  /// Selected day-of-month (1–31), or null for "no reminder".
  final int? selectedDay;
  final ValueChanged<int> onSelectDay;
  final VoidCallback onNoReminder;

  static const _lastDay = 31;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final noReminder = selectedDay == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          selectedDay == null
              ? 'Pick the day your bill is due'
              : 'Due on the ${_ordinal(selectedDay!)} of every month',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 12),

        // ── Day grid, 1–31 ────────────────────────────────────────────────
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          children: [
            for (int day = 1; day <= _lastDay; day++)
              _DayCell(
                day: day,
                selected: !noReminder && selectedDay == day,
                onTap: () => onSelectDay(day),
                scheme: scheme,
              ),
          ],
        ),

        // Only worth saying when it applies to the chosen day.
        if (selectedDay != null && selectedDay! > 28) ...[
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 13, color: scheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'In shorter months you will be reminded on the last day '
                  'instead.',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 14),

        // ── No-reminder option ────────────────────────────────────────────
        GestureDetector(
          onTap: onNoReminder,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: noReminder
                  ? scheme.errorContainer
                  : scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: noReminder
                    ? scheme.error
                    : scheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  noReminder
                      ? Icons.notifications_off
                      : Icons.notifications_off_outlined,
                  size: 17,
                  color: noReminder
                      ? scheme.onErrorContainer
                      : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'No reminder',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: noReminder
                        ? scheme.onErrorContainer
                        : scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static String _ordinal(int day) {
    if (day >= 11 && day <= 13) return '${day}th';
    return switch (day % 10) {
      1 => '${day}st',
      2 => '${day}nd',
      3 => '${day}rd',
      _ => '${day}th',
    };
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.selected,
    required this.onTap,
    required this.scheme,
  });

  final int day;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? scheme.primary
                : scheme.outline.withValues(alpha: 0.12),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          '$day',
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? Colors.white : scheme.onSurface,
          ),
        ),
      ),
    );
  }
}
