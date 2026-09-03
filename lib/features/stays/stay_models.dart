import 'package:flutter/material.dart';

enum StayType { boutiqueHotel, apartment, designHotel, bAndB }

extension StayTypeExt on StayType {
  String get label {
    switch (this) {
      case StayType.boutiqueHotel:
        return 'Boutique Hotel';
      case StayType.apartment:
        return 'Appartamento Storico';
      case StayType.designHotel:
        return 'Design Hotel';
      case StayType.bAndB:
        return 'B&B di Charme';
    }
  }

  IconData get icon {
    switch (this) {
      case StayType.boutiqueHotel:
        return Icons.hotel_rounded;
      case StayType.apartment:
        return Icons.apartment_rounded;
      case StayType.designHotel:
        return Icons.bed_rounded;
      case StayType.bAndB:
        return Icons.home_rounded;
    }
  }
}

/// A real stay accommodation offer.
class StayOffer {
  const StayOffer({
    required this.id,
    required this.name,
    required this.type,
    required this.neighborhood,
    required this.ratingScore,
    required this.ratingCount,
    required this.ratingLabel,
    required this.pricePerNightEur,
    required this.amenities,
    required this.imageUrl,
    required this.bookingUrl,
    required this.badgeLabel,
    required this.walkingMinutesToCenter,
  });

  final String id;
  final String name;
  final StayType type;
  final String neighborhood;
  final double ratingScore; // e.g. 9.2
  final int ratingCount;
  final String ratingLabel; // e.g. 'Eccellente'
  final double pricePerNightEur;
  final List<String> amenities;
  final String imageUrl;
  final String bookingUrl;
  final String badgeLabel;
  final int walkingMinutesToCenter;
}
