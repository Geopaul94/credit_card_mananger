import 'package:flutter/material.dart';

import '../../../../core/ui/responsive_layout.dart';

/// Placeholder shown while cards are being decrypted.
///
/// A spinner says "something is happening"; a skeleton says "your cards are
/// about to appear here", which makes the same wait feel shorter and stops
/// the layout jumping when real content lands.
class CardListSkeleton extends StatefulWidget {
  const CardListSkeleton({this.itemCount = 2, super.key});
  final int itemCount;

  @override
  State<CardListSkeleton> createState() => _CardListSkeletonState();
}

class _CardListSkeletonState extends State<CardListSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return IgnorePointer(
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          context.spacing(16),
          context.spacing(16),
          context.spacing(16),
          context.spacing(96),
        ),
        children: [
          _Block(height: 118, radius: 20, pulse: _pulse, scheme: scheme),
          SizedBox(height: context.spacing(20)),
          for (var i = 0; i < widget.itemCount; i++) ...[
            _Block(height: 220, radius: 20, pulse: _pulse, scheme: scheme),
            SizedBox(height: context.spacing(16)),
          ],
        ],
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({
    required this.height,
    required this.radius,
    required this.pulse,
    required this.scheme,
  });

  final double height;
  final double radius;
  final Animation<double> pulse;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, _) {
        return Container(
          height: height,
          decoration: BoxDecoration(
            color: Color.lerp(
              scheme.surfaceContainerHigh,
              scheme.surfaceContainerHighest,
              pulse.value,
            ),
            borderRadius: BorderRadius.circular(radius),
          ),
        );
      },
    );
  }
}
