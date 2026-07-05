import 'package:flutter/material.dart';

/// A "swipe right to confirm" slider. Used to mark a card's bill as paid.
class SwipeToConfirm extends StatefulWidget {
  const SwipeToConfirm({
    required this.onConfirmed,
    this.label = 'Swipe right to mark as Paid',
    super.key,
  });

  final VoidCallback onConfirmed;
  final String label;

  @override
  State<SwipeToConfirm> createState() => _SwipeToConfirmState();
}

class _SwipeToConfirmState extends State<SwipeToConfirm>
    with SingleTickerProviderStateMixin {
  static const double _thumbW = 54.0;
  static const double _trackH = 62.0;
  static const double _margin = 5.0;

  double _progress = 0.0; // 0.0 → 1.0
  bool _done = false;

  late final AnimationController _snapCtrl;
  late Animation<double> _snapAnim;

  @override
  void initState() {
    super.initState();
    _snapCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 320));
  }

  @override
  void dispose() {
    _snapCtrl.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails d, double maxDrag) {
    if (_done) return;
    _snapCtrl.stop();
    setState(() {
      _progress =
          ((_progress * maxDrag) + d.delta.dx).clamp(0.0, maxDrag) / maxDrag;
    });
  }

  void _onDragEnd(DragEndDetails d, double maxDrag) {
    if (_done) return;
    if (_progress >= 0.78) {
      setState(() {
        _progress = 1.0;
        _done = true;
      });
      widget.onConfirmed();
    } else {
      // Snap back with spring
      _snapAnim = Tween<double>(begin: _progress, end: 0.0).animate(
        CurvedAnimation(parent: _snapCtrl, curve: Curves.easeOutCubic),
      )..addListener(() => setState(() => _progress = _snapAnim.value));
      _snapCtrl.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final maxDrag = constraints.maxWidth - _thumbW - _margin * 2;

      return GestureDetector(
        onHorizontalDragUpdate: (d) => _onDragUpdate(d, maxDrag),
        onHorizontalDragEnd: (d) => _onDragEnd(d, maxDrag),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: _trackH,
          decoration: BoxDecoration(
            color: _done
                ? Colors.green.withValues(alpha: 0.15)
                : Color.lerp(
                    Colors.green.withValues(alpha: 0.06),
                    Colors.green.withValues(alpha: 0.18),
                    _progress,
                  ),
            borderRadius: BorderRadius.circular(_trackH / 2),
            border: Border.all(
              color: Color.lerp(
                Colors.green.withValues(alpha: 0.25),
                Colors.green.withValues(alpha: 0.55),
                _progress,
              )!,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Track hint text
              if (!_done)
                Opacity(
                  opacity: (1.0 - _progress * 1.8).clamp(0.0, 1.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 50), // offset for thumb
                      Icon(Icons.check_circle_outline,
                          size: 16, color: Colors.green.shade600),
                      const SizedBox(width: 6),
                      Text(
                        widget.label,
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

              // Draggable thumb
              if (!_done)
                Positioned(
                  left: _margin + _progress * maxDrag,
                  child: Container(
                    width: _thumbW,
                    height: _thumbW,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color.lerp(Colors.green.shade400,
                              Colors.green.shade600, _progress)!,
                          Color.lerp(Colors.green.shade500,
                              Colors.green.shade800, _progress)!,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withValues(
                              alpha: 0.3 + _progress * 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      _progress > 0.6 ? Icons.check : Icons.chevron_right,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}
