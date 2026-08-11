import 'package:flutter/material.dart';

import '../../../../core/theme/card_palette.dart';
import '../../domain/entities/payment_card.dart';

/// Small colour swatch identifying a card by bank code and last four digits,
/// in the same colour the card's full visual uses (CardPalette). Shared by
/// every screen that needs a compact stand-in for a card — the home hero,
/// the reminders list — so a given card is always the same colour wherever
/// it's shown in miniature.
class CardChip extends StatelessWidget {
  const CardChip({required this.card, this.size = 40, super.key});

  final PaymentCard card;
  final double size;

  String _shortLabel() {
    final bank = card.bankName?.trim();
    if (bank == null || bank.isEmpty) return card.typeLabel;
    return bank.length <= 6 ? bank.toUpperCase() : bank.substring(0, 6).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final digits = card.cardNumber.replaceAll(RegExp(r'\D'), '');
    final last4 = digits.length >= 4 ? digits.substring(digits.length - 4) : '';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: CardPalette.forCard(card).first,
        borderRadius: BorderRadius.circular(size * 0.22),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _shortLabel(),
            maxLines: 1,
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.19,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
          if (last4.isNotEmpty)
            Text(
              last4,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: size * 0.21,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}
