import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/ui/responsive_layout.dart';
import '../../../domain/entities/card_folder.dart';
import '../../../domain/entities/payment_card.dart';
import '../../bloc/card_overview/card_overview_bloc.dart';
import '../../bloc/card_overview/card_overview_event.dart';
import '../../bloc/card_overview/card_overview_state.dart';
import '../../widgets/card_tile.dart';
import 'widgets/create_folder_sheet.dart';
import 'widgets/folder_manage_cards_sheet.dart';
import 'widgets/folder_palette.dart';

/// Full screen view displaying all cards belonging to a specific folder,
/// styled identically to the main home screen with full card interactions.
class FolderCardsScreen extends StatefulWidget {
  const FolderCardsScreen({
    required this.folder,
    required this.onFolderUpdated,
    required this.onFolderDeleted,
    super.key,
  });

  final CardFolder folder;
  final ValueChanged<CardFolder> onFolderUpdated;
  final VoidCallback onFolderDeleted;

  @override
  State<FolderCardsScreen> createState() => _FolderCardsScreenState();
}

class _FolderCardsScreenState extends State<FolderCardsScreen> {
  late CardFolder _folder;
  final TextEditingController _searchCtrl = TextEditingController();
  bool _searchOpen = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _folder = widget.folder;
    final bloc = context.read<CardOverviewBloc>();
    if (bloc.state.cards.isEmpty && !bloc.state.isLoading) {
      bloc.add(const LoadCardsRequested());
    }
  }

  @override
  void didUpdateWidget(covariant FolderCardsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.folder != widget.folder) {
      setState(() => _folder = widget.folder);
    }
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

  void _openManageCards(List<PaymentCard> allCards) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FolderManageCardsSheet(
        folder: _folder,
        allCards: allCards,
        onFolderUpdated: (updated) {
          if (!mounted) return;
          setState(() => _folder = updated);
          widget.onFolderUpdated(updated);
        },
      ),
    );
  }

  void _openEditFolder(List<PaymentCard> allCards) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateFolderSheet(
        initialFolder: _folder,
        allCards: allCards,
        onSave: (saved) {
          if (!mounted) return;
          setState(() => _folder = saved);
          widget.onFolderUpdated(saved);
        },
      ),
    );
  }

  Future<void> _confirmDeleteFolder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete folder?'),
        content: Text(
          'Delete "${_folder.name}"? The cards inside will not be removed from your vault.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      HapticFeedback.mediumImpact();
      widget.onFolderDeleted();
      Navigator.of(context).pop();
    }
  }

  List<PaymentCard> _filterCards(List<PaymentCard> cards) {
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
    final gradient = FolderPalette.gradientFor(_folder.colorIndex);
    final iconData = FolderPalette.iconFor(_folder.iconKey);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<CardOverviewBloc, CardOverviewState>(
          builder: (context, state) {
            if (state.isLoading && state.cards.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            final byId = {for (final card in state.cards) card.id: card};
            final folderCards = _folder.cardIds
                .map((id) => byId[id])
                .whereType<PaymentCard>()
                .toList();
            final visibleCards = _searchOpen
                ? _filterCards(folderCards)
                : folderCards;

            return ResponsiveContent(
              child: Column(
                children: [
                  // App Bar / Navigation Header
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      context.spacing(8),
                      context.spacing(8),
                      context.spacing(16),
                      0,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_rounded),
                          tooltip: 'Back to folders',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const Spacer(),
                        if (folderCards.isNotEmpty)
                          IconButton(
                            icon: Icon(
                              _searchOpen
                                  ? Icons.close_rounded
                                  : Icons.search_rounded,
                            ),
                            tooltip: _searchOpen ? 'Close search' : 'Search cards',
                            onPressed: _toggleSearch,
                          ),
                        IconButton(
                          icon: const Icon(Icons.playlist_add_rounded),
                          tooltip: 'Manage cards',
                          onPressed: () => _openManageCards(state.cards),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded),
                          tooltip: 'Folder options',
                          onSelected: (val) {
                            if (val == 'edit') {
                              _openEditFolder(state.cards);
                            } else if (val == 'delete') {
                              _confirmDeleteFolder();
                            }
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 20),
                                  SizedBox(width: 12),
                                  Text('Edit folder'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_outline_rounded,
                                    size: 20,
                                    color: scheme.error,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Delete folder',
                                    style: TextStyle(color: scheme.error),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Folder Hero Banner
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      context.spacing(16),
                      context.spacing(4),
                      context.spacing(16),
                      context.spacing(12),
                    ),
                    child: Container(
                      padding: EdgeInsets.all(context.spacing(16)),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: gradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: gradient.first.withValues(alpha: 0.28),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(context.spacing(10)),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(iconData, color: Colors.white, size: 26),
                          ),
                          SizedBox(width: context.spacing(14)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _folder.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${folderCards.length} ${folderCards.length == 1 ? 'card' : 'cards'} organized',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.88),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // In-folder search field
                  if (_searchOpen)
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        context.spacing(16),
                        0,
                        context.spacing(16),
                        context.spacing(12),
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (v) => setState(() => _query = v),
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Search cards in "${_folder.name}"',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _query.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close_rounded),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() => _query = '');
                                  },
                                )
                              : null,
                        ),
                      ),
                    ),

                  // Cards List
                  Expanded(
                    child: folderCards.isEmpty
                        ? _EmptyFolderCardsView(
                            onAddCards: () => _openManageCards(state.cards),
                          )
                        : visibleCards.isEmpty
                            ? Center(
                                child: Text(
                                  'No cards matching "$_query"',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                ),
                              )
                            : ListView.builder(
                                padding: EdgeInsets.fromLTRB(
                                  context.spacing(16),
                                  context.spacing(4),
                                  context.spacing(16),
                                  context.spacing(96),
                                ),
                                itemCount: visibleCards.length,
                                itemBuilder: (context, index) {
                                  final card = visibleCards[index];
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final allCards = context.read<CardOverviewBloc>().state.cards;
          _openManageCards(allCards);
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Manage Cards'),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
    );
  }
}

class _EmptyFolderCardsView extends StatelessWidget {
  const _EmptyFolderCardsView({required this.onAddCards});
  final VoidCallback onAddCards;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.spacing(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(context.spacing(20)),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
              ),
              child: Icon(
                Icons.credit_card_off_rounded,
                size: 48,
                color: scheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: context.spacing(16)),
            Text(
              'No cards in this folder yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            SizedBox(height: context.spacing(6)),
            Text(
              'Add existing cards from your vault into this folder for quick access.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            SizedBox(height: context.spacing(20)),
            FilledButton.icon(
              onPressed: onAddCards,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Cards to Folder'),
            ),
          ],
        ),
      ),
    );
  }
}
