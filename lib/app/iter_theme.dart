import 'package:flutter/material.dart';

/// Iter visual world — "Rotta viva": an orientation system for a route that
/// becomes possible one confirmed signal at a time.
abstract final class IterPalette {
  static const lightCanvas = Color(0xFFF9F7EF);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightRaised = Color(0xFFF0EEE6);
  static const lightInk = Color(0xFF18204B);
  static const lightMutedInk = Color(0xFF4D567E);
  static const lightRoute = Color(0xFF2D63FF);
  static const lightRouteDeep = Color(0xFF183CBA);
  static const lightSignal = Color(0xFFFF5C42);
  static const possibility = Color(0xFFE7FF67);
  static const lightLine = Color(0xFF70799E);

  static const darkCanvas = Color(0xFF0B1028);
  static const darkSurface = Color(0xFF141C3B);
  static const darkRaised = Color(0xFF1D2750);
  static const darkInk = Color(0xFFF9F7EF);
  static const darkMutedInk = Color(0xFFC7CEE4);
  static const darkRoute = Color(0xFF7EA0FF);
  static const darkRouteDeep = Color(0xFFDDE6FF);
  static const darkSignal = Color(0xFFFF7A63);
  static const darkLine = Color(0xFFB7C1E8);

  static const lightError = Color(0xFFB3261E);
  static const darkError = Color(0xFFFFB4AB);
  static const darkOnError = Color(0xFF690005);
}

@immutable
class IterColorRoles extends ThemeExtension<IterColorRoles> {
  const IterColorRoles({
    required this.canvas,
    required this.raised,
    required this.mutedInk,
    required this.route,
    required this.routeSignal,
    required this.possibility,
    required this.videoScrim,
  });

  final Color canvas;
  final Color raised;
  final Color mutedInk;
  final Color route;
  final Color routeSignal;
  final Color possibility;
  final Color videoScrim;

  @override
  IterColorRoles copyWith({
    Color? canvas,
    Color? raised,
    Color? mutedInk,
    Color? route,
    Color? routeSignal,
    Color? possibility,
    Color? videoScrim,
  }) {
    return IterColorRoles(
      canvas: canvas ?? this.canvas,
      raised: raised ?? this.raised,
      mutedInk: mutedInk ?? this.mutedInk,
      route: route ?? this.route,
      routeSignal: routeSignal ?? this.routeSignal,
      possibility: possibility ?? this.possibility,
      videoScrim: videoScrim ?? this.videoScrim,
    );
  }

  @override
  IterColorRoles lerp(ThemeExtension<IterColorRoles>? other, double t) {
    if (other is! IterColorRoles) return this;
    return IterColorRoles(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      raised: Color.lerp(raised, other.raised, t)!,
      mutedInk: Color.lerp(mutedInk, other.mutedInk, t)!,
      route: Color.lerp(route, other.route, t)!,
      routeSignal: Color.lerp(routeSignal, other.routeSignal, t)!,
      possibility: Color.lerp(possibility, other.possibility, t)!,
      videoScrim: Color.lerp(videoScrim, other.videoScrim, t)!,
    );
  }
}

extension IterThemeContext on BuildContext {
  IterColorRoles get iterColors => Theme.of(this).extension<IterColorRoles>()!;
}

abstract final class IterTheme {
  static const _bodyFontFamily = 'Figtree';
  static const _displayFontFamily = 'BricolageGrotesque';

  static const wordmarkTextStyle = TextStyle(
    fontFamily: _displayFontFamily,
    fontSize: 25,
    height: 1,
    letterSpacing: -0.8,
    fontWeight: FontWeight.w800,
  );

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final canvas = isDark ? IterPalette.darkCanvas : IterPalette.lightCanvas;
    final surface = isDark ? IterPalette.darkSurface : IterPalette.lightSurface;
    final raised = isDark ? IterPalette.darkRaised : IterPalette.lightRaised;
    final ink = isDark ? IterPalette.darkInk : IterPalette.lightInk;
    final muted = isDark ? IterPalette.darkMutedInk : IterPalette.lightMutedInk;
    final primary = isDark ? IterPalette.darkRoute : IterPalette.lightRoute;
    final secondary = isDark ? IterPalette.darkSignal : IterPalette.lightSignal;
    final outline = isDark ? IterPalette.darkLine : IterPalette.lightLine;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: isDark ? IterPalette.darkCanvas : Colors.white,
      primaryContainer: isDark
          ? const Color(0xFF294690)
          : const Color(0xFFDDE6FF),
      onPrimaryContainer: isDark
          ? IterPalette.darkRouteDeep
          : IterPalette.lightRouteDeep,
      secondary: secondary,
      onSecondary: IterPalette.lightInk,
      secondaryContainer: isDark
          ? const Color(0xFF613039)
          : const Color(0xFFFFE1D9),
      onSecondaryContainer: isDark
          ? const Color(0xFFFFDAD4)
          : IterPalette.lightInk,
      tertiary: IterPalette.possibility,
      onTertiary: IterPalette.lightInk,
      error: isDark ? IterPalette.darkError : IterPalette.lightError,
      onError: isDark ? IterPalette.darkOnError : Colors.white,
      surface: surface,
      onSurface: ink,
      surfaceContainerLowest: canvas,
      surfaceContainerLow: surface,
      surfaceContainer: raised,
      surfaceContainerHigh: isDark
          ? const Color(0xFF26315E)
          : const Color(0xFFE9E7DF),
      surfaceContainerHighest: isDark
          ? const Color(0xFF303E72)
          : const Color(0xFFE1DFD7),
      onSurfaceVariant: muted,
      outline: outline,
      outlineVariant: isDark
          ? const Color(0xFF4E5E8D)
          : const Color(0xFFC9C7BE),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: isDark ? IterPalette.lightCanvas : IterPalette.lightInk,
      onInverseSurface: isDark ? IterPalette.lightInk : IterPalette.lightCanvas,
      inversePrimary: isDark ? IterPalette.lightRoute : IterPalette.darkRoute,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: _bodyFontFamily,
      scaffoldBackgroundColor: canvas,
      splashFactory: InkSparkle.splashFactory,
      extensions: <ThemeExtension<dynamic>>[
        IterColorRoles(
          canvas: canvas,
          raised: raised,
          mutedInk: muted,
          route: primary,
          routeSignal: secondary,
          possibility: IterPalette.possibility,
          videoScrim: const Color(0x52000000),
        ),
      ],
    );

    final textTheme = base.textTheme
        .apply(fontFamily: _bodyFontFamily)
        .copyWith(
          displayLarge: base.textTheme.displayLarge?.copyWith(
            fontFamily: _displayFontFamily,
            fontSize: 44,
            height: 1.04,
            letterSpacing: -1.2,
            fontWeight: FontWeight.w800,
            color: ink,
          ),
          displayMedium: base.textTheme.displayMedium?.copyWith(
            fontFamily: _displayFontFamily,
            fontSize: 38,
            height: 1.06,
            letterSpacing: -0.8,
            fontWeight: FontWeight.w800,
            color: ink,
          ),
          displaySmall: base.textTheme.displaySmall?.copyWith(
            fontFamily: _displayFontFamily,
            fontSize: 34,
            height: 1.08,
            letterSpacing: -0.6,
            fontWeight: FontWeight.w700,
            color: ink,
          ),
          headlineLarge: base.textTheme.headlineLarge?.copyWith(
            fontFamily: _displayFontFamily,
            fontSize: 28,
            height: 1.12,
            letterSpacing: -0.4,
            fontWeight: FontWeight.w700,
            color: ink,
          ),
          headlineMedium: base.textTheme.headlineMedium?.copyWith(
            fontFamily: _displayFontFamily,
            fontSize: 24,
            height: 1.2,
            letterSpacing: -0.2,
            fontWeight: FontWeight.w700,
            color: ink,
          ),
          headlineSmall: base.textTheme.headlineSmall?.copyWith(
            fontFamily: _displayFontFamily,
            fontSize: 21,
            height: 1.24,
            letterSpacing: -0.1,
            fontWeight: FontWeight.w700,
            color: ink,
          ),
          titleLarge: base.textTheme.titleLarge?.copyWith(
            fontFamily: _displayFontFamily,
            fontSize: 20,
            height: 1.25,
            fontWeight: FontWeight.w700,
            color: ink,
          ),
          titleMedium: base.textTheme.titleMedium?.copyWith(
            fontSize: 17,
            height: 1.3,
            fontWeight: FontWeight.w600,
            color: ink,
          ),
          bodyLarge: base.textTheme.bodyLarge?.copyWith(
            fontSize: 17,
            height: 1.45,
            fontWeight: FontWeight.w400,
            color: ink,
          ),
          bodyMedium: base.textTheme.bodyMedium?.copyWith(
            fontSize: 15,
            height: 1.4,
            color: ink,
          ),
          labelLarge: base.textTheme.labelLarge?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        );

    final rounded14 = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );
    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: canvas,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: surface,
        indicatorColor: scheme.primaryContainer,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return textTheme.labelMedium?.copyWith(
            color: states.contains(WidgetState.selected) ? primary : muted,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: rounded14,
          textStyle: textTheme.labelLarge,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          elevation: 0,
          shape: rounded14,
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape: rounded14,
          side: BorderSide(color: outline),
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: textTheme.bodyMedium?.copyWith(color: muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      chipTheme: ChipThemeData(
        shape: rounded14,
        side: BorderSide(color: outline),
        selectedColor: scheme.primaryContainer,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        labelStyle: textTheme.labelLarge,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: muted,
        textColor: ink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
