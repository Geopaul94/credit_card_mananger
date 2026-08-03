import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/ui/responsive_layout.dart';
import '../../../domain/entities/payment_card.dart';
import '../../bloc/card_overview/card_overview_bloc.dart';
import '../../bloc/card_overview/card_overview_event.dart';
import '../../bloc/card_overview/card_overview_state.dart';
import '../../widgets/section_card.dart';
import '../../widgets/swipe_to_confirm.dart';

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Reminders tab — shows each card's upcoming due date. Cards inside the active
/// window (3 days before → 1 day after due) get a swipe-to-pay slider; paying
/// stops that cycle's reminders.
class ReminderScreen extends StatelessWidget {
  const ReminderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      body: BlocBuilder<CardOverviewBloc, CardOverviewState>(
        builder: (context, state) {
          final withDue =
              state.cards.where((c) => c.dueDay != null).toList();

          if (state.isLoading && withDue.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (withDue.isEmpty) return const _EmptyReminders();

          // Classify by cycle status.
          final actionNeeded = <PaymentCard>[]; // active window, unpaid
          final upcoming = <PaymentCard>[]; // further out, unpaid
          final paid = <PaymentCard>[];
          for (final c in withDue) {
            if (state.paidCardIds.contains(c.id)) {
              paid.add(c);
            } else if ((c.reminderInfo?.delta ?? 99) <= 3) {
              actionNeeded.add(c);
            } else {
              upcoming.add(c);
            }
          }
          int byDelta(PaymentCard a, PaymentCard b) =>
              (a.reminderInfo?.delta ?? 0).compareTo(b.reminderInfo?.delta ?? 0);
          actionNeeded.sort(byDelta);
          upcoming.sort(byDelta);
          paid.sort(byDelta);

          return ResponsiveContent(
            child: ListView(
              padding: EdgeInsets.fromLTRB(context.spacing(16),
                  context.spacing(12), context.spacing(16), context.spacing(96)),
              children: [
                _SummaryHeader(actionCount: actionNeeded.length),
                SizedBox(height: context.spacing(20)),
                if (actionNeeded.isNotEmpty) ...[
                  const SectionLabel(label: 'DUE NOW'),
                  const SizedBox(height: 10),
                  ...actionNeeded.map((c) => _ActiveReminderCard(card: c)),
                  SizedBox(height: context.spacing(8)),
                ],
                if (upcoming.isNotEmpty) ...[
                  const SectionLabel(label: 'UPCOMING'),
                  const SizedBox(height: 10),
                  ...upcoming.map((c) => _CompactRow(card: c)),
                  SizedBox(height: context.spacing(8)),
                ],
                if (paid.isNotEmpty) ...[
                  const SectionLabel(label: 'PAID THIS CYCLE'),
                  const SizedBox(height: 10),
                  ...paid.map((c) => _CompactRow(card: c, paid: true)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Status helpers ───────────────────────────────────────────────────────────

class _Status {
  const _Status(this.label, this.color, this.urgent);
  final String label;
  final Color color;
  final bool urgent;
}

_Status _statusFor(BuildContext context, int delta) {
  final scheme = Theme.of(context).colorScheme;
  const amber = Color(0xFFD97706);
  if (delta < 0) {
    return _Status(
        'Overdue by ${-delta} day${delta == -1 ? '' : 's'}', scheme.error, true);
  }
  if (delta == 0) return _Status('Due today', scheme.error, true);
  if (delta == 1) return _Status('Due tomorrow', amber, true);
  if (delta <= 3) return _Status('Due in $delta days', amber, true);
  return _Status('Due in $delta days', scheme.onSurfaceVariant, false);
}

String _fmtDate(DateTime d) => '${_months[d.month - 1]} ${d.day}';

List<Color> _gradientFor(String typeLabel) {
  switch (typeLabel) {
    case 'Debit':
      return [const Color(0xFF7C3AED), const Color(0xFF5B21B6)];
    case 'Prepaid':
      return [const Color(0xFF059669), const Color(0xFF0D9488)];
    default:
      return [const Color(0xFF1D4ED8), const Color(0xFF4F46E5)];
  }
}

String _maskedLast4(PaymentCard c) {
  final digits = c.cardNumber.replaceAll(RegExp(r'\D'), '');
  final last4 =
      digits.length >= 4 ? digits.substring(digits.length - 4) : '••••';
  return '•••• $last4';
}

// ─── Summary header ───────────────────────────────────────────────────────────

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({required this.actionCount});
  final int actionCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final allClear = actionCount == 0;
    final accent = allClear ? const Color(0xFF0D9488) : scheme.primary;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent, Color.lerp(accent, Colors.black, 0.18)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              allClear ? Icons.check_circle_outline : Icons.notifications_active,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  allClear ? "You're all caught up" : 'Payments need attention',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  allClear
                      ? 'No bills due in the next few days.'
                      : '$actionCount bill${actionCount == 1 ? '' : 's'} due soon — swipe to mark paid.',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12.5,
                      height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section title ────────────────────────────────────────────────────────────

// ─── Active reminder card (with swipe-to-pay) ────────────────────────────────

class _ActiveReminderCard extends StatelessWidget {
  const _ActiveReminderCard({required this.card});
  final PaymentCard card;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final info = card.reminderInfo!;
    final status = _statusFor(context, info.delta);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: status.urgent
              ? status.color.withValues(alpha: 0.35)
              : scheme.outline.withValues(alpha: 0.14),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _CardAvatar(card: card),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _maskedLast4(card),
                      style: TextStyle(
                          fontSize: 12.5,
                          color: scheme.onSurfaceVariant,
                          letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
              _StatusChip(status: status),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.event_outlined,
                  size: 15, color: scheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                'Due ${_fmtDate(info.date)}',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SwipeToConfirm(
            label: 'Swipe to mark Paid',
            onConfirmed: () => context
                .read<CardOverviewBloc>()
                .add(MarkCardPaidRequested(cardId: card.id)),
          ),
        ],
      ),
    );
  }
}

// ─── Compact row (upcoming + paid) ───────────────────────────────────────────

class _CompactRow extends StatelessWidget {
  const _CompactRow({required this.card, this.paid = false});
  final PaymentCard card;
  final bool paid;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final info = card.reminderInfo!;
    final status = _statusFor(context, info.delta);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          _CardAvatar(card: card, small: true, faded: paid),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.displayTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface),
                ),
                const SizedBox(height: 2),
                Text(
                  paid
                      ? 'Paid ✓ · reminders paused'
                      : 'Due ${_fmtDate(info.date)} · ${status.label}',
                  style: TextStyle(
                      fontSize: 12,
                      color: paid
                          ? const Color(0xFF0D9488)
                          : scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (paid)
            TextButton(
              onPressed: () => context
                  .read<CardOverviewBloc>()
                  .add(MarkCardUnpaidRequested(cardId: card.id)),
              style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              child: const Text('Undo'),
            )
          else
            _StatusChip(status: status),
        ],
      ),
    );
  }
}

// ─── Shared bits ──────────────────────────────────────────────────────────────

class _CardAvatar extends StatelessWidget {
  const _CardAvatar(
      {required this.card, this.small = false, this.faded = false});
  final PaymentCard card;
  final bool small;
  final bool faded;

  @override
  Widget build(BuildContext context) {
    final size = small ? 38.0 : 46.0;
    return Opacity(
      opacity: faded ? 0.55 : 1,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _gradientFor(card.typeLabel),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(small ? 11 : 13),
        ),
        child: Icon(Icons.credit_card,
            color: Colors.white.withValues(alpha: 0.95), size: small ? 18 : 22),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final _Status status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
            color: status.color,
            fontWeight: FontWeight.w700,
            fontSize: 11.5),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyReminders extends StatelessWidget {
  const _EmptyReminders();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.notifications_off_outlined,
                  size: 34, color: scheme.primary),
            ),
            const SizedBox(height: 18),
            Text(
              'No reminders yet',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              'Add a due date to a card and it will show up here with payment reminders.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13.5,
                  height: 1.5,
                  color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
