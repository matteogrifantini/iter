import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:iter/app/app_config.dart';
import 'package:iter/features/chat_first_prototype/gemini_ai_service.dart';

void main() {
  group('GeminiAiService', () {
    test(
      'returns offline result when backend is mock or configuration is missing',
      () async {
        const config = AppConfig(
          backend: 'mock',
          supabaseUrl: '',
          supabaseAnonKey: '',
        );
        final service = GeminiAiService(config: config);

        final result = await service.generatePlan(
          operation: 'suggest_destination',
          message: 'Vorrei andare in Portogallo',
        );

        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, contains('Offline'));
      },
    );

    test('parses SSE stream correctly on successful response', () async {
      const config = AppConfig(
        backend: 'supabase',
        supabaseUrl: 'https://test-project.supabase.co',
        supabaseAnonKey: 'test-anon-key',
      );

      final sseBody = [
        'event: stage',
        'data: {"type":"stage","operation":"suggest_destination","message":"Cerco la meta ideale"}',
        '',
        'event: proposal',
        'data: {"type":"proposal","kind":"destination","destination":{"name":"Porto","country":"Portogallo","why":"Città affascinante sul fiume Douro"}}',
        '',
        'event: complete',
        'data: {"type":"complete","draft":{"destination":"Porto","days":[{"dayIndex":1,"title":"Giorno 1 · Arrivo","items":[{"poiId":"p-1","title":"Livraria Lello","category":"cultura","timeSlot":"10:00–12:00","locked":false}]}]}}',
        '',
      ].join('\n');

      final mockClient = MockClient((request) async {
        expect(request.url.path, contains('/functions/v1/plan'));
        expect(request.headers['apikey'], 'test-anon-key');
        expect(request.headers['Authorization'], 'Bearer test-anon-key');
        final decoded = jsonDecode(request.body) as Map<String, dynamic>;
        expect(decoded['operation'], 'suggest_destination');
        return http.Response(
          sseBody,
          200,
          headers: {'content-type': 'text/event-stream; charset=utf-8'},
        );
      });

      final service = GeminiAiService(config: config, httpClient: mockClient);

      final result = await service.generatePlan(
        operation: 'suggest_destination',
        message: 'Vorrei un weekend a Porto',
      );

      if (!result.isSuccess) {
        fail('generatePlan failed with error: ${result.errorMessage}');
      }

      expect(result.isSuccess, isTrue);
      expect(result.destinationName, 'Porto');
      expect(result.destinationCountry, 'Portogallo');
      expect(result.destinationWhy, 'Città affascinante sul fiume Douro');
      expect(result.days.length, 1);
      expect(result.days.first.items.first.title, 'Livraria Lello');
    });

    test('handles HTTP errors gracefully without throwing', () async {
      const config = AppConfig(
        backend: 'supabase',
        supabaseUrl: 'https://test-project.supabase.co',
        supabaseAnonKey: 'test-anon-key',
      );

      final mockClient = MockClient((request) async {
        return http.Response('Rate limit exceeded', 429);
      });

      final service = GeminiAiService(config: config, httpClient: mockClient);

      final result = await service.generatePlan(
        operation: 'suggest_destination',
        message: 'Test query',
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('429'));
    });
  });
}
