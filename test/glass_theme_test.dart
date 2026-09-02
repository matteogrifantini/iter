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
}
