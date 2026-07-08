import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/backup/backup_cubit.dart';
import '../../../../../core/notifications/notification_service.dart';
import '../../../../../core/storage/secure_card_storage.dart';
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
    this._storage,
  ) : super(const CardOverviewState()) {
    on<LoadCardsRequested>(_onLoad);
    on<AddCardRequested>(_onAddCard);
    on<UpdateCardRequested>(_onUpdateCard);
    on<DeleteCardRequested>(_onDeleteCard);
    on<MarkCardPaidRequested>(_onMarkPaid);
    on<MarkCardUnpaidRequested>(_onMarkUnpaid);
  }

  final GetSavedCardsUseCase _getSavedCards;
  final AddCardUseCase _addCard;
  final UpdateCardUseCase _updateCard;
  final DeleteCardUseCase _deleteCard;
  final BackupCubit _backup;
  final SecureCardStorage _storage;
  final _notif = NotificationService.instance;

  /// cardId → the due date the payment covers. Source of truth for paid status;
  /// the state's [CardOverviewState.paidCardIds] is derived from this.
  Map<String, DateTime> _paidMap = {};

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Card IDs whose paid mark still covers the current cycle (covered due date
  /// is today or later) and which still exist.
  Set<String> _currentPaidIds(List<PaymentCard> cards) {
    final today = _dateOnly(DateTime.now());
    final ids = cards.map((c) => c.id).toSet();
    return _paidMap.entries
        .where((e) =>
            ids.contains(e.key) && !_dateOnly(e.value).isBefore(today))
        .map((e) => e.key)
        .toSet();
  }

  Future<void> _persistPaid() => _storage.savePaidMap(_paidMap);

  /// Materialises the saved cards as a true `List<PaymentCard>`. The data
  /// source returns `List<PaymentCardModel>`, whose reified element type would
  /// otherwise break `firstWhere(orElse: () => <PaymentCard>)` downstream.
  Future<List<PaymentCard>> _loadCards() async =>
      List<PaymentCard>.from(await _getSavedCards());

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<void> _onLoad(
    LoadCardsRequested event,
    Emitter<CardOverviewState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final cards = await _loadCards();

      // Restore persisted paid status, dropping stale (past-cycle) and
      // orphaned (deleted-card) entries, then write the pruned map back.
      _paidMap = _storage.loadPaidMap();
      final today = _dateOnly(DateTime.now());
      final cardIds = cards.map((c) => c.id).toSet();
      _paidMap.removeWhere((id, covered) =>
          !cardIds.contains(id) || _dateOnly(covered).isBefore(today));
      await _persistPaid();

      emit(state.copyWith(
        cards: cards,
        isLoading: false,
        clearError: true,
        paidCardIds: _paidMap.keys.toSet(),
      ));
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
        bankName: (event.bankName?.trim().isEmpty ?? true)
            ? null
            : event.bankName!.trim(),
        cardName: (event.cardName?.trim().isEmpty ?? true)
            ? null
            : event.cardName!.trim(),
        dueDay: event.dueDay,
      );

      await _addCard(card);
      await _notif.scheduleCardReminders(card);

      final cards = await _loadCards();
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
      if (old.dueDay != event.card.dueDay) {
        if (event.card.dueDay == null) {
          await _notif.cancelCardReminders(event.card.id);
        } else {
          await _notif.scheduleCardReminders(event.card);
        }
        if (_paidMap.containsKey(event.card.id)) {
          _paidMap = Map<String, DateTime>.from(_paidMap)
            ..remove(event.card.id);
          await _persistPaid();
        }
      }

      final cards = await _loadCards();
      emit(state.copyWith(
          cards: cards,
          paidCardIds: _currentPaidIds(cards),
          clearError: true));
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
      final cards = await _loadCards();

      // Drop any persisted paid mark for the removed card.
      if (_paidMap.containsKey(event.cardId)) {
        _paidMap = Map<String, DateTime>.from(_paidMap)..remove(event.cardId);
        await _persistPaid();
      }
      emit(state.copyWith(
          cards: cards,
          paidCardIds: _currentPaidIds(cards),
          clearError: true));
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

    // The covered cycle is this card's upcoming due date. Cards without a due
    // day don't surface the paid control, but fall back to today just in case.
    final covered = card.nextDueDate ?? _dateOnly(DateTime.now());

    // Persist + reflect the user's intent first; the reminder reschedule is
    // best-effort and must not be able to undo the paid mark if it throws.
    _paidMap = Map<String, DateTime>.from(_paidMap)..[event.cardId] = covered;
    await _persistPaid();
    emit(state.copyWith(paidCardIds: _currentPaidIds(state.cards)));

    try {
      await _notif.rescheduleForNextMonth(card);
    } catch (_) {
      // Notification reschedule is non-critical; ignore failures.
    }
  }

  // ── Mark unpaid (undo) ────────────────────────────────────────────────────

  Future<void> _onMarkUnpaid(
    MarkCardUnpaidRequested event,
    Emitter<CardOverviewState> emit,
  ) async {
    _paidMap = Map<String, DateTime>.from(_paidMap)..remove(event.cardId);
    await _persistPaid();
    emit(state.copyWith(paidCardIds: _currentPaidIds(state.cards)));

    // Restore this cycle's reminders that mark-paid had pushed to next month.
    final card = state.cards.where((c) => c.id == event.cardId).firstOrNull;
    if (card != null && card.dueDay != null) {
      try {
        await _notif.scheduleCardReminders(card);
      } catch (_) {
        // Non-critical.
      }
    }
  }
}
