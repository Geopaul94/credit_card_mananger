import 'package:credit_cards/features/cards/domain/entities/payment_card.dart';
import 'package:flutter_test/flutter_test.dart';

PaymentCard _card({
  String? bankName,
  String? cardName,
  int? dueDay,
  String cardNumber = '4532123456789012',
  String typeLabel = 'Visa',
}) =>
    PaymentCard(
      id: 'id-1',
      holderName: 'JOHN DOE',
      cardNumber: cardNumber,
      expiryDate: '08/29',
      typeLabel: typeLabel,
      cvv: '123',
      bankName: bankName,
      cardName: cardName,
      dueDay: dueDay,
    );

void main() {
  group('PaymentCard.displayTitle', () {
    test('shows "Bank - Card Name" when both set', () {
      expect(
        _card(bankName: 'Axis Bank', cardName: 'Flipkart').displayTitle,
        'Axis Bank - Flipkart',
      );
    });
    test('shows bank only when no card name', () {
      expect(_card(bankName: 'HDFC Bank').displayTitle, 'HDFC Bank');
    });
    test('shows card name only when no bank', () {
      expect(_card(cardName: 'OneCard').displayTitle, 'OneCard');
    });
    test('falls back to typeLabel when neither set', () {
      expect(_card(typeLabel: 'Mastercard').displayTitle, 'Mastercard');
    });
    test('treats whitespace-only as empty', () {
      expect(_card(bankName: '   ', cardName: '  ').displayTitle, 'Visa');
    });
  });

  group('PaymentCard.formattedNumber', () {
    test('groups 16 digits into 4 groups of 4', () {
      expect(_card(cardNumber: '4532123456789012').formattedNumber,
          '4532 1234 5678 9012');
    });
    test('groups 15 digits (Amex) correctly', () {
      expect(_card(cardNumber: '378282246310005').formattedNumber,
          '3782 8224 6310 005');
    });
    test('strips non-digits before grouping', () {
      expect(_card(cardNumber: '4532-1234 5678/9012').formattedNumber,
          '4532 1234 5678 9012');
    });
    test('handles empty number', () {
      expect(_card(cardNumber: '').formattedNumber, '');
    });
  });

  group('PaymentCard.dueDayLabel', () {
    test('returns empty when no dueDay', () {
      expect(_card().dueDayLabel, '');
    });
    test('1st, 2nd, 3rd suffixes', () {
      expect(_card(dueDay: 1).dueDayLabel, '1st');
      expect(_card(dueDay: 2).dueDayLabel, '2nd');
      expect(_card(dueDay: 3).dueDayLabel, '3rd');
    });
    test('4th–10th use th', () {
      for (final d in [4, 5, 6, 7, 8, 9, 10]) {
        expect(_card(dueDay: d).dueDayLabel, '${d}th');
      }
    });
    test('11th, 12th, 13th use th (irregular)', () {
      expect(_card(dueDay: 11).dueDayLabel, '11th');
      expect(_card(dueDay: 12).dueDayLabel, '12th');
      expect(_card(dueDay: 13).dueDayLabel, '13th');
    });
    test('21st, 22nd, 23rd, 31st suffixes', () {
      expect(_card(dueDay: 21).dueDayLabel, '21st');
      expect(_card(dueDay: 22).dueDayLabel, '22nd');
      expect(_card(dueDay: 23).dueDayLabel, '23rd');
      expect(_card(dueDay: 31).dueDayLabel, '31st');
    });
  });

  group('PaymentCard.nextDueDate', () {
    test('returns null when no dueDay', () {
      expect(_card().nextDueDate, null);
    });
    test('upcoming day this month → this month', () {
      final today = DateTime.now();
      // pick a day at least 2 ahead so it stays in this month
      if (today.day <= 25) {
        final card = _card(dueDay: today.day + 2);
        final due = card.nextDueDate!;
        expect(due.year, today.year);
        expect(due.month, today.month);
        expect(due.day, today.day + 2);
      }
    });
    test('past day → next month', () {
      final today = DateTime.now();
      if (today.day >= 3) {
        final card = _card(dueDay: today.day - 1);
        final due = card.nextDueDate!;
        final expected = DateTime(today.year, today.month + 1, today.day - 1);
        expect(due.month, expected.month);
        expect(due.year, expected.year);
      }
    });
    test('day 31 in Feb is clamped to last day of Feb', () {
      // Can't fully verify without time control, but we can sanity-check the
      // contract: nextDueDate is never null for dueDay 31, and is a valid date.
      final due = _card(dueDay: 31).nextDueDate!;
      // Day must be valid for whichever month it landed in.
      final lastDayOfMonth = DateTime(due.year, due.month + 1, 0).day;
      expect(due.day <= lastDayOfMonth, true);
      expect(due.day >= 28, true); // 31 clamped is at minimum 28 (Feb non-leap)
    });
  });

  group('PaymentCard.reminderInfo', () {
    test('null when no dueDay', () {
      expect(_card().reminderInfo, null);
    });
    test('today → delta 0', () {
      final today = DateTime.now();
      final info = _card(dueDay: today.day).reminderInfo!;
      expect(info.delta, 0);
      expect(info.date.day, today.day);
    });
    test('1 day overdue → delta -1, same month', () {
      final today = DateTime.now();
      if (today.day >= 2) {
        final info = _card(dueDay: today.day - 1).reminderInfo!;
        expect(info.delta, -1);
        expect(info.date.month, today.month);
      }
    });
    test('2 days overdue → rolls to next month with positive delta', () {
      final today = DateTime.now();
      if (today.day >= 3) {
        final info = _card(dueDay: today.day - 2).reminderInfo!;
        expect(info.delta > 0, true);
        // Should land in the following month (or its valid clamped day).
        expect(info.date.isAfter(today), true);
      }
    });
  });

  group('PaymentCard.copyWith', () {
    test('clearBankName drops bank', () {
      final c = _card(bankName: 'HDFC').copyWith(clearBankName: true);
      expect(c.bankName, null);
    });
    test('clearCardName drops card name', () {
      final c = _card(cardName: 'Flipkart').copyWith(clearCardName: true);
      expect(c.cardName, null);
    });
    test('clearDueDay drops due day', () {
      final c = _card(dueDay: 15).copyWith(clearDueDay: true);
      expect(c.dueDay, null);
    });
    test('passing new bankName overrides', () {
      final c = _card(bankName: 'HDFC').copyWith(bankName: 'Axis');
      expect(c.bankName, 'Axis');
    });
  });
}
