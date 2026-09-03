import 'dart:convert';
import 'package:http/http.dart' as http;

import 'weather_models.dart';

/// Service interfacing with Open-Meteo REST API (100% Free, no API keys needed).
class WeatherService {
  WeatherService({http.Client? httpClient})
    : _client = httpClient ?? http.Client();

  final http.Client _client;

  static const Map<String, (double, double)> _cityCoordinates = {
    'budapest': (47.4979, 19.0402),
    'porto': (41.1579, -8.6291),
    'roma': (41.9028, 12.4964),
    'lisbona': (38.7223, -9.1393),
    'barcellona': (41.3851, 2.1734),
    'parigi': (48.8566, 2.3522),
    'berlino': (52.5200, 13.4050),
    'praga': (50.0755, 14.4378),
    'amsterdam': (52.3676, 4.9041),
    'firenze': (43.7696, 11.2558),
    'vienna': (48.2082, 16.3738),
    'madrid': (40.4168, -3.7038),
    'londra': (51.5074, -0.1278),
    'tokyo': (35.6762, 139.6503),
    'new york': (40.7128, -74.0060),
  };

  /// Fetches real-time weather and 7-day forecast for a destination.
  Future<TripWeatherReport> fetchWeather(String destination) async {
    final key = destination.trim().toLowerCase();
    var coords = _cityCoordinates[key];
    if (coords == null) {
      for (final entry in _cityCoordinates.entries) {
        if (key.contains(entry.key) || entry.key.contains(key)) {
          coords = entry.value;
          break;
        }
      }
    }
    coords ??= const (47.4979, 19.0402); // Default to Budapest/European climate

    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast?latitude=${coords.$1}&longitude=${coords.$2}&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max&current=temperature_2m,weather_code&timezone=auto',
    );

    try {
      final response = await _client
          .get(url)
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return _parseOpenMeteoResponse(destination, data);
      }
    } catch (_) {}

    return _fallbackReport(destination);
  }

  TripWeatherReport _parseOpenMeteoResponse(
    String destination,
    Map<String, dynamic> data,
  ) {
    final current = data['current'] as Map<String, dynamic>? ?? {};
    final daily = data['daily'] as Map<String, dynamic>? ?? {};

    final currentTemp = (current['temperature_2m'] as num?)?.toDouble() ?? 14.0;
    final currentCode = (current['weather_code'] as num?)?.toInt() ?? 1;

    final dates = (daily['time'] as List<dynamic>? ?? []).cast<String>();
    final maxTemps = (daily['temperature_2m_max'] as List<dynamic>? ?? [])
        .map((e) => (e as num).toDouble())
        .toList();
    final minTemps = (daily['temperature_2m_min'] as List<dynamic>? ?? [])
        .map((e) => (e as num).toDouble())
        .toList();
    final codes = (daily['weather_code'] as List<dynamic>? ?? [])
        .map((e) => (e as num).toInt())
        .toList();
    final precips =
        (daily['precipitation_probability_max'] as List<dynamic>? ?? [])
            .map((e) => (e as num).toInt())
            .toList();

    final forecastList = <DailyWeather>[];
    for (var i = 0; i < dates.length && i < 7; i++) {
      forecastList.add(
        DailyWeather(
          date:
              DateTime.tryParse(dates[i]) ??
              DateTime.now().add(Duration(days: i)),
          tempMax: i < maxTemps.length ? maxTemps[i] : currentTemp + 2,
          tempMin: i < minTemps.length ? minTemps[i] : currentTemp - 4,
          weatherCode: i < codes.length ? codes[i] : currentCode,
          precipitationProbability: i < precips.length ? precips[i] : 10,
        ),
      );
    }

    final tip = _generateClothingTip(currentTemp, forecastList);

    return TripWeatherReport(
      destination: destination,
      currentTemp: currentTemp,
      currentWeatherCode: currentCode,
      dailyForecast: forecastList,
      clothingTip: tip,
    );
  }

  String _generateClothingTip(double temp, List<DailyWeather> forecast) {
    final hasRain = forecast.any((d) => d.precipitationProbability > 40);
    if (temp < 8) {
      return hasRain
          ? 'Clima freddo e possibilità di pioggia: cappotto pesante, sciarpa e ombrello compatto.'
          : 'Clima freddo: giacca invernale, maglioni caldi e scarpe impermeabili.';
    } else if (temp < 18) {
      return hasRain
          ? 'Clima mite ma variabile: abbigliamento a strati e giacca antivento/antipioggia.'
          : 'Clima piacevole: t-shirt con felpa o giacca leggera per la sera.';
    } else {
      return 'Clima caldo: abiti leggeri e traspiranti, occhiali da sole e borraccia.';
    }
  }

  TripWeatherReport _fallbackReport(String destination) {
    final now = DateTime.now();
    return TripWeatherReport(
      destination: destination,
      currentTemp: 15.0,
      currentWeatherCode: 1,
      clothingTip:
          'Clima ideale per camminare: abbigliamento a strati e scarpe comode.',
      dailyForecast: List.generate(
        5,
        (i) => DailyWeather(
          date: now.add(Duration(days: i)),
          tempMax: 18.0 - i,
          tempMin: 9.0 - (i % 2),
          weatherCode: i == 2 ? 61 : (i % 2 == 0 ? 0 : 2),
          precipitationProbability: i == 2 ? 65 : 15,
        ),
      ),
    );
  }
}
