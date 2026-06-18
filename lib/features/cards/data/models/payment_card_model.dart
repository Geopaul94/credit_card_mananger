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
    super.cardName,
    super.dueDay,
    super.notes,
  });

  factory PaymentCardModel.fromEntity(PaymentCard card) => PaymentCardModel(
        id: card.id,
        holderName: card.holderName,
        cardNumber: card.cardNumber,
        expiryDate: card.expiryDate,
        typeLabel: card.typeLabel,
        cvv: card.cvv,
        bankName: card.bankName,
        cardName: card.cardName,
        dueDay: card.dueDay,
        notes: card.notes,
      );
}
