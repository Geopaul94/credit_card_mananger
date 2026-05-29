import 'package:equatable/equatable.dart';

abstract class CardOverviewEvent extends Equatable {
  const CardOverviewEvent();
  @override
  List<Object?> get props => [];
}

class LoadCardsRequested extends CardOverviewEvent {
  const LoadCardsRequested();
}

class AddCardRequested extends CardOverviewEvent {
  const AddCardRequested({
    required this.holderName,
    required this.cardNumber,
    required this.expiryDate,
    required this.typeLabel,
    required this.cvv,
    this.bankName,
    this.dueDay,
  });

  final String holderName;
  final String cardNumber;
  final String expiryDate;
  final String typeLabel;
  final String cvv;
  final String? bankName;
  final int? dueDay;

  @override
  List<Object?> get props =>
      [holderName, cardNumber, expiryDate, typeLabel, cvv, bankName, dueDay];
}

/// Fired when user marks a card's bill as paid for the current cycle.
class MarkCardPaidRequested extends CardOverviewEvent {
  const MarkCardPaidRequested({required this.cardId});
  final String cardId;

  @override
  List<Object?> get props => [cardId];
}
