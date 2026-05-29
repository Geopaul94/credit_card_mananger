import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/ui/responsive_layout.dart';
import '../../domain/entities/payment_card.dart';

// ─── Card height constant shared between front and back ───────────────────────
const double _kCardHeight = 200;

class CardTile extends StatefulWidget {
  const CardTile({required this.card, super.key});
  final PaymentCard card;

  @override
  State<CardTile> createState() => _CardTileState();
}

class _CardTileState extends State<CardTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _flipAnim;
  bool _showFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _flipAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _flipAnim.addListener(() {
      final nowFront = _flipAnim.value <= 0.5;
      if (nowFront != _showFront) setState(() => _showFront = nowFront);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flip() {
    if (_controller.isAnimating) return;
    _controller.isDismissed ? _controller.forward() : _controller.reverse();
  }

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
          content: Row(children: [
            const Icon(Icons.check_circle_outline,
                color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('$label copied'),
          ]),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.spacing(16)),
      child: GestureDetector(
        onTap: _flip,
        child: AnimatedBuilder(
          animation: _flipAnim,
          builder: (context, _) {
            final angle = _flipAnim.value * math.pi;
            return Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001) // perspective
                ..rotateY(angle),
              alignment: Alignment.center,
              child: _showFront
                  ? _CardFront(
                      card: widget.card,
                      gradientColors: _gradientColors,
                      onFlip: _flip,
                    )
                  : Transform(
                      // counter-rotate the back so text isn't mirrored
                      transform: Matrix4.identity()..rotateY(math.pi),
                      alignment: Alignment.center,
                      child: _CardBack(
                        card: widget.card,
                        gradientColors: _gradientColors,
                        onFlip: _flip,
                        onCopy: _copy,
                      ),
                    ),
            );
          },
        ),
      ),
    );
  }
}

// ─── FRONT ────────────────────────────────────────────────────────────────────

class _CardFront extends StatelessWidget {
  const _CardFront({
    required this.card,
    required this.gradientColors,
    required this.onFlip,
  });

  final PaymentCard card;
  final List<Color> gradientColors;
  final VoidCallback onFlip;

  String get _masked {
    final d = card.cardNumber.replaceAll(RegExp(r'\D'), '');
    final last4 = d.length >= 4 ? d.substring(d.length - 4) : d;
    return '**** **** **** $last4';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _kCardHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: 0.4),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bank name + type badge
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
              _TypeBadge(label: card.typeLabel),
            ],
          ),
          const SizedBox(height: 16),
          // EMV chip
          _ChipIcon(),
          const SizedBox(height: 16),
          // Masked card number
          Text(
            _masked,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              letterSpacing: 2.8,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          // Holder + expiry + eye button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'CARD HOLDER',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 9,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    card.holderName.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'VALID THRU',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 9,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        card.expiryDate,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  // Eye / flip button
                  GestureDetector(
                    onTap: onFlip,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.remove_red_eye_outlined,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── BACK ─────────────────────────────────────────────────────────────────────

class _CardBack extends StatefulWidget {
  const _CardBack({
    required this.card,
    required this.gradientColors,
    required this.onFlip,
    required this.onCopy,
  });

  final PaymentCard card;
  final List<Color> gradientColors;
  final VoidCallback onFlip;
  final void Function(String value, String label) onCopy;

  @override
  State<_CardBack> createState() => _CardBackState();
}

class _CardBackState extends State<_CardBack> {
  bool _showCvv = false;
  bool _showNumber = false;

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final last4 = card.cardNumber.replaceAll(RegExp(r'\D'), '');
    final maskedNum = last4.length >= 4
        ? '**** **** **** ${last4.substring(last4.length - 4)}'
        : '****';

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: _kCardHeight,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: widget.gradientColors,
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.gradientColors.last.withValues(alpha: 0.4),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Magnetic stripe ──────────────────────────────────────────
            Container(
              height: 42,
              color: const Color(0xFF111827),
            ),

            // ── Signature strip with CVV ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  children: [
                    // Signature lines
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(
                          3,
                          (_) => Container(
                            height: 1,
                            color: Colors.grey.shade300,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'CVV',
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _showCvv ? card.cvv : '•••',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(width: 4),
                    _SmallIconBtn(
                      icon: _showCvv
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey.shade500,
                      onTap: () =>
                          setState(() => _showCvv = !_showCvv),
                    ),
                    _SmallIconBtn(
                      icon: Icons.copy,
                      color: Colors.grey.shade500,
                      onTap: () => widget.onCopy(card.cvv, 'CVV'),
                    ),
                  ],
                ),
              ),
            ),

            // ── Card details ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                children: [
                  _BackRow(
                    label: 'Number',
                    value: _showNumber ? card.formattedNumber : maskedNum,
                    onCopy: () =>
                        widget.onCopy(card.formattedNumber, 'Card number'),
                    extraAction: _SmallIconBtn(
                      icon: _showNumber
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.white70,
                      onTap: () =>
                          setState(() => _showNumber = !_showNumber),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _BackRow(
                    label: 'Expiry',
                    value: card.expiryDate,
                    onCopy: () =>
                        widget.onCopy(card.expiryDate, 'Expiry date'),
                  ),
                  const SizedBox(height: 8),
                  _BackRow(
                    label: 'Holder',
                    value: card.holderName,
                    onCopy: () =>
                        widget.onCopy(card.holderName, 'Holder name'),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // ── Flip-back hint ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(right: 16, bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: widget.onFlip,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.flip, color: Colors.white70, size: 13),
                          SizedBox(width: 5),
                          Text(
                            'flip back',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
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

// ─── Back detail row ──────────────────────────────────────────────────────────

class _BackRow extends StatelessWidget {
  const _BackRow({
    required this.label,
    required this.value,
    required this.onCopy,
    this.extraAction,
  });

  final String label;
  final String value;
  final VoidCallback onCopy;
  final Widget? extraAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (extraAction != null) ...[
          extraAction!,
          const SizedBox(width: 2),
        ],
        _SmallIconBtn(
          icon: Icons.copy,
          color: Colors.white60,
          onTap: onCopy,
        ),
      ],
    );
  }
}

// ─── Shared small helpers ─────────────────────────────────────────────────────

class _SmallIconBtn extends StatelessWidget {
  const _SmallIconBtn({
    required this.icon,
    required this.onTap,
    required this.color,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _ChipIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 26,
      decoration: BoxDecoration(
        color: Colors.amber.shade300,
        borderRadius: BorderRadius.circular(5),
        gradient: LinearGradient(
          colors: [Colors.amber.shade200, Colors.amber.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: CustomPaint(painter: _ChipPainter()),
    );
  }
}

class _ChipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.amber.shade600
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    // Horizontal lines
    canvas.drawLine(Offset(0, size.height * 0.33),
        Offset(size.width, size.height * 0.33), paint);
    canvas.drawLine(Offset(0, size.height * 0.66),
        Offset(size.width, size.height * 0.66), paint);
    // Vertical center line
    canvas.drawLine(Offset(size.width * 0.5, 0),
        Offset(size.width * 0.5, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
