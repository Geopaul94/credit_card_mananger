import 'package:flutter/material.dart';

import '../../../../domain/entities/payment_card.dart';

/// The reverse of the card, shown after the flip animation: magnetic stripe,
/// signature panel, and the details that are printed on a real card's back.
class CardBackFace extends StatelessWidget {
  const CardBackFace({
    required this.card,
    required this.gradientColors,
    this.height = 220,
    super.key,
  });

  final PaymentCard card;
  final List<Color> gradientColors;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          boxShadow: [
            BoxShadow(
              color: gradientColors.last.withValues(alpha: 0.4),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(height: 36, color: const Color(0xFF111827)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                // With a code stored the strip carries it (as a real card
                // does); without one it's just the blank signature panel.
                child: card.hasCvv
                    ? Row(
                        children: [
                          const Expanded(child: _SignatureLines()),
                          const SizedBox(width: 10),
                          Text(
                            'CVV',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            card.cvv!,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      )
                    : const _SignatureLines(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                children: [
                  _BackInfoRow(label: 'TYPE', value: card.typeLabel),
                  const SizedBox(height: 6),
                  _BackInfoRow(label: 'HOLDER', value: card.holderName),
                  const SizedBox(height: 6),
                  _BackInfoRow(label: 'EXPIRY', value: card.expiryDate),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.touch_app_outlined,
                    size: 12,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'tap to flip',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The three ruled lines of a signature panel.
class _SignatureLines extends StatelessWidget {
  const _SignatureLines();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        3,
        (_) => Container(height: 1, color: Colors.grey.shade300),
      ),
    );
  }
}

class _BackInfoRow extends StatelessWidget {
  const _BackInfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 48,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ],
    );
  }
}
