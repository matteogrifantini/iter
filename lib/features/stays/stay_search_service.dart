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

    if (key.contains('tenerife') || key.contains('canarie')) {
      return [
        StayOffer(
          id: 'stay-tfs-1',
          name: 'The Ritz-Carlton Tenerife, Abama',
          type: StayType.designHotel,
          neighborhood: 'Guía de Isora (Costa Ovest)',
          ratingScore: 9.4,
          ratingCount: 1840,
          ratingLabel: 'Meraviglioso',
          pricePerNightEur: 195.0,
          walkingMinutesToCenter: 20,
          amenities: [
            'Spiaggia privata & Funicolare',
            'Ristorante stellato',
            'Piscine panoramiche sull\'oceano',
            'Cancellazione gratuita',
          ],
          imageUrl: 'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=800&q=80',
          badgeLabel: 'Miglior Resort Vista Tramonto',
          bookingUrl: googleHotelsUrl,
        ),
        StayOffer(
          id: 'stay-tfs-2',
          name: 'Hard Rock Hotel Tenerife',
          type: StayType.boutiqueHotel,
          neighborhood: 'Playa Paraíso (Costa Adeje Sud)',
          ratingScore: 8.9,
          ratingCount: 2650,
          ratingLabel: 'Favoloso',
          pricePerNightEur: 140.0,
          walkingMinutesToCenter: 12,
          amenities: [
            'Laguna d\'acqua salata',
            'Sky Lounge 16° piano',
            'Design e musica',
            'Posizione strategica per il sud',
          ],
          imageUrl: 'https://images.unsplash.com/photo-1544644181-1484b3fdfc62?w=800&q=80',
          badgeLabel: 'Prezzo Ottimo (-15%)',
          bookingUrl: googleHotelsUrl,
        ),
        StayOffer(
          id: 'stay-tfs-3',
          name: 'Hotel Botánico & The Oriental Spa',
          type: StayType.designHotel,
          neighborhood: 'Puerto de la Cruz (Nord Storico)',
          ratingScore: 9.2,
          ratingCount: 1420,
          ratingLabel: 'Eccellente',
          pricePerNightEur: 115.0,
          walkingMinutesToCenter: 8,
          amenities: [
            'Giardini subtropicali',
            'Thermal Spa di lusso',
            'Atmosfera tranquilla e rilassante',
            'Ottimo rapporto qualità/prezzo',
          ],
          imageUrl: 'https://images.unsplash.com/photo-1518684079-3c830dcef090?w=800&q=80',
          badgeLabel: 'Rapporto Qualità-Prezzo',
          bookingUrl: googleHotelsUrl,
        ),
        StayOffer(
          id: 'stay-tfs-4',
          name: 'Laguna Nivaria Hotel & Spa',
          type: StayType.apartment,
          neighborhood: 'San Cristóbal de La Laguna (Centro Storico)',
          ratingScore: 9.0,
          ratingCount: 1100,
          ratingLabel: 'Eccellente',
          pricePerNightEur: 92.0,
          walkingMinutesToCenter: 2,
          amenities: [
            'Dimora storica del XVI secolo',
            'Centro pedonale UNESCO',
            'Vicino a ottimi ristoranti e bar',
            'Cancellazione gratuita',
          ],
          imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800&q=80',
          badgeLabel: 'Cultura & Charme Storico',
          bookingUrl: googleHotelsUrl,
        ),
      ];
    }

    if (key.contains('new york') || key.contains('nyc') || key.contains('manhattan')) {

      return [
        StayOffer(
          id: 'stay-nyc-1',
          name: 'Arlo Midtown NYC',
          type: StayType.boutiqueHotel,
          neighborhood: 'Manhattan Centro (Midtown West)',
          ratingScore: 9.1,
          ratingCount: 2310,
          ratingLabel: 'Eccellente',
          pricePerNightEur: 165.0,
          amenities: [
            'Rooftop lounge',
            'Design moderno',
            'Cancellazione gratuita',
            'Metro a 2 min',
          ],
          imageUrl:
              'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=600',
          bookingUrl: googleHotelsUrl,
          badgeLabel: 'Scelta Iter · Posizione baricentrica',
          walkingMinutesToCenter: 4,
        ),
        StayOffer(
          id: 'stay-nyc-2',
          name: 'The Hoxton Williamsburg',
          type: StayType.boutiqueHotel,
          neighborhood: 'Williamsburg (Brooklyn)',
          ratingScore: 9.3,
          ratingCount: 1450,
          ratingLabel: 'Eccellente',
          pricePerNightEur: 185.0,
          amenities: [
            'Vista skyline su Manhattan',
            'Ristorante panoramico',
            'Biciclette gratuite',
          ],
          imageUrl:
              'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=600',
          bookingUrl: googleHotelsUrl,
          badgeLabel: 'Vibe creativa & Rooftop vista skyline',
          walkingMinutesToCenter: 12,
        ),
        StayOffer(
          id: 'stay-nyc-3',
          name: 'Sohotel Manhattan',
          type: StayType.designHotel,
          neighborhood: 'Lower Manhattan (SoHo / Bowery)',

          ratingScore: 8.8,
          ratingCount: 1980,
          ratingLabel: 'Molto buono',
          pricePerNightEur: 139.0,
          amenities: [
            'Edificio storico',
            'Vicino a metro',
            'Rapporto qualità/prezzo ottimo',
          ],
          imageUrl:
              'https://images.unsplash.com/photo-1578683010236-d716f9a3f461?w=600',
          bookingUrl: googleHotelsUrl,
          badgeLabel: 'Prezzo ottimo (-18% media Manhattan)',
          walkingMinutesToCenter: 8,
        ),
      ];
    }

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

    if (key.contains('berlino') || key.contains('berlin')) {
      return [
        StayOffer(
          id: 'stay-ber-1',
          name: 'The Circus Hotel',
          type: StayType.boutiqueHotel,
          neighborhood: 'Mitte / Rosenthaler Platz (Baricentro)',
          ratingScore: 9.4,
          ratingCount: 2180,
          ratingLabel: 'Eccellente',
          pricePerNightEur: 92.0,
          amenities: const ['Rooftop con bar panoramico', 'Noleggio bici', 'Colazione bio', 'Cancellazione gratuita'],
          imageUrl: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=600',
          bookingUrl: googleHotelsUrl,
          badgeLabel: 'Baricentro perfetto · Walking score 95',
          walkingMinutesToCenter: 2,
        ),
        StayOffer(
          id: 'stay-ber-2',
          name: '25hours Hotel Bikini Berlin',
          type: StayType.designHotel,
          neighborhood: 'Charlottenburg / Tiergarten',
          ratingScore: 9.2,
          ratingCount: 1840,
          ratingLabel: 'Favoloso',
          pricePerNightEur: 115.0,
          amenities: const ['Monkey Bar sul tetto vista zoo', 'Sauna panoramica', 'Bici Schindelhauer', 'Design jungle'],
          imageUrl: 'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=600',
          bookingUrl: googleHotelsUrl,
          badgeLabel: 'Design unico & Vibe creativa',
          walkingMinutesToCenter: 12,
        ),
        StayOffer(
          id: 'stay-ber-3',
          name: 'Motel One Berlin-Hackescher Markt',
          type: StayType.designHotel,
          neighborhood: 'Mitte (Hackescher Markt)',

          ratingScore: 9.0,
          ratingCount: 3410,
          ratingLabel: 'Ottimo',
          pricePerNightEur: 79.0,
          amenities: const ['Aria condizionata', 'Lounge bar 24/7', 'Colazione a buffet', 'S-Bahn a 100m'],
          imageUrl: 'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=600',
          bookingUrl: googleHotelsUrl,
          badgeLabel: 'Smart & Miglior prezzo/posizione',
          walkingMinutesToCenter: 4,
        ),
        StayOffer(
          id: 'stay-ber-4',
          name: 'Michelberger Hotel',
          type: StayType.boutiqueHotel,
          neighborhood: 'Friedrichshain (Warschauer Str.)',
          ratingScore: 8.9,
          ratingCount: 1560,
          ratingLabel: 'Molto buono',
          pricePerNightEur: 85.0,
          amenities: const ['A 300m dall\'East Side Gallery', 'Ristorante bio', 'Corte interna animata', 'Bar artigianale'],
          imageUrl: 'https://images.unsplash.com/photo-1590490360182-c33d57733427?w=600',
          bookingUrl: googleHotelsUrl,
          badgeLabel: 'Vibe berlinese autentica',
          walkingMinutesToCenter: 15,
        ),
      ];
    }

    if (key.contains('monaco') || key.contains('munich')) {
      return [
        StayOffer(
          id: 'stay-muc-1',
          name: 'Beyond by Geisel',
          type: StayType.boutiqueHotel,
          neighborhood: 'Altstadt / Marienplatz (Baricentro)',
          ratingScore: 9.6,
          ratingCount: 1120,
          ratingLabel: 'Eccezionale',
          pricePerNightEur: 135.0,
          amenities: const ['Affacciato su Marienplatz', 'Colazione gourmet inclusa', 'Lounge esclusiva', 'Servizio concierge'],
          imageUrl: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=600',
          bookingUrl: googleHotelsUrl,
          badgeLabel: 'Baricentro perfetto · Walking score 98',
          walkingMinutesToCenter: 1,
        ),
        StayOffer(
          id: 'stay-muc-2',
          name: 'The Flushing Meadows Hotel',
          type: StayType.designHotel,
          neighborhood: 'Glockenbachviertel',
          ratingScore: 9.2,
          ratingCount: 1450,
          ratingLabel: 'Favoloso',
          pricePerNightEur: 98.0,
          amenities: const ['Rooftop bar con vista', 'Design studio personalizzati', 'Vicino al fiume Isar', 'Atmosfera trendy'],
          imageUrl: 'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=600',
          bookingUrl: googleHotelsUrl,
          badgeLabel: 'Vibe creativa & Nightlife',
          walkingMinutesToCenter: 8,
        ),
        StayOffer(
          id: 'stay-muc-3',
          name: 'Motel One München-Sendlinger Tor',
          type: StayType.designHotel,
          neighborhood: 'Altstadt / Sendlinger Tor',
          ratingScore: 9.1,
          ratingCount: 2980,
          ratingLabel: 'Ottimo',
          pricePerNightEur: 75.0,
          amenities: const ['Aria condizionata', 'Lounge bar 24/7', 'Metro U-Bahn a 50m', 'Colazione a buffet'],
          imageUrl: 'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=600',
          bookingUrl: googleHotelsUrl,
          badgeLabel: 'Miglior rapporto qualità/prezzo',
          walkingMinutesToCenter: 6,
        ),
        StayOffer(
          id: 'stay-muc-4',
          name: '25hours Hotel The Royal Bavarian',
          type: StayType.designHotel,
          neighborhood: 'Hauptbahnhof / Karlsplatz',
          ratingScore: 9.0,
          ratingCount: 2100,
          ratingLabel: 'Ottimo',
          pricePerNightEur: 89.0,
          amenities: const ['Ristorante NENI', 'Boilerman Bar', 'Sauna bavarese', 'Bici gratis'],
          imageUrl: 'https://images.unsplash.com/photo-1590490360182-c33d57733427?w=600',
          bookingUrl: googleHotelsUrl,
          badgeLabel: 'Stile bavarese & Posizione strategica',
          walkingMinutesToCenter: 9,
        ),
      ];
    }

    if (key.contains('stoccarda') || key.contains('stuttgart')) {
      return [
        StayOffer(
          id: 'stay-str-1',
          name: 'Steigenberger Graf Zeppelin',
          type: StayType.boutiqueHotel,
          neighborhood: 'Stuttgart-Mitte / Hauptbahnhof (Baricentro)',
          ratingScore: 9.3,
          ratingCount: 1650,
          ratingLabel: 'Favoloso',
          pricePerNightEur: 119.0,
          amenities: const ['Di fronte alla Hauptbahnhof', 'Spa con piscina', 'Ristorante gourmet', 'Camere insonorizzate'],
          imageUrl: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=600',
          bookingUrl: googleHotelsUrl,
          badgeLabel: 'Baricentro perfetto · Walking score 97',
          walkingMinutesToCenter: 2,
        ),
        StayOffer(
          id: 'stay-str-2',
          name: 'Jaz in the City Stuttgart',
          type: StayType.designHotel,
          neighborhood: 'Europaviertel / Stadtbibliothek',
          ratingScore: 9.1,
          ratingCount: 2240,
          ratingLabel: 'Ottimo',
          pricePerNightEur: 89.0,
          amenities: const ['Rooftop bar Wolfram Bar', 'Vibe musicale e design', 'Adiacente alla Stadtbibliothek', 'Fitness & Sauna'],
          imageUrl: 'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=600',
          bookingUrl: googleHotelsUrl,
          badgeLabel: 'Design & Rooftop panoramico',
          walkingMinutesToCenter: 7,
        ),
        StayOffer(
          id: 'stay-str-3',
          name: 'Motel One Stuttgart-Mitte',
          type: StayType.designHotel,
          neighborhood: 'Stuttgart-Mitte / Lautenschlagerstraße',
          ratingScore: 9.0,
          ratingCount: 3120,
          ratingLabel: 'Ottimo',
          pricePerNightEur: 72.0,
          amenities: const ['A 150m da Königstraße', 'One Lounge 24h', 'Aria condizionata', 'Wi-Fi ultra veloce'],
          imageUrl: 'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=600',
          bookingUrl: googleHotelsUrl,
          badgeLabel: 'Miglior rapporto qualità/prezzo',
          walkingMinutesToCenter: 4,
        ),
        StayOffer(
          id: 'stay-str-4',
          name: 'EmiLu Design Hotel',
          type: StayType.boutiqueHotel,
          neighborhood: 'Stuttgart-Mitte / Gerberviertel',
          ratingScore: 9.4,
          ratingCount: 980,
          ratingLabel: 'Eccezionale',
          pricePerNightEur: 125.0,
          amenities: const ['Boutique hotel di lusso', 'Terrazza Fritz Bar', 'Sauna panoramica', 'Colazione biologica locale'],
          imageUrl: 'https://images.unsplash.com/photo-1590490360182-c33d57733427?w=600',
          bookingUrl: googleHotelsUrl,
          badgeLabel: 'Stile raffinato & Gerberviertel',
          walkingMinutesToCenter: 6,
        ),
      ];
    }

    if (key.contains('palermo')) {




      return [
        StayOffer(
          id: 'stay-pal-1',
          name: 'Palazzo Sitano Boutique Hotel',
          type: StayType.boutiqueHotel,
          neighborhood: 'Kalsa / Piazza Marina (Baricentro)',
          ratingScore: 9.3,
          ratingCount: 1420,
          ratingLabel: 'Eccellente',
          pricePerNightEur: 78.0,
          amenities: const ['Colazione tipica siciliana', 'WiFi fibra', 'Cancellazione gratuita', 'Corte interna'],
          imageUrl: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=600',
          bookingUrl: googleHotelsUrl,
          badgeLabel: 'Baricentro storico perfetto',
          walkingMinutesToCenter: 3,
        ),
        StayOffer(
          id: 'stay-pal-2',
          name: 'Quattro Canti Suites & Terrace',
          type: StayType.apartment,
          neighborhood: 'Centro Storico (Quattro Canti)',
          ratingScore: 9.1,
          ratingCount: 890,
          ratingLabel: 'Ottimo',
          pricePerNightEur: 68.0,
          amenities: const ['Terrazza sui tetti barocchi', 'Aria condizionata', 'Cucina attrezzata', 'Self check-in'],
          imageUrl: 'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=600',
          bookingUrl: googleHotelsUrl,
          badgeLabel: 'Super centrale',
          walkingMinutesToCenter: 1,
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

    if (key.contains('messina')) {
      return [
        StayOffer(
          id: 'stay-ms-1',
          name: 'Hotel Royal Palace Messina',
          type: StayType.boutiqueHotel,
          neighborhood: 'Centro Storico · Via Cannizzaro (Baricentro)',
          ratingScore: 9.2,
          ratingCount: 1420,
          ratingLabel: 'Eccellente',
          pricePerNightEur: 82.0,
          amenities: [
            'Colazione siciliana artigianale',
            'WiFi fibra ad alta velocità',
            'Cancellazione gratuita',
            'A 400m da Piazza Duomo',
          ],
          imageUrl: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=600',
          bookingUrl: googleHotelsUrl,
          badgeLabel: 'La scelta di Iter · Posizione baricentrica',
          walkingMinutesToCenter: 4,
        ),
        StayOffer(
          id: 'stay-ms-2',
          name: 'VMaison Charme Hotel & Rooftop',
          type: StayType.designHotel,
          neighborhood: 'Piazza Cairoli & Marina',
          ratingScore: 9.5,
          ratingCount: 890,
          ratingLabel: 'Eccezionale',
          pricePerNightEur: 114.0,
          amenities: [
            'Rooftop bar con vista sullo Stretto',
            'Design contemporaneo d\'autore',
            'Letti king size deluxe',
            'Colazione gourmet in terrazza',
          ],
          imageUrl: 'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=600',
          bookingUrl: googleHotelsUrl,
          badgeLabel: 'Boutique di Charme · Vista Stretto',
          walkingMinutesToCenter: 7,
        ),
        StayOffer(
          id: 'stay-ms-3',
          name: 'Quattro Fontane Suites & Lofts',
          type: StayType.apartment,
          neighborhood: 'Centro Storico · Via Cavour',
          ratingScore: 9.3,
          ratingCount: 650,
          ratingLabel: 'Eccellente',
          pricePerNightEur: 68.0,
          amenities: [
            'Cucina completa & Macchina espresso',
            'Self check-in 24/7 con codice',
            'Balcone panoramico tipico',
            'Aria condizionata silenziosa',
          ],
          imageUrl: 'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=600',
          bookingUrl: googleHotelsUrl,
          badgeLabel: 'Miglior rapporto qualità/prezzo',
          walkingMinutesToCenter: 5,
        ),
        StayOffer(
          id: 'stay-ms-4',
          name: 'Garibaldi Heritage Relais',
          type: StayType.bAndB,
          neighborhood: 'Via Garibaldi · Zona Teatro Vittorio Emanuele',
          ratingScore: 9.0,
          ratingCount: 510,
          ratingLabel: 'Ottimo',
          pricePerNightEur: 75.0,
          amenities: [
            'Host locale e consigli esclusivi',
            'Camera in palazzo nobiliare d\'epoca',
            'Cancellazione flessibile',
            'Vicinissimo al lungomare',
          ],
          imageUrl: 'https://images.unsplash.com/photo-1590490360182-c33d57733427?w=600',
          bookingUrl: googleHotelsUrl,
          badgeLabel: 'Atmosfera autentica locale',
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

    // Generic realistic accommodation with 4 curated choices
    return [
      StayOffer(
        id: 'stay-gen-1',
        name: 'Historic Center Boutique Retreat',
        type: StayType.boutiqueHotel,
        neighborhood: 'Centro Storico (Baricentro)',
        ratingScore: 9.4,
        ratingCount: 1250,
        ratingLabel: 'Eccellente',
        pricePerNightEur: 92.0,
        amenities: [
          'Colazione artigianale inclusa',
          'WiFi fibra ad alta velocità',
          'Cancellazione flessibile fino a 24h prima',
          'Walking score eccellente (95/100)',
        ],
        imageUrl:
            'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=600',
        bookingUrl: googleHotelsUrl,
        badgeLabel: 'La scelta di Iter · Posizione baricentrica',
        walkingMinutesToCenter: 4,
      ),
      StayOffer(
        id: 'stay-gen-2',
        name: 'Design Suites with Panoramic Balcony',
        type: StayType.apartment,
        neighborhood: 'Quartiere Culturale & Scorci',
        ratingScore: 9.2,
        ratingCount: 780,
        ratingLabel: 'Eccellente',
        pricePerNightEur: 72.0,
        amenities: [
          'Balcone o terrazzino panoramico',
          'Cucina accessoriata & macchina caffè',
          'Self check-in digitale 24/7',
          'Aria condizionata inverter',
        ],
        imageUrl:
            'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=600',
        bookingUrl: googleHotelsUrl,
        badgeLabel: 'Miglior rapporto qualità/prezzo',
        walkingMinutesToCenter: 7,
      ),
      StayOffer(
        id: 'stay-gen-3',
        name: 'Grand Hotel & Rooftop Lounge',
        type: StayType.designHotel,
        neighborhood: 'Quartiere Nobiliare & Belvedere',
        ratingScore: 9.5,
        ratingCount: 940,
        ratingLabel: 'Eccezionale',
        pricePerNightEur: 128.0,
        amenities: [
          'Rooftop bar con vista a 360 gradi',
          'Area relax & idromassaggio',
          'Colazione gourmet con prodotti DOP',
          'Insonorizzazione totale',
        ],
        imageUrl:
            'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=600',
        bookingUrl: googleHotelsUrl,
        badgeLabel: 'Comfort superiore & Vista',
        walkingMinutesToCenter: 6,
      ),
      StayOffer(
        id: 'stay-gen-4',
        name: 'Authentic Heritage B&B',
        type: StayType.bAndB,
        neighborhood: 'Borgo Storico Artigiano',
        ratingScore: 9.1,
        ratingCount: 430,
        ratingLabel: 'Ottimo',
        pricePerNightEur: 62.0,
        amenities: [
          'Consigli e itinerari segreti dell\'host',
          'Posizione silenziosa ma vicina a tutto',
          'Cancellazione completamente gratuita',
          'Atmosfera calda e familiare',
        ],
        imageUrl:
            'https://images.unsplash.com/photo-1590490360182-c33d57733427?w=600',
        bookingUrl: googleHotelsUrl,
        badgeLabel: 'Smart & Accoglienza locale',
        walkingMinutesToCenter: 8,
      ),
    ];
  }
}
