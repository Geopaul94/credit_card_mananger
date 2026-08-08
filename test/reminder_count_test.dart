// Tests for the "needs attention now" rule that drives both the reminders
// tab badge and the screen's DUE NOW group. Due days are derived from today,
// so these stay correct as real time moves on (including across month ends —
// a due day that has already passed this month rolls to next month).

import 'package:flutter_test/flutter_test.dart';

import 'package:credit_cards/features/cards/domain/entities/payment_card.dart';
import 'package:credit_cards/features/cards/presentation/bloc/card_overview/card_overview_state.dart';

/// A card whose due date lands [daysAway] days from today.
PaymentCard _dueIn(int daysAway, {String id = '1'}) {
  final target = DateTime.now().add(Duration(days: daysAway));
  return PaymentCard(
    id: id,
    holderName: 'Geo Paulson',
    cardNumber: '4532123456789012',
    expiryDate: '12/29',
    typeLabel: 'Credit',
    bankName: 'HDFC Bank',
    dueDay: target.day,
  );
}

PaymentCard _noDueDay({String id = '1'}) => PaymentCard(
      id: id,
      holderName: 'Geo Paulson',
      cardNumber: '4532123456789012',
      expiryDate: '12/29',
      typeLabel: 'Credit',
      bankName: 'Axis Bank',
    );

void main() {
  group('needsActionNow', () {
    test('a bill due today needs action', () {
      final card = _dueIn(0);
      final state = CardOverviewState(cards: [card]);
      expect(state.needsActionNow(card), isTrue);
    });

    test('a bill due inside the 3-day window needs action', () {
      final card = _dueIn(2);
      final state = CardOverviewState(cards: [card]);
      expect(state.needsActionNow(card), isTrue);
    });

    test('a bill further out does not', () {
      final card = _dueIn(10);
      final state = CardOverviewState(cards: [card]);
      expect(state.needsActionNow(card), isFalse);
    });

    test('a card already marked paid does not, even when due today', () {
      final card = _dueIn(0);
      final state = CardOverviewState(cards: [card], paidCardIds: {card.id});
      expect(state.needsActionNow(card), isFalse);
    });

    test('a card with no due day never does', () {
      final card = _noDueDay();
      final state = CardOverviewState(cards: [card]);
      expect(state.needsActionNow(card), isFalse);
    });
  });

  group('actionNeededCount', () {
    test('is zero with no cards', () {
      expect(const CardOverviewState().actionNeededCount, 0);
    });

    test('counts only the cards inside the window', () {
      final state = CardOverviewState(
        cards: [
          _dueIn(0, id: 'a'), // due today      → counts
          _dueIn(3, id: 'b'), // edge of window → counts
          _dueIn(12, id: 'c'), // far off        → no
          _noDueDay(id: 'd'), // no reminder    → no
        ],
      );
      expect(state.actionNeededCount, 2);
    });

    test('drops back as bills are marked paid', () {
      final cards = [_dueIn(0, id: 'a'), _dueIn(1, id: 'b')];
      expect(CardOverviewState(cards: cards).actionNeededCount, 2);
      expect(
        CardOverviewState(cards: cards, paidCardIds: const {'a'})
            .actionNeededCount,
        1,
      );
      expect(
        CardOverviewState(cards: cards, paidCardIds: const {'a', 'b'})
            .actionNeededCount,
        0,
      );
    });
  });
}
