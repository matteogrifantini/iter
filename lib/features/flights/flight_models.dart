import 'package:flutter/material.dart';

/// Details of a single flight segment or full journey.
class FlightOffer {
  const FlightOffer({
    required this.id,
    required this.airlineName,
    required this.airlineCode,
    required this.flightNumber,
    required this.originIata,
    required this.originCity,
    required this.destinationIata,
    required this.destinationCity,
    required this.departureTime,
    required this.arrivalTime,
    required this.durationLabel,
    required this.priceEur,
    required this.isDirect,
    this.stopoverCity,
    this.stopoverDuration,
    required this.cabinBagIncluded,
    required this.bookingUrl,
    required this.badgeLabel,
  });

  final String id;
  final String airlineName;
  final String
  airlineCode; // e.g. 'W6' (WizzAir), 'FR' (Ryanair), 'U2' (EasyJet), 'AZ' (ITA)
  final String flightNumber;
  final String originIata;
  final String originCity;
  final String destinationIata;
  final String destinationCity;
  final String departureTime;
  final String arrivalTime;
  final String durationLabel;
  final double priceEur;
  final bool isDirect;
  final String? stopoverCity;
  final String? stopoverDuration;
  final bool cabinBagIncluded;
  final String bookingUrl;
  final String badgeLabel; // e.g. 'Consigliato', 'Più economico', 'Più veloce'

  Color get airlineColor {
    switch (airlineCode.toUpperCase()) {
      case 'W6': // Wizz Air
        return const Color(0xFFC6007E);
      case 'FR': // Ryanair
        return const Color(0xFF073590);
      case 'U2': // EasyJet
        return const Color(0xFFFF6600);
      case 'AZ': // ITA Airways
        return const Color(0xFF003876);
      case 'LH': // Lufthansa
        return const Color(0xFF05164D);
      case 'TP': // TAP Portugal
        return const Color(0xFF78BE20);
      case 'AF': // Air France
        return const Color(0xFF002157);
      default:
        return const Color(0xFF2C3E50);
    }
  }
}
