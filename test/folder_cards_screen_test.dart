import 'package:credit_cards/core/theme/app_theme.dart';
import 'package:credit_cards/features/cards/domain/entities/card_folder.dart';
import 'package:credit_cards/features/cards/domain/entities/payment_card.dart';
import 'package:credit_cards/features/cards/presentation/bloc/card_overview/card_overview_bloc.dart';
import 'package:credit_cards/features/cards/presentation/bloc/card_overview/card_overview_state.dart';
import 'package:credit_cards/features/cards/presentation/pages/folders_screen/folder_cards_screen.dart';
import 'package:credit_cards/features/cards/presentation/widgets/card_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeCardOverviewBloc extends Cubit<CardOverviewState>
    implements CardOverviewBloc {
  _FakeCardOverviewBloc(super.initialState);

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
    cardName: 'Sapphiro',
    typeLabel: 'Credit',
  );

  testWidgets('FolderCardsScreen renders cards in folder using CardTile',
      (tester) async {
    final bloc = _FakeCardOverviewBloc(
      const CardOverviewState(
        cards: [card1, card2],
        isLoading: false,
      ),
    );

    final folder = CardFolder(
      id: 'f1',
      name: 'Travel Cards',
      colorIndex: 1,
      iconKey: 'flight',
      cardIds: const ['c1'],
      createdAt: DateTime(2025, 1, 1),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: BlocProvider<CardOverviewBloc>.value(
          value: bloc,
          child: FolderCardsScreen(
            folder: folder,
            onFolderUpdated: (_) {},
            onFolderDeleted: () {},
          ),
        ),
      ),
    );

    // Header checks
    expect(find.text('Travel Cards'), findsOneWidget);
    expect(find.text('1 card organized'), findsOneWidget);

    // Should find CardTile for card1 but not for card2
    expect(find.byType(CardTile), findsOneWidget);
    expect(find.textContaining('Infinia'), findsOneWidget);
    expect(find.textContaining('Sapphiro'), findsNothing);
  });

  testWidgets('FolderCardsScreen displays empty state when folder has no cards',
      (tester) async {
    final bloc = _FakeCardOverviewBloc(
      const CardOverviewState(
        cards: [card1, card2],
        isLoading: false,
      ),
    );

    final emptyFolder = CardFolder(
      id: 'f2',
      name: 'Empty Folder',
      colorIndex: 0,
      iconKey: 'folder',
      cardIds: const [],
      createdAt: DateTime(2025, 1, 1),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: BlocProvider<CardOverviewBloc>.value(
          value: bloc,
          child: FolderCardsScreen(
            folder: emptyFolder,
            onFolderUpdated: (_) {},
            onFolderDeleted: () {},
          ),
        ),
      ),
    );

    expect(find.text('No cards in this folder yet'), findsOneWidget);
    expect(find.text('Add Cards to Folder'), findsOneWidget);
    expect(find.byType(CardTile), findsNothing);
  });
}
