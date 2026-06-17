import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/backup/backup_cubit.dart';
import '../../../../../core/notifications/notification_service.dart';
import '../../../domain/entities/payment_card.dart';
import '../../../domain/usecases/add_card_use_case.dart';
import '../../../domain/usecases/delete_card_use_case.dart';
import '../../../domain/usecases/get_saved_cards_use_case.dart';
import '../../../domain/usecases/update_card_use_case.dart';
import 'card_overview_event.dart';
import 'card_overview_state.dart';

class CardOverviewBloc extends Bloc<CardOverviewEvent, CardOverviewState> {
  CardOverviewBloc(
    this._getSavedCards,
    this._addCard,
    this._updateCard,
    this._deleteCard,
    this._backup,
  ) : super(const CardOverviewState()) {
    on<LoadCardsRequested>(_onLoad);
    on<AddCardRequested>(_onAddCard);
    on<UpdateCardRequested>(_onUpdateCard);
    on<DeleteCardRequested>(_onDeleteCard);
    on<MarkCardPaidRequested>(_onMarkPaid);
  }

  final GetSavedCardsUseCase _getSavedCards;
  final AddCardUseCase _addCard;
  final UpdateCardUseCase _updateCard;
  final DeleteCardUseCase _deleteCard;
  final BackupCubit _backup;
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
      // Silently auto-backup if ≥ 7 days have passed since the last backup.
      _backup.autoBackupIfNeeded(cards);
    } catch (_) {
      emit(state.copyWith(
          isLoading: false, errorMessage: 'Unable to load cards.'));
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
        bankName: (event.bankName?.trim().isEmpty ?? true)
            ? null
            : event.bankName!.trim(),
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

  // ── Update card ───────────────────────────────────────────────────────────

  Future<void> _onUpdateCard(
    UpdateCardRequested event,
    Emitter<CardOverviewState> emit,
  ) async {
    try {
      await _updateCard(event.card);

      // Reschedule (or cancel) reminders when the due day changes, and clear
      // any stale "paid" flag — a changed/cleared cycle should start unpaid.
      final old = state.cards.firstWhere((c) => c.id == event.card.id,
          orElse: () => event.card);
      var paid = state.paidCardIds;
      if (old.dueDay != event.card.dueDay) {
        if (event.card.dueDay == null) {
          await _notif.cancelCardReminders(event.card.id);
        } else {
          await _notif.scheduleCardReminders(event.card);
        }
        if (paid.contains(event.card.id)) {
          paid = Set<String>.from(paid)..remove(event.card.id);
        }
      }

      final cards = await _getSavedCards();
      emit(state.copyWith(cards: cards, paidCardIds: paid, clearError: true));
    } catch (_) {
      emit(state.copyWith(errorMessage: 'Unable to update card.'));
    }
  }

  // ── Delete card ───────────────────────────────────────────────────────────

  Future<void> _onDeleteCard(
    DeleteCardRequested event,
    Emitter<CardOverviewState> emit,
  ) async {
    try {
      await _deleteCard(event.cardId);
      // Cancel any reminders so a deleted card can't fire orphaned notifications.
      await _notif.cancelCardReminders(event.cardId);
      final cards = await _getSavedCards();

      // Remove from paid set too.
      final paid = Set<String>.from(state.paidCardIds)..remove(event.cardId);
      emit(state.copyWith(cards: cards, paidCardIds: paid, clearError: true));
    } catch (_) {
      emit(state.copyWith(errorMessage: 'Unable to delete card.'));
    }
  }

  // ── Mark paid ─────────────────────────────────────────────────────────────

  Future<void> _onMarkPaid(
    MarkCardPaidRequested event,
    Emitter<CardOverviewState> emit,
  ) async {
    final card =
        state.cards.where((c) => c.id == event.cardId).firstOrNull;
    if (card == null) return;

    // Reflect the user's intent first; the reminder reschedule is best-effort
    // and must not be able to undo the paid mark if it throws.
    final updated = Set<String>.from(state.paidCardIds)..add(event.cardId);
    emit(state.copyWith(paidCardIds: updated));

    try {
      await _notif.rescheduleForNextMonth(card);
    } catch (_) {
      // Notification reschedule is non-critical; ignore failures.
    }
  }
}
