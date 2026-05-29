import 'package:equatable/equatable.dart';

import '../../../domain/entities/payment_card.dart';

class CardOverviewState extends Equatable {
  const CardOverviewState({
    this.cards = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<PaymentCard> cards;
  final bool isLoading;
  final String? errorMessage;

  CardOverviewState copyWith({
    List<PaymentCard>? cards,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CardOverviewState(
      cards: cards ?? this.cards,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [cards, isLoading, errorMessage];
}
