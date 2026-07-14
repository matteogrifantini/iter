import 'package:flutter/material.dart';

abstract final class IterPalette {
  // Light: neutral daylight with a subtle petrol bias, never cream.
  static const lightCanvas = Color(0xFFF4F7F7);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightRaised = Color(0xFFE8EFF0);
  static const lightInk = Color(0xFF10191B);
  static const lightMutedInk = Color(0xFF45585C);
  static const petrol = Color(0xFF075866);
  static const petrolPressed = Color(0xFF003F4B);
  static const vermilion = Color(0xFFC84833);
  static const mintSignal = Color(0xFF56C9B2);
  static const lightLine = Color(0xFFB8C7CA);

  // Dark: its own surface ramp. Depth comes from lightness, not shadows.
  static const darkCanvas = Color(0xFF091113);
  static const darkSurface = Color(0xFF101B1E);
  static const darkRaised = Color(0xFF19292D);
  static const darkInk = Color(0xFFEAF2F3);
  static const darkMutedInk = Color(0xFFA9BBBF);
  static const darkPetrol = Color(0xFF78CBD5);
  static const darkVermilion = Color(0xFFFF8F79);
  static const darkLine = Color(0xFF40575C);
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
    final primary = isDark ? IterPalette.darkPetrol : IterPalette.petrol;
    final secondary = isDark
        ? IterPalette.darkVermilion
        : IterPalette.vermilion;
    final outline = isDark ? IterPalette.darkLine : IterPalette.lightLine;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: isDark ? IterPalette.darkCanvas : Colors.white,
      primaryContainer: isDark
          ? const Color(0xFF173D44)
          : const Color(0xFFD1E9EC),
      onPrimaryContainer: isDark ? IterPalette.darkInk : IterPalette.petrol,
      secondary: secondary,
      onSecondary: isDark ? IterPalette.darkCanvas : Colors.white,
      secondaryContainer: isDark
          ? const Color(0xFF43241F)
          : const Color(0xFFFFDDD6),
      onSecondaryContainer: isDark
          ? const Color(0xFFFFDAD2)
          : const Color(0xFF722010),
      tertiary: IterPalette.mintSignal,
      onTertiary: IterPalette.darkCanvas,
      error: isDark ? const Color(0xFFFFB4AB) : const Color(0xFFB3261E),
      onError: isDark ? const Color(0xFF690005) : Colors.white,
      surface: surface,
      onSurface: ink,
      surfaceContainerLowest: canvas,
      surfaceContainerLow: surface,
      surfaceContainer: raised,
      surfaceContainerHigh: isDark
          ? const Color(0xFF223438)
          : const Color(0xFFDCE6E8),
      surfaceContainerHighest: isDark
          ? const Color(0xFF2B4146)
          : const Color(0xFFCEDCDF),
      onSurfaceVariant: muted,
      outline: outline,
      outlineVariant: isDark
          ? const Color(0xFF2F464B)
          : const Color(0xFFD3DFE1),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: ink,
      onInverseSurface: surface,
      inversePrimary: isDark ? IterPalette.petrol : IterPalette.darkPetrol,
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
          videoScrim: const Color(0xA6000000),
        ),
      ],
    );

    final textTheme = base.textTheme.copyWith(
      displaySmall: base.textTheme.displaySmall?.copyWith(
        fontSize: 40,
        height: 1.02,
        letterSpacing: -1.1,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      headlineLarge: base.textTheme.headlineLarge?.copyWith(
        fontSize: 34,
        height: 1.06,
        letterSpacing: -0.8,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontSize: 28,
        height: 1.1,
        letterSpacing: -0.5,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontSize: 21,
        height: 1.2,
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
        height: 1.48,
        fontWeight: FontWeight.w400,
        color: ink,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        fontSize: 15,
        height: 1.45,
        color: ink,
      ),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w700,
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
      chipTheme: ChipThemeData(
        shape: rounded14,
        side: BorderSide(color: outline),
        selectedColor: scheme.primaryContainer,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        labelStyle: textTheme.labelLarge,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
      ),
    );
  }
}
