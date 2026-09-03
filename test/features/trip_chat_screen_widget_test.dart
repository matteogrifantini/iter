import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iter/features/ai/gemini_models.dart';
import 'package:iter/features/ai/gemini_travel_service.dart';
import 'package:iter/features/chat/trip_chat_screen.dart';
import 'package:iter/features/trips/trip_details_screen.dart';
import 'package:iter/features/trips/trip_entity.dart';
import 'package:iter/features/trips/trip_repository.dart';


import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class FakeGeminiTravelService extends GeminiTravelService {
  FakeGeminiTravelService({this.responseDraft})
      : super(
          apiKey: 'fake-key',
          client: MockClient((_) async => http.Response('{}', 200)),
        );

  final GeminiTripPlanDraft? responseDraft;
  String? lastDepartureCity;
  bool? lastDirectOnly;
  List<ChatMessage>? lastHistory;
  String? lastPrompt;

  @override
  Future<GeminiTripPlanDraft> generateTripAdvice(
    String userPrompt, {
    String departureCity = 'Roma',
    String? userStyle,
    String? budget,
    TripPlanningStage stage = TripPlanningStage.flight,
    bool directOnly = false,
    List<ChatMessage> conversationHistory = const [],
  }) async {
    lastPrompt = userPrompt;
    lastDepartureCity = departureCity;
    lastDirectOnly = directOnly;
    lastHistory = conversationHistory;

    if (responseDraft != null) return responseDraft!;

    return const GeminiTripPlanDraft(
      message: 'Fantastica idea! Ecco la proposta per Budapest.',
      destination: 'Budapest',
      durationDays: 5,
      flight: FlightAdvice(
        outbound: 'Roma FCO - Budapest BUD',
        priceEstimate: '172€ a/r',
        searchUrl: 'https://www.google.com/travel/flights',
        outboundOffers: [
          FlightRealOffer(
            id: 'out-1',
            airline: 'Wizz Air',
            price: 125,
            departureTime: '08:35',
            arrivalTime: '10:25',
            durationMinutes: 110,
            isDirect: true,
            stops: 0,
            bookingUrl: 'https://www.google.com/travel/flights',
          ),
          FlightRealOffer(
            id: 'out-2',
            airline: 'Ryanair',
            price: 138,
            departureTime: '07:00',
            arrivalTime: '08:40',
            durationMinutes: 100,
            isDirect: true,
            stops: 0,
            bookingUrl: 'https://www.google.com/travel/flights',
          ),
        ],
        returnOffers: [
          FlightRealOffer(
            id: 'ret-1',
            airline: 'Ryanair',
            price: 47,
            departureTime: '20:10',
            arrivalTime: '21:50',
            durationMinutes: 100,
            isDirect: true,
            stops: 0,
            bookingUrl: 'https://www.google.com/travel/flights',
          ),
          FlightRealOffer(
            id: 'ret-2',
            airline: 'Wizz Air',
            price: 48,
            departureTime: '19:00',
            arrivalTime: '20:50',
            durationMinutes: 110,
            isDirect: true,
            stops: 0,
            bookingUrl: 'https://www.google.com/travel/flights',
          ),
        ],
        offers: [
          FlightRealOffer(
            id: 'comb-1',
            airline: 'Wizz Air + Ryanair',
            price: 172,
            departureTime: '08:35',
            arrivalTime: '21:50',
            durationMinutes: 210,
            isDirect: true,
            stops: 0,
            bookingUrl: 'https://www.google.com/travel/flights',
          ),
        ],
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('TripChatScreen visualizza FlightSelectorCard con tab Andata e Ritorno separati', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repo = TripRepository();
    final fakeAi = FakeGeminiTravelService();

    await tester.pumpWidget(
      MaterialApp(
        home: TripChatScreen(
          initialPrompt: 'Vorrei organizzare un viaggio a Budapest dal 5 al 10 dicembre',
          tripRepository: repo,
          aiService: fakeAi,
          onOpenSnapshot: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verificare messaggio di benvenuto e destinazione
    expect(find.text('Fantastica idea! Ecco la proposta per Budapest.'), findsOneWidget);
    expect(find.text('Configura il tuo Volo'), findsOneWidget);

    // Verificare la presenza dei Tab 1. Andata e 2. Ritorno
    expect(find.text('1. Andata'), findsOneWidget);
    expect(find.text('2. Ritorno'), findsOneWidget);

    // Nel tab Andata attivo per default: ci sono le offerte di andata
    expect(find.text('Wizz Air'), findsOneWidget);
    expect(find.text('125 €'), findsOneWidget);
    expect(find.text('Ryanair'), findsOneWidget);
    expect(find.text('138 €'), findsOneWidget);

    // Totale stimato iniziale: 125 (andata default) + 47 (ritorno default) = 172 €
    expect(find.text('172 €'), findsOneWidget);

    // Cliccare sul tab 2. Ritorno
    await tester.tap(find.text('2. Ritorno'));
    await tester.pumpAndSettle();

    // Nel tab Ritorno: offerte di ritorno visibili
    expect(find.text('47 €'), findsOneWidget);
    expect(find.text('48 €'), findsOneWidget);

    // Selezionare l'altra offerta di ritorno (Wizz Air 48 €)
    await tester.tap(find.text('48 €'));
    await tester.pumpAndSettle();

    // Il totale si aggiorna dinamicamente: 125 + 48 = 173 €
    expect(find.text('173 €'), findsOneWidget);

    // Verificare presenza del pulsante Salva opzione e prosegui
    expect(find.text('Salva opzione e prosegui'), findsOneWidget);
    expect(find.text('Vedi su Google Flights'), findsOneWidget);

    // Cliccare su Salva opzione e verificare stato salvato senza uscire dall'app
    await tester.tap(find.text('Salva opzione e prosegui'));
    await tester.pumpAndSettle();
    expect(find.text('Opzione di volo salvata nel viaggio'), findsOneWidget);

    // Verificare ASSENZA di pulsanti rigidi "Passo successivo"
    expect(find.textContaining('Passo successivo'), findsNothing);

  });

  testWidgets('TripChatScreen rileva citta di partenza Roma e richiesta volo diretto dal testo', (tester) async {
    final repo = TripRepository();
    final fakeAi = FakeGeminiTravelService();

    await tester.pumpWidget(
      MaterialApp(
        home: TripChatScreen(
          initialPrompt: 'Ciao sono di Roma, vorrei un volo diretto per Budapest 5-10 dicembre',
          tripRepository: repo,
          aiService: fakeAi,
          onOpenSnapshot: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(fakeAi.lastDepartureCity, 'Roma');
    expect(fakeAi.lastDirectOnly, isTrue);
  });

  testWidgets('TripDetailsScreen visualizza dettagli, voli e piano giornaliero senza errori', (tester) async {

    final trip = TripEntity(
      id: 'trip-budapest-123',
      destination: 'Budapest',
      durationDays: 5,
      status: TripStatus.ready,
      createdAt: DateTime(2026, 9, 3),
      coverImageUrl: 'https://images.unsplash.com/photo-1488646953014-85cb44e25828',
      latestPlan: const GeminiTripPlanDraft(
        destination: 'Budapest',
        durationDays: 5,
        message: 'Itinerario pronto',
        days: [
          DailyPlanDraft(
            dayNumber: 1,
            theme: 'Castello di Buda e Bastione dei Pescatori',
            stops: ['Ponte delle Catene', 'Chiesa di Mattia'],
            diningRecommendation: 'Kikötő Bistro',
          ),
          DailyPlanDraft(
            dayNumber: 2,
            theme: 'Parlamento e Terme Széchenyi',
            stops: ['Parlamento Ungherese', 'Piazza degli Eroi'],
            diningRecommendation: 'Café Gerbeaud',
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TripDetailsScreen(trip: trip),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Budapest'), findsWidgets);
    expect(find.text('5 giorni • Creato con Iter AI'), findsOneWidget);

    expect(find.text('Giorno 1'), findsOneWidget);
    expect(find.text('Castello di Buda e Bastione dei Pescatori'), findsOneWidget);
    expect(find.text('Ponte delle Catene'), findsOneWidget);
    expect(find.text('Giorno 2'), findsOneWidget);
    expect(find.text('Parlamento e Terme Széchenyi'), findsOneWidget);
  });
}

