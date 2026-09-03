import 'stay_models.dart';

enum StaySortBy { recommended, priceLow, ratingHigh }

/// Service searching realistic, neighborhood-matched accommodations for trips.
class StaySearchService {
  const StaySearchService();

  Future<List<StayOffer>> searchStays({
    required String destination,
    StaySortBy sortBy = StaySortBy.recommended,
  }) async {
    final key = destination.trim().toLowerCase();
    final results = _getStaysForDestination(key, destination);

    switch (sortBy) {
      case StaySortBy.priceLow:
        results.sort(
          (a, b) => a.pricePerNightEur.compareTo(b.pricePerNightEur),
        );
        break;
      case StaySortBy.ratingHigh:
        results.sort((a, b) => b.ratingScore.compareTo(a.ratingScore));
        break;
      case StaySortBy.recommended:
        break;
    }

    return results;
  }

  List<StayOffer> _getStaysForDestination(String key, String destName) {
    final googleHotelsUrl =
        'https://www.google.com/travel/hotels?q=Hotels%20in%20$destName';

    if (key.contains('budapest')) {
      return [
        StayOffer(
          id: 'stay-bud-1',
          name: 'Stories Boutique Hotel Budapest',
          type: StayType.boutiqueHotel,
          neighborhood: 'Distretto VI · Terézváros (vicino Opera)',
          ratingScore: 9.3,
          ratingCount: 1420,
          ratingLabel: 'Eccellente',
          pricePerNightEur: 89.0,
          amenities: [
            'WiFi ultra-veloce',
            'Colazione inclusa',
            'Cancellazione gratuita',
            'Aria condizionata',
          ],
          imageUrl:
              'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=600',
          bookingUrl: googleHotelsUrl,
          badgeLabel: 'La scelta di Iter · Posizione top',
          walkingMinutesToCenter: 5,
        ),
        StayOffer(
          id: 'stay-bud-2',
          name: 'Danubio Riverside Heritage Loft',
          type: StayType.apartment,
          neighborhood: 'Distretto V · Belváros (vista fiume)',
          ratingScore: 9.5,
          ratingCount: 880,
          ratingLabel: 'Eccezionale',
          pricePerNightEur: 74.0,
          amenities: [
            'Cucina attrezzata',
            'Vista Danubio',
            'Self check-in 24/7',
            'Macchina espresso',
          ],
          imageUrl:
              'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=600',
          bookingUrl: googleHotelsUrl,
          badgeLabel: 'Miglior rapporto qualità/prezzo',
          walkingMinutesToCenter: 8,
        ),
        StayOffer(
          id: 'stay-bud-3',
          name: 'Continental Hotel & Thermal Spa',
          type: StayType.designHotel,
          neighborhood: 'Distretto VII · Quartiere Ebraico',
          ratingScore: 8.9,
          ratingCount: 3100,
          ratingLabel: 'Ottimo',
          pricePerNightEur: 118.0,
          amenities: [
            'Piscina interna & Spa',
            'Rooftop panoramico',
            'Palestra',
            'Colazione gourmet',
          ],
          imageUrl:
              'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=600',
          bookingUrl: googleHotelsUrl,
          badgeLabel: 'Spa & Relax',
          walkingMinutesToCenter: 12,
        ),
      ];
    }

    if (key.contains('lisbona') || key.contains('lisbon')) {
      return [
        StayOffer(
          id: 'stay-lis-1',
          name: 'AlmaLusa Baixa / Chiado',
          type: StayType.boutiqueHotel,
          neighborhood: 'Baixa / Chiado (Baricentro)',
          ratingScore: 9.4,
          ratingCount: 1650,
          ratingLabel: 'Eccellente',
          pricePerNightEur: 98.0,
          amenities: ['Colazione inclusa', 'WiFi fibra', 'Cancellazione gratuita', 'Concierge'],
          imageUrl: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=600',
          bookingUrl: googleHotelsUrl,
          badgeLabel: 'Baricentro perfetto',
          walkingMinutesToCenter: 3,
        ),
        StayOffer(
          id: 'stay-lis-2',
          name: 'Memmo Alfama Design Hotel',
          type: StayType.designHotel,
          neighborhood: 'Alfama (Vista Tago)',
          ratingScore: 9.2,
          ratingCount: 980,
          ratingLabel: 'Eccellente',
          pricePerNightEur: 115.0,
          amenities: ['Piscina panoramica', 'Rooftop bar', 'Vista fiume Tago', 'Colazione gourmet'],
          imageUrl: 'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=600',
          bookingUrl: googleHotelsUrl,
          badgeLabel: 'Piscina & Panorama',
          walkingMinutesToCenter: 7,
        ),
        StayOffer(
          id: 'stay-lis-3',
          name: 'Lisbon Chiado Vintage Loft',
          type: StayType.apartment,
          neighborhood: 'Bairro Alto / Chiado',
          ratingScore: 9.5,
          ratingCount: 720,
          ratingLabel: 'Eccezionale',
          pricePerNightEur: 79.0,
          amenities: ['Cucina completa', 'Balcone tipico', 'Self check-in', 'Smart TV'],
          imageUrl: 'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=600',
          bookingUrl: googleHotelsUrl,
          badgeLabel: 'Miglior rapporto qualità/prezzo',
          walkingMinutesToCenter: 5,
        ),
      ];
    }

    if (key.contains('milano') || key.contains('milan')) {
      return [
        StayOffer(
          id: 'stay-mil-1',
          name: 'Room Mate Giulia Design Hotel',
          type: StayType.designHotel,
          neighborhood: 'Duomo / Galleria',
          ratingScore: 9.3,
          ratingCount: 2100,
          ratingLabel: 'Eccellente',
          pricePerNightEur: 135.0,
          amenities: ['Sauna & Fitness', 'Colazione fino alle 12', 'Design Patricia Urquiola', 'WiFi fibra'],
          imageUrl: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=600',
          bookingUrl: googleHotelsUrl,
          badgeLabel: 'A 2 passi dal Duomo',
          walkingMinutesToCenter: 2,
        ),
        StayOffer(
          id: 'stay-mil-2',
          name: 'Brera Art District Suites',
          type: StayType.apartment,
          neighborhood: 'Brera (Baricentro)',
          ratingScore: 9.4,
          ratingCount: 650,
          ratingLabel: 'Eccezionale',
          pricePerNightEur: 110.0,
          amenities: ['Balcone su via Fiori Chiari', 'Macchina Nespresso', 'Self check-in', 'Climatizzato'],
          imageUrl: 'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=600',
          bookingUrl: googleHotelsUrl,
          badgeLabel: 'Baricentro Brera',
          walkingMinutesToCenter: 4,
        ),
      ];
    }

    if (key.contains('madrid')) {
      return [
        StayOffer(
          id: 'stay-mad-1',
          name: 'Only YOU Boutique Hotel Madrid',
          type: StayType.boutiqueHotel,
          neighborhood: 'Barrio de Las Letras / Huertas',
          ratingScore: 9.4,
          ratingCount: 1890,
          ratingLabel: 'Eccellente',
          pricePerNightEur: 118.0,
          amenities: ['Colazione inclusa', 'Cocktail lounge', 'Palestra', 'Cancellazione gratuita'],
          imageUrl: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=600',
          bookingUrl: googleHotelsUrl,
          badgeLabel: 'Scelta Iter a Madrid',
          walkingMinutesToCenter: 5,
        ),
        StayOffer(
          id: 'stay-mad-2',
          name: 'Dear Hotel Madrid Gran Vía',
          type: StayType.designHotel,
          neighborhood: 'Gran Vía / Malasaña',
          ratingScore: 9.1,
          ratingCount: 2400,
          ratingLabel: 'Eccellente',
          pricePerNightEur: 92.0,
          amenities: ['Rooftop con piscina panoramica', 'Ristorante panoramico', 'WiFi alta velocità'],
          imageUrl: 'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=600',
          bookingUrl: googleHotelsUrl,
          badgeLabel: 'Piscina sul tetto',
          walkingMinutesToCenter: 6,
        ),
      ];
    }

    if (key.contains('roma') || key.contains('rome')) {
      return [
        StayOffer(
          id: 'stay-rom-1',
          name: 'The Fifteen Keys Boutique Hotel',
          type: StayType.boutiqueHotel,
          neighborhood: 'Rione Monti (Baricentro)',
          ratingScore: 9.5,
          ratingCount: 1100,
          ratingLabel: 'Eccezionale',
          pricePerNightEur: 125.0,
          amenities: ['Corte interna con giardino', 'Colazione all\'aperto', 'Bici gratuite', 'Cancellazione flessibile'],
          imageUrl: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=600',
          bookingUrl: googleHotelsUrl,
          badgeLabel: 'Baricentro Monti',
          walkingMinutesToCenter: 8,
        ),
      ];
    }


    // Generic realistic accommodation
    return [
      StayOffer(
        id: 'stay-gen-1',
        name: 'Historic Center Boutique Retreat',
        type: StayType.boutiqueHotel,
        neighborhood: 'Centro Storico',
        ratingScore: 9.4,
        ratingCount: 1250,
        ratingLabel: 'Eccellente',
        pricePerNightEur: 92.0,
        amenities: [
          'Colazione inclusa',
          'WiFi fibra',
          'Cancellazione flessibile',
          'Concierge locale',
        ],
        imageUrl:
            'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=600',
        bookingUrl: googleHotelsUrl,
        badgeLabel: 'Consigliato da Iter',
        walkingMinutesToCenter: 5,
      ),
      StayOffer(
        id: 'stay-gen-2',
        name: 'Design Loft with Terrace',
        type: StayType.apartment,
        neighborhood: 'Quartiere Culturale',
        ratingScore: 9.1,
        ratingCount: 780,
        ratingLabel: 'Ottimo',
        pricePerNightEur: 75.0,
        amenities: [
          'Terrazzo privato',
          'Cucina accessoriata',
          'Self check-in',
          'Smart TV',
        ],
        imageUrl:
            'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=600',
        bookingUrl: googleHotelsUrl,
        badgeLabel: 'Più conveniente',
        walkingMinutesToCenter: 10,
      ),
    ];
  }
}
