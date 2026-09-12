import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../domain/entities/card_folder.dart';

/// Empty state for Folders screen with one-tap starter templates.
class EmptyFoldersView extends StatelessWidget {
  const EmptyFoldersView({
    required this.onCreateFolder,
    required this.onQuickTemplate,
    super.key,
  });

  final VoidCallback onCreateFolder;
  final ValueChanged<CardFolder> onQuickTemplate;

  static final List<CardFolder> _starterTemplates = [
    CardFolder(
      id: 'template_travel',
      name: 'Travel Cards',
      iconKey: 'flight',
      colorIndex: 2, // Sapphire
      createdAt: DateTime.now(),
    ),
    CardFolder(
      id: 'template_shopping',
      name: 'Shopping & Offers',
      iconKey: 'shopping',
      colorIndex: 3, // Sunset Amber
      createdAt: DateTime.now(),
    ),
    CardFolder(
      id: 'template_business',
      name: 'Work & Expenses',
      iconKey: 'work',
      colorIndex: 1, // Emerald
      createdAt: DateTime.now(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon container
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    scheme.primary.withValues(alpha: 0.18),
                    scheme.secondary.withValues(alpha: 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: scheme.primary.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.folder_copy_rounded,
                size: 40,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Organize with Folders',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                'Group your cards into custom folders for travel, online shopping, bills, or business expenses.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.45,
                    ),
              ),
            ),
            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                onCreateFolder();
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create Custom Folder'),
            ),
            const SizedBox(height: 32),

            // Quick starter suggestion pills
            Text(
              'OR START WITH A POPULAR TEMPLATE',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _starterTemplates.map((template) {
                return ActionChip(
                  avatar: const Icon(Icons.add_circle_outline_rounded, size: 16),
                  label: Text(template.name),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onQuickTemplate(template.copyWith(
                      id: DateTime.now().microsecondsSinceEpoch.toString(),
                      createdAt: DateTime.now(),
                    ));
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
