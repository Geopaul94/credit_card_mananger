import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/ui/responsive_layout.dart';
import '../../../domain/entities/payment_card.dart';
import '../../bloc/card_overview/card_overview_bloc.dart';
import '../../bloc/card_overview/card_overview_event.dart';
import '../../bloc/card_overview/card_overview_state.dart';
import '../../widgets/card_skeleton.dart';
import '../../widgets/card_tile.dart';
import '../../widgets/empty_card_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Below this many cards the list is scannable by eye and a search box is
  /// just another thing on screen.
  static const _searchAppearsAt = 5;

  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    context.read<CardOverviewBloc>().add(const LoadCardsRequested());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Matches against everything a person might recall about a card — the bank,
  /// the product name, whose name is on it, its type, and the last four
  /// digits, which is usually how a card is identified out loud.
  List<PaymentCard> _filter(List<PaymentCard> cards) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return cards;
    final digits = q.replaceAll(RegExp(r'\D'), '');

    return cards.where((c) {
      final haystack = [
        c.bankName ?? '',
        c.cardName ?? '',
        c.holderName,
        c.typeLabel,
        c.displayTitle,
      ].join(' ').toLowerCase();
      if (haystack.contains(q)) return true;
      return digits.isNotEmpty && c.cardNumber.contains(digits);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Cards')),
      body: BlocBuilder<CardOverviewBloc, CardOverviewState>(
        builder: (context, state) {
          if (state.isLoading) return const CardListSkeleton();

          if (state.errorMessage != null) {
            return _ErrorView(
              message: state.errorMessage!,
              onRetry: () => context.read<CardOverviewBloc>().add(
                const LoadCardsRequested(),
              ),
            );
          }

          if (state.cards.isEmpty) return const EmptyCardView();

          final showSearch = state.cards.length >= _searchAppearsAt;
          final visible = showSearch ? _filter(state.cards) : state.cards;
          final isSearching = _query.trim().isNotEmpty;

          // Leading items: the summary (hidden while searching, so results
          // get the room) and the search field itself.
          final headers = <Widget>[
            if (!isSearching)
              _VaultSummary(
                cards: state.cards,
                paidCardIds: state.paidCardIds,
              ),
            if (showSearch)
              _SearchField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
                onClear: () {
                  _searchCtrl.clear();
                  setState(() => _query = '');
                },
              ),
          ];

          if (visible.isEmpty) {
            return ResponsiveContent(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      context.spacing(16),
                      context.spacing(16),
                      context.spacing(16),
                      0,
                    ),
                    child: Column(children: headers),
                  ),
                  Expanded(child: _NoMatches(query: _query.trim())),
                ],
              ),
            );
          }

          // Lazily built, and reorderable by long-press drag. Dragging is only
          // meaningful on the unfiltered list — while searching, the visible
          // indices don't match stored positions — so search results render as
          // a plain list.
          return ResponsiveContent(
            child: ReorderableListView.builder(
              buildDefaultDragHandles: !isSearching,
              padding: EdgeInsets.fromLTRB(
                context.spacing(16),
                context.spacing(16),
                context.spacing(16),
                context.spacing(96),
              ),
              header: Column(
                children: [
                  for (final h in headers)
                    Padding(
                      padding: EdgeInsets.only(bottom: context.spacing(16)),
                      child: h,
                    ),
                ],
              ),
              proxyDecorator: (child, index, animation) =>
                  _DragProxy(animation: animation, child: child),
              onReorderStart: (_) => HapticFeedback.mediumImpact(),
              // Unlike the older onReorder, this callback already accounts for
              // the dragged item leaving its slot — no off-by-one fix needed.
              onReorderItem: (oldIndex, newIndex) {
                if (isSearching) return;
                context.read<CardOverviewBloc>().add(
                      ReorderCardsRequested(
                        oldIndex: oldIndex,
                        newIndex: newIndex,
                      ),
                    );
              },
              itemCount: visible.length,
              itemBuilder: (context, index) {
                final card = visible[index];
                return CardTile(
                  // Reorder animations track items by key, not position.
                  key: ValueKey(card.id),
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

// ─── Drag proxy ───────────────────────────────────────────────────────────────

/// How a card looks while it is being dragged: slightly lifted and enlarged,
/// so it reads as "picked up" rather than glitched.
class _DragProxy extends StatelessWidget {
  const _DragProxy({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = Curves.easeOut.transform(animation.value);
        return Transform.scale(
          scale: 1.0 + 0.03 * t,
          child: child,
        );
      },
    );
  }
}

// ─── Search ───────────────────────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search bank, name, or last 4 digits',
        prefixIcon: Icon(Icons.search, size: 20, color: scheme.onSurfaceVariant),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: onClear,
                tooltip: 'Clear',
              ),
        isDense: true,
      ),
    );
  }
}

class _NoMatches extends StatelessWidget {
  const _NoMatches({required this.query});
  final String query;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.spacing(28)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: context.spacing(40),
              color: scheme.onSurfaceVariant,
            ),
            SizedBox(height: context.spacing(10)),
            Text(
              'No cards match "$query"',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
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
