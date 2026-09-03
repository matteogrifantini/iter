import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:iter/features/weather/weather_service.dart';

void main() {
  group('WeatherService', () {
    test('parses Open-Meteo JSON response into TripWeatherReport', () async {
      final mockJson = '''
      {
        "current": {
          "temperature_2m": 8.5,
          "weather_code": 3
        },
        "daily": {
          "time": ["2026-12-05", "2026-12-06", "2026-12-07"],
          "temperature_2m_max": [10.2, 9.1, 7.5],
          "temperature_2m_min": [3.4, 2.0, 1.1],
          "weather_code": [3, 61, 71],
          "precipitation_probability_max": [10, 75, 40]
        }
      }
      ''';

      final mockClient = MockClient((request) async {
        expect(request.url.host, 'api.open-meteo.com');
        return http.Response(
          mockJson,
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = WeatherService(httpClient: mockClient);
      final report = await service.fetchWeather('Budapest');

      expect(report.destination, 'Budapest');
      expect(report.currentTemp, 8.5);
      expect(report.currentWeatherCode, 3);
      expect(report.dailyForecast.length, 3);
      expect(report.dailyForecast[0].tempMax, 10.2);
      expect(report.dailyForecast[1].conditionLabel, 'Pioggia');
      expect(report.dailyForecast[1].precipitationProbability, 75);
      expect(report.clothingTip, isNotEmpty);
    });

    test('returns fallback report gracefully when HTTP fails', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Internal Error', 500);
      });

      final service = WeatherService(httpClient: mockClient);
      final report = await service.fetchWeather('Porto');

      expect(report.destination, 'Porto');
      expect(report.dailyForecast, isNotEmpty);
      expect(report.currentTemp, greaterThan(0));
    });
  });
}
