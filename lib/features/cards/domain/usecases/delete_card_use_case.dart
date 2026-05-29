import '../repositories/card_repository.dart';

class DeleteCardUseCase {
  const DeleteCardUseCase(this._repository);
  final CardRepository _repository;

  Future<void> call(String cardId) => _repository.deleteCard(cardId);
}
