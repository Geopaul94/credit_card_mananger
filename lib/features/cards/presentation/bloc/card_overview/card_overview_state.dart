import 'package:equatable/equatable.dart';

import '../../../domain/entities/payment_card.dart';

class CardOverviewState extends Equatable {
  const CardOverviewState({
    this.cards = const [],
    this.isLoading = false,
    this.errorMessage,
    this.paidCardIds = const {},
  });

  final List<PaymentCard> cards;
  final bool isLoading;
  final String? errorMessage;

  /// Card IDs marked as paid in the current session/cycle.
  final Set<String> paidCardIds;

  /// A card needs attention when it is unpaid and inside the reminder window:
  /// due within three days, due today, or already overdue.
  ///
  /// Defined once here because two places show it — the reminders screen's
  /// "DUE NOW" group and the count on the reminders tab. If they drifted
  /// apart, the badge would promise a number the list doesn't contain.
  bool needsActionNow(PaymentCard card) {
    if (paidCardIds.contains(card.id)) return false;
    final info = card.reminderInfo;
    return info != null && info.delta <= 3;
  }

  /// How many cards need attention right now — the reminders tab badge.
  int get actionNeededCount => cards.where(needsActionNow).length;

  CardOverviewState copyWith({
    List<PaymentCard>? cards,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    Set<String>? paidCardIds,
  }) {
    return CardOverviewState(
      cards: cards ?? this.cards,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      paidCardIds: paidCardIds ?? this.paidCardIds,
    );
  }

  @override
  List<Object?> get props => [cards, isLoading, errorMessage, paidCardIds];
}
