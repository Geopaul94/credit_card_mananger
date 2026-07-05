import '../../../../core/storage/secure_card_storage.dart';
import '../../domain/entities/payment_card.dart';
import '../models/payment_card_model.dart';

abstract class LocalCardDataSource {
  Future<List<PaymentCardModel>> getCards();
  Future<void> addCard(PaymentCardModel card);
  Future<void> updateCard(PaymentCardModel card);
  Future<void> deleteCard(String cardId);

  /// Overwrites all stored cards — used by backup restore.
  Future<void> replaceAll(List<PaymentCard> cards);
}

class LocalCardDataSourceImpl implements LocalCardDataSource {
  LocalCardDataSourceImpl(this._storage);

  final SecureCardStorage _storage;

  /// In-memory cache so repeated reads don't decrypt on every call.
  List<PaymentCardModel>? _cache;

  @override
  Future<List<PaymentCardModel>> getCards() async {
    _cache ??= (await _storage.loadCards())
        .map(PaymentCardModel.fromEntity)
        .toList();
    return List<PaymentCardModel>.from(_cache!);
  }

  @override
  Future<void> addCard(PaymentCardModel card) async {
    final list = await getCards();
    list.insert(0, card);
    _cache = list;
    await _storage.saveCards(list);
  }

  @override
  Future<void> updateCard(PaymentCardModel card) async {
    final list = await getCards();
    final idx = list.indexWhere((c) => c.id == card.id);
    if (idx != -1) list[idx] = card;
    _cache = list;
    await _storage.saveCards(list);
  }

  @override
  Future<void> deleteCard(String cardId) async {
    final list = await getCards();
    list.removeWhere((c) => c.id == cardId);
    _cache = list;
    await _storage.saveCards(list);
  }

  @override
  Future<void> replaceAll(List<PaymentCard> cards) async {
    final models = cards.map(PaymentCardModel.fromEntity).toList();
    _cache = models;
    await _storage.replaceAll(models);
  }
}
