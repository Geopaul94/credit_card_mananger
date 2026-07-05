import 'package:flutter/material.dart';

const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];
const _weekdayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S']; // Sunday-first

/// Inline month-grid picker for a billing **due day** (day-of-month, 1–31).
///
/// Renders the current calendar month. Tapping a date selects that day number
/// as the monthly due day (the bill repeats every month on that day). The
/// "No reminder" action clears the selection — represented by
/// [selectedDay] == null.
class DueDateCalendar extends StatelessWidget {
  const DueDateCalendar({
    super.key,
    required this.selectedDay,
    required this.onSelectDay,
    required this.onNoReminder,
    this.month,
  });

  /// Selected day-of-month (1–31), or null for "no reminder".
  final int? selectedDay;
  final ValueChanged<int> onSelectDay;
  final VoidCallback onNoReminder;

  /// Month to display; defaults to the current month. Injectable for tests.
  final DateTime? month;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final shown = month ?? now;
    final year = shown.year;
    final m = shown.month;
    final daysInMonth = DateTime(year, m + 1, 0).day;
    final isCurrentMonth = year == now.year && m == now.month;
    final todayDay = isCurrentMonth ? now.day : -1;

    // weekday of the 1st (Mon=1 … Sun=7) → number of leading blanks (Sun-first)
    final leadingBlanks = DateTime(year, m, 1).weekday % 7;
    final noReminder = selectedDay == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Month header ──────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_month_outlined, size: 18, color: scheme.primary),
            const SizedBox(width: 8),
            Text(
              '${_monthNames[m - 1]} $year',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: scheme.onSurface),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Repeats every month on the day you pick',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),

        // ── Weekday labels ────────────────────────────────────────────────
        Row(
          children: _weekdayLabels
              .map((w) => Expanded(
                    child: Center(
                      child: Text(
                        w,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurfaceVariant),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),

        // ── Day grid ──────────────────────────────────────────────────────
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          children: [
            for (int i = 0; i < leadingBlanks; i++) const SizedBox.shrink(),
            for (int day = 1; day <= daysInMonth; day++)
              _DayCell(
                day: day,
                selected: !noReminder && selectedDay == day,
                isToday: day == todayDay,
                onTap: () => onSelectDay(day),
                scheme: scheme,
              ),
          ],
        ),
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
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.selected,
    required this.isToday,
    required this.onTap,
    required this.scheme,
  });

  final int day;
  final bool selected;
  final bool isToday;
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
                : isToday
                    ? scheme.primary.withValues(alpha: 0.5)
                    : scheme.outline.withValues(alpha: 0.12),
            width: isToday && !selected ? 1.5 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          '$day',
          style: TextStyle(
            fontSize: 13,
            fontWeight:
                selected || isToday ? FontWeight.w700 : FontWeight.w500,
            color: selected ? Colors.white : scheme.onSurface,
          ),
        ),
      ),
    );
  }
}
