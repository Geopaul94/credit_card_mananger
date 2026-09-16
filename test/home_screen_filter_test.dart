import 'package:credit_cards/core/backup/backup_cubit.dart';
import 'package:credit_cards/core/di/service_locator.dart';
import 'package:credit_cards/core/storage/folder_storage.dart';
import 'package:credit_cards/core/theme/app_theme.dart';
import 'package:credit_cards/features/cards/domain/entities/card_folder.dart';
import 'package:credit_cards/features/cards/domain/entities/payment_card.dart';
import 'package:credit_cards/features/cards/presentation/bloc/card_overview/card_overview_bloc.dart';
import 'package:credit_cards/features/cards/presentation/bloc/card_overview/card_overview_event.dart';
import 'package:credit_cards/features/cards/presentation/bloc/card_overview/card_overview_state.dart';
import 'package:credit_cards/features/cards/presentation/pages/home_screen/home_screen.dart';
import 'package:credit_cards/features/cards/presentation/pages/home_screen/models/home_card_filter.dart';
import 'package:credit_cards/features/cards/presentation/pages/home_screen/widgets/card_filter_dropdown.dart';
import 'package:credit_cards/features/cards/presentation/widgets/card_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeCardOverviewBloc extends Cubit<CardOverviewState>
    implements CardOverviewBloc {
  _FakeCardOverviewBloc(super.initialState);

  @override
  void add(CardOverviewEvent event) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeBackupCubit extends Cubit<BackupState> implements BackupCubit {
  _FakeBackupCubit() : super(const BackupState());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFolderStorage implements FolderStorage {
  _FakeFolderStorage(this.folders);
  final List<CardFolder> folders;

  @override
  Future<List<CardFolder>> loadFolders() async => folders;

  @override
  Future<void> saveFolders(List<CardFolder> f) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const card1 = PaymentCard(
    id: 'c1',
    cardNumber: '4532750012345678',
    holderName: 'GEO PAULSON',
    expiryDate: '12/28',
    bankName: 'HDFC Bank',
    cardName: 'Infinia',
    typeLabel: 'Credit',
  );

  const card2 = PaymentCard(
    id: 'c2',
    cardNumber: '5123450087654321',
    holderName: 'GEO PAULSON',
    expiryDate: '06/29',
    bankName: 'ICICI Bank',
    cardName: 'Salary Debit',
    typeLabel: 'Debit',
  );

  const card3 = PaymentCard(
    id: 'c3',
    cardNumber: '6071230011223344',
    holderName: 'GEO PAULSON',
    expiryDate: '08/30',
    bankName: 'Axis Bank',
    cardName: 'Forex Prepaid',
    typeLabel: 'Prepaid',
  );

  final testFolder = CardFolder(
    id: 'f1',
    name: 'Work Expenses',
    iconKey: 'work',
    colorIndex: 2,
    cardIds: const ['c1'],
    createdAt: DateTime(2025, 1, 1),
  );

  final emptyFolder = CardFolder(
    id: 'f2',
    name: 'Empty Folder',
    iconKey: 'folder',
    colorIndex: 1,
    cardIds: const [],
    createdAt: DateTime(2025, 1, 1),
  );

  setUp(() async {
    await sl.reset();
    sl.registerLazySingleton<FolderStorage>(
      () => _FakeFolderStorage([testFolder, emptyFolder]),
    );
  });

  tearDown(() async {
    await sl.reset();
  });

  group('HomeCardFilter logic', () {
    test('AllCardsFilter returns all cards', () {
      const filter = AllCardsFilter();
      final res = filter.apply([card1, card2, card3]);
      expect(res.length, 3);
    });

    test('CardTypeFilter filters correctly by type', () {
      const creditFilter = CardTypeFilter('Credit');
      expect(creditFilter.apply([card1, card2, card3]), [card1]);

      const debitFilter = CardTypeFilter('Debit');
      expect(debitFilter.apply([card1, card2, card3]), [card2]);

      const prepaidFilter = CardTypeFilter('Prepaid');
      expect(prepaidFilter.apply([card1, card2, card3]), [card3]);
    });

    test('FolderCardFilter filters cards by folder cardIds', () {
      final filter = FolderCardFilter(testFolder);
      final res = filter.apply([card1, card2, card3]);
      expect(res, [card1]);
    });
  });

  group('HomeScreen Filter Dropdown Widget Tests', () {
    testWidgets('Renders all cards by default and filters by Card Type',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final bloc = _FakeCardOverviewBloc(
        const CardOverviewState(
          cards: [card1, card2, card3],
          isLoading: false,
        ),
      );
      final backupCubit = _FakeBackupCubit();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MultiBlocProvider(
            providers: [
              BlocProvider<CardOverviewBloc>.value(value: bloc),
              BlocProvider<BackupCubit>.value(value: backupCubit),
            ],
            child: const HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // All 3 cards should be present initially
      expect(find.byType(CardTile), findsNWidgets(3));
      expect(find.text('ALL CARDS'), findsOneWidget);
      expect(find.byType(CardFilterDropdown), findsOneWidget);

      // Open the filter dropdown
      await tester.tap(find.byType(CardFilterDropdown));
      await tester.pumpAndSettle();

      // Tap "Debit Cards"
      await tester.tap(find.text('Debit Cards'));
      await tester.pumpAndSettle();

      // Now only Debit card (Salary Debit) should be visible
      expect(find.byType(CardTile), findsOneWidget);
      expect(find.textContaining('Salary Debit'), findsOneWidget);
      expect(find.textContaining('Infinia'), findsNothing);
      expect(find.text('DEBIT CARDS'), findsOneWidget);
    });

    testWidgets('Filters by Folder from dropdown', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final bloc = _FakeCardOverviewBloc(
        const CardOverviewState(
          cards: [card1, card2, card3],
          isLoading: false,
        ),
      );
      final backupCubit = _FakeBackupCubit();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MultiBlocProvider(
            providers: [
              BlocProvider<CardOverviewBloc>.value(value: bloc),
              BlocProvider<BackupCubit>.value(value: backupCubit),
            ],
            child: const HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open filter dropdown
      await tester.tap(find.byType(CardFilterDropdown));
      await tester.pumpAndSettle();

      // Tap folder "Work Expenses"
      expect(find.text('FOLDERS'), findsOneWidget);
      await tester.tap(find.text('Work Expenses'));
      await tester.pumpAndSettle();

      // Only Infinia (c1 in folder) should be visible
      expect(find.byType(CardTile), findsOneWidget);
      expect(find.textContaining('Infinia'), findsOneWidget);
      expect(find.text('WORK EXPENSES'), findsOneWidget);
    });

    testWidgets(
        'Empty filter preserves header and allows resetting back to all cards',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Only 1 credit card, no prepaid or debit
      final bloc = _FakeCardOverviewBloc(
        const CardOverviewState(
          cards: [card1],
          isLoading: false,
        ),
      );
      final backupCubit = _FakeBackupCubit();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MultiBlocProvider(
            providers: [
              BlocProvider<CardOverviewBloc>.value(value: bloc),
              BlocProvider<BackupCubit>.value(value: backupCubit),
            ],
            child: const HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Select Prepaid Cards (none exist in vault)
      await tester.tap(find.byType(CardFilterDropdown));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Prepaid Cards'));
      await tester.pumpAndSettle();

      // Should show empty state message
      expect(find.byType(CardTile), findsNothing);
      expect(find.text('No Prepaid Cards found'), findsOneWidget);

      // Section header and dropdown MUST still be visible
      expect(find.byType(CardFilterDropdown), findsOneWidget);
      expect(find.text('PREPAID CARDS'), findsOneWidget);

      // "Show all cards" button is available
      expect(find.text('Show all cards'), findsOneWidget);
      await tester.tap(find.text('Show all cards'));
      await tester.pumpAndSettle();

      // Back to normal homescreen with card1 visible!
      expect(find.byType(CardTile), findsOneWidget);
      expect(find.text('ALL CARDS'), findsOneWidget);
      expect(find.textContaining('Infinia'), findsOneWidget);
    });
  });
}
