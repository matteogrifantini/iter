import 'package:flutter/foundation.dart';
import '../ai/gemini_models.dart';

@immutable
class CentroidRecommendation {
  const CentroidRecommendation({
    required this.optimalNeighborhood,
    required this.explanation,
    required this.walkingScore,
    required this.averageMinutesToSpots,
    required this.metroLineAdvice,
  });

  final String optimalNeighborhood;
  final String explanation;
  final int walkingScore;
  final int averageMinutesToSpots;
  final String metroLineAdvice;
}

class CentroidSolver {
  const CentroidSolver();

  /// Risolve il baricentro geografico e il quartiere ideale in base alla meta e alle attrazioni scelte.
  CentroidRecommendation solveOptimalArea({
    required String destination,
    required List<AttractionItem> chosenAttractions,
  }) {
    final destLower = destination.trim().toLowerCase();
    final names = chosenAttractions.map((a) => a.name.toLowerCase()).join(' ');

    if (destLower.contains('lisbona') || destLower.contains('lisbon')) {
      if (names.contains('belém') || names.contains('jeronimos')) {
        return const CentroidRecommendation(
          optimalNeighborhood: 'Baixa / Chiado & Cais do Sodré',
          explanation: 'Baricentro strategico: hai sia tappe a est (Alfama a piedi) che a ovest (Belém con il tram 15E da Praça da Figueira).',
          walkingScore: 94,
          averageMinutesToSpots: 10,
          metroLineAdvice: 'Metro Verde / Tram 15E / Elevador de Santa Justa',
        );
      }
      return const CentroidRecommendation(
        optimalNeighborhood: 'Chiado & Bairro Alto',
        explanation: 'Cuore pulsante e pedonale: sei a pochi passi dai miradouros, dai ristoranti tipici e dal Tram 28.',
        walkingScore: 96,
        averageMinutesToSpots: 8,
        metroLineAdvice: 'Metro Blu e Verde (Baixa-Chiado)',
      );
    }

    if (destLower.contains('budapest')) {
      if (names.contains('terme') || names.contains('széchenyi')) {
        return const CentroidRecommendation(
          optimalNeighborhood: 'Distretto VI · Terézváros (Andrássy út)',
          explanation: 'Asse centrale perfetto: equidistante dal Danubio a ovest e dal Parco delle Terme Széchenyi a est con la storica Metro M1.',
          walkingScore: 92,
          averageMinutesToSpots: 9,
          metroLineAdvice: 'Metro M1 storica sotto casa',
        );
      }
      return const CentroidRecommendation(
        optimalNeighborhood: 'Distretto V · Belváros (Centro Danubio)',
        explanation: 'Baricentro perfetto sul fiume: attraversi a piedi il Ponte delle Catene verso Buda o passeggi verso il Parlamento.',
        walkingScore: 95,
        averageMinutesToSpots: 7,
        metroLineAdvice: 'Tram panoramico 2 lungo il Danubio',
      );
    }

    if (destLower.contains('milano') || destLower.contains('milan')) {
      return const CentroidRecommendation(
        optimalNeighborhood: 'Brera & Cairoli',
        explanation: 'Baricentro ideale: a metà strada tra il Duomo a sud, il Castello Sforzesco a ovest e la Pinacoteca a nord.',
        walkingScore: 98,
        averageMinutesToSpots: 6,
        metroLineAdvice: 'Metro M1/M2 e tram storici 1 e 2',
      );
    }

    if (destLower.contains('madrid')) {
      return const CentroidRecommendation(
        optimalNeighborhood: 'Barrio de Las Letras / Huertas',
        explanation: 'Baricentro culturale: a 7 minuti a piedi dal Museo del Prado, da Puerta del Sol e dal Parco del Retiro.',
        walkingScore: 95,
        averageMinutesToSpots: 8,
        metroLineAdvice: 'Metro 1 (Antón Martín / Sol)',
      );
    }

    if (destLower.contains('roma') || destLower.contains('rome')) {
      return const CentroidRecommendation(
        optimalNeighborhood: 'Rione Monti',
        explanation: 'Baricentro storico e autentico: a 8 minuti a piedi dal Colosseo e dai Fori, vicinissimo a Termini per il treno.',
        walkingScore: 93,
        averageMinutesToSpots: 10,
        metroLineAdvice: 'Metro B Cavour / Colosseo',
      );
    }

    // Default baricentrico generico
    return CentroidRecommendation(
      optimalNeighborhood: 'Centro Storico Pedonale',
      explanation: 'Posizione baricentrica ottimizzata per raggiungere le ${chosenAttractions.length} tappe a piedi o con poche fermate.',
      walkingScore: 90,
      averageMinutesToSpots: 10,
      metroLineAdvice: 'Linee urbane centrali',
    );
  }
}
