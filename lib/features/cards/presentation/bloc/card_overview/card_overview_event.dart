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
  });

  final String holderName;
  final String cardNumber;
  final String expiryDate;
  final String typeLabel;
  final String cvv;
  final String? bankName;

  @override
  List<Object?> get props => [
        holderName,
        cardNumber,
        expiryDate,
        typeLabel,
        cvv,
        bankName,
      ];
}
