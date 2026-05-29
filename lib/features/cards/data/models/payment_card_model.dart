import '../../domain/entities/payment_card.dart';

class PaymentCardModel extends PaymentCard {
  const PaymentCardModel({
    required super.id,
    required super.holderName,
    required super.cardNumber,
    required super.expiryDate,
    required super.typeLabel,
    required super.cvv,
    super.bankName,
  });
}
