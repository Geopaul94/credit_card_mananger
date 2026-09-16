import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../domain/entities/card_folder.dart';
import '../../folders_screen/widgets/folder_palette.dart';
import '../models/home_card_filter.dart';

/// A compact Material 3 filter button on the Home screen that lets users
/// switch between "All Cards", card types (Credit, Debit, Prepaid), and
/// user-defined custom folders.
class CardFilterDropdown extends StatelessWidget {
  const CardFilterDropdown({
    super.key,
    required this.selectedFilter,
    required this.folders,
    required this.onFilterChanged,
  });

  final HomeCardFilter selectedFilter;
  final List<CardFolder> folders;
  final ValueChanged<HomeCardFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isFiltered = selectedFilter is! AllCardsFilter;

    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: PopupMenuThemeData(
          color: scheme.surfaceContainerHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: scheme.outline.withValues(alpha: 0.15),
            ),
          ),
          elevation: 6,
        ),
      ),
      child: PopupMenuButton<HomeCardFilter>(
        initialValue: selectedFilter,
        tooltip: 'Filter cards',
        onSelected: (filter) {
          HapticFeedback.selectionClick();
          onFilterChanged(filter);
        },
        itemBuilder: (context) => _buildMenuItems(context),
        child: Material(
          color: isFiltered
              ? scheme.primaryContainer
              : scheme.surfaceContainerHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isFiltered
                  ? scheme.primary.withValues(alpha: 0.5)
                  : scheme.outline.withValues(alpha: 0.18),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isFiltered
                      ? Icons.filter_alt_rounded
                      : Icons.filter_list_rounded,
                  size: 15,
                  color: isFiltered
                      ? scheme.onPrimaryContainer
                      : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 5),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 110),
                  child: Text(
                    selectedFilter.shortLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isFiltered ? FontWeight.w700 : FontWeight.w600,
                      color: isFiltered
                          ? scheme.onPrimaryContainer
                          : scheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.arrow_drop_down_rounded,
                  size: 18,
                  color: isFiltered
                      ? scheme.onPrimaryContainer
                      : scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<PopupMenuEntry<HomeCardFilter>> _buildMenuItems(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final items = <PopupMenuEntry<HomeCardFilter>>[];

    // ── Section: CARD TYPES ──────────────────────────────────────────────────
    items.add(
      PopupMenuItem<HomeCardFilter>(
        value: const AllCardsFilter(),
        child: _FilterItemRow(
          icon: Icons.dashboard_outlined,
          title: 'All Cards',
          isSelected: selectedFilter is AllCardsFilter,
        ),
      ),
    );

    for (final type in ['Credit', 'Debit', 'Prepaid']) {
      final filter = CardTypeFilter(type);
      final isSelected = selectedFilter is CardTypeFilter &&
          (selectedFilter as CardTypeFilter).cardType.toLowerCase() ==
              type.toLowerCase();

      final icon = switch (type) {
        'Credit' => Icons.credit_card_rounded,
        'Debit' => Icons.account_balance_wallet_outlined,
        _ => Icons.payments_outlined,
      };

      items.add(
        PopupMenuItem<HomeCardFilter>(
          value: filter,
          child: _FilterItemRow(
            icon: icon,
            title: '$type Cards',
            isSelected: isSelected,
          ),
        ),
      );
    }

    // ── Section: FOLDERS ─────────────────────────────────────────────────────
    if (folders.isNotEmpty) {
      items.add(const PopupMenuDivider());
      items.add(
        PopupMenuItem<HomeCardFilter>(
          enabled: false,
          height: 28,
          child: Text(
            'FOLDERS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: scheme.secondary,
            ),
          ),
        ),
      );

      for (final folder in folders) {
        final isSelected = selectedFilter is FolderCardFilter &&
            (selectedFilter as FolderCardFilter).folder.id == folder.id;

        final gradient = FolderPalette.gradientFor(folder.colorIndex);
        final folderIcon = FolderPalette.iconFor(folder.iconKey);

        items.add(
          PopupMenuItem<HomeCardFilter>(
            value: FolderCardFilter(folder),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(folderIcon, size: 13, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    folder.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? scheme.primary : scheme.onSurface,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_rounded, size: 18, color: scheme.primary),
              ],
            ),
          ),
        );
      }
    }

    return items;
  }
}

class _FilterItemRow extends StatelessWidget {
  const _FilterItemRow({
    required this.icon,
    required this.title,
    required this.isSelected,
  });

  final IconData icon;
  final String title;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? scheme.primary : scheme.onSurface,
              fontSize: 13,
            ),
          ),
        ),
        if (isSelected)
          Icon(Icons.check_rounded, size: 18, color: scheme.primary),
      ],
    );
  }
}
