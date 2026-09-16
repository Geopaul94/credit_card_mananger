import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/backup/backup_cubit.dart';
import '../../../../../core/di/service_locator.dart';
import '../../../../../core/storage/folder_storage.dart';
import '../../../../../core/ui/responsive_layout.dart';
import '../../../../backup/presentation/backup_screen.dart';
import '../../../domain/entities/card_folder.dart';
import '../../../domain/entities/payment_card.dart';
import '../../bloc/card_overview/card_overview_bloc.dart';
import '../../bloc/card_overview/card_overview_event.dart';
import '../../bloc/card_overview/card_overview_state.dart';
import '../../widgets/card_skeleton.dart';
import '../../widgets/card_tile.dart';
import '../../widgets/empty_card_view.dart';
import '../add_card_screen/add_card_screen.dart';
import 'models/home_card_filter.dart';
import 'widgets/card_filter_dropdown.dart';
import 'widgets/home_header.dart';
import 'widgets/next_bill_hero.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  bool _searchOpen = false;
  HomeCardFilter _selectedFilter = const AllCardsFilter();
  List<CardFolder> _folders = const [];

  @override
  void initState() {
    super.initState();
    context.read<CardOverviewBloc>().add(const LoadCardsRequested());
    _loadFolders();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFolders() async {
    final folders = await sl<FolderStorage>().loadFolders();
    if (!mounted) return;
    setState(() => _folders = folders);
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

  void _resetFilterAndSearch() {
    setState(() {
      _selectedFilter = const AllCardsFilter();
      _searchCtrl.clear();
      _query = '';
    });
  }

  /// Filters cards by the active [HomeCardFilter] (type or folder), and then
  /// matches against the search query if search is open.
  List<PaymentCard> _filterCards(List<PaymentCard> cards) {
    final filtered = _selectedFilter.apply(cards);
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return filtered;
    final digits = q.replaceAll(RegExp(r'\D'), '');

    return filtered.where((c) {
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

            if (state.cards.isEmpty) {
              return BlocBuilder<BackupCubit, BackupState>(
                buildWhen: (p, c) => p.account != c.account,
                builder: (context, backupState) => EmptyCardView(
                  connectedEmail: backupState.account?.email,
                  onRestore: () => openBackupScreen(context),
                ),
              );
            }

            final visible = _filterCards(state.cards);
            final isSearching = _searchOpen && _query.trim().isNotEmpty;
            final isCustomOrdered =
                !isSearching && _selectedFilter is AllCardsFilter;

            final headers = <Widget>[
              if (!isSearching)
                NextBillHero(
                  cards: state.cards,
                  paidCardIds: state.paidCardIds,
                ),
              if (!isSearching)
                _SectionHeader(
                  selectedFilter: _selectedFilter,
                  count: visible.length,
                  folders: _folders,
                  onFilterChanged: (f) => setState(() => _selectedFilter = f),
                ),
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
                        HomeHeader(
                          searchOpen: _searchOpen,
                          onToggleSearch: _toggleSearch,
                        ),
                        if (_searchOpen) ...[
                          SizedBox(height: context.spacing(12)),
                          HomeSearchField(
                            controller: _searchCtrl,
                            onChanged: (v) => setState(() => _query = v),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Expanded(
                    child: visible.isEmpty
                        ? ListView(
                            padding: EdgeInsets.fromLTRB(
                              context.spacing(16),
                              context.spacing(16),
                              context.spacing(16),
                              context.spacing(96),
                            ),
                            children: [
                              for (final h in headers)
                                Padding(
                                  padding: EdgeInsets.only(
                                    bottom: context.spacing(16),
                                  ),
                                  child: h,
                                ),
                              HomeNoMatches(
                                query: _query.trim(),
                                filterLabel: _selectedFilter is AllCardsFilter
                                    ? null
                                    : _selectedFilter.label,
                                onClearFilter:
                                    (_selectedFilter is! AllCardsFilter ||
                                            isSearching)
                                        ? _resetFilterAndSearch
                                        : null,
                              ),
                            ],
                          )
                        : ReorderableListView.builder(
                            buildDefaultDragHandles: isCustomOrdered,
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
                            onReorderItem: (oldIndex, newIndex) {
                              if (!isCustomOrdered) return;
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
        onPressed: () async {
          await openAddCardScreen(context);
          _loadFolders();
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 2,
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }
}

// ─── Section Header with Label & Filter Dropdown ─────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.selectedFilter,
    required this.count,
    required this.folders,
    required this.onFilterChanged,
  });

  final HomeCardFilter selectedFilter;
  final int count;
  final List<CardFolder> folders;
  final ValueChanged<HomeCardFilter> onFilterChanged;

  String get _label {
    if (selectedFilter is AllCardsFilter) return 'ALL CARDS';
    return selectedFilter.label.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _label,
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
        ),
        CardFilterDropdown(
          selectedFilter: selectedFilter,
          folders: folders,
          onFilterChanged: onFilterChanged,
        ),
      ],
    );
  }
}

// ─── Drag proxy ───────────────────────────────────────────────────────────────

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
