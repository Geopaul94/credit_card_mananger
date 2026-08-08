// The edit screen exists so a typo no longer costs the whole card. These
// tests pin the guarantee that matters: editing identity fields must not
// disturb anything else attached to the card.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:credit_cards/core/theme/app_theme.dart';
import 'package:credit_cards/features/cards/domain/entities/payment_card.dart';
import 'package:credit_cards/features/cards/presentation/widgets/due_date_calendar.dart';

const _card = PaymentCard(
  id: '1754200000000',
  holderName: 'Geo Paulson',
  cardNumber: '4532123456789012',
  expiryDate: '06/29',
  typeLabel: 'Credit',
  cvv: '123',
  bankName: 'Yes Bank',
  cardName: 'Uni',
  dueDay: 15,
  notes: 'Login: geo@example.com',
);

/// The picker always lives inside a scrolling form in the app, so the test
/// surface gives it the same freedom rather than a fixed 800x600 box.
Widget _app(Widget child) => MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  group('editing a card', () {
    test('correcting the number keeps everything else intact', () {
      // The whole point: before this screen existed, fixing one digit meant
      // deleting the card and losing all of the below.
      final fixed = _card.copyWith(cardNumber: '4532123456789013');

      expect(fixed.cardNumber, '4532123456789013');
      expect(fixed.id, _card.id, reason: 'identity must survive an edit');
      expect(fixed.dueDay, 15);
      expect(fixed.notes, 'Login: geo@example.com');
      expect(fixed.cvv, '123');
      expect(fixed.bankName, 'Yes Bank');
    });

    test('clearing the bank name actually clears it', () {
      // copyWith(bankName: null) alone would keep the old value, so the screen
      // pairs it with clearBankName.
      final cleared = _card.copyWith(clearBankName: true);
      expect(cleared.bankName, isNull);
      expect(cleared.cardName, 'Uni', reason: 'only the bank was cleared');
    });

    test('changing the number changes the visible last four', () {
      expect(_card.copyWith(cardNumber: '4532123456785555').formattedNumber,
          endsWith('5555'));
    });
  });

  group('DueDayPicker', () {
    testWidgets('offers every day 1-31 regardless of the month', (tester) async {
      await tester.pumpWidget(_app(
        DueDayPicker(selectedDay: 15, onSelectDay: (_) {}, onNoReminder: () {}),
      ));

      // A month grid would hide 29-31 in February and 31 in April. A due day
      // repeats monthly, so all of them must always be reachable.
      expect(find.text('1'), findsOneWidget);
      expect(find.text('29'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);
      expect(find.text('31'), findsOneWidget);
    });

    testWidgets('states the chosen day in words', (tester) async {
      await tester.pumpWidget(_app(
        DueDayPicker(selectedDay: 3, onSelectDay: (_) {}, onNoReminder: () {}),
      ));
      expect(find.text('Due on the 3rd of every month'), findsOneWidget);
    });

    testWidgets('warns only when the day cannot exist in every month',
        (tester) async {
      await tester.pumpWidget(_app(
        DueDayPicker(selectedDay: 15, onSelectDay: (_) {}, onNoReminder: () {}),
      ));
      expect(find.textContaining('shorter months'), findsNothing);

      await tester.pumpWidget(_app(
        DueDayPicker(selectedDay: 31, onSelectDay: (_) {}, onNoReminder: () {}),
      ));
      expect(find.textContaining('shorter months'), findsOneWidget);
    });

    testWidgets('reports the tapped day', (tester) async {
      int? picked;
      await tester.pumpWidget(_app(
        DueDayPicker(
          selectedDay: null,
          onSelectDay: (d) => picked = d,
          onNoReminder: () {},
        ),
      ));

      await tester.tap(find.text('28'));
      expect(picked, 28);
    });

    testWidgets('offers turning reminders off', (tester) async {
      var cleared = false;
      await tester.pumpWidget(_app(
        DueDayPicker(
          selectedDay: 10,
          onSelectDay: (_) {},
          onNoReminder: () => cleared = true,
        ),
      ));

      // Sits below the grid, so bring it on screen before tapping.
      await tester.ensureVisible(find.text('No reminder'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('No reminder'));
      expect(cleared, isTrue);
    });
  });
}
