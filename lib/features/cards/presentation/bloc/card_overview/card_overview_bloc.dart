import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/payment_card.dart';
import '../../../domain/usecases/add_card_use_case.dart';
import '../../../domain/usecases/get_saved_cards_use_case.dart';
import 'card_overview_event.dart';
import 'card_overview_state.dart';

class CardOverviewBloc extends Bloc<CardOverviewEvent, CardOverviewState> {
  CardOverviewBloc(this._getSavedCardsUseCase, this._addCardUseCase)
      : super(const CardOverviewState()) {
    on<LoadCardsRequested>(_onLoadCardsRequested);
    on<AddCardRequested>(_onAddCardRequested);
  }

  final GetSavedCardsUseCase _getSavedCardsUseCase;
  final AddCardUseCase _addCardUseCase;

  Future<void> _onLoadCardsRequested(
    LoadCardsRequested event,
    Emitter<CardOverviewState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final cards = await _getSavedCardsUseCase.call();
      emit(state.copyWith(cards: cards, isLoading: false, clearError: true));
    } catch (_) {
      emit(state.copyWith(isLoading: false, errorMessage: 'Unable to load cards.'));
    }
  }

  Future<void> _onAddCardRequested(
    AddCardRequested event,
    Emitter<CardOverviewState> emit,
  ) async {
    try {
      // Store digits only for the card number
      final cardNumber = event.cardNumber.replaceAll(RegExp(r'\D'), '');

      await _addCardUseCase.call(
        PaymentCard(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          holderName: event.holderName.trim(),
          cardNumber: cardNumber,
          expiryDate: event.expiryDate.trim(),
          typeLabel: event.typeLabel.trim(),
          cvv: event.cvv.trim(),
          bankName: event.bankName?.trim().isEmpty == true
              ? null
              : event.bankName?.trim(),
        ),
      );

      final cards = await _getSavedCardsUseCase.call();
      emit(state.copyWith(cards: cards, clearError: true));
    } catch (_) {
      emit(state.copyWith(errorMessage: 'Unable to add card right now.'));
    }
  }
}
