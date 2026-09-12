import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/theme/card_palette.dart';
import '../../../../../../core/ui/responsive_layout.dart';
import '../../../../domain/entities/card_folder.dart';
import '../../../../domain/entities/payment_card.dart';
import '../../../bloc/card_overview/card_overview_bloc.dart';

/// Bottom sheet to add or remove cards belonging to a folder.
class FolderManageCardsSheet extends StatefulWidget {
  const FolderManageCardsSheet({
    required this.folder,
    required this.allCards,
    required this.onFolderUpdated,
    super.key,
  });

  final CardFolder folder;
  final List<PaymentCard> allCards;
  final ValueChanged<CardFolder> onFolderUpdated;

  @override
  State<FolderManageCardsSheet> createState() => _FolderManageCardsSheetState();
}

class _FolderManageCardsSheetState extends State<FolderManageCardsSheet> {
  late Set<String> _selectedCardIds;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedCardIds = widget.folder.cardIds.toSet();
  }

  List<PaymentCard> get _effectiveCards {
    try {
      final blocCards = context.read<CardOverviewBloc>().state.cards;
      if (blocCards.isNotEmpty) return blocCards;
    } catch (_) {}
    return widget.allCards;
  }

  void _toggleCard(PaymentCard card) {
    HapticFeedback.selectionClick();
    if (!mounted) return;
    setState(() {
      if (_selectedCardIds.contains(card.id)) {
        _selectedCardIds.remove(card.id);
      } else {
        _selectedCardIds.add(card.id);
      }
    });
    final updated = widget.folder.copyWith(
      cardIds: _selectedCardIds.toList(),
    );
    widget.onFolderUpdated(updated);
  }

  List<PaymentCard> get _filteredCards {
    final list = _effectiveCards;
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return list;
    return list.where((c) {
      final text = [
        c.displayTitle,
        c.bankName ?? '',
        c.cardName ?? '',
        c.holderName,
        c.typeLabel,
        c.formattedNumber,
      ].join(' ').toLowerCase();
      return text.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final filtered = _filteredCards;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: EdgeInsets.only(
                top: context.spacing(12),
                bottom: context.spacing(8),
              ),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.spacing(20),
              vertical: context.spacing(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manage Folder Cards',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        '${_selectedCardIds.length} of ${_effectiveCards.length} cards selected',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                FilledButton.tonal(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Done'),
                ),
              ],
            ),
          ),

          // Search Field if vault has multiple cards
          if (_effectiveCards.length > 3)
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.spacing(20),
                0,
                context.spacing(20),
                context.spacing(12),
              ),
              child: TextField(
                onChanged: (v) {
                  if (!mounted) return;
                  setState(() => _searchQuery = v);
                },
                decoration: InputDecoration(
                  hintText: 'Search vault cards',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: context.spacing(16),
                    vertical: context.spacing(10),
                  ),
                  isDense: true,
                ),
              ),
            ),

          const Divider(height: 1),

          // Card List
          Flexible(
            child: _effectiveCards.isEmpty
                ? Padding(
                    padding: EdgeInsets.all(context.spacing(32)),
                    child: Center(
                      child: Text(
                        'No cards in your vault yet.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                  )
                : filtered.isEmpty
                    ? Padding(
                        padding: EdgeInsets.all(context.spacing(32)),
                        child: Center(
                          child: Text(
                            'No matching cards found.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.fromLTRB(
                          context.spacing(16),
                          context.spacing(8),
                          context.spacing(16),
                          MediaQuery.of(context).padding.bottom + context.spacing(16),
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final card = filtered[index];
                          final isSelected = _selectedCardIds.contains(card.id);
                          final cardGrad = CardPalette.forCard(card);

                          return Padding(
                            padding: EdgeInsets.only(bottom: context.spacing(8)),
                            child: Material(
                              color: isSelected
                                  ? scheme.primaryContainer.withValues(alpha: 0.25)
                                  : scheme.surfaceContainerHighest.withValues(alpha: 0.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: isSelected
                                      ? scheme.primary.withValues(alpha: 0.5)
                                      : scheme.outline.withValues(alpha: 0.12),
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: ListTile(
                                onTap: () => _toggleCard(card),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: context.spacing(14),
                                  vertical: context.spacing(2),
                                ),
                                leading: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: cardGrad,
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      card.displayTitle.isNotEmpty
                                          ? card.displayTitle.substring(0, 1).toUpperCase()
                                          : 'C',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  card.displayTitle,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Text(
                                  '•••• ${card.lastFour} · ${card.typeLabel}',
                                  style: TextStyle(
                                    color: scheme.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: Checkbox(
                                  value: isSelected,
                                  onChanged: (_) => _toggleCard(card),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
