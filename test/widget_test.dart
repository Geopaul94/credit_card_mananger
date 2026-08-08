// Widget smoke tests for pieces that render without any real services.
// (The full app boots DI, biometrics, and notifications, which don't exist
// in the test environment — screens are covered at the widget level instead.)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:credit_cards/core/theme/app_theme.dart';
import 'package:credit_cards/features/cards/domain/entities/payment_card.dart';
import 'package:credit_cards/features/cards/presentation/widgets/card_skeleton.dart';
import 'package:credit_cards/features/cards/presentation/widgets/card_tile.dart';
import 'package:credit_cards/features/cards/presentation/widgets/empty_card_view.dart';

Widget _app(Widget child) => MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('empty state offers a way to add the first card', (tester) async {
    await tester.pumpWidget(_app(const EmptyCardView()));

    expect(find.text('Your vault is empty'), findsOneWidget);
    // The screen must never be a dead end — the CTA has to be there.
    expect(find.text('Add your first card'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
  });

  testWidgets('empty state hides the restore prompt when there is no handler',
      (tester) async {
    await tester.pumpWidget(_app(const EmptyCardView()));

    expect(find.text('Used Card Vault before?'), findsNothing);
  });

  testWidgets('empty state invites a returning user to connect Google',
      (tester) async {
    var tapped = false;
    await tester.pumpWidget(_app(EmptyCardView(onRestore: () => tapped = true)));

    expect(find.text('Used Card Vault before?'), findsOneWidget);
    expect(find.text('Connect Google account'), findsOneWidget);

    await tester.tap(find.text('Connect Google account'));
    expect(tapped, isTrue);
  });

  testWidgets('empty state offers a direct restore once an account is connected',
      (tester) async {
    await tester.pumpWidget(_app(EmptyCardView(
      onRestore: () {},
      connectedEmail: 'geopaul94@gmail.com',
    )));

    // Nothing left to "connect" — the ask becomes the restore itself.
    expect(find.text('Restore my cards'), findsOneWidget);
    expect(find.text('Connect Google account'), findsNothing);
    expect(find.textContaining('geopaul94@gmail.com'), findsOneWidget);
  });

  testWidgets('card face shows title, masked number, and holder',
      (tester) async {
    const card = PaymentCard(
      id: '1',
      holderName: 'Geo Paulson',
      cardNumber: '4532123456789012',
      expiryDate: '12/29',
      typeLabel: 'Credit',
      bankName: 'HDFC Bank',
      cardName: 'Millennia',
    );

    await tester.pumpWidget(_app(
      const CardFrontFace(
        card: card,
        gradientColors: [Color(0xFF004C8F), Color(0xFF002B5C)],
      ),
    ));

    expect(find.text('HDFC Bank - Millennia'), findsOneWidget);
    // Only the last four digits may ever appear on the face.
    expect(find.text('**** **** **** 9012'), findsOneWidget);
    expect(find.textContaining('4532'), findsNothing);
    expect(find.text('GEO PAULSON'), findsOneWidget);
  });

  testWidgets('paid badge replaces the type badge once a bill is paid',
      (tester) async {
    // Bank name set so the card's title doesn't fall back to the type label,
    // which would make 'Credit' legitimately present as the title.
    const card = PaymentCard(
      id: '1',
      holderName: 'Geo Paulson',
      cardNumber: '4532123456789012',
      expiryDate: '12/29',
      typeLabel: 'Credit',
      bankName: 'Axis Bank',
    );

    await tester.pumpWidget(_app(
      const CardFrontFace(
        card: card,
        gradientColors: [Color(0xFF1D4ED8), Color(0xFF4F46E5)],
        isPaid: true,
      ),
    ));

    expect(find.text('Paid ✓'), findsOneWidget);
    expect(find.text('Credit'), findsNothing);
  });

  testWidgets('loading skeleton renders and animates without errors',
      (tester) async {
    await tester.pumpWidget(_app(const CardListSkeleton()));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(CardListSkeleton), findsOneWidget);
  });
}
