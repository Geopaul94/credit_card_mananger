// Tests for how a card is presented: which payment network its number belongs
// to, and which gradient it is drawn with.

import 'package:flutter_test/flutter_test.dart';

import 'package:credit_cards/core/theme/card_palette.dart';
import 'package:credit_cards/features/cards/domain/entities/payment_card.dart';
import 'package:credit_cards/features/cards/presentation/widgets/card_brand.dart';

PaymentCard _card({String id = '1', String? bank, String number = '4532123456789012'}) =>
    PaymentCard(
      id: id,
      holderName: 'Geo Paulson',
      cardNumber: number,
      expiryDate: '08/28',
      typeLabel: 'Credit',
      bankName: bank,
    );

void main() {
  group('detectCardBrand', () {
    test('Visa starts with 4', () {
      expect(detectCardBrand('4532123456789012'), CardBrand.visa);
    });

    test('Mastercard covers both 51-55 and the 2221-2720 range', () {
      expect(detectCardBrand('5412345678901234'), CardBrand.mastercard);
      expect(detectCardBrand('2221001234567890'), CardBrand.mastercard);
      expect(detectCardBrand('2720991234567890'), CardBrand.mastercard);
    });

    test('Amex is 34 or 37', () {
      expect(detectCardBrand('341234567890123'), CardBrand.amex);
      expect(detectCardBrand('371234567890123'), CardBrand.amex);
    });

    test('RuPay wins the shared 60 range', () {
      expect(detectCardBrand('6012345678901234'), CardBrand.rupay);
      expect(detectCardBrand('6521123456789012'), CardBrand.rupay);
    });

    test('Discover keeps 6011 and 644-649', () {
      expect(detectCardBrand('6011123456789012'), CardBrand.discover);
      expect(detectCardBrand('6441123456789012'), CardBrand.discover);
    });

    test('Diners Club is 36, 38, or 300-305', () {
      expect(detectCardBrand('36123456789012'), CardBrand.dinersClub);
      expect(detectCardBrand('30123456789012'), CardBrand.dinersClub);
    });

    test('ignores spaces in a formatted number', () {
      expect(detectCardBrand('4532 1234 5678 9012'), CardBrand.visa);
    });

    test('unrecognised or too-short numbers return unknown', () {
      expect(detectCardBrand('9999123456789012'), CardBrand.unknown);
      expect(detectCardBrand('4'), CardBrand.unknown);
      expect(detectCardBrand(''), CardBrand.unknown);
    });
  });

  group('CardPalette', () {
    test('a recognised bank gets its brand colours', () {
      final hdfc = CardPalette.forCard(_card(bank: 'HDFC Bank'));
      final axis = CardPalette.forCard(_card(bank: 'Axis Bank'));
      expect(hdfc, isNot(equals(axis)));
    });

    test('bank matching is case-insensitive and works on partial names', () {
      expect(
        CardPalette.forCard(_card(bank: 'hdfc')),
        CardPalette.forCard(_card(bank: 'HDFC Bank')),
      );
    });

    test('the same card always gets the same colours', () {
      final first = CardPalette.forCard(_card(id: '1754200000000'));
      final second = CardPalette.forCard(_card(id: '1754200000000'));
      expect(first, equals(second));
    });

    test('cards with no bank still differ from each other', () {
      // Two ids that must not collapse onto one colour, so a list of unnamed
      // cards is still visually separable.
      final a = CardPalette.forCard(_card(id: '1754200000001'));
      final b = CardPalette.forCard(_card(id: '1754200000002'));
      expect(a, isNot(equals(b)));
    });

    test('always returns a two-stop gradient', () {
      expect(CardPalette.forCard(_card()).length, 2);
      expect(CardPalette.forCard(_card(bank: 'HDFC Bank')).length, 2);
    });
  });
}
