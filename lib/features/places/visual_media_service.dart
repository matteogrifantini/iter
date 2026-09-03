import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'real_place_service.dart';

@immutable
class DestinationVisualData {
  const DestinationVisualData({
    required this.destination,
    required this.tagline,
    required this.images,
    required this.climatePill,
    required this.transportPill,
    required this.flightAdvicePill,
    this.videoUrl,
  });

  final String destination;
  final String tagline;
  final List<String> images;
  final String climatePill;
  final String transportPill;
  final String flightAdvicePill;
  final String? videoUrl;
}

class VisualMediaService {
  VisualMediaService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  static const Map<String, DestinationVisualData> _curatedCatalog = {
    'lisbona': DestinationVisualData(
      destination: 'Lisbona',
      tagline: 'Luce dorata sull\'Atlantico, miradouros e tram storici tra i vicoli di Alfama.',
      images: [
        'https://images.unsplash.com/photo-1509840841025-9088ba78a826?w=800&q=80',
        'https://images.unsplash.com/photo-1513581166391-887a96ddeafd?w=800&q=80',
        'https://images.unsplash.com/photo-1524396309943-e03f5249f002?w=800&q=80',
      ],
      climatePill: '18-23°C in Autunno · Clima ideale',
      transportPill: 'Tram 28 e metro ovunque',
      flightAdvicePill: 'Voli diretti da Roma FCO ~70€',
    ),
    'budapest': DestinationVisualData(
      destination: 'Budapest',
      tagline: 'Fascino asburgico sul Danubio, terme calde all\'aperto e ruin bar segreti.',
      images: [
        'https://images.unsplash.com/photo-1549877452-9c387954fbc2?w=800&q=80',
        'https://images.unsplash.com/photo-1517737812598-1a43d0ef2a60?w=800&q=80',
        'https://images.unsplash.com/photo-1505872245034-5c5ab9888941?w=800&q=80',
      ],
      climatePill: '14-19°C · Perfetta per le terme',
      transportPill: 'Tram 2 panoramico sul fiume',
      flightAdvicePill: 'Voli diretti low-cost da 50€',
    ),
    'milano': DestinationVisualData(
      destination: 'Milano',
      tagline: 'Guglie gotiche, mostre di livello mondiale e la vivacità serale di Brera e Navigli.',
      images: [
        'https://images.unsplash.com/photo-1513584684374-8bab748fbf90?w=800&q=80',
        'https://images.unsplash.com/photo-1543429776-2782fc8e1acd?w=800&q=80',
        'https://images.unsplash.com/photo-1579783902614-a3fb3927b675?w=800&q=80',
      ],
      climatePill: 'Autunno fresco & mostre d\'arte',
      transportPill: 'Frecciarossa 2h59m da Roma Termini',
      flightAdvicePill: 'In treno AV centro-centro',
    ),
    'madrid': DestinationVisualData(
      destination: 'Madrid',
      tagline: 'Energia infinita, musei del Triangolo d\'Oro e tapas bar aperti fino a tardi.',
      images: [
        'https://images.unsplash.com/photo-1539037116277-4db20889f2d4?w=800&q=80',
        'https://images.unsplash.com/photo-1543783207-ec64e4d95325?w=800&q=80',
        'https://images.unsplash.com/photo-1509356843151-3e7d96241e11?w=800&q=80',
      ],
      climatePill: '20-24°C soleggiato e piacevole',
      transportPill: 'Città perfetta a piedi e metro',
      flightAdvicePill: 'Voli frequenti da 60€',
    ),
    'parigi': DestinationVisualData(
      destination: 'Parigi',
      tagline: 'Bistrot d\'autore, lungosenna alberato e scorci iconici da Montmartre a Le Marais.',
      images: [
        'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=800&q=80',
        'https://images.unsplash.com/photo-1499856871958-5b9627545d1a?w=800&q=80',
        'https://images.unsplash.com/photo-1431274172761-fca41d930114?w=800&q=80',
      ],
      climatePill: 'Autunno romantico & foliage',
      transportPill: 'Metro capillare linea per linea',
      flightAdvicePill: 'Voli diretti FCO/BGY da 65€',
    ),
  };

  /// Restituisce i contenuti multimediali curati o dinamici per la meta richiesta.
  Future<DestinationVisualData> getVisualData(String destination) async {
    final key = destination.trim().toLowerCase();
    for (final entry in _curatedCatalog.entries) {
      if (key.contains(entry.key)) {
        return entry.value;
      }
    }

    // Dynamic fallback tramite Wikipedia API
    try {
      final realService = RealPlaceService(httpClient: _client);
      final details = await realService.fetchPlaceDetails(destination).timeout(const Duration(seconds: 2));
      final primaryImage = details?.imageUrl ?? 'https://images.unsplash.com/photo-1488646953014-85cb44e25828?w=800&q=80';
      return DestinationVisualData(
        destination: destination,
        tagline: details?.description.isNotEmpty == true 
            ? details!.description 
            : 'Una meta affascinante tutta da scoprire con Iter.',
        images: [primaryImage],
        climatePill: 'Consigliata da Iter',
        transportPill: 'Collegamenti verificati',
        flightAdvicePill: 'Pianificazione attiva',
      );
    } catch (_) {
      return DestinationVisualData(
        destination: destination,
        tagline: 'Una destinazione imperdibile selezionata per te.',
        images: const ['https://images.unsplash.com/photo-1488646953014-85cb44e25828?w=800&q=80'],
        climatePill: 'Stagione favorevole',
        transportPill: 'A misura di viaggiatore',
        flightAdvicePill: 'Opzioni disponibili',
      );
    }
  }
}
