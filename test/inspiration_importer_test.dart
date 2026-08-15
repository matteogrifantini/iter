import 'package:flutter_test/flutter_test.dart';
import 'package:iter/features/chat_first_prototype/inspiration_importer.dart';
import 'package:iter/features/chat_first_prototype/inspiration_models.dart';

void main() {
  test('mock importer extracts Instagram and TikTok fixtures', () {
    final instagram = parseMockInspiration(
      'https://www.instagram.com/reel/iter-porto',
    );
    final tiktok = parseMockInspiration(
      'https://www.tiktok.com/@iter/roma-foro',
    );

    expect(instagram.isValid, isTrue);
    expect(instagram.draft?.platform, InspirationPlatform.instagram);
    expect(instagram.draft?.destinationId, 'porto');
    expect(tiktok.draft?.platform, InspirationPlatform.tiktok);
    expect(tiktok.draft?.destinationId, 'roma');
  });

  test('mock importer rejects non-approved links without network access', () {
    final unsupported = parseMockInspiration('https://example.com/video');
    final insecure = parseMockInspiration(
      'http://www.instagram.com/reel/iter-porto',
    );
    final empty = parseMockInspiration('  ');

    expect(unsupported.draft, isNull);
    expect(unsupported.errorMessage, isNotEmpty);
    expect(insecure.isValid, isFalse);
    expect(empty.isValid, isFalse);
  });
}
