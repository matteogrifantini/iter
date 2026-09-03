import 'package:flutter/material.dart';

/// Represents daily weather forecast for a trip.
class DailyWeather {
  const DailyWeather({
    required this.date,
    required this.tempMax,
    required this.tempMin,
    required this.weatherCode,
    required this.precipitationProbability,
  });

  final DateTime date;
  final double tempMax;
  final double tempMin;
  final int weatherCode;
  final int precipitationProbability;

  String get conditionLabel {
    switch (weatherCode) {
      case 0:
        return 'Sereno';
      case 1:
      case 2:
        return 'Poco nuvoloso';
      case 3:
        return 'Coperto';
      case 45:
      case 48:
        return 'Nebbia';
      case 51:
      case 53:
      case 55:
        return 'Pioggerella';
      case 61:
      case 63:
      case 65:
        return 'Pioggia';
      case 71:
      case 73:
      case 75:
        return 'Neve';
      case 80:
      case 81:
      case 82:
        return 'Rovesci';
      case 95:
      case 96:
      case 99:
        return 'Temporale';
      default:
        return 'Variabile';
    }
  }

  IconData get icon {
    switch (weatherCode) {
      case 0:
        return Icons.wb_sunny_rounded;
      case 1:
      case 2:
        return Icons.wb_cloudy_rounded;
      case 3:
        return Icons.cloud_rounded;
      case 45:
      case 48:
        return Icons.waves_rounded;
      case 51:
      case 53:
      case 55:
      case 61:
      case 63:
      case 65:
      case 80:
      case 81:
      case 82:
        return Icons.water_drop_rounded;
      case 71:
      case 73:
      case 75:
        return Icons.ac_unit_rounded;
      case 95:
      case 96:
      case 99:
        return Icons.flash_on_rounded;
      default:
        return Icons.wb_cloudy_rounded;
    }
  }
}

/// Complete weather report for a destination.
class TripWeatherReport {
  const TripWeatherReport({
    required this.destination,
    required this.currentTemp,
    required this.currentWeatherCode,
    required this.dailyForecast,
    required this.clothingTip,
  });

  final String destination;
  final double currentTemp;
  final int currentWeatherCode;
  final List<DailyWeather> dailyForecast;
  final String clothingTip;
}
