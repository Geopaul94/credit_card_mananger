import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/backup/backup_cubit.dart';
import '../../../../../core/theme/card_palette.dart';
import '../../../../../core/ui/responsive_layout.dart';
import '../../../../backup/presentation/backup_screen.dart';
import '../../../domain/entities/payment_card.dart';
import '../../bloc/card_overview/card_overview_bloc.dart';
import '../../bloc/card_overview/card_overview_event.dart';
import '../../bloc/card_overview/card_overview_state.dart';
import '../../widgets/card_skeleton.dart';
import '../../widgets/card_tile.dart';
import '../../widgets/empty_card_view.dart';
import '../add_card_screen/add_card_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  bool _searchOpen = false;

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

  void _toggleSearch() {
    setState(() {
      _searchOpen = !_searchOpen;
      if (!_searchOpen) {
        _searchCtrl.clear();
        _query = '';
      }
    });
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
      body: SafeArea(
        child: BlocBuilder<CardOverviewBloc, CardOverviewState>(
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

            // An empty vault is also what a reinstall looks like, so this is
            // where the offer to restore a Drive backup belongs.
            if (state.cards.isEmpty) {
              return BlocBuilder<BackupCubit, BackupState>(
                buildWhen: (p, c) => p.account != c.account,
                builder: (context, backupState) => EmptyCardView(
                  connectedEmail: backupState.account?.email,
                  onRestore: () => openBackupScreen(context),
                ),
              );
            }

            final visible = _searchOpen ? _filter(state.cards) : state.cards;
            final isSearching = _searchOpen && _query.trim().isNotEmpty;

            // The hero and "ALL CARDS" label are hidden while actively
            // searching, so filtered results get the room instead.
            final headers = <Widget>[
              if (!isSearching)
                _NextBillHero(cards: state.cards, paidCardIds: state.paidCardIds),
              if (!isSearching) _AllCardsLabel(count: state.cards.length),
            ];

            return ResponsiveContent(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      context.spacing(16),
                      context.spacing(8),
                      context.spacing(16),
                      0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Header(
                          searchOpen: _searchOpen,
                          onToggleSearch: _toggleSearch,
                        ),
                        if (_searchOpen) ...[
                          SizedBox(height: context.spacing(12)),
                          _SearchField(
                            controller: _searchCtrl,
                            onChanged: (v) => setState(() => _query = v),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Expanded(
                    child: visible.isEmpty
                        ? _NoMatches(query: _query.trim())
                        // Lazily built, and reorderable by long-press drag.
                        // Dragging is only meaningful on the unfiltered
                        // list — while searching, visible indices don't
                        // match stored positions — so results render plain.
                        : ReorderableListView.builder(
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
                                    padding: EdgeInsets.only(
                                      bottom: context.spacing(16),
                                    ),
                                    child: h,
                                  ),
                              ],
                            ),
                            proxyDecorator: (child, index, animation) =>
                                _DragProxy(animation: animation, child: child),
                            onReorderStart: (_) =>
                                HapticFeedback.mediumImpact(),
                            // Unlike the older onReorder, this callback
                            // already accounts for the dragged item leaving
                            // its slot — no off-by-one fix needed.
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
                                // Reorder animations track items by key.
                                key: ValueKey(card.id),
                                card: card,
                                isPaid: state.paidCardIds.contains(card.id),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => openAddCardScreen(context),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 2,
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.searchOpen, required this.onToggleSearch});
  final bool searchOpen;
  final VoidCallback onToggleSearch;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.secondary,
                      letterSpacing: 1,
                    ),
              ),
              const SizedBox(height: 2),
              Text('My cards', style: Theme.of(context).textTheme.displaySmall),
            ],
          ),
        ),
        _CircleIconButton(
          icon: searchOpen ? Icons.close : Icons.search,
          onTap: onToggleSearch,
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // A shade more tan than the page background, so the circle actually
    // reads as a button rather than disappearing into the cream behind it.
    return Material(
      color: scheme.surfaceContainerHigh,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 20, color: scheme.onSurface),
        ),
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
  const _SearchField({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      autofocus: true,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search bank, name, or last 4 digits',
        prefixIcon: Icon(Icons.search, size: 20, color: scheme.onSurfaceVariant),
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

// ─── Next-bill hero ───────────────────────────────────────────────────────────

const _weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// The soonest unpaid bill, front and centre — the one thing on this screen
/// worth acting on today.
class _NextBillHero extends StatelessWidget {
  const _NextBillHero({required this.cards, required this.paidCardIds});

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
                Icon(Icons.check_circle_outline,
                    color: scheme.onSecondaryContainer, size: 22),
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
                    _MiniChip(card: next.card),
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

/// Small colour swatch identifying the soonest-due card — same colour and
/// bank label as the full gradient card below, so the hero and the card it
/// points at are visibly the same card, not just a generic icon.
class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.card});
  final PaymentCard card;

  String _shortLabel() {
    final bank = card.bankName?.trim();
    if (bank == null || bank.isEmpty) return card.typeLabel;
    return bank.length <= 6 ? bank.toUpperCase() : bank.substring(0, 6).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final digits = card.cardNumber.replaceAll(RegExp(r'\D'), '');
    final last4 = digits.length >= 4 ? digits.substring(digits.length - 4) : '';

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: CardPalette.forCard(card).first,
        borderRadius: BorderRadius.circular(9),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _shortLabel(),
            maxLines: 1,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
          if (last4.isNotEmpty)
            Text(
              last4,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}

class _AllCardsLabel extends StatelessWidget {
  const _AllCardsLabel({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(
          'ALL CARDS',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                letterSpacing: 1,
              ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: scheme.onPrimaryContainer,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
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
