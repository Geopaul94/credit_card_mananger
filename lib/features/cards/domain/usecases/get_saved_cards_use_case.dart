import '../entities/payment_card.dart';
import '../repositories/card_repository.dart';

class GetSavedCardsUseCase {
  const GetSavedCardsUseCase(this._repository);

  final CardRepository _repository;

  Future<List<PaymentCard>> call() {
    return _repository.getSavedCards();
  }
}
