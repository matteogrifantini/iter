import 'package:flutter/material.dart';

class NewTripSimpleOptionGrid extends StatelessWidget {
  const NewTripSimpleOptionGrid({
    super.key,
    required this.children,
    this.spacing = 10,
  });

  final List<Widget> children;
  final double spacing;

  static bool usesSingleColumn(BuildContext context) {
    final media = MediaQuery.of(context);
    final scaledBody = media.textScaler.scale(16);
    return media.size.width <= 360 || scaledBody > 20;
  }

  @override
  Widget build(BuildContext context) {
    final singleColumn = usesSingleColumn(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = singleColumn
            ? constraints.maxWidth
            : (constraints.maxWidth - spacing) / 2;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}
