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
    this.bestPeriod = 'Maggio - Giugno & Settembre - Ottobre',
    this.averageDailyCost = '~110€ / giorno (alloggio, pasti, visite)',
    this.insiderTips = const [
      'Prenota online i monumenti iconici per evitare ore di coda',
      'Esplora a piedi i vicoli dei quartieri storici per scovare locali autentici',
      'Assaggia la cucina tipica nei mercati rionali',
    ],
    this.highlights = const [],
  });

  final String destination;
  final String tagline;
  final List<String> images;
  final String climatePill;
  final String transportPill;
  final String flightAdvicePill;
  final String? videoUrl;
  final String bestPeriod;
  final String averageDailyCost;
  final List<String> insiderTips;
  final List<String> highlights;
}

class VisualMediaService {
  VisualMediaService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  static const Map<String, DestinationVisualData> _curatedCatalog = {
    'barcellona': DestinationVisualData(
      destination: 'Barcellona',
      tagline: 'Capolavori di Gaudí, brezza del Mediterraneo e tapas bar vibranti tra il Born e il Barrio Gotico.',
      images: [
        'https://images.unsplash.com/photo-1583422409516-2895a77efded?w=800&q=80',
        'https://images.unsplash.com/photo-1539037116277-4db20889f2d4?w=800&q=80',
        'https://images.unsplash.com/photo-1511527661048-7fe73d85e9a4?w=800&q=80',
      ],
      climatePill: '21-25°C soleggiato e ventilato',
      transportPill: 'Metro capillare e lungomare a piedi',
      flightAdvicePill: 'Voli diretti da Roma FCO ~45-65€',
      bestPeriod: 'Maggio - Giugno & Settembre - Ottobre (clima caldo perfetto, evita l\'afa e la folla di Agosto)',
      averageDailyCost: '~115€ / giorno (hotel centrale, tapas e monumenti)',
      insiderTips: [
        'Prenota la Sagrada Família con almeno 2-3 settimane di anticipo: i biglietti sul posto sono quasi sempre esauriti!',
        'Evita i ristoranti turistici sulla Rambla: per tapas autentiche vai a El Born o nel quartiere Gràcia.',
        'Sali al tramonto ai Bunkers del Carmel per la vista a 360° più spettacolare e gratuita della città.',
        'Attento ai borseggiatori nelle stazioni metro della Rambla e a Plaça Catalunya.',
      ],
      highlights: ['Sagrada Família', 'Park Güell', 'Casa Batlló', 'Barrio Gotico & El Born', 'Barceloneta'],
    ),
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
      bestPeriod: 'Aprile - Giugno & Settembre - Novembre (temperature miti e luce spettacolare)',
      averageDailyCost: '~95€ / giorno (ottimo rapporto qualità/prezzo)',
      insiderTips: [
        'Prendi il tram 28 al mattino presto (prima delle 08:30) per evitare la fila di turisti.',
        'I Pastéis de Belém originali si mangiano caldi con cannella nell\'antica pasticceria vicino al monastero.',
        'Goditi il tramonto a Miradouro de Santa Luzia con musica fado dal vivo.',
      ],
      highlights: ['Torre de Belém', 'Mosteiro dos Jerónimos', 'Alfama & Miradouros', 'Tram 28', 'Praça do Comércio'],
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
      bestPeriod: 'Ottobre per il foliage dorato o Dicembre per mercatini e terme con il vapore nell\'aria fredda',
      averageDailyCost: '~80€ / giorno (una delle capitali europee più convenienti)',
      insiderTips: [
        'Porta costume, ciabatte e cuffia alle Terme Széchenyi per evitare di noleggiarli a caro prezzo.',
        'La vista più iconica del Parlamento illuminato si gode di notte dal Bastione dei Pescatori o dal battello.',
        'Visita Szimpla Kert, il primo e più famoso ruin bar, anche di giorno la domenica mattina per il mercatino locale.',
      ],
      highlights: ['Parlamento di Budapest', 'Bastione dei Pescatori', 'Terme Széchenyi', 'Ponte delle Catene', 'Ruin Bar'],
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
      bestPeriod: 'Settembre - Novembre & Marzo - Maggio per design, mostre ed eventi',
      averageDailyCost: '~140€ / giorno',
      insiderTips: [
        'Da Roma prendi assolutamente il Frecciarossa AV (3 ore centro-centro, zero stress da aeroporto).',
        'Sali sulle terrazze del Duomo a piedi al tramonto per vedere le Alpi e le guglie illuminate.',
        'Il Cenacolo Vinciano richiede prenotazione obbligatoria con mesi di anticipo.',
      ],
      highlights: ['Duomo & Terrazze', 'Castello Sforzesco', 'Pinacoteca di Brera', 'Navigli & Darsena', 'Galleria'],
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
      bestPeriod: 'Maggio - Giugno & Ottobre (in estate il caldo supera spesso i 38°C)',
      averageDailyCost: '~105€ / giorno',
      insiderTips: [
        'Il Museo del Prado è gratuito dal lunedì al sabato dalle 18:00 alle 20:00.',
        'Assaggia il bocadillo de calamares in Plaza Mayor nel bar storico La Campana.',
        'Noleggia una barchetta al laghetto del Parco del Retiro prima di visitare il Palacio de Cristal.',
      ],
      highlights: ['Museo del Prado', 'Palacio Real', 'Parco del Retiro', 'Plaza Mayor', 'Gran Vía'],
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
        bestPeriod: 'Primavera e primo Autunno (clima ideale per esplorare)',
        averageDailyCost: '~100-120€ / giorno complessivo',
        insiderTips: const [
          'Pianifica le attrazioni principali al mattino per evitare folla',
          'Scegli un alloggio in posizione baricentrica per muoverti a piedi',
        ],
      );
    } catch (_) {
      return DestinationVisualData(
        destination: destination,
        tagline: 'Una destinazione imperdibile selezionata per te.',
        images: const ['https://images.unsplash.com/photo-1488646953014-85cb44e25828?w=800&q=80'],
        climatePill: 'Stagione favorevole',
        transportPill: 'A misura di viaggiatore',
        flightAdvicePill: 'Opzioni disponibili',
        bestPeriod: 'Primavera e Autunno',
        averageDailyCost: '~100€ / giorno',
        insiderTips: const [
          'Pianifica le visite con anticipo',
          'Muoviti a piedi nel centro storico',
        ],
      );
    }
  }
}
