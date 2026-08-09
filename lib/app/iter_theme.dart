import 'package:flutter/material.dart';

/// Iter visual world — "Neutro System Blue".
///
/// THESIS: a quiet native travel planner that refuses the travel-brand rut of
/// warm creams and editorial terracotta; this product is a tool on the phone,
/// not a magazine inside it. Neutrals plus one decisive action colour carry
/// the brand.
///
/// OWN-WORLD: iOS-style neutrals (light grouped greys and white, pure-black
/// dark surfaces) with System Blue as the single accent, a hairline separator
/// grammar, no shadows, and Material 3 components toned neutral.
///
/// STORY: the traveller always sees the current decision cleanly; the single
/// blue action is unmistakable, status is quiet, and content (media, maps,
/// the trip) carries the personality.
///
/// FIRST VIEWPORT: light grouped background, white raised surfaces, one blue
/// primary action, ink labels with muted secondary copy; the blue accent never
/// scatters.
///
/// FORM: replacement visual world, pinned by request (App-wide, neutral +
/// System Blue), re-defining the Design System that previously shipped the
/// "Atlante personale" warm palette.
abstract final class IterPalette {
  // Light: iOS system greys. Grouped background, white raised surfaces.
  static const lightCanvas = Color(0xFFF2F2F7);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightRaised = Color(0xFFE9E9EF);
  static const lightInk = Color(0xFF000000);
  static const lightMutedInk = Color(0xFF6C6C70);
  static const systemBlue = Color(0xFF0A52DB);
  static const systemBlueDeep = Color(0xFF0A3C9C);
  static const systemRed = Color(0xFFFF3B30);
  static const systemGreen = Color(0xFF34C759);
  static const lightLine = Color(0xFFD1D1D6);

  // Dark: iOS dark greys, black primary surface.
  static const darkCanvas = Color(0xFF000000);
  static const darkSurface = Color(0xFF1C1C1E);
  static const darkRaised = Color(0xFF2C2C2E);
  static const darkInk = Color(0xFFFFFFFF);
  static const darkMutedInk = Color(0xFFAEAEB2);
  static const darkBlue = Color(0xFF4C8CFF);
  static const darkBlueDeep = Color(0xFF8FB6FF);
  static const darkRed = Color(0xFFFF453A);
  static const darkGreen = Color(0xFF30D158);
  static const darkLine = Color(0xFF3A3A3C);
}

@immutable
class IterColorRoles extends ThemeExtension<IterColorRoles> {
  const IterColorRoles({
    required this.canvas,
    required this.raised,
    required this.mutedInk,
    required this.route,
    required this.routeSignal,
    required this.videoScrim,
  });

  final Color canvas;
  final Color raised;
  final Color mutedInk;
  final Color route;
  final Color routeSignal;
  final Color videoScrim;

  @override
  IterColorRoles copyWith({
    Color? canvas,
    Color? raised,
    Color? mutedInk,
    Color? route,
    Color? routeSignal,
    Color? videoScrim,
  }) {
    return IterColorRoles(
      canvas: canvas ?? this.canvas,
      raised: raised ?? this.raised,
      mutedInk: mutedInk ?? this.mutedInk,
      route: route ?? this.route,
      routeSignal: routeSignal ?? this.routeSignal,
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
      videoScrim: Color.lerp(videoScrim, other.videoScrim, t)!,
    );
  }
}

extension IterThemeContext on BuildContext {
  IterColorRoles get iterColors => Theme.of(this).extension<IterColorRoles>()!;
}

abstract final class IterTheme {
  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final canvas = isDark ? IterPalette.darkCanvas : IterPalette.lightCanvas;
    final surface = isDark ? IterPalette.darkSurface : IterPalette.lightSurface;
    final raised = isDark ? IterPalette.darkRaised : IterPalette.lightRaised;
    final ink = isDark ? IterPalette.darkInk : IterPalette.lightInk;
    final muted = isDark ? IterPalette.darkMutedInk : IterPalette.lightMutedInk;
    final primary = isDark ? IterPalette.darkBlue : IterPalette.systemBlue;
    final secondary = isDark ? IterPalette.darkRed : IterPalette.systemRed;
    final outline = isDark ? IterPalette.darkLine : IterPalette.lightLine;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: isDark ? IterPalette.darkCanvas : Colors.white,
      primaryContainer: isDark
          ? const Color(0xFF17314E)
          : const Color(0xFFDBE6FA),
      onPrimaryContainer: isDark ? IterPalette.darkBlueDeep : IterPalette.systemBlueDeep,
      secondary: secondary,
      onSecondary: isDark ? IterPalette.darkCanvas : Colors.white,
      secondaryContainer: isDark
          ? const Color(0xFF4D2621)
          : const Color(0xFFFDEAEA),
      onSecondaryContainer: isDark
          ? const Color(0xFFFFC7BE)
          : const Color(0xFF92241A),
      tertiary: isDark ? IterPalette.darkGreen : IterPalette.systemGreen,
      onTertiary: IterPalette.darkCanvas,
      error: isDark ? const Color(0xFFFFB3AB) : const Color(0xFFB3261E),
      onError: isDark ? const Color(0xFF7A0008) : Colors.white,
      surface: surface,
      onSurface: ink,
      surfaceContainerLowest: canvas,
      surfaceContainerLow: surface,
      surfaceContainer: raised,
      surfaceContainerHigh: isDark
          ? const Color(0xFF3A3A3C)
          : const Color(0xFFE3E3E9),
      surfaceContainerHighest: isDark
          ? const Color(0xFF45444A)
          : const Color(0xFFDADAE0),
      onSurfaceVariant: muted,
      outline: outline,
      outlineVariant: isDark
          ? const Color(0xFF3A3A3C)
          : const Color(0xFFE5E5EA),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: ink,
      onInverseSurface: surface,
      inversePrimary: isDark ? IterPalette.systemBlue : IterPalette.darkBlue,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      splashFactory: InkSparkle.splashFactory,
      extensions: <ThemeExtension<dynamic>>[
        IterColorRoles(
          canvas: canvas,
          raised: raised,
          mutedInk: muted,
          route: primary,
          routeSignal: secondary,
          videoScrim: const Color(0x52000000),
        ),
      ],
    );

    final textTheme = base.textTheme.copyWith(
      displaySmall: base.textTheme.displaySmall?.copyWith(
        fontSize: 34,
        height: 1.08,
        letterSpacing: -0.6,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      headlineLarge: base.textTheme.headlineLarge?.copyWith(
        fontSize: 28,
        height: 1.12,
        letterSpacing: -0.4,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontSize: 24,
        height: 1.2,
        letterSpacing: -0.2,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
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

    final rounded12 = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
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
          shape: rounded12,
          textStyle: textTheme.labelLarge,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          elevation: 0,
          shape: rounded12,
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape: rounded12,
          side: BorderSide(color: outline),
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: textTheme.bodyMedium?.copyWith(color: muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: rounded12,
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}