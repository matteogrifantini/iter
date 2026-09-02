import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iter/app/iter_theme.dart';

void main() {
  test('glass roles light e dark hanno blur e fallback', () {
    final light = IterTheme.light();
    final dark = IterTheme.dark();
    final lGlass = light.extension<IterGlassRoles>()!;
    final dGlass = dark.extension<IterGlassRoles>()!;
    expect(lGlass.blurSigma, 18.0);
    expect(dGlass.blurSigma, 18.0);
    expect(lGlass.sheetRadius, 28.0);
    expect(lGlass.cardRadius, 24.0);
    expect(lGlass.pillRadius, 20.0);
  });

  testWidgets('useBlur true di default', (tester) async {
    late bool result;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Builder(
          builder: (context) {
            result = IterGlassRoles.useBlur(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(result, isTrue);
  });

  testWidgets('useBlur false con reduced motion', (tester) async {
    late bool result;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Builder(
          builder: (context) {
            result = IterGlassRoles.useBlur(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(result, isFalse);
  });

  testWidgets('useBlur false con high contrast', (tester) async {
    late bool result;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(highContrast: true),
        child: Builder(
          builder: (context) {
            result = IterGlassRoles.useBlur(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(result, isFalse);
  });
}
