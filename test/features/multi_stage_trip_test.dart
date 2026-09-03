import 'package:flutter_test/flutter_test.dart';
import 'package:iter/features/ai/gemini_models.dart';

void main() {
  group('Multi-stage Trip Planning Drafts', () {
    test('passo 1: genera bozza con solo volo', () {
      const draftFlight = GeminiTripPlanDraft(
        message: 'Budapest a dicembre è magica!',
        destination: 'Budapest',
        durationDays: 5,
        stage: TripPlanningStage.flight,
        flight: FlightAdvice(
          outbound: 'Milano MXP - Budapest BUD • Wizz Air (1h 40m)',
          priceEstimate: '45€',
          searchUrl: 'https://www.google.com/travel/flights',
        ),
      );

      expect(draftFlight.stage, TripPlanningStage.flight);
      expect(draftFlight.flight, isNotNull);
      expect(draftFlight.neighborhoods, isEmpty);
      expect(draftFlight.days, isEmpty);
    });

    test('passo 2: accumula alloggi preservando il volo del passo 1', () {
      const draftFlight = GeminiTripPlanDraft(
        message: 'Budapest a dicembre è magica!',
        destination: 'Budapest',
        durationDays: 5,
        stage: TripPlanningStage.flight,
        flight: FlightAdvice(
          outbound: 'Milano MXP - Budapest BUD • Wizz Air',
          priceEstimate: '45€',
          searchUrl: 'https://www.google.com/travel/flights',
        ),
      );

      final draftStay = draftFlight.copyWith(
        stage: TripPlanningStage.stay,
        message: 'Ecco dove alloggiare a Budapest.',
        neighborhoods: const [
          NeighborhoodAdvice(
            name: 'District VII',
            why: 'Quartiere ebraico e ruin bar',
            searchUrl: 'https://www.booking.com',
          )
        ],
      );

      expect(draftStay.stage, TripPlanningStage.stay);
      expect(draftStay.flight?.outbound, contains('Wizz Air'));
      expect(draftStay.neighborhoods.length, 1);
      expect(draftStay.days, isEmpty);
    });

    test('passo 3: accumula itinerario preservando volo e alloggi', () {
      const initial = GeminiTripPlanDraft(
        message: 'Ecco dove alloggiare',
        destination: 'Budapest',
        durationDays: 5,
        stage: TripPlanningStage.stay,
        flight: FlightAdvice(
          outbound: 'Milano MXP - Budapest BUD',
          priceEstimate: '45€',
          searchUrl: 'https://www.google.com/travel/flights',
        ),
        neighborhoods: [
          NeighborhoodAdvice(name: 'District VII', why: 'Autentico')
        ],
      );

      final draftItinerary = initial.copyWith(
        stage: TripPlanningStage.itinerary,
        message: 'Ecco il tuo itinerario!',
        days: const [
          DailyPlanDraft(
            dayNumber: 1,
            theme: 'Terme Széchenyi e centro storico',
            stops: ['Piazza degli Eroi', 'Terme Széchenyi'],
          )
        ],
      );

      expect(draftItinerary.stage, TripPlanningStage.itinerary);
      expect(draftItinerary.flight, isNotNull);
      expect(draftItinerary.neighborhoods.length, 1);
      expect(draftItinerary.days.length, 1);
    });
  });
}
