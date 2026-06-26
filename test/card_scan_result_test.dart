import 'package:credit_cards/features/cards/data/services/card_scan_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CardScanResult', () {
    test('hasAnyField false when all null', () {
      expect(const CardScanResult().hasAnyField, false);
    });
    test('hasAnyField true when at least one field set', () {
      expect(const CardScanResult(cardNumber: '4532').hasAnyField, true);
      expect(const CardScanResult(cvv: '123').hasAnyField, true);
      expect(const CardScanResult(bankName: 'HDFC').hasAnyField, true);
    });

    group('merge', () {
      test('keeps this fields, fills nulls from other', () {
        const a = CardScanResult(cardNumber: '4532', holderName: 'JOHN');
        const b = CardScanResult(cardNumber: '9999', cvv: '321');
        final out = a.merge(b);
        expect(out.cardNumber, '4532'); // a wins
        expect(out.holderName, 'JOHN'); // only on a
        expect(out.cvv, '321'); // only on b
      });
      test('this all-null merge with other returns other', () {
        const a = CardScanResult();
        const b = CardScanResult(
          holderName: 'JANE',
          cardNumber: '5555',
          expiryDate: '11/27',
          cvv: '789',
          bankName: 'ICICI Bank',
          cardName: 'Amazon Pay',
        );
        final out = a.merge(b);
        expect(out.holderName, 'JANE');
        expect(out.cardNumber, '5555');
        expect(out.expiryDate, '11/27');
        expect(out.cvv, '789');
        expect(out.bankName, 'ICICI Bank');
        expect(out.cardName, 'Amazon Pay');
      });
      test('this all-filled merge with empty other returns this', () {
        const a = CardScanResult(
          holderName: 'AMY',
          cardNumber: '1111',
          expiryDate: '12/26',
          cvv: '999',
          bankName: 'HDFC Bank',
          cardName: 'Regalia',
        );
        const b = CardScanResult();
        final out = a.merge(b);
        expect(out.holderName, 'AMY');
        expect(out.cardNumber, '1111');
        expect(out.expiryDate, '12/26');
        expect(out.cvv, '999');
        expect(out.bankName, 'HDFC Bank');
        expect(out.cardName, 'Regalia');
      });
    });
  });
}
