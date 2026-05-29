import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/notifications/notification_service.dart';
import '../../../domain/entities/payment_card.dart';
import '../../../domain/usecases/add_card_use_case.dart';
import '../../../domain/usecases/get_saved_cards_use_case.dart';
import 'card_overview_event.dart';
import 'card_overview_state.dart';

class CardOverviewBloc extends Bloc<CardOverviewEvent, CardOverviewState> {
  CardOverviewBloc(this._getSavedCards, this._addCard)
      : super(const CardOverviewState()) {
    on<LoadCardsRequested>(_onLoad);
    on<AddCardRequested>(_onAddCard);
    on<MarkCardPaidRequested>(_onMarkPaid);
  }

  final GetSavedCardsUseCase _getSavedCards;
  final AddCardUseCase _addCard;
  final _notif = NotificationService.instance;

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<void> _onLoad(
    LoadCardsRequested event,
    Emitter<CardOverviewState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final cards = await _getSavedCards();
      emit(state.copyWith(cards: cards, isLoading: false, clearError: true));
    } catch (_) {
      emit(state.copyWith(isLoading: false, errorMessage: 'Unable to load cards.'));
    }
  }

  // ── Add card ──────────────────────────────────────────────────────────────

  Future<void> _onAddCard(
    AddCardRequested event,
    Emitter<CardOverviewState> emit,
  ) async {
    try {
      final card = PaymentCard(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        holderName: event.holderName.trim(),
        cardNumber: event.cardNumber.replaceAll(RegExp(r'\D'), ''),
        expiryDate: event.expiryDate.trim(),
        typeLabel: event.typeLabel.trim(),
        cvv: event.cvv.trim(),
        bankName: (event.bankName?.trim().isEmpty ?? true) ? null : event.bankName!.trim(),
        dueDay: event.dueDay,
      );

      await _addCard(card);
      await _notif.scheduleCardReminders(card);

      final cards = await _getSavedCards();
      emit(state.copyWith(cards: cards, clearError: true));
    } catch (_) {
      emit(state.copyWith(errorMessage: 'Unable to add card right now.'));
    }
  }

  // ── Mark paid ─────────────────────────────────────────────────────────────

  Future<void> _onMarkPaid(
    MarkCardPaidRequested event,
    Emitter<CardOverviewState> emit,
  ) async {
    final card = state.cards.where((c) => c.id == event.cardId).firstOrNull;
    if (card == null) return;

    await _notif.rescheduleForNextMonth(card);

    final updated = Set<String>.from(state.paidCardIds)..add(event.cardId);
    emit(state.copyWith(paidCardIds: updated));
  }
}
