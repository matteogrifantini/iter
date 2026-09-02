import 'package:flutter/material.dart';
import 'package:iter/app/iter_theme.dart';
import 'iter_ui_primitives.dart';

class IterGlassBar extends StatelessWidget {
  const IterGlassBar({super.key, required this.child, this.padding = const EdgeInsets.all(12)});
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final glass = Theme.of(context).extension<IterGlassRoles>() ?? const IterGlassRoles();
    return IterMaterialSurface(
      key: const Key('iter-glass-bar'),
      padding: padding,
      borderRadius: BorderRadius.circular(glass.pillRadius),
      translucent: true,
      child: child,
    );
  }
}

class IterGlassSheet extends StatelessWidget {
  const IterGlassSheet({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final glass = Theme.of(context).extension<IterGlassRoles>() ?? const IterGlassRoles();
    return IterMaterialSurface(
      key: const Key('iter-glass-sheet'),
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(glass.sheetRadius),
      translucent: true,
      child: child,
    );
  }
}

class IterHeroScrim extends StatelessWidget {
  const IterHeroScrim({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final glass = Theme.of(context).extension<IterGlassRoles>() ?? const IterGlassRoles();
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.0),
            Colors.black.withValues(alpha: glass.scrimAlpha),
          ],
        ),
      ),
      child: child,
    );
  }
}
