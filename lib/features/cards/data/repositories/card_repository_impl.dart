import '../../domain/entities/payment_card.dart';
import '../../domain/repositories/card_repository.dart';
import '../datasources/local_card_data_source.dart';
import '../models/payment_card_model.dart';

class CardRepositoryImpl implements CardRepository {
  const CardRepositoryImpl(this._localDataSource);

  final LocalCardDataSource _localDataSource;

  @override
  Future<List<PaymentCard>> getSavedCards() => _localDataSource.getCards();

  @override
  Future<void> addCard(PaymentCard card) =>
      _localDataSource.addCard(PaymentCardModel.fromEntity(card));

  @override
  Future<void> updateCard(PaymentCard card) =>
      _localDataSource.updateCard(PaymentCardModel.fromEntity(card));

  @override
  Future<void> deleteCard(String cardId) =>
      _localDataSource.deleteCard(cardId);
}
