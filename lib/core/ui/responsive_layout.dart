import 'package:flutter/widgets.dart';

extension ResponsiveLayoutX on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;

  bool get isTablet => screenWidth >= 600;

  double spacing(double mobileValue, {double? tabletValue}) {
    if (isTablet) {
      return tabletValue ?? mobileValue * 1.35;
    }
    return mobileValue;
  }

  double font(double mobileValue, {double? tabletValue}) {
    if (isTablet) {
      return tabletValue ?? mobileValue * 1.2;
    }
    return mobileValue;
  }

  double get contentMaxWidth => isTablet ? 720 : 560;
}

class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: context.contentMaxWidth),
        child: child,
      ),
    );
  }
}
