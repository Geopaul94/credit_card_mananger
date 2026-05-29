import '../entities/payment_card.dart';

abstract class CardRepository {
  Future<List<PaymentCard>> getSavedCards();
  Future<void> addCard(PaymentCard card);
}
