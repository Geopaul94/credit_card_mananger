import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/ui/responsive_layout.dart';
import '../../domain/entities/payment_card.dart';

class CardTile extends StatefulWidget {
  const CardTile({required this.card, super.key});

  final PaymentCard card;

  @override
  State<CardTile> createState() => _CardTileState();
}

class _CardTileState extends State<CardTile> {
  bool _showNumber = false;
  bool _showCvv = false;

  List<Color> get _gradientColors {
    switch (widget.card.typeLabel) {
      case 'Debit':
        return [const Color(0xFF7C3AED), const Color(0xFF5B21B6)];
      case 'Prepaid':
        return [const Color(0xFF059669), const Color(0xFF0D9488)];
      default:
        return [const Color(0xFF1D4ED8), const Color(0xFF4F46E5)];
    }
  }

  void _copy(String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('$label copied to clipboard'),
            ],
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    return Padding(
      padding: EdgeInsets.only(bottom: context.spacing(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardFace(
            card: card,
            gradientColors: _gradientColors,
            showNumber: _showNumber,
            onToggleNumber: () =>
                setState(() => _showNumber = !_showNumber),
            onCopyNumber: () =>
                _copy(card.formattedNumber, 'Card number'),
          ),
          const SizedBox(height: 8),
          _CardDetailStrip(
            card: card,
            showCvv: _showCvv,
            onToggleCvv: () => setState(() => _showCvv = !_showCvv),
            onCopyCvv: () => _copy(card.cvv, 'CVV'),
            onCopyExpiry: () => _copy(card.expiryDate, 'Expiry date'),
            onCopyHolder: () => _copy(card.holderName, 'Card holder name'),
          ),
        ],
      ),
    );
  }
}

// ─── Card face ───────────────────────────────────────────────────────────────

class _CardFace extends StatelessWidget {
  const _CardFace({
    required this.card,
    required this.gradientColors,
    required this.showNumber,
    required this.onToggleNumber,
    required this.onCopyNumber,
  });

  final PaymentCard card;
  final List<Color> gradientColors;
  final bool showNumber;
  final VoidCallback onToggleNumber;
  final VoidCallback onCopyNumber;

  String _masked(String digits) {
    final d = digits.replaceAll(RegExp(r'\D'), '');
    if (d.length < 4) return '**** **** **** ****';
    return '**** **** **** ${d.substring(d.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final displayNumber =
        showNumber ? card.formattedNumber : _masked(card.cardNumber);

    return Container(
      height: 198,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: bank name + type badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  card.bankName ?? card.typeLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    letterSpacing: 0.4,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    card.typeLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // EMV chip
            Container(
              width: 36,
              height: 26,
              decoration: BoxDecoration(
                color: Colors.amber.shade300,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            const SizedBox(height: 14),
            // Card number + eye + copy
            Row(
              children: [
                Expanded(
                  child: Text(
                    displayNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      letterSpacing: 2.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _CardIconButton(
                  icon: showNumber
                      ? Icons.visibility_off
                      : Icons.visibility,
                  onTap: onToggleNumber,
                  tooltip: showNumber ? 'Hide number' : 'Show number',
                ),
                const SizedBox(width: 4),
                _CardIconButton(
                  icon: Icons.copy,
                  onTap: onCopyNumber,
                  tooltip: 'Copy card number',
                ),
              ],
            ),
            const Spacer(),
            // Holder name + expiry
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  card.holderName.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'VALID THRU  ${card.expiryDate}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Detail strip below card ─────────────────────────────────────────────────

class _CardDetailStrip extends StatelessWidget {
  const _CardDetailStrip({
    required this.card,
    required this.showCvv,
    required this.onToggleCvv,
    required this.onCopyCvv,
    required this.onCopyExpiry,
    required this.onCopyHolder,
  });

  final PaymentCard card;
  final bool showCvv;
  final VoidCallback onToggleCvv;
  final VoidCallback onCopyCvv;
  final VoidCallback onCopyExpiry;
  final VoidCallback onCopyHolder;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          // CVV row
          _DetailRow(
            icon: Icons.lock_outline,
            label: 'CVV',
            value: showCvv ? card.cvv : '•••',
            valueLetterSpacing: showCvv ? 2 : 3,
            trailingWidgets: [
              _StripIconButton(
                icon: showCvv ? Icons.visibility_off : Icons.visibility,
                tooltip: showCvv ? 'Hide CVV' : 'Show CVV',
                onTap: onToggleCvv,
              ),
              _StripIconButton(
                icon: Icons.copy,
                tooltip: 'Copy CVV',
                onTap: onCopyCvv,
              ),
            ],
          ),
          Divider(height: 1, color: scheme.outline.withValues(alpha: 0.08)),
          // Expiry row
          _DetailRow(
            icon: Icons.calendar_month_outlined,
            label: 'Expiry',
            value: card.expiryDate,
            valueLetterSpacing: 1.5,
            trailingWidgets: [
              _StripIconButton(
                icon: Icons.copy,
                tooltip: 'Copy expiry',
                onTap: onCopyExpiry,
              ),
            ],
          ),
          Divider(height: 1, color: scheme.outline.withValues(alpha: 0.08)),
          // Holder name row
          _DetailRow(
            icon: Icons.person_outline,
            label: 'Holder',
            value: card.holderName,
            valueLetterSpacing: 0.3,
            trailingWidgets: [
              _StripIconButton(
                icon: Icons.copy,
                tooltip: 'Copy name',
                onTap: onCopyHolder,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.trailingWidgets,
    this.valueLetterSpacing = 0,
  });

  final IconData icon;
  final String label;
  final String value;
  final double valueLetterSpacing;
  final List<Widget> trailingWidgets;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 15, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            '$label  ',
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
                letterSpacing: valueLetterSpacing,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ...trailingWidgets,
        ],
      ),
    );
  }
}

// ─── Shared icon button styles ────────────────────────────────────────────────

class _CardIconButton extends StatelessWidget {
  const _CardIconButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, color: Colors.white70, size: 18),
        ),
      ),
    );
  }
}

class _StripIconButton extends StatelessWidget {
  const _StripIconButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 16, color: scheme.primary),
        ),
      ),
    );
  }
}
