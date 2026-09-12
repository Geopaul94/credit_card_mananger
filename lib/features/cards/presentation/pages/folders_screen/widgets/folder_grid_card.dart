import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../domain/entities/card_folder.dart';
import '../../../../domain/entities/payment_card.dart';
import 'folder_palette.dart';
import 'folder_stack_preview.dart';

/// Interactive folder card styled like a luxury digital card sleeve.
class FolderGridCard extends StatelessWidget {
  const FolderGridCard({
    required this.folder,
    required this.cards,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final CardFolder folder;
  final List<PaymentCard> cards;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final gradient = FolderPalette.gradientFor(folder.colorIndex);
    final iconData = FolderPalette.iconFor(folder.iconKey);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: gradient.first.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1.2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Background subtle glass glow overlay
                Positioned(
                  top: -40,
                  right: -40,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                ),

                // Cards Stack Preview
                Positioned(
                  left: 0,
                  right: 0,
                  top: 52,
                  bottom: 74,
                  child: FolderStackPreview(cards: cards),
                ),

                // Bottom gradient protection for readability
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 90,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.65),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),

                // Top Folder Header (Icon + Tab + Menu)
                Positioned(
                  left: 16,
                  right: 8,
                  top: 14,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                            width: 0.8,
                          ),
                        ),
                        child: Icon(
                          iconData,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${cards.length} ${cards.length == 1 ? 'card' : 'cards'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      const Spacer(),
                      PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        tooltip: 'Folder options',
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        onSelected: (value) {
                          if (value == 'edit') {
                            onEdit();
                          } else if (value == 'delete') {
                            onDelete();
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 18),
                                SizedBox(width: 12),
                                Text('Edit folder'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18,
                                  color: Colors.redAccent,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Delete folder',
                                  style: TextStyle(color: Colors.redAccent),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Bottom Details
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        folder.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        cards.isEmpty
                            ? 'Tap to manage cards'
                            : '${cards.map((c) => c.bankName ?? c.displayTitle).take(2).join(', ')}${cards.length > 2 ? '...' : ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
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
      ),
    );
  }
}
