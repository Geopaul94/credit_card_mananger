import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/theme/card_palette.dart';
import '../../../../domain/entities/card_folder.dart';
import '../../../../domain/entities/payment_card.dart';
import '../../../bloc/card_overview/card_overview_bloc.dart';
import 'folder_palette.dart';

/// Modal bottom sheet to create or edit a folder.
class CreateFolderSheet extends StatefulWidget {
  const CreateFolderSheet({
    this.initialFolder,
    required this.allCards,
    required this.onSave,
    super.key,
  });

  final CardFolder? initialFolder;
  final List<PaymentCard> allCards;
  final ValueChanged<CardFolder> onSave;

  @override
  State<CreateFolderSheet> createState() => _CreateFolderSheetState();
}

class _CreateFolderSheetState extends State<CreateFolderSheet> {
  late final TextEditingController _nameController;
  late String _iconKey;
  late int _colorIndex;
  late Set<String> _selectedCardIds;

  bool get _isEditing => widget.initialFolder != null;

  @override
  void initState() {
    super.initState();
    final folder = widget.initialFolder;
    _nameController = TextEditingController(text: folder?.name ?? '');
    _iconKey = folder?.iconKey ?? 'folder';
    _colorIndex = folder?.colorIndex ?? 0;
    _selectedCardIds = Set<String>.from(folder?.cardIds ?? <String>[]);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    HapticFeedback.lightImpact();
    final result = CardFolder(
      id: widget.initialFolder?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      iconKey: _iconKey,
      colorIndex: _colorIndex,
      cardIds: _selectedCardIds.toList(),
      createdAt: widget.initialFolder?.createdAt ?? DateTime.now(),
    );

    widget.onSave(result);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selectedGradient = FolderPalette.gradientFor(_colorIndex);

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            16,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),

          // Title & preview avatar
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: selectedGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  FolderPalette.iconFor(_iconKey),
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  _isEditing ? 'Edit Folder' : 'New Folder',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                // Folder Name input
                TextField(
                  controller: _nameController,
                  autofocus: !_isEditing,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Folder Name',
                    hintText: 'e.g. Travel Cards, Daily Expenses',
                    prefixIcon: const Icon(Icons.drive_file_rename_outline_rounded),
                    suffixIcon: _nameController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _nameController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 18),

                // Icon Selector
                Text(
                  'FOLDER ICON',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: FolderPalette.icons.entries.map((entry) {
                      final isSelected = _iconKey == entry.key;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          avatar: Icon(
                            entry.value.icon,
                            size: 18,
                            color: isSelected
                                ? scheme.onPrimary
                                : scheme.onSurfaceVariant,
                          ),
                          label: Text(entry.value.label),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) {
                              HapticFeedback.selectionClick();
                              setState(() => _iconKey = entry.key);
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 18),

                // Color Theme Selector
                Text(
                  'COLOR THEME',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: FolderPalette.gradients.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final isSelected = _colorIndex == index;
                      final grad = FolderPalette.gradients[index];
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _colorIndex = index);
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: grad,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                              color: isSelected
                                  ? scheme.onSurface
                                  : Colors.transparent,
                              width: 2.5,
                            ),
                            boxShadow: [
                              if (isSelected)
                                BoxShadow(
                                  color: grad.first.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                            ],
                          ),
                          child: isSelected
                              ? const Icon(Icons.check_rounded,
                                  color: Colors.white, size: 20)
                              : null,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Card Selection
                Builder(
                  builder: (context) {
                    List<PaymentCard> effectiveCards = widget.allCards;
                    try {
                      final blocCards =
                          context.watch<CardOverviewBloc>().state.cards;
                      if (blocCards.isNotEmpty) {
                        effectiveCards = blocCards;
                      }
                    } catch (_) {}

                    if (effectiveCards.isEmpty) return const SizedBox.shrink();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'INCLUDE CARDS (${_selectedCardIds.length})',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6,
                                  ),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  if (_selectedCardIds.length ==
                                      effectiveCards.length) {
                                    _selectedCardIds.clear();
                                  } else {
                                    _selectedCardIds = {
                                      for (final c in effectiveCards) c.id
                                    };
                                  }
                                });
                              },
                              child: Text(_selectedCardIds.length ==
                                      effectiveCards.length
                                  ? 'Deselect all'
                                  : 'Select all'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ...effectiveCards.map((card) {
                          final isChecked = _selectedCardIds.contains(card.id);
                          return CheckboxListTile(
                            value: isChecked,
                            onChanged: (val) {
                              HapticFeedback.selectionClick();
                              setState(() {
                                if (val == true) {
                                  _selectedCardIds.add(card.id);
                                } else {
                                  _selectedCardIds.remove(card.id);
                                }
                              });
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            title: Text(
                              card.displayTitle,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text('•••• ${card.lastFour}'),
                            secondary: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: CardPalette.forCard(card),
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  card.displayTitle.isNotEmpty
                                      ? card.displayTitle[0].toUpperCase()
                                      : 'C',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Save / Create CTA Button
          FilledButton.icon(
            onPressed: _nameController.text.trim().isNotEmpty ? _save : null,
            icon: Icon(_isEditing ? Icons.save_rounded : Icons.check_rounded),
            label: Text(_isEditing ? 'Save Changes' : 'Create Folder'),
          ),
        ],
      ),
    );
  }
}
