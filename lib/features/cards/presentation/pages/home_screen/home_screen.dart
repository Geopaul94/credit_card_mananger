import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/ui/responsive_layout.dart';
import '../../../domain/entities/payment_card.dart';
import '../../bloc/card_overview/card_overview_bloc.dart';
import '../../bloc/card_overview/card_overview_event.dart';
import '../../bloc/card_overview/card_overview_state.dart';
import '../../widgets/card_tile.dart';
import '../../widgets/empty_card_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CardOverviewBloc>().add(const LoadCardsRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Cards')),
      body: BlocBuilder<CardOverviewBloc, CardOverviewState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.errorMessage != null) {
            return _ErrorView(
              message: state.errorMessage!,
              onRetry: () => context.read<CardOverviewBloc>().add(
                const LoadCardsRequested(),
              ),
            );
          }

          if (state.cards.isEmpty) return const EmptyCardView();

          // Lazily built: only the cards actually on screen are laid out,
          // which matters because each one is a full-height gradient card.
          return ResponsiveContent(
            child: ListView.builder(
              padding: EdgeInsets.fromLTRB(
                context.spacing(16),
                context.spacing(16),
                context.spacing(16),
                context.spacing(96),
              ),
              // One extra leading item for the summary header.
              itemCount: state.cards.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: context.spacing(20)),
                    child: _VaultSummary(
                      cards: state.cards,
                      paidCardIds: state.paidCardIds,
                    ),
                  );
                }
                final card = state.cards[index - 1];
                return CardTile(
                  card: card,
                  isPaid: state.paidCardIds.contains(card.id),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ─── Summary header ───────────────────────────────────────────────────────────

/// The hero at the top of the vault. Answers the two questions actually worth
/// answering on open — how many cards am I holding, and what is due next —
/// instead of greeting the user with text they cannot act on.
class _VaultSummary extends StatelessWidget {
  const _VaultSummary({required this.cards, required this.paidCardIds});

  final List<PaymentCard> cards;
  final Set<String> paidCardIds;

  /// The unpaid card whose due date lands soonest, or null if nothing is due.
  ({PaymentCard card, int delta})? get _nextDue {
    ({PaymentCard card, int delta})? soonest;
    for (final c in cards) {
      if (paidCardIds.contains(c.id)) continue;
      final info = c.reminderInfo;
      if (info == null) continue;
      if (soonest == null || info.delta < soonest.delta) {
        soonest = (card: c, delta: info.delta);
      }
    }
    return soonest;
  }

  String _dueLabel(int delta) {
    if (delta < 0) {
      final days = -delta;
      return days == 1 ? 'overdue by a day' : 'overdue by $days days';
    }
    return switch (delta) {
      0 => 'due today',
      1 => 'due tomorrow',
      _ => 'due in $delta days',
    };
  }

  @override
  Widget build(BuildContext context) {
    final next = _nextDue;
    final isUrgent = next != null && next.delta <= 1;

    return Container(
      padding: EdgeInsets.all(context.spacing(18)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(context.spacing(20)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.32),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            cards.length == 1
                ? '1 card secured'
                : '${cards.length} cards secured',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: context.font(21),
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: context.spacing(14)),

          // Next bill — the one thing worth acting on today.
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: context.spacing(12),
              vertical: context.spacing(10),
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: isUrgent ? 0.22 : 0.13),
              borderRadius: BorderRadius.circular(context.spacing(12)),
              border: Border.all(
                color: Colors.white.withValues(alpha: isUrgent ? 0.5 : 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  next == null
                      ? Icons.check_circle_outline
                      : (isUrgent
                            ? Icons.notifications_active_outlined
                            : Icons.event_outlined),
                  color: Colors.white,
                  size: context.spacing(19),
                ),
                SizedBox(width: context.spacing(10)),
                Expanded(
                  child: next == null
                      ? Text(
                          'No bills due — you are all caught up.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: context.font(13.5),
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              next.card.displayTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: context.font(14),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              _dueLabel(next.delta),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: context.font(12.5),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),

          SizedBox(height: context.spacing(12)),
          Row(
            children: [
              Icon(
                Icons.lock_outline,
                size: context.spacing(13),
                color: Colors.white.withValues(alpha: 0.7),
              ),
              SizedBox(width: context.spacing(6)),
              Expanded(
                child: Text(
                  'Encrypted on this device',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: context.font(11.5),
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

// ─── Error state ──────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.spacing(32)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: context.spacing(56),
              height: context.spacing(56),
              decoration: BoxDecoration(
                color: scheme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_off_outlined,
                color: scheme.onErrorContainer,
                size: context.spacing(26),
              ),
            ),
            SizedBox(height: context.spacing(14)),
            Text(
              "Couldn't load your cards",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: context.spacing(6)),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            SizedBox(height: context.spacing(18)),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
