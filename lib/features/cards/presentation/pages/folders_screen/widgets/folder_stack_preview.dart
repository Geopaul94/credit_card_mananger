import 'package:flutter/material.dart';

import '../../../../../../core/theme/card_palette.dart';
import '../../../../domain/entities/payment_card.dart';

/// Renders a multi-layered, fanned mini-card stack preview peeking out of a folder.
class FolderStackPreview extends StatelessWidget {
  const FolderStackPreview({
    required this.cards,
    super.key,
  });

  final List<PaymentCard> cards;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return _EmptyFolderPocket();
    }

    final displayCards = cards.take(3).toList();
    final count = displayCards.length;

    return Center(
      child: SizedBox(
        width: 220,
        height: 140,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            if (count >= 3)
              Positioned(
                top: 0,
                child: Transform.rotate(
                  angle: 0.12,
                  child: _MiniCardFace(
                    card: displayCards[2],
                    scale: 0.88,
                    opacity: 0.70,
                    elevation: 4,
                  ),
                ),
              ),
            if (count >= 2)
              Positioned(
                top: 8,
                child: Transform.rotate(
                  angle: -0.09,
                  child: _MiniCardFace(
                    card: displayCards[1],
                    scale: 0.94,
                    opacity: 0.88,
                    elevation: 8,
                  ),
                ),
              ),
            Positioned(
              top: 16,
              child: _MiniCardFace(
                card: displayCards[0],
                scale: 1.0,
                opacity: 1.0,
                elevation: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniCardFace extends StatelessWidget {
  const _MiniCardFace({
    required this.card,
    required this.scale,
    required this.opacity,
    required this.elevation,
  });

  final PaymentCard card;
  final double scale;
  final double opacity;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final gradient = CardPalette.forCard(card);

    return Opacity(
      opacity: opacity,
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: 172,
          height: 104,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: elevation * 1.2,
                offset: Offset(0, elevation * 0.5),
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.22),
              width: 0.8,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      card.bankName ?? card.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  Container(
                    width: 14,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBBF24).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '•••• ${card.lastFour}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    card.typeLabel.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyFolderPocket extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 150,
        height: 90,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white.withValues(alpha: 0.08),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            style: BorderStyle.solid,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_card_rounded,
              size: 28,
              color: Colors.white.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 4),
            Text(
              'No cards inside',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
