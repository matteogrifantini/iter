import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:iter/features/translator/translator_service.dart';

void main() {
  group('TravelTranslatorService', () {
    test('returns language profile and essential phrases for Budapest', () {
      final service = TravelTranslatorService();
      final profile = service.getLanguageForDestination('Budapest');

      expect(profile.code, 'hu');
      expect(profile.name, contains('Ungherese'));
      expect(profile.phrases.any((p) => p.italian.contains('Grazie')), isTrue);
    });

    test('translates text using live translation API', () async {
      final mockJson = '''
      {
        "responseData": {
          "translatedText": "Jó napot"
        },
        "responseStatus": 200
      }
      ''';

      final mockClient = MockClient((request) async {
        return http.Response(
          mockJson,
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = TravelTranslatorService(httpClient: mockClient);
      final translated = await service.translateText('Buongiorno', 'hu');

      expect(translated, 'Jó napot');
    });
  });
}
