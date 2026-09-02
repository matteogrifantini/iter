import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:iter/app/iter_theme.dart';

/// The shared geometry for Iter's replacement visual world.
class IterPageFrame extends StatelessWidget {
  const IterPageFrame({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(24, 20, 24, 112),
    this.maxWidth = 760,
    this.expandHeight = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double maxWidth;
  final bool expandHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : maxWidth;
        final width = math.min(maxWidth, available);
        final horizontal = width <= 360 ? 16.0 : 24.0;
        final resolvedPadding = padding.resolve(Directionality.of(context));
        final height = expandHeight
            ? (constraints.hasBoundedHeight && constraints.maxHeight > 0
                  ? constraints.maxHeight
                  : MediaQuery.sizeOf(context).height)
            : null;
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            key: const Key('iter-page-frame'),
            width: width,
            height: height,
            child: Padding(
              padding: resolvedPadding.copyWith(
                left: math.min(resolvedPadding.left, horizontal),
                right: math.min(resolvedPadding.right, horizontal),
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// A single floating material. Translucency is reserved for chrome and has a
/// solid fallback so dense content remains legible when blur is unavailable.
class IterMaterialSurface extends StatelessWidget {
  const IterMaterialSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.translucent = false,
    this.elevation = 2,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final bool translucent;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final glass =
        Theme.of(context).extension<IterGlassRoles>() ?? const IterGlassRoles();
    final blur = translucent && IterGlassRoles.useBlur(context);
    final material = Material(
      color: blur
          ? colors.surface.withValues(alpha: glass.tintAlpha)
          : colors.surfaceContainerLow,
      elevation: elevation,
      shadowColor: colors.shadow.withValues(alpha: .12),
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: BorderSide(
          color: colors.outlineVariant.withValues(alpha: glass.borderAlpha),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding, child: child),
    );
    final content = blur
        ? ClipRRect(
            borderRadius: borderRadius,
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: glass.blurSigma,
                sigmaY: glass.blurSigma,
              ),
              child: material,
            ),
          )
        : material;
    return content;
  }
}

class IterSectionHeading extends StatelessWidget {
  const IterSectionHeading({
    super.key,
    required this.title,
    this.eyebrow,
    this.trailing,
  });

  final String title;
  final String? eyebrow;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final titleWidget = Text(
      title,
      style: Theme.of(context).textTheme.headlineLarge,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (eyebrow != null) ...<Widget>[
                Text(
                  eyebrow!,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 6),
              ],
              titleWidget,
            ],
          ),
        ),
        if (trailing != null) ...<Widget>[const SizedBox(width: 12), trailing!],
      ],
    );
  }
}

class IterRouteDivider extends StatelessWidget {
  const IterRouteDivider({super.key, required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      key: Key(active ? 'iter-route-divider-active' : 'iter-route-divider'),
      width: 24,
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 1,
              height: double.infinity,
              color: colors.outlineVariant.withValues(alpha: .8),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: active ? colors.primary : colors.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: active ? colors.primary : colors.outline,
                width: active ? 0 : 1.5,
              ),
            ),
            child: SizedBox(width: active ? 12 : 10, height: active ? 12 : 10),
          ),
        ],
      ),
    );
  }
}
