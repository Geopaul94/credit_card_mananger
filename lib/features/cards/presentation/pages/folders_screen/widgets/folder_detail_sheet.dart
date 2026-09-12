import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../../core/theme/card_palette.dart';
import '../../../../domain/entities/card_folder.dart';
import '../../../../domain/entities/payment_card.dart';
import '../../card_detail_screen/card_detail_screen.dart';
import 'folder_palette.dart';

/// Modal bottom sheet to view and manage cards within a folder.
class FolderDetailSheet extends StatefulWidget {
  const FolderDetailSheet({
    required this.folder,
    required this.allCards,
    required this.onFolderUpdated,
    required this.onDeleteFolder,
    required this.onEditFolder,
    super.key,
  });

  final CardFolder folder;
  final List<PaymentCard> allCards;
  final ValueChanged<CardFolder> onFolderUpdated;
  final VoidCallback onDeleteFolder;
  final VoidCallback onEditFolder;

  @override
  State<FolderDetailSheet> createState() => _FolderDetailSheetState();
}

class _FolderDetailSheetState extends State<FolderDetailSheet> {
  late CardFolder _folder;
  final String _addSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _folder = widget.folder;
  }

  List<PaymentCard> get _currentCards {
    final map = {for (final c in widget.allCards) c.id: c};
    return _folder.cardIds.map((id) => map[id]).whereType<PaymentCard>().toList();
  }

  List<PaymentCard> get _availableCards {
    final currentIds = _folder.cardIds.toSet();
    final list = widget.allCards.where((c) => !currentIds.contains(c.id)).toList();
    if (_addSearchQuery.trim().isEmpty) return list;
    final q = _addSearchQuery.toLowerCase();
    return list.where((c) {
      final text = '${c.displayTitle} ${c.bankName ?? ''} ${c.cardNumber} ${c.holderName}'
          .toLowerCase();
      return text.contains(q);
    }).toList();
  }

  void _toggleCard(PaymentCard card) {
    HapticFeedback.selectionClick();
    final newIds = List<String>.from(_folder.cardIds);
    if (newIds.contains(card.id)) {
      newIds.remove(card.id);
    } else {
      newIds.add(card.id);
    }
    final updated = _folder.copyWith(cardIds: newIds);
    setState(() => _folder = updated);
    widget.onFolderUpdated(updated);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final gradient = FolderPalette.gradientFor(_folder.colorIndex);
    final iconData = FolderPalette.iconFor(_folder.iconKey);
    final currentCards = _currentCards;
    final availableCards = _availableCards;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),

          // Folder Banner Header
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(iconData, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
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
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${currentCards.length} ${currentCards.length == 1 ? 'card' : 'cards'} organized',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.white),
                  tooltip: 'Edit folder',
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onEditFolder();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Scrollable Content
          Flexible(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                MediaQuery.of(context).padding.bottom + 24,
              ),
              children: [
                // Cards in folder
                Row(
                  children: [
                    Text(
                      'CARDS IN FOLDER (${currentCards.length})',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (currentCards.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: scheme.outline.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'No cards added to this folder yet.\nSelect cards below to add them.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                  )
                else
                  ...currentCards.map(
                    (card) => _CardListTile(
                      card: card,
                      trailingIcon: Icons.remove_circle_outline_rounded,
                      trailingColor: Colors.redAccent,
                      trailingTooltip: 'Remove from folder',
                      onTrailingTap: () => _toggleCard(card),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CardDetailScreen(card: card),
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 20),
                // Add Cards Section
                Row(
                  children: [
                    Text(
                      'ADD CARDS TO FOLDER',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (widget.allCards.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'No cards exist in your vault yet.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                else if (availableCards.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline_rounded,
                            color: scheme.primary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'All cards in your vault are in this folder.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...availableCards.map(
                    (card) => _CardListTile(
                      card: card,
                      trailingIcon: Icons.add_circle_outline_rounded,
                      trailingColor: scheme.primary,
                      trailingTooltip: 'Add to folder',
                      onTrailingTap: () => _toggleCard(card),
                      onTap: () => _toggleCard(card),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardListTile extends StatelessWidget {
  const _CardListTile({
    required this.card,
    required this.trailingIcon,
    required this.trailingColor,
    required this.trailingTooltip,
    required this.onTrailingTap,
    required this.onTap,
  });

  final PaymentCard card;
  final IconData trailingIcon;
  final Color trailingColor;
  final String trailingTooltip;
  final VoidCallback onTrailingTap;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cardGrad = CardPalette.forCard(card);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.outline.withValues(alpha: 0.12),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
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
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          '•••• ${card.lastFour} · ${card.typeLabel}',
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
        ),
        trailing: IconButton(
          icon: Icon(trailingIcon, color: trailingColor, size: 22),
          tooltip: trailingTooltip,
          onPressed: onTrailingTap,
        ),
      ),
    );
  }
}
