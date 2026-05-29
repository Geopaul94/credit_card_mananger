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
