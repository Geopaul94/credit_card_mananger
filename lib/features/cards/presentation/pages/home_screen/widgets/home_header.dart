import 'package:flutter/material.dart';

import '../../../../../../core/ui/responsive_layout.dart';

/// Top header on the Home Screen displaying time-based greeting, "My cards"
/// title, and search toggle button.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.searchOpen,
    required this.onToggleSearch,
  });

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
        HomeCircleIconButton(
          icon: searchOpen ? Icons.close : Icons.search,
          onTap: onToggleSearch,
        ),
      ],
    );
  }
}

class HomeCircleIconButton extends StatelessWidget {
  const HomeCircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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

class HomeSearchField extends StatelessWidget {
  const HomeSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
  });

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

class HomeNoMatches extends StatelessWidget {
  const HomeNoMatches({
    super.key,
    required this.query,
    this.filterLabel,
    this.onClearFilter,
  });

  final String query;
  final String? filterLabel;
  final VoidCallback? onClearFilter;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final String title;
    final String subtitle;
    final IconData icon;

    if (query.isNotEmpty) {
      icon = Icons.search_off_rounded;
      title = 'No cards match "$query"';
      subtitle = 'Try searching for another bank, product name, or last 4 digits.';
    } else if (filterLabel != null && filterLabel!.isNotEmpty) {
      icon = Icons.filter_list_off_rounded;
      title = 'No $filterLabel found';
      subtitle = 'You have not added any $filterLabel to your vault yet.';
    } else {
      icon = Icons.credit_card_off_rounded;
      title = 'No cards found';
      subtitle = 'No cards match your current view.';
    }

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.spacing(24),
          vertical: context.spacing(32),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: context.spacing(56),
              height: context.spacing(56),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: context.spacing(28),
                color: scheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: context.spacing(16)),
            Text(
              title,
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            SizedBox(height: context.spacing(6)),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            if (onClearFilter != null) ...[
              SizedBox(height: context.spacing(20)),
              FilledButton.tonalIcon(
                onPressed: onClearFilter,
                icon: const Icon(Icons.clear_all_rounded, size: 18),
                label: const Text('Show all cards'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
