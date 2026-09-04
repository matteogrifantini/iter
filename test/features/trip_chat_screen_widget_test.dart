import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iter/features/ai/gemini_models.dart';
import 'package:iter/features/ai/gemini_travel_service.dart';
import 'package:iter/features/chat/trip_chat_screen.dart';
import 'package:iter/features/trips/trip_details_screen.dart';
import 'package:iter/features/trips/trip_entity.dart';
import 'package:iter/features/trips/trip_repository.dart';
import 'package:iter/features/chat/widgets/flight_selector_card.dart';
import 'package:iter/features/chat/widgets/destination_hero_card.dart';
import 'package:iter/features/chat/widgets/interactive_question_options.dart';





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
    TripPlanningContext? planningContext,
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

    // Verificare presenza dell'Action Card compatta del volo
    expect(find.text('Opzioni Volo per Budapest'), findsOneWidget);
    expect(find.text('Scegli volo'), findsOneWidget);

    // Cliccare per aprire il FlightPickerSheet dedicato
    await tester.tap(find.text('Scegli volo'));
    await tester.pumpAndSettle();

    // Verificare apertura del FlightPickerSheet
    expect(find.text('Selezione Volo a/r'), findsOneWidget);
    expect(find.textContaining('Confronto tariffe date vicine'), findsOneWidget);

    // Verificare presenza del link Google Flights
    expect(find.textContaining('Google Flights'), findsOneWidget);


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

  testWidgets('TripChatScreen gestisce fase esplorativa: nessun volo forzato e mostra chips di suggerimento', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final fakeAi = FakeGeminiTravelService(
      responseDraft: const GeminiTripPlanDraft(
        message: 'Budapest è pura magia! Terme storiche e atmosfera unica.',
        destination: 'Budapest',
        durationDays: 3,
        flight: null,
        suggestedReplies: ['Cerchiamo i voli', 'Consigliami il periodo migliore'],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TripChatScreen(
          initialPrompt: 'Vorrei andare a Budapest',
          aiService: fakeAi,
          onOpenSnapshot: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Messaggio discorsivo visibile
    expect(find.textContaining('Budapest è pura magia'), findsOneWidget);

    // 2. NESSUNA FlightSelectorCard mostrata (nessuna forzatura)
    expect(find.byType(FlightSelectorCard), findsNothing);

    // 3. Chip di suggerimento visibili
    expect(find.text('Cerchiamo i voli'), findsOneWidget);
    expect(find.text('Consigliami il periodo migliore'), findsOneWidget);

    // 4. Tap sul chip invia il messaggio di ricerca voli
    await tester.tap(find.text('Cerchiamo i voli'));
    await tester.pumpAndSettle();

    expect(fakeAi.lastPrompt, 'Cerchiamo i voli');
  });

  testWidgets('Richiesta Berlino procede step-by-step senza TripProfilingCard invasiva', (tester) async {
    final aiService = GeminiTravelService(apiKey: ''); // smart fallback offline

    await tester.pumpWidget(
      MaterialApp(
        home: TripChatScreen(
          initialPrompt: 'Voglio andare a Berlino',
          aiService: aiService,
          onOpenSnapshot: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verificare che la card di profiling con 16 filtri NON esista
    expect(find.text('Che tipo di viaggio desideri?'), findsNothing);
    expect(find.text('Personalizza viaggio a Berlino'), findsNothing);

    // 2. Verificare che la card visiva della città sia presente
    expect(find.byType(DestinationHeroCard), findsOneWidget);
    expect(find.text('Berlino'), findsWidgets);

    // 3. Verificare la singola domanda sul numero di persone
    expect(find.textContaining('Con quante persone hai intenzione di viaggiare?'), findsOneWidget);

    // 4. Verificare i chip compatti di scelta sopra il composer
    expect(find.text('In coppia'), findsOneWidget);
    expect(find.text('Da solo'), findsOneWidget);
    expect(find.text('Con amici'), findsOneWidget);
    expect(find.text('In famiglia'), findsOneWidget);

    // 5. Cliccare su 'In coppia': procede al secondo step (vibe vacanza)
    await tester.tap(find.text('In coppia'));
    await tester.pumpAndSettle();

    // 6. Verificare la seconda domanda sul tipo di vacanza
    expect(find.textContaining('Che tipo di vacanza avete in mente'), findsOneWidget);
    expect(find.text('Cultura & Musei'), findsOneWidget);
    expect(find.text('Relax & Parchi'), findsOneWidget);

    // Ancora nessuna card di profiling invasiva o bottone interno
    expect(find.text('Che tipo di viaggio desideri?'), findsNothing);
    expect(find.text('Personalizza viaggio a Berlino'), findsNothing);

    // Verificare che la DestinationHeroCard NON sia stata duplicata
    expect(find.byType(DestinationHeroCard), findsOneWidget);
  });

  testWidgets('Richiesta Monaco invia DestinationHeroCard solo al primo messaggio e non la ripete', (tester) async {
    final aiService = GeminiTravelService(apiKey: '');

    await tester.pumpWidget(
      MaterialApp(
        home: TripChatScreen(
          initialPrompt: 'Voglio andare a Monaco in Germania',
          aiService: aiService,
          onOpenSnapshot: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Primo messaggio: DestinationHeroCard presente una sola volta
    expect(find.byType(DestinationHeroCard), findsOneWidget);
    expect(find.text('Monaco di Baviera'), findsWidgets);
    expect(find.text('In coppia'), findsOneWidget);

    // Tap su 'In coppia'
    await tester.tap(find.text('In coppia'));
    await tester.pumpAndSettle();

    // Secondo messaggio: DestinationHeroCard continua a essere esattamente UNA in tutta la chat, NON duplicata
    expect(find.byType(DestinationHeroCard), findsOneWidget);
    expect(find.textContaining('Che tipo di vacanza avete in mente'), findsOneWidget);
  });

  testWidgets('InteractiveQuestionOptions supporta selezione multipla e invio combinato', (tester) async {
    String? selectedResult;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InteractiveQuestionOptions(
            options: const [
              'Cultura & Musei',
              'Vita serale & Locali',
              'Relax & Parchi',
            ],
            onSelect: (val) {
              selectedResult = val;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Puoi scegliere più opzioni:'), findsOneWidget);
    expect(find.text('Cultura & Musei'), findsOneWidget);
    expect(find.text('Vita serale & Locali'), findsOneWidget);
    expect(find.text('Relax & Parchi'), findsOneWidget);

    // Seleziona prima opzione
    await tester.tap(find.text('Cultura & Musei'));
    await tester.pumpAndSettle();
    expect(find.text('Invia scelte (1)'), findsOneWidget);

    // Seleziona seconda opzione
    await tester.tap(find.text('Vita serale & Locali'));
    await tester.pumpAndSettle();
    expect(find.text('Invia scelte (2)'), findsOneWidget);

    // Invia combinazione
    await tester.tap(find.text('Invia scelte (2)'));
    await tester.pumpAndSettle();

    expect(selectedResult, 'Cultura & Musei e Vita serale & Locali');
  });

  testWidgets('Richiesta Stoccarda: prima risposta mostra DestinationHeroCard con carosello, bottoni con emoji e nessuna rotta viva', (tester) async {
    final aiService = GeminiTravelService(apiKey: '');

    await tester.pumpWidget(
      MaterialApp(
        home: TripChatScreen(
          initialPrompt: 'Voglio andare a Stoccarda in Germania',
          aiService: aiService,
          onOpenSnapshot: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // DestinationHeroCard presente con Stoccarda
    expect(find.byType(DestinationHeroCard), findsOneWidget);
    expect(find.text('Stoccarda'), findsWidgets);

    // Opzioni con emoji presenti sotto la domanda
    expect(find.text('In coppia'), findsOneWidget);
    expect(find.text('Da solo'), findsOneWidget);

    // Rotta viva Giorno 1 NON deve essere presente
    expect(find.textContaining('Rotta viva'), findsNothing);
  });

  testWidgets('TripDetailsScreen: bottoni di booking in evidenza, box chat persistente e riordino manuale delle tappe', (tester) async {
    final trip = TripEntity(
      id: 'trip-str-test',
      destination: 'Stoccarda',
      durationDays: 2,
      status: TripStatus.ready,
      createdAt: DateTime.now(),
      coverImageUrl: 'https://images.unsplash.com/photo-1542282088-72c9c27ed0cd',
      latestPlan: const GeminiTripPlanDraft(
        destination: 'Stoccarda',
        durationDays: 2,
        message: 'Itinerario pronto',
        days: [
          DailyPlanDraft(
            dayNumber: 1,
            theme: 'Centro Storico & Musei',
            stops: ['Schlossplatz', 'Staatsgalerie'],
          ),
          DailyPlanDraft(
            dayNumber: 2,
            theme: 'Mondo Motori & Vigne',
            stops: ['Mercedes-Benz Museum', 'Colle Württemberg'],
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

    // Box chat persistente in basso
    expect(find.text('Modifica il tuo itinerario, chiedi qualsiasi cosa...'), findsOneWidget);

    // Tappe giorno 1
    expect(find.text('Schlossplatz'), findsOneWidget);
    expect(find.text('Staatsgalerie'), findsOneWidget);

    // Test riordino manuale delle tappe: premi freccia giù sulla prima tappa 'Schlossplatz'
    final downArrows = find.byIcon(Icons.arrow_downward_rounded);
    expect(downArrows, findsWidgets);
    await tester.ensureVisible(downArrows.first);
    await tester.pumpAndSettle();
    await tester.tap(downArrows.first);
    await tester.pumpAndSettle();

    // Conferma salvataggio avvenuto
    expect(find.textContaining('Itinerario aggiornato e salvato con successo!'), findsOneWidget);
  });
}

