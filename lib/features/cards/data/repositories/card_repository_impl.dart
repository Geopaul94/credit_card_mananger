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
  Future<void> addCard(PaymentCard card) {
    return _localDataSource.addCard(
      PaymentCardModel(
        id: card.id,
        holderName: card.holderName,
        cardNumber: card.cardNumber,
        expiryDate: card.expiryDate,
        typeLabel: card.typeLabel,
        cvv: card.cvv,
        bankName: card.bankName,
        dueDay: card.dueDay,
      ),
    );
  }
}
