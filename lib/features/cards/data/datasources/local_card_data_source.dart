import '../models/payment_card_model.dart';

abstract class LocalCardDataSource {
  Future<List<PaymentCardModel>> getCards();
  Future<void> addCard(PaymentCardModel card);
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
    ),
    const PaymentCardModel(
      id: '2',
      holderName: 'Alex Joseph',
      cardNumber: '5412345678901094',
      expiryDate: '03/27',
      typeLabel: 'Debit',
      cvv: '318',
      bankName: 'SBI Bank',
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
}
