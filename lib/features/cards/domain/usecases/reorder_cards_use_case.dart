import '../entities/payment_card.dart';
import '../repositories/card_repository.dart';

/// Persists a new card order.
///
/// Cards are stored as an ordered list, so "the order the user chose" is
/// simply the list itself — no per-card position field needed, and older
/// installs are unaffected.
class ReorderCardsUseCase {
  const ReorderCardsUseCase(this._repository);
  final CardRepository _repository;

  Future<void> call(List<PaymentCard> cardsInNewOrder) =>
      _repository.replaceAll(cardsInNewOrder);
}
