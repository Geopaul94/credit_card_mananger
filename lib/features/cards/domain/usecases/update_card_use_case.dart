import '../entities/payment_card.dart';
import '../repositories/card_repository.dart';

class UpdateCardUseCase {
  const UpdateCardUseCase(this._repository);
  final CardRepository _repository;

  Future<void> call(PaymentCard card) => _repository.updateCard(card);
}
