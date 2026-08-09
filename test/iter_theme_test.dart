import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:iter/app/iter_theme.dart';

void main() {
  test('Rotta viva themes expose their semantic palette and typography', () {
    final light = IterTheme.light();
    final dark = IterTheme.dark();

    expect(light.scaffoldBackgroundColor, const Color(0xFFF9F7EF));
    expect(light.colorScheme.primary, const Color(0xFF2D63FF));
    expect(dark.scaffoldBackgroundColor, const Color(0xFF0B1028));
    expect(dark.colorScheme.surface, const Color(0xFF141C3B));
    expect(dark.colorScheme.onSecondary, const Color(0xFF18204B));
    expect(light.textTheme.bodyMedium?.fontFamily, 'Figtree');
    expect(light.textTheme.headlineLarge?.fontFamily, 'BricolageGrotesque');
    expect(
      light.extension<IterColorRoles>()?.possibility,
      const Color(0xFFE7FF67),
    );
  });

  test(
    'possibility remains available through IterColorRoles copy and lerp',
    () {
      const start = IterColorRoles(
        canvas: Color(0xFF000000),
        raised: Color(0xFF111111),
        mutedInk: Color(0xFF222222),
        route: Color(0xFF333333),
        routeSignal: Color(0xFF444444),
        possibility: Color(0xFF555555),
        videoScrim: Color(0xFF666666),
      );
      const end = Color(0xFF777777);

      expect(start.copyWith(possibility: end).possibility, end);
      expect(start.lerp(start.copyWith(possibility: end), 1).possibility, end);
    },
  );
}
