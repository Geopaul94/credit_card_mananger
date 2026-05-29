import '../models/payment_card_model.dart';

abstract class LocalCardDataSource {
  Future<List<PaymentCardModel>> getCards();
  Future<void> addCard(PaymentCardModel card);
  Future<void> updateCard(PaymentCardModel card);
  Future<void> deleteCard(String cardId);
}

class LocalCardDataSourceImpl implements LocalCardDataSource {
  final List<PaymentCardModel> _cards = [
    const PaymentCardModel(
      id: '1',
      holderName: 'Alex Joseph',
      cardNumber: '4532123456787621',
      expiryDate: '08/28',
      typeLabel: 'Credit',
      cvv: '742',
      bankName: 'HDFC Bank',
      dueDay: 15,
    ),
    const PaymentCardModel(
      id: '2',
      holderName: 'Alex Joseph',
      cardNumber: '5412345678901094',
      expiryDate: '03/27',
      typeLabel: 'Debit',
      cvv: '318',
      bankName: 'SBI Bank',
      dueDay: 5,
    ),
    const PaymentCardModel(
      id: '3',
      holderName: 'Alex Joseph',
      cardNumber: '6011000990135816',
      expiryDate: '11/26',
      typeLabel: 'Prepaid',
      cvv: '561',
      bankName: 'Axis Bank',
    ),
  ];

  @override
  Future<List<PaymentCardModel>> getCards() async =>
      List<PaymentCardModel>.from(_cards);

  @override
  Future<void> addCard(PaymentCardModel card) async =>
      _cards.insert(0, card);

  @override
  Future<void> updateCard(PaymentCardModel card) async {
    final idx = _cards.indexWhere((c) => c.id == card.id);
    if (idx != -1) _cards[idx] = card;
  }

  @override
  Future<void> deleteCard(String cardId) async =>
      _cards.removeWhere((c) => c.id == cardId);
}
