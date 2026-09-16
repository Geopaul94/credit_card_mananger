import 'package:equatable/equatable.dart';

import '../../../../domain/entities/card_folder.dart';
import '../../../../domain/entities/payment_card.dart';

/// Sealed filter hierarchy used by the Home screen to filter cards by
/// card type or user-defined folder.
sealed class HomeCardFilter extends Equatable {
  const HomeCardFilter();

  String get label;
  String get shortLabel;
  List<PaymentCard> apply(List<PaymentCard> cards);
}

class AllCardsFilter extends HomeCardFilter {
  const AllCardsFilter();

  @override
  String get label => 'All Cards';

  @override
  String get shortLabel => 'All';

  @override
  List<PaymentCard> apply(List<PaymentCard> cards) => cards;

  @override
  List<Object?> get props => const ['all'];
}

class CardTypeFilter extends HomeCardFilter {
  const CardTypeFilter(this.cardType);

  final String cardType; // 'Credit', 'Debit', 'Prepaid'

  @override
  String get label => '$cardType Cards';

  @override
  String get shortLabel => cardType;

  @override
  List<PaymentCard> apply(List<PaymentCard> cards) {
    return cards
        .where((c) => c.typeLabel.toLowerCase() == cardType.toLowerCase())
        .toList();
  }

  @override
  List<Object?> get props => [cardType.toLowerCase()];
}

class FolderCardFilter extends HomeCardFilter {
  const FolderCardFilter(this.folder);

  final CardFolder folder;

  @override
  String get label => folder.name;

  @override
  String get shortLabel => folder.name;

  @override
  List<PaymentCard> apply(List<PaymentCard> cards) {
    final ids = folder.cardIds.toSet();
    return cards.where((c) => ids.contains(c.id)).toList();
  }

  @override
  List<Object?> get props => [folder.id];
}
