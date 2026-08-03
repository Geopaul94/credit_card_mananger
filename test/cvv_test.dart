// Unit tests for the optional CVV feature: input validation, the OCR parser
// that reads the code off a card back, and the entity/model plumbing that
// keeps cards saved before the feature existed loading correctly.

import 'package:flutter_test/flutter_test.dart';

import 'package:credit_cards/core/utils/card_input.dart';
import 'package:credit_cards/features/cards/data/models/payment_card_model.dart';
import 'package:credit_cards/features/cards/data/services/card_scan_service.dart';
import 'package:credit_cards/features/cards/domain/entities/payment_card.dart';

/// A card with everything filled in, so each test only states what it cares
/// about. `cvv` is deliberately left null — the default for existing cards.
PaymentCard _card({String? cvv}) => PaymentCard(
      id: '1',
      holderName: 'Geo Paulson',
      cardNumber: '4532123456789012',
      expiryDate: '08/28',
      typeLabel: 'Credit',
      cvv: cvv,
    );

void main() {
  group('validateCvv', () {
    test('accepts an empty value — storing a CVV is optional', () {
      expect(validateCvv(''), isNull);
      expect(validateCvv(null), isNull);
      expect(validateCvv('   '), isNull);
    });

    test('accepts 3 digits (most networks) and 4 (Amex)', () {
      expect(validateCvv('123'), isNull);
      expect(validateCvv('1234'), isNull);
    });

    test('rejects too few digits', () {
      expect(validateCvv('12'), isNotNull);
      expect(validateCvv('1'), isNotNull);
    });

    test('rejects more than 4 digits', () {
      expect(validateCvv('12345'), isNotNull);
    });
  });

  group('CardScanService.parseCvv', () {
    test('prefers an explicitly labelled code', () {
      expect(CardScanService.parseCvv('CVV 123'), '123');
      expect(CardScanService.parseCvv('cvc2: 456'), '456');
      expect(CardScanService.parseCvv('CID 1234'), '1234');
    });

    test('reads the signature-panel pattern "last four, then code"', () {
      expect(CardScanService.parseCvv('AUTHORISED SIGNATURE\n9012 456'), '456');
    });

    test('reads a 3-digit group standing alone on its own line', () {
      expect(CardScanService.parseCvv('HDFC BANK\n789\nsomething else'), '789');
    });

    test('does not mistake an expiry or issue date for a code', () {
      expect(CardScanService.parseCvv('VALID THRU 08/28'), isNull);
      expect(CardScanService.parseCvv('MEMBER SINCE 099'), isNull);
    });

    test('does not pull digits out of a printed card number', () {
      expect(
        CardScanService.parseCvv('4532 1234 5678 9012\nHDFC BANK'),
        isNull,
      );
    });

    test('returns null when the back reads nothing usable', () {
      expect(CardScanService.parseCvv('CUSTOMER CARE 1800 202 6161'), isNull);
      expect(CardScanService.parseCvv(''), isNull);
    });

    test('a bare 4-digit group is treated as card digits, not an Amex code',
        () {
      expect(CardScanService.parseCvv('AXIS BANK\n9012'), isNull);
    });
  });

  group('PaymentCard cvv', () {
    test('defaults to null so cards saved before the feature still load', () {
      expect(_card().cvv, isNull);
      expect(_card().hasCvv, isFalse);
    });

    test('hasCvv is false for a blank string, true for a real code', () {
      expect(_card(cvv: '').hasCvv, isFalse);
      expect(_card(cvv: '  ').hasCvv, isFalse);
      expect(_card(cvv: '123').hasCvv, isTrue);
    });

    test('copyWith sets and preserves the code', () {
      final withCvv = _card().copyWith(cvv: '123');
      expect(withCvv.cvv, '123');
      // Copying for an unrelated reason must not drop it.
      expect(withCvv.copyWith(dueDay: 5).cvv, '123');
    });

    test('copyWith(clearCvv) removes it', () {
      expect(_card(cvv: '123').copyWith(clearCvv: true).cvv, isNull);
    });

    test('two cards differing only by CVV are not equal', () {
      expect(_card(cvv: '123'), isNot(equals(_card(cvv: '456'))));
      expect(_card(cvv: '123'), equals(_card(cvv: '123')));
    });
  });

  group('PaymentCardModel', () {
    test('fromEntity carries the CVV through the data layer', () {
      expect(PaymentCardModel.fromEntity(_card(cvv: '123')).cvv, '123');
      expect(PaymentCardModel.fromEntity(_card()).cvv, isNull);
    });
  });
}
