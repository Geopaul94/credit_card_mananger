import '../entities/payment_card.dart';
import '../repositories/card_repository.dart';

class AddCardUseCase {
  const AddCardUseCase(this._repository);

  final CardRepository _repository;

  Future<void> call(PaymentCard card) {
    return _repository.addCard(card);
  }
}
