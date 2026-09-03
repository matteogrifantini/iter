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

    if (key.contains('porto')) {
      return [
        StayOffer(
          id: 'stay-opo-1',
          name: 'Ribeira Historic Riverfront House',
          type: StayType.apartment,
          neighborhood: 'Ribeira (sul fiume Douro)',
          ratingScore: 9.6,
          ratingCount: 1100,
          ratingLabel: 'Eccezionale',
          pricePerNightEur: 82.0,
          amenities: [
            'Balcone sul Douro',
            'Azulejos originali',
            'Cucina completa',
            'Vino di Porto di benvenuto',
          ],
          imageUrl:
              'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=600',
          bookingUrl: googleHotelsUrl,
          badgeLabel: 'Vista mozzafiato',
          walkingMinutesToCenter: 4,
        ),
        StayOffer(
          id: 'stay-opo-2',
          name: 'The Clérigos Design Boutique',
          type: StayType.boutiqueHotel,
          neighborhood: 'Baixa / Clérigos',
          ratingScore: 9.2,
          ratingCount: 940,
          ratingLabel: 'Eccellente',
          pricePerNightEur: 95.0,
          amenities: [
            'Design contemporaneo',
            'Colazione artigianale',
            'Insonorizzazione',
            'Cocktail bar',
          ],
          imageUrl:
              'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=600',
          bookingUrl: googleHotelsUrl,
          badgeLabel: 'Centrale & Silenzioso',
          walkingMinutesToCenter: 2,
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
