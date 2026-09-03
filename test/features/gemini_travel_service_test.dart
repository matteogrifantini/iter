import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:iter/features/ai/gemini_travel_service.dart';

void main() {
  test('GeminiTravelService invia richiesta e mappa risposta strutturata', () async {
    final mockClient = MockClient((request) async {
      expect(request.url.queryParameters['key'], 'test-api-key');
      expect(request.method, 'POST');
      final fakeResponse = {
        'candidates': [
          {
            'content': {
              'parts': [
                {
                  'text': jsonEncode({
                    'message': 'Ecco una bellissima proposta per Madrid!',
                    'destination': 'Madrid',
                    'durationDays': 3,
                    'flight': {
                      'outbound': 'Milano MXP - Madrid MAD',
                      'priceEstimate': '65€',
                      'searchUrl': 'https://www.skyscanner.it/trasporti/voli/mil/mad/'
                    },
                    'neighborhoods': [
                      {
                        'name': 'Malasaña',
                        'why': 'Perfetto per locali alternativi, caffè vintage e tapas autentiche',
                        'searchUrl': 'https://www.booking.com/searchresults.html?ss=Malasana+Madrid'
                      }
                    ],
                    'days': [
                      {
                        'dayNumber': 1,
                        'theme': 'Centro storico e tradizioni',
                        'stops': ['Plaza Mayor', 'Mercado de San Miguel', 'Palazzo Reale'],
                        'diningRecommendation': 'Casa Lucio per uova rotte tipiche'
                      },
                      {
                        'dayNumber': 2,
                        'theme': 'Arte e quartieri vivi',
                        'stops': ['Museo del Prado', 'Parque del Retiro'],
                        'diningRecommendation': 'Mercado de Antón Martín'
                      }
                    ]
                  })
                }
              ]
            }
          }
        ]
      };
      return http.Response.bytes(
        utf8.encode(jsonEncode(fakeResponse)),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );


    });

    final service = GeminiTravelService(apiKey: 'test-api-key', client: mockClient);
    final result = await service.generateTripAdvice('Vorrei 3 giorni a Madrid con buon cibo');
    
    expect(result.destination, 'Madrid');
    expect(result.durationDays, 3);
    expect(result.flight?.outbound, 'Milano MXP - Madrid MAD');
    expect(result.neighborhoods.first.name, 'Malasaña');
    expect(result.days.length, 2);
    expect(result.days.first.stops.length, 3);
    expect(result.days.first.diningRecommendation, contains('Casa Lucio'));
  });

  test('GeminiTravelService rispetta shouldSearchFlights = false quando si esplora una meta', () async {
    final mockClient = MockClient((request) async {
      final fakeResponse = {
        'candidates': [
          {
            'content': {
              'parts': [
                {
                  'text': jsonEncode({
                    'message': 'Budapest è pura magia tra terme e caffè storici. Che tipo di esperienza cerchi?',
                    'destination': 'Budapest',
                    'durationDays': 3,
                    'shouldSearchFlights': false,
                    'suggestedReplies': ['Cerchiamo i voli', 'Consigliami il periodo migliore']
                  })
                }
              ]
            }
          }
        ]
      };
      return http.Response.bytes(
        utf8.encode(jsonEncode(fakeResponse)),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });

    final service = GeminiTravelService(apiKey: 'test-api-key', client: mockClient);
    final result = await service.generateTripAdvice('Vorrei andare a Budapest');

    expect(result.destination, 'Budapest');
    expect(result.shouldSearchFlights, isFalse);
    expect(result.flight, isNull);
    expect(result.suggestedReplies, contains('Cerchiamo i voli'));
  });

  test('GeminiTravelService NON forza mai i voli su tratte ferroviarie (es. Milano da Roma) al primo messaggio', () async {
    final mockClient = MockClient((request) async {
      final fakeResponse = {
        'candidates': [
          {
            'content': {
              'parts': [
                {
                  'text': jsonEncode({
                    'message': 'Milano ad Halloween è vibrante tra mostre ed eventi. Da Roma preferisci il treno ad alta velocità (3h) o vuoi valutare i voli? E con chi andrai?',
                    'destination': 'Milano',
                    'durationDays': 3,
                    'shouldSearchFlights': false,
                    'suggestedReplies': ['Preferisco il treno', 'Mostrami i voli', 'In coppia', 'Ponte 31 ott - 2 nov']
                  })
                }
              ]
            }
          }
        ]
      };
      return http.Response.bytes(
        utf8.encode(jsonEncode(fakeResponse)),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });

    final service = GeminiTravelService(apiKey: 'test-api-key', client: mockClient);
    final result = await service.generateTripAdvice(
      'Voglio andare a Milano ad Halloween',
      departureCity: 'Roma',
    );

    expect(result.destination, 'Milano');
    expect(result.shouldSearchFlights, isFalse);
    expect(result.flight, isNull);
    expect(result.suggestedReplies, contains('Preferisco il treno'));
    expect(result.suggestedReplies, contains('Mostrami i voli'));
  });

  test('GeminiTravelService gestisce errore HTTP in modo trasparente', () async {

    final mockClient = MockClient((request) async {
      return http.Response(jsonEncode({
        'error': {'message': 'API key not valid'}
      }), 400);
    });

    final service = GeminiTravelService(apiKey: 'invalid-key', client: mockClient);
    expect(
      () => service.generateTripAdvice('Vorrei andare a Berlino'),
      throwsA(isA<GeminiServiceException>()),
    );
  });
}
