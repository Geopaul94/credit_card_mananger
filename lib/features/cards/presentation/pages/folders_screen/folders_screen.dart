import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/di/service_locator.dart';
import '../../../../../core/storage/folder_storage.dart';
import '../../../../../core/ui/responsive_layout.dart';
import '../../../domain/entities/card_folder.dart';
import '../../../domain/entities/payment_card.dart';
import '../../bloc/card_overview/card_overview_bloc.dart';
import '../../bloc/card_overview/card_overview_state.dart';
import 'widgets/create_folder_sheet.dart';
import 'widgets/empty_folders_view.dart';
import 'widgets/folder_detail_sheet.dart';
import 'widgets/folder_grid_card.dart';

class FoldersScreen extends StatefulWidget {
  const FoldersScreen({super.key});

  @override
  State<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<CardFolder> _folders = <CardFolder>[];
  bool _isLoading = true;
  String _query = '';
  int _filterIndex = 0; // 0: All, 1: With Cards, 2: Empty

  @override
  void initState() {
    super.initState();
    _loadPersistedFolders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPersistedFolders() async {
    final loaded = await sl<FolderStorage>().loadFolders();
    if (!mounted) return;
    setState(() {
      _folders.clear();
      _folders.addAll(loaded);
      _isLoading = false;
    });
  }

  Future<void> _persistFolders() async {
    await sl<FolderStorage>().saveFolders(_folders);
  }

  List<PaymentCard> _cardsForFolder(
    CardFolder folder,
    List<PaymentCard> allCards,
  ) {
    final byId = {for (final card in allCards) card.id: card};
    return folder.cardIds
        .map((id) => byId[id])
        .whereType<PaymentCard>()
        .toList();
  }

  bool _cardMatchesQuery(PaymentCard card, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    final haystack = [
      card.displayTitle,
      card.holderName,
      card.bankName ?? '',
      card.cardName ?? '',
      card.typeLabel,
      card.formattedNumber,
    ].join(' ').toLowerCase();
    return haystack.contains(q);
  }

  List<CardFolder> _filteredFolders(List<PaymentCard> allCards) {
    final q = _query.trim().toLowerCase();
    return _folders.where((folder) {
      final cards = _cardsForFolder(folder, allCards);

      // Filter category check
      if (_filterIndex == 1 && cards.isEmpty) return false;
      if (_filterIndex == 2 && cards.isNotEmpty) return false;

      // Search query check
      if (q.isEmpty) return true;
      if (folder.name.toLowerCase().contains(q)) return true;
      return cards.any((card) => _cardMatchesQuery(card, q));
    }).toList();
  }

  void _openCreateFolder([CardFolder? folderToEdit]) {
    final allCards = context.read<CardOverviewBloc>().state.cards;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => CreateFolderSheet(
        initialFolder: folderToEdit,
        allCards: allCards,
        onSave: (savedFolder) {
          setState(() {
            if (folderToEdit != null) {
              final idx = _folders.indexWhere((f) => f.id == savedFolder.id);
              if (idx != -1) {
                _folders[idx] = savedFolder;
              }
            } else {
              _folders.insert(0, savedFolder);
            }
          });
          _persistFolders();
        },
      ),
    );
  }

  void _openFolderDetail(CardFolder folder, List<PaymentCard> allCards) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => FolderDetailSheet(
        folder: folder,
        allCards: allCards,
        onFolderUpdated: (updated) {
          setState(() {
            final idx = _folders.indexWhere((f) => f.id == updated.id);
            if (idx != -1) {
              _folders[idx] = updated;
            }
          });
          _persistFolders();
        },
        onDeleteFolder: () {
          _confirmDeleteFolder(folder);
        },
        onEditFolder: () {
          _openCreateFolder(folder);
        },
      ),
    );
  }

  Future<void> _confirmDeleteFolder(CardFolder folder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete folder?'),
        content: Text(
          'Delete "${folder.name}"? The cards inside this folder will not be removed from your vault.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      HapticFeedback.mediumImpact();
      setState(() {
        _folders.removeWhere((f) => f.id == folder.id);
      });
      _persistFolders();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<CardOverviewBloc, CardOverviewState>(
          builder: (context, state) {
            final allCards = state.cards;
            final visibleFolders = _filteredFolders(allCards);

            if (_isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return ResponsiveContent(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Bar
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Folders',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              Text(
                                '${_folders.length} ${_folders.length == 1 ? 'folder' : 'folders'} · organize cards',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: scheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: () => _openCreateFolder(),
                          icon: const Icon(Icons.create_new_folder_outlined, size: 18),
                          label: const Text('New Folder'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Search input
                    TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _query = value),
                      decoration: InputDecoration(
                        hintText: 'Search folders or cards',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _query = '');
                                },
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Filter chips
                    if (_folders.isNotEmpty)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ChoiceChip(
                              label: const Text('All Folders'),
                              selected: _filterIndex == 0,
                              onSelected: (_) => setState(() => _filterIndex = 0),
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('With Cards'),
                              selected: _filterIndex == 1,
                              onSelected: (_) => setState(() => _filterIndex = 1),
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('Empty'),
                              selected: _filterIndex == 2,
                              onSelected: (_) => setState(() => _filterIndex = 2),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),

                    // Content View
                    if (_folders.isEmpty)
                      Expanded(
                        child: EmptyFoldersView(
                          onCreateFolder: () => _openCreateFolder(),
                          onQuickTemplate: (template) {
                            setState(() => _folders.insert(0, template));
                            _persistFolders();
                          },
                        ),
                      )
                    else if (visibleFolders.isEmpty)
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 48,
                                color: scheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No matching folders found',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _query = '';
                                    _filterIndex = 0;
                                  });
                                },
                                child: const Text('Reset filters'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth > 580;
                            return GridView.builder(
                              padding: const EdgeInsets.only(bottom: 96, top: 4),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: isWide ? 2 : 1,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                                childAspectRatio: isWide ? 1.05 : 1.42,
                              ),
                              itemCount: visibleFolders.length,
                              itemBuilder: (context, index) {
                                final folder = visibleFolders[index];
                                final folderCards =
                                    _cardsForFolder(folder, allCards);

                                return FolderGridCard(
                                  folder: folder,
                                  cards: folderCards,
                                  onTap: () =>
                                      _openFolderDetail(folder, allCards),
                                  onEdit: () => _openCreateFolder(folder),
                                  onDelete: () => _confirmDeleteFolder(folder),
                                );
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
