import 'package:equatable/equatable.dart';

class PaymentCard extends Equatable {
  const PaymentCard({
    required this.id,
    required this.holderName,
    required this.cardNumber,
    required this.expiryDate,
    required this.typeLabel,
    required this.cvv,
    this.bankName,
  });

  final String id;
  final String holderName;

  /// Full card number, stored as digits only (e.g. "4532123456789012")
  final String cardNumber;
  final String expiryDate;
  final String typeLabel;
  final String cvv;
  final String? bankName;

  /// Returns card number formatted as groups: 4532 1234 5678 9012
  String get formattedNumber {
    final digits = cardNumber.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  @override
  List<Object?> get props => [
        id,
        holderName,
        cardNumber,
        expiryDate,
        typeLabel,
        cvv,
        bankName,
      ];
}
