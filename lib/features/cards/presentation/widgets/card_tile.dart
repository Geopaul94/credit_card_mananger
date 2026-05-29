import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/ui/responsive_layout.dart';
import '../../domain/entities/payment_card.dart';
import '../bloc/card_overview/card_overview_bloc.dart';
import '../pages/card_detail_screen/card_detail_screen.dart';

const double _kCardHeight = 220;

// ─── Card tile — shows the front face, tap opens detail screen ────────────────

class CardTile extends StatelessWidget {
  const CardTile({required this.card, this.isPaid = false, super.key});
  final PaymentCard card;
  final bool isPaid;

  List<Color> get _gradientColors {
    switch (card.typeLabel) {
      case 'Debit':
        return [const Color(0xFF7C3AED), const Color(0xFF5B21B6)];
      case 'Prepaid':
        return [const Color(0xFF059669), const Color(0xFF0D9488)];
      default:
        return [const Color(0xFF1D4ED8), const Color(0xFF4F46E5)];
    }
  }

  void _openDetail(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (ctx, anim, _) => BlocProvider.value(
          value: context.read<CardOverviewBloc>(),
          child: CardDetailScreen(card: card),
        ),
        transitionsBuilder: (ctx, anim, _, child) {
          final curved =
              CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.06),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 380),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.spacing(16)),
      child: GestureDetector(
        onTap: () => _openDetail(context),
        child: _CardFront(
          card: card,
          gradientColors: _gradientColors,
          isPaid: isPaid,
        ),
      ),
    );
  }
}

// ─── Card front widget (used here and in CardDetailScreen) ────────────────────

class CardFrontFace extends StatelessWidget {
  const CardFrontFace({
    required this.card,
    required this.gradientColors,
    this.isPaid = false,
    super.key,
  });

  final PaymentCard card;
  final List<Color> gradientColors;
  final bool isPaid;

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
          // Bank name + type badge + paid badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  card.bankName ?? card.typeLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (isPaid)
                _Badge(
                  label: 'Paid ✓',
                  color: Colors.greenAccent,
                  bg: Colors.green.withValues(alpha: 0.3),
                )
              else
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
          // Holder + expiry + tap hint
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Column(
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
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
                  const SizedBox(width: 12),
                  // Tap-hint eye icon
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.remove_red_eye_outlined,
                      color: Colors.white,
                      size: 17,
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

// ─── Private alias used internally by CardTile ────────────────────────────────

class _CardFront extends CardFrontFace {
  const _CardFront({
    required super.card,
    required super.gradientColors,
    super.isPaid,
  });
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

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

class _Badge extends StatelessWidget {
  const _Badge(
      {required this.label, required this.color, required this.bg});
  final String label;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontWeight: FontWeight.w700, fontSize: 11),
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
        gradient: LinearGradient(
          colors: [Colors.amber.shade200, Colors.amber.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(5),
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
    canvas.drawLine(Offset(0, size.height * 0.33),
        Offset(size.width, size.height * 0.33), paint);
    canvas.drawLine(Offset(0, size.height * 0.66),
        Offset(size.width, size.height * 0.66), paint);
    canvas.drawLine(Offset(size.width * 0.5, 0),
        Offset(size.width * 0.5, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
