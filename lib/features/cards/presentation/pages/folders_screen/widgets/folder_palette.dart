import 'package:flutter/material.dart';

/// Preset color themes and icons for Card Folders.
class FolderPalette {
  FolderPalette._();

  /// Curated fintech gradient themes for folders.
  static const List<List<Color>> gradients = [
    // 0: Deep Indigo / Violet (Default)
    [Color(0xFF4F46E5), Color(0xFF7C3AED)],
    // 1: Emerald / Forest
    [Color(0xFF059669), Color(0xFF0D9488)],
    // 2: Royal Sapphire / Azure
    [Color(0xFF2563EB), Color(0xFF0284C7)],
    // 3: Sunset Amber / Coral
    [Color(0xFFD97706), Color(0xFFEA580C)],
    // 4: Rose Ruby / Magenta
    [Color(0xFFE11D48), Color(0xFFC026D3)],
    // 5: Obsidian / Slate Titanium
    [Color(0xFF334155), Color(0xFF1E293B)],
    // 6: Midnight Purple / Neon
    [Color(0xFF7E22CE), Color(0xFF4338CA)],
    // 7: Ocean Teal / Mint
    [Color(0xFF0F766E), Color(0xFF0284C7)],
  ];

  static List<Color> gradientFor(int index) {
    if (index < 0 || index >= gradients.length) {
      return gradients.first;
    }
    return gradients[index];
  }

  /// Available folder icons with readable labels.
  static const Map<String, ({IconData icon, String label})> icons = {
    'folder': (icon: Icons.folder_rounded, label: 'Default'),
    'wallet': (icon: Icons.account_balance_wallet_rounded, label: 'Wallet'),
    'flight': (icon: Icons.flight_takeoff_rounded, label: 'Travel'),
    'shopping': (icon: Icons.shopping_bag_rounded, label: 'Shopping'),
    'work': (icon: Icons.business_center_rounded, label: 'Business'),
    'home': (icon: Icons.home_rounded, label: 'Home & Bills'),
    'star': (icon: Icons.star_rounded, label: 'Favorites'),
    'shield': (icon: Icons.security_rounded, label: 'Secure Vault'),
    'receipt': (icon: Icons.receipt_long_rounded, label: 'Expenses'),
  };

  static IconData iconFor(String? key) {
    if (key != null && icons.containsKey(key)) {
      return icons[key]!.icon;
    }
    return Icons.folder_rounded;
  }
}
