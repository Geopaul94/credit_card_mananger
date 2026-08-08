import 'package:flutter/material.dart';

/// The payment network a card belongs to, worked out from its number.
enum CardBrand { visa, mastercard, amex, rupay, discover, dinersClub, unknown }

/// Identifies the network from the card number's opening digits (its IIN).
///
/// Ranges follow ISO/IEC 7812. RuPay is checked before Discover because the
/// two share the 60/65 space and this app's users are mostly in India, where
/// a 60-prefixed card is overwhelmingly RuPay.
CardBrand detectCardBrand(String cardNumber) {
  final d = cardNumber.replaceAll(RegExp(r'\D'), '');
  if (d.length < 2) return CardBrand.unknown;

  int prefix(int length) =>
      d.length >= length ? int.parse(d.substring(0, length)) : -1;

  final two = prefix(2);
  final three = prefix(3);
  final four = prefix(4);

  if (d[0] == '4') return CardBrand.visa;
  if (two == 34 || two == 37) return CardBrand.amex;
  if (two >= 51 && two <= 55) return CardBrand.mastercard;
  if (four >= 2221 && four <= 2720) return CardBrand.mastercard;

  // Discover's own ranges first — RuPay never issues in these.
  if (four == 6011) return CardBrand.discover;
  if (three >= 644 && three <= 649) return CardBrand.discover;

  // Everything else across 60x/65x is treated as RuPay. Discover also issues
  // in the 65 range, but this app's users are in India, where 65 is
  // overwhelmingly RuPay — Slice, Jupiter/CSB and most co-brands sit in
  // 652x-653x. A US Discover card starting 65 would be labelled RuPay here;
  // that trade is deliberate, because showing DISCOVER on an ordinary Indian
  // card is the mistake people actually see.
  if (two == 60 || two == 65 || three == 508) return CardBrand.rupay;

  if (two == 36 || two == 38 || (three >= 300 && three <= 305)) {
    return CardBrand.dinersClub;
  }
  return CardBrand.unknown;
}

/// The network wordmark shown on the card face.
///
/// Drawn as type and simple shapes rather than bundled logo images: it keeps
/// the app free of third-party brand assets, scales crisply at any size, and
/// stays legible on every gradient.
class CardBrandMark extends StatelessWidget {
  const CardBrandMark({required this.cardNumber, this.height = 26, super.key});

  final String cardNumber;
  final double height;

  @override
  Widget build(BuildContext context) {
    final brand = detectCardBrand(cardNumber);
    return SizedBox(
      height: height,
      child: switch (brand) {
        CardBrand.visa => _Wordmark('VISA', italic: true, spacing: 1.5),
        CardBrand.mastercard => _MastercardCircles(height: height),
        CardBrand.amex => _BoxedWordmark('AMEX'),
        CardBrand.rupay => _Wordmark('RuPay', spacing: 0.2),
        CardBrand.discover => _Wordmark('DISCOVER', spacing: 0.8),
        CardBrand.dinersClub => _Wordmark('DINERS', spacing: 0.8),
        CardBrand.unknown => const SizedBox.shrink(),
      },
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark(this.text, {this.italic = false, this.spacing = 1});
  final String text;
  final bool italic;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: 19,
          fontWeight: FontWeight.w900,
          fontStyle: italic ? FontStyle.italic : FontStyle.normal,
          letterSpacing: spacing,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }
}

class _BoxedWordmark extends StatelessWidget {
  const _BoxedWordmark(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

/// Mastercard's two interlocking discs.
class _MastercardCircles extends StatelessWidget {
  const _MastercardCircles({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    final d = height * 0.82;
    return SizedBox(
      width: d * 1.62,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          _disc(d, const Color(0xFFEB001B)),
          Positioned(left: d * 0.62, child: _disc(d, const Color(0xFFF79E1B))),
        ],
      ),
    );
  }

  Widget _disc(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.9),
      shape: BoxShape.circle,
    ),
  );
}
