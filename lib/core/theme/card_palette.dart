import 'package:flutter/material.dart';

import '../../features/cards/domain/entities/payment_card.dart';

/// Picks the gradient a card is drawn with.
///
/// Colour is how you tell one card from another in a list, so a shared
/// per-type gradient made every credit card look identical. Instead:
///   1. a recognised issuing bank gets its own brand colours, and
///   2. anything else falls back to a fixed palette chosen from the card's id,
///      so the same card always comes back the same colour.
///
/// Both are deterministic — a card never changes colour between launches.
class CardPalette {
  CardPalette._();

  static List<Color> forCard(PaymentCard card) {
    final bank = card.bankName?.toLowerCase().trim();
    if (bank != null && bank.isNotEmpty) {
      for (final entry in _bankGradients.entries) {
        if (bank.contains(entry.key)) return entry.value;
      }
    }
    return _fallbackFor(card);
  }

  /// Stable index from the card id (a millisecond timestamp), so the choice
  /// survives restarts and never shuffles when the list is re-sorted.
  static List<Color> _fallbackFor(PaymentCard card) {
    var hash = 0;
    for (final unit in card.id.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return _fallbacks[hash % _fallbacks.length];
  }

  /// Brand colours for the banks the scanner already recognises.
  /// Keys are matched with `contains`, so "HDFC Bank" hits "hdfc".
  static const _bankGradients = <String, List<Color>>{
    'hdfc': [Color(0xFF004C8F), Color(0xFF002B5C)],
    'icici': [Color(0xFFF37021), Color(0xFF9E2A2B)],
    'state bank': [Color(0xFF22409A), Color(0xFF16295F)],
    'sbi': [Color(0xFF22409A), Color(0xFF16295F)],
    'axis': [Color(0xFF97144D), Color(0xFF5E0C30)],
    'kotak': [Color(0xFFED232A), Color(0xFF9B1216)],
    'indusind': [Color(0xFF8E2A3E), Color(0xFF5A1926)],
    'idfc': [Color(0xFF9C1D26), Color(0xFF611118)],
    'yes bank': [Color(0xFF00518F), Color(0xFF01305A)],
    'punjab': [Color(0xFFA4123F), Color(0xFF6B0B29)],
    'baroda': [Color(0xFFF15A22), Color(0xFF9B3411)],
    'canara': [Color(0xFF00539B), Color(0xFF003261)],
    'union': [Color(0xFFE31E24), Color(0xFF8F1216)],
    'american express': [Color(0xFF006FCF), Color(0xFF00437F)],
    'citi': [Color(0xFF056DAE), Color(0xFF03446D)],
    'hsbc': [Color(0xFFDB0011), Color(0xFF8A000B)],
    'standard chartered': [Color(0xFF0473EA), Color(0xFF014694)],
    'chase': [Color(0xFF117ACA), Color(0xFF0A4B7D)],
    'bank of america': [Color(0xFFE31837), Color(0xFF8E0F22)],
    'wells fargo': [Color(0xFFD71E28), Color(0xFF8A1219)],
    'capital one': [Color(0xFF004977), Color(0xFF002C48)],
    'barclays': [Color(0xFF00AEEF), Color(0xFF00688F)],
  };

  /// Deliberately varied in hue so neighbouring cards never look alike.
  static const _fallbacks = <List<Color>>[
    [Color(0xFF1D4ED8), Color(0xFF4F46E5)], // indigo
    [Color(0xFF7C3AED), Color(0xFF5B21B6)], // violet
    [Color(0xFF059669), Color(0xFF0D9488)], // emerald
    [Color(0xFFB45309), Color(0xFF7C2D12)], // amber
    [Color(0xFF0E7490), Color(0xFF155E75)], // cyan
    [Color(0xFFBE123C), Color(0xFF881337)], // rose
    [Color(0xFF334155), Color(0xFF0F172A)], // graphite
  ];
}
