import 'package:flutter/material.dart';

import '../../../../domain/entities/payment_card.dart';
import '../../../widgets/card_chip.dart';

const _weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// The soonest unpaid bill, front and centre — the one thing on this screen
/// worth acting on today.
class NextBillHero extends StatelessWidget {
  const NextBillHero({
    super.key,
    required this.cards,
    required this.paidCardIds,
  });

  final List<PaymentCard> cards;
  final Set<String> paidCardIds;

  ({PaymentCard card, DateTime date, int delta})? get _nextDue {
    ({PaymentCard card, DateTime date, int delta})? soonest;
    for (final c in cards) {
      if (paidCardIds.contains(c.id)) continue;
      final info = c.reminderInfo;
      if (info == null) continue;
      if (soonest == null || info.delta < soonest.delta) {
        soonest = (card: c, date: info.date, delta: info.delta);
      }
    }
    return soonest;
  }

  String _dateLabel(DateTime d) =>
      '${_weekdayNames[d.weekday - 1]}, ${d.day} ${_monthNames[d.month - 1]}';

  String _pillLabel(int delta) {
    if (delta < 0) return delta == -1 ? 'OVERDUE BY 1 DAY' : 'OVERDUE';
    return switch (delta) {
      0 => 'DUE TODAY',
      1 => 'NEXT BILL TOMORROW',
      _ => 'NEXT BILL IN $delta DAYS',
    };
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final next = _nextDue;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: next == null
          ? Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: scheme.onSecondaryContainer,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'All caught up — no bills due right now.',
                    style: text.titleSmall
                        ?.copyWith(color: scheme.onSecondaryContainer),
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _pillLabel(next.delta),
                  style: text.labelSmall?.copyWith(
                    color: scheme.onSecondaryContainer.withValues(alpha: 0.7),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _dateLabel(next.date),
                  style: text.headlineSmall
                      ?.copyWith(color: scheme.onSecondaryContainer),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CardChip(card: next.card),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${next.card.displayTitle} · due on the '
                        '${next.card.dueDayLabel}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall?.copyWith(
                          color: scheme.onSecondaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
