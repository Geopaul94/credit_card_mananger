// Tests for PaymentCard's expiry reasoning. Dates are built relative to "now"
// so these keep passing as real time moves on.

import 'package:flutter_test/flutter_test.dart';

import 'package:credit_cards/features/cards/domain/entities/payment_card.dart';

PaymentCard _cardExpiring(String mmYy) => PaymentCard(
      id: '1',
      holderName: 'Geo Paulson',
      cardNumber: '4532123456789012',
      expiryDate: mmYy,
      typeLabel: 'Credit',
    );

/// Formats a date as the MM/YY a card would carry.
String _mmYy(DateTime d) =>
    '${d.month.toString().padLeft(2, '0')}/${(d.year % 100).toString().padLeft(2, '0')}';

void main() {
  final now = DateTime.now();

  group('expiresAt', () {
    test('runs to the last moment of the printed month', () {
      final end = _cardExpiring('08/28').expiresAt!;
      expect(end.year, 2028);
      expect(end.month, 8);
      expect(end.day, 31); // August has 31 days
    });

    test('handles February and short months', () {
      expect(_cardExpiring('02/27').expiresAt!.day, 28);
      expect(_cardExpiring('04/27').expiresAt!.day, 30);
    });

    test('December rolls the year correctly rather than into month 13', () {
      final end = _cardExpiring('12/29').expiresAt!;
      expect(end.year, 2029);
      expect(end.month, 12);
      expect(end.day, 31);
    });

    test('is null for a malformed or impossible date', () {
      expect(_cardExpiring('').expiresAt, isNull);
      expect(_cardExpiring('8/28').expiresAt, isNull);
      expect(_cardExpiring('13/28').expiresAt, isNull);
      expect(_cardExpiring('00/28').expiresAt, isNull);
    });
  });

  group('isExpired', () {
    test('a month that has fully passed is expired', () {
      final lastMonth = DateTime(now.year, now.month - 1, 1);
      expect(_cardExpiring(_mmYy(lastMonth)).isExpired, isTrue);
    });

    test('the current month is not expired — a card is valid all month', () {
      expect(_cardExpiring(_mmYy(now)).isExpired, isFalse);
    });

    test('a future month is not expired', () {
      final nextYear = DateTime(now.year + 1, now.month, 1);
      expect(_cardExpiring(_mmYy(nextYear)).isExpired, isFalse);
    });

    test('an unparseable date is never reported as expired', () {
      expect(_cardExpiring('nonsense').isExpired, isFalse);
    });
  });

  group('isExpiringSoon', () {
    test('the current month counts as expiring soon', () {
      expect(_cardExpiring(_mmYy(now)).isExpiringSoon(), isTrue);
    });

    test('a year out is not expiring soon', () {
      final nextYear = DateTime(now.year + 1, now.month, 1);
      expect(_cardExpiring(_mmYy(nextYear)).isExpiringSoon(), isFalse);
    });

    test('an already-expired card is not "expiring soon"', () {
      final lastMonth = DateTime(now.year, now.month - 1, 1);
      final card = _cardExpiring(_mmYy(lastMonth));
      expect(card.isExpired, isTrue);
      expect(card.isExpiringSoon(), isFalse);
    });

    test('the window is configurable', () {
      final inThreeMonths = DateTime(now.year, now.month + 3, 1);
      final card = _cardExpiring(_mmYy(inThreeMonths));
      expect(card.isExpiringSoon(), isFalse); // 60-day default
      expect(card.isExpiringSoon(withinDays: 150), isTrue);
    });
  });
}
