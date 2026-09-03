import 'dart:convert';
import 'package:http/http.dart' as http;
import '../flights/fast_flights_service.dart';
import '../flights/google_flights_url_builder.dart';
import '../trips/trip_entity.dart';
import 'gemini_models.dart';
import '../places/real_place_service.dart';
import '../places/visual_media_service.dart';
import '../stays/stay_models.dart';
import '../stays/stay_search_service.dart';





class GeminiServiceException implements Exception {
  const GeminiServiceException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => 'GeminiServiceException: $message (code: $statusCode)';
}

class GeminiTravelService {
  GeminiTravelService({
    required this.apiKey,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String apiKey;
  final http.Client _client;

  static const List<String> _models = [
    'gemini-2.5-flash',
    'gemini-3-flash-preview',
    'gemini-flash-latest',
  ];

  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';

  static String _buildSystemPrompt(TripPlanningStage stage) {
    const commonPersona = '''
Sei Iter, il consulente di viaggio personale per viaggiatori italiani.
Parla come un concierge o un amico esperto su WhatsApp:
- TONO DIRETTO E UMANO: Niente frasi generiche o cerimoniosi convenevoli (VIETATO dire "Budapest è un'ottima città" o "Milano è una splendida meta"). Esprimi opinioni forti da insider.
- BREVE E INCISIVO: Massimo 2-3 frasi chiare per messaggio. Dritto al punto.
- CONOSCI IL VIAGGIATORE: Il viaggiatore parte di default da Roma se non specificato altrimenti.
''';

    switch (stage) {
      case TripPlanningStage.inspiration:
        return '''
$commonPersona
STATO: IL VIAGGIATORE CERCA ISPIRAZIONE / NON HA ANCORA UNA META.
1. Proponi 2 sole mete a contrasto adatte alla stagione (es. per l'autunno: Siviglia per sole e tapas all'aperto, oppure Budapest per terme storiche e foliage).
2. Spiega in mezza riga perché ognuna vale la pena adesso.
3. Chiedi che vibe cerca (caldo/relax, cultura, vita serale).
4. Fornisci 3-4 "suggestedReplies" con i nomi delle mete.

Rispondi SOLO con questo JSON valido:
{
  "message": "2-3 frasi dirette da insider che mettono a confronto le 2 mete",
  "destination": "",
  "durationDays": 3,
  "shouldSearchFlights": false,
  "suggestedReplies": ["Meta 1", "Meta 2", "Altro"]
}
''';

      case TripPlanningStage.flight:
      case TripPlanningStage.transport:
        return '''
$commonPersona
STATO: DEFINIZIONE TRASPORTI & COME ARRIVARE.
1. Se il viaggiatore menziona solo una meta (es. "Milano ad Halloween", "Budapest", "Lisbona"):
   - NON aprire i voli! "shouldSearchFlights": false.
   - Da Roma per tratte italiane (Milano, Firenze, Bologna, Napoli): raccomanda seccamente il treno AV (Frecciarossa/Italo 3h centro-centro, zero stress di aeroporto).
   - Per l'estero: chiedi se preferisce voli diretti, con quante persone andrà e conferma le date.
   - Fornisci chip per facilitare la risposta (es. ["In treno AV", "Mostrami i voli", "In coppia", "31 ott - 2 nov"]).
2. Apri i voli ("shouldSearchFlights": true) SOLO se l'utente lo chiede esplicitamente ("Cerca i voli", "Mostrami i voli", o chip volo).

Rispondi SOLO con questo JSON valido:
{
  "message": "Consiglio secco sul mezzo migliore e 2 domande rapide su compagni e date",
  "destination": "Nome città",
  "durationDays": 3,
  "shouldSearchFlights": false,
  "departureDate": "YYYY-MM-DD",
  "returnDate": "YYYY-MM-DD",
  "suggestedReplies": ["Opzione 1", "Opzione 2", "Opzione 3"]
}
''';

      case TripPlanningStage.attractions:
        return '''
$commonPersona
STATO: CURAZIONE MONUMENTI ED ESPERIENZE ("MI PIACE / NON MI PIACE").
Proponi da 4 a 6 monumenti, scorci o esperienze autentiche per la destinazione.
Per ciascuna fornisci: nome iconico, categoria (es. Panorama, Arte, Relax, Serata), e un motivo da insider per cui non perderla (1 riga).

Rispondi SOLO con questo JSON valido:
{
  "message": "1-2 frasi secche che introducono le esperienze più forti della città",
  "destination": "Nome città",
  "durationDays": 3,
  "shouldSearchFlights": false,
  "attractions": [
    {
      "name": "Nome monumento o luogo",
      "category": "Categoria breve",
      "why": "Motivo da insider in 1 riga"
    }
  ],
  "suggestedReplies": ["Ho scelto le attrazioni", "Mostrami dove alloggiare"]
}
''';

      case TripPlanningStage.stay:
        return '''
$commonPersona
STATO: DOVE ALLOGGIARE & HOTEL STRATEGICI.
In base alle attrazioni scelte dal viaggiatore o alla geografia della città:
1. Spiega in 2 frasi qual è il quartiere baricentrico perfetto per non perdere tempo sui mezzi (es. Brera a Milano, Terézváros a Budapest, Malasaña a Madrid).
2. Spiega brevemente il vibe della zona (vicinanza a piedi, sicurezza, locali la sera).
3. Invita a scegliere la struttura ideale per dormire nella card qui sotto.

Rispondi SOLO con questo JSON valido:
{
  "message": "Consiglio secco sul quartiere baricentrico perfetto per le tappe scelte",
  "destination": "Nome città",
  "durationDays": 3,
  "shouldSearchFlights": false,
  "neighborhoods": [
    {
      "name": "Nome quartiere consigliato",
      "why": "Perché è strategico per visitare la città",
      "searchUrl": "https://www.google.com/travel/hotels"
    }
  ],
  "suggestedReplies": ["Salva alloggio e prosegui", "Passiamo all'itinerario"]
}
''';

      case TripPlanningStage.itinerary:
        return '''
$commonPersona
STATO: ITINERARIO OTTIMIZZATO GIORNO PER GIORNO.
Crea la timeline giorno per giorno ordinata geograficamente, includendo i monumenti scelti e raccomandazioni gastronomiche tipiche (trattoria o mercato, no trappole per turisti).

Rispondi SOLO con questo JSON valido:
{
  "message": "1-2 frasi: ecco il tuo piano ottimizzato per vicinanza a piedi",
  "destination": "Nome città",
  "durationDays": 3,
  "days": [
    {
      "dayNumber": 1,
      "theme": "Tema della giornata",
      "stops": ["Tappa 1", "Tappa 2", "Tappa 3"],
      "diningRecommendation": "Locale tipico e cosa ordinare"
    }
  ],
  "suggestedReplies": ["Salva viaggio", "Modifica tappe"]
}
''';
    }
  }


  Future<GeminiTripPlanDraft> generateTripAdvice(

    String userPrompt, {
    String departureCity = 'Roma',
    String? userStyle,
    String? budget,
    TripPlanningStage stage = TripPlanningStage.flight,
    bool directOnly = false,
    List<ChatMessage> conversationHistory = const [],
  }) async {
    if (apiKey.trim().isEmpty) {
      return _generateSmartFallback(userPrompt, departureCity, stage);
    }


    final today = DateTime.now();
    final todayIso = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final todayStr = GoogleFlightsUrlBuilder.formatShortDate(today);

    final fullPrompt = StringBuffer()
      ..writeln('[Contesto temporale: oggi è $todayStr ($todayIso). Calcola "prossimo weekend" rispetto a oggi]')
      ..writeln('Partenza confermata: $departureCity')
      ..writeln(directOnly ? 'Preferenza volo: SOLO VOLI DIRETTI (senza scali)' : '')
      ..writeln(userStyle != null ? 'Stile preferito: $userStyle' : '')
      ..writeln(budget != null ? 'Budget indicativo: $budget' : '')
      ..writeln('Richiesta del viaggiatore: $userPrompt');


    final systemPrompt = _buildSystemPrompt(stage);

    final contents = <Map<String, dynamic>>[];
    for (final msg in conversationHistory) {
      if (msg.text.trim().isEmpty) continue;
      contents.add({
        'role': msg.role == 'user' ? 'user' : 'model',
        'parts': [{'text': msg.text}],
      });
    }
    contents.add({
      'role': 'user',
      'parts': [{'text': fullPrompt.toString()}],
    });

    final requestBody = {
      'systemInstruction': {
        'parts': [
          {'text': systemPrompt}
        ]
      },
      'contents': contents,
      'generationConfig': {
        'responseMimeType': 'application/json',
        'temperature': 0.7,
      }
    };

    http.Response? response;
    String lastErrMsg = 'Errore sconosciuto';

    for (final model in _models) {
      final endpoint = Uri.parse('$_baseUrl/$model:generateContent?key=$apiKey');
      try {
        final res = await _client.post(
          endpoint,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestBody),
        );
        if (res.statusCode == 200) {
          response = res;
          break;
        } else if (res.statusCode == 503 || res.statusCode == 404 || res.statusCode == 429) {
          // Modello occupato o non trovato: prova il fallback successivo
          continue;
        } else {
          lastErrMsg = 'HTTP ${res.statusCode}: ${res.body}';
          break;
        }
      } catch (e) {
        lastErrMsg = e.toString();
      }
    }

    if (response == null || response.statusCode != 200) {
      throw GeminiServiceException(lastErrMsg);
    }

    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = data['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        throw const GeminiServiceException('Nessuna risposta ricevuta da Gemini.');
      }

      final content = candidates.first['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;
      final text = parts?.first['text'] as String?;

      if (text == null || text.trim().isEmpty) {
        throw const GeminiServiceException('Contenuto vuoto restituito da Gemini.');
      }

      final cleanJson = _cleanJsonString(text);
      final parsedJson = jsonDecode(cleanJson) as Map<String, dynamic>;
      final rawDraft = GeminiTripPlanDraft.fromJson(parsedJson);

      // Arricchisce i voli usando il motore reale di Google Flights (fast-flights)
      // solo se l'IA ha deciso che è il momento opportuno (shouldSearchFlights == true)
      // e non si tratta di un primo messaggio esplorativo o di una tratta tipicamente ferroviaria
      FlightAdvice? enrichedFlight;
      final hasFlightKeywords = _hasExplicitFlightIntent(userPrompt);
      final isFirstMessage = conversationHistory.isEmpty;
      final isRailFavoriteRoute = _isRailFavoriteDestination(departureCity, rawDraft.destination);

      final shouldSearch = rawDraft.shouldSearchFlights &&
          (hasFlightKeywords || (!isFirstMessage && !isRailFavoriteRoute) || rawDraft.flight != null);



      if (shouldSearch) {
        DateTime? geminiDep;
        DateTime? geminiRet;
        final rawDep = parsedJson['departureDate']?.toString();
        final rawRet = parsedJson['returnDate']?.toString();
        if (rawDep != null && rawDep.length >= 10) {
          geminiDep = DateTime.tryParse(rawDep);
        }
        if (rawRet != null && rawRet.length >= 10) {
          geminiRet = DateTime.tryParse(rawRet);
        }

        const fastFlights = FastFlightsService();
        final flightResults = await fastFlights.searchRealFlights(
          destination: rawDraft.destination.isNotEmpty ? rawDraft.destination : 'Madrid',
          originCity: departureCity,
          departureDate: geminiDep,
          returnDate: geminiRet,
          textWithDates: userPrompt,
          directOnly: directOnly,
        );

        final minPrice = flightResults.offers.isNotEmpty ? flightResults.offers.first.price : 0;
        final priceLabel = minPrice > 0 ? 'Da $minPrice€ a/r' : (rawDraft.flight?.priceEstimate ?? '');

        final outboundLabel = rawDraft.flight?.outbound.isNotEmpty == true
            ? rawDraft.flight!.outbound
            : 'Voli da $departureCity a ${rawDraft.destination}';

        enrichedFlight = FlightAdvice(
          outbound: outboundLabel,
          priceEstimate: priceLabel,
          searchUrl: flightResults.searchUrl,
          offers: flightResults.offers,
          outboundOffers: flightResults.outboundOffers,
          returnOffers: flightResults.returnOffers,
          departureDateStr: flightResults.departureDateStr,
          returnDateStr: flightResults.returnDateStr,
          formattedDates: flightResults.formattedDates,
          priceEvaluation: flightResults.priceEvaluation,
          priceAdvice: flightResults.priceAdvice,
        );
      }

      // Arricchimento alloggi se siamo nello step soggiorno o se l'utente chiede alloggi
      List<StayOffer> enrichedStays = rawDraft.stayOffers;
      if (rawDraft.neighborhoods.isNotEmpty || stage == TripPlanningStage.stay || _hasStayIntent(userPrompt)) {
        try {
          const stayService = StaySearchService();
          final results = await stayService.searchStays(
            destination: rawDraft.destination.isNotEmpty ? rawDraft.destination : 'Milano',
          );
          if (results.isNotEmpty) {
            enrichedStays = results;
          }
        } catch (_) {}
      }

      // Arricchimento immagini attrazioni se presenti
      List<AttractionItem> enrichedAttractions = rawDraft.attractions;
      if (rawDraft.attractions.isNotEmpty) {
        final placeService = RealPlaceService(httpClient: _client);
        final list = <AttractionItem>[];
        for (final item in rawDraft.attractions) {
          if (item.imageUrl.contains('unsplash.com/photo-1513581166391')) {
            try {
              final detail = await placeService.fetchPlaceDetails(item.name, destination: rawDraft.destination)
                  .timeout(const Duration(milliseconds: 1500));
              if (detail?.imageUrl != null) {
                list.add(AttractionItem(
                  id: item.id,
                  name: item.name,
                  category: item.category,
                  why: item.why,
                  imageUrl: detail!.imageUrl!,
                  estimatedTimeMinutes: item.estimatedTimeMinutes,
                ));
                continue;
              }
            } catch (_) {}
          }
          list.add(item);
        }
        enrichedAttractions = list;
      }

      // Arricchimento visual media della destinazione (Zero token Gemini)
      DestinationVisualData? visualData;
      if (rawDraft.destination.isNotEmpty) {
        try {
          final visualService = VisualMediaService(client: _client);
          visualData = await visualService.getVisualData(rawDraft.destination)
              .timeout(const Duration(milliseconds: 1500));
        } catch (_) {}
      }

      return GeminiTripPlanDraft(
        message: rawDraft.message,
        destination: rawDraft.destination,
        durationDays: rawDraft.durationDays,
        stage: stage,
        flight: enrichedFlight ?? (shouldSearch ? rawDraft.flight : null),
        neighborhoods: rawDraft.neighborhoods,
        days: rawDraft.days,
        suggestedReplies: rawDraft.suggestedReplies,
        shouldSearchFlights: shouldSearch,
        attractions: enrichedAttractions,
        stayOffers: enrichedStays,
        selectedStay: rawDraft.selectedStay,
        destinationVisual: visualData,
      );


    } catch (e) {


      if (e is GeminiServiceException) rethrow;
      throw GeminiServiceException('Impossibile elaborare i dati del viaggio da Gemini: $e');
    }
  }

  Future<({bool success, String? error, String? model})> testConnection() async {
    if (apiKey.trim().isEmpty) {
      return (success: false, error: 'Chiave API non fornita.', model: null);
    }
    for (final model in _models) {
      final endpoint = Uri.parse('$_baseUrl/$model:generateContent?key=$apiKey');
      try {
        final response = await _client.post(
          endpoint,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': 'Ping'}
                ]
              }
            ]
          }),
        );
        if (response.statusCode == 200) {
          return (success: true, error: null, model: model);
        } else if (response.statusCode == 503 || response.statusCode == 404) {
          continue;
        } else {
          try {
            final errJson = jsonDecode(response.body) as Map<String, dynamic>;
            final msg = errJson['error']?['message'] as String?;
            return (success: false, error: msg ?? 'HTTP ${response.statusCode}', model: model);
          } catch (_) {
            return (success: false, error: 'HTTP ${response.statusCode}', model: model);
          }
        }
      } catch (e) {
        // try next model
      }
    }
    return (success: false, error: 'Impossibile contattare i modelli Gemini.', model: null);
  }

  String _cleanJsonString(String raw) {


    var trimmed = raw.trim();
    if (trimmed.startsWith('```json')) {
      trimmed = trimmed.substring(7);
    } else if (trimmed.startsWith('```')) {
      trimmed = trimmed.substring(3);
    }
    if (trimmed.endsWith('```')) {
      trimmed = trimmed.substring(0, trimmed.length - 3);
    }
    return trimmed.trim();
  }

  static bool _hasExplicitFlightIntent(String text) {
    final lower = text.toLowerCase();
    final flightTerms = [
      'volo',
      'voli',
      'aereo',
      'aerei',
      'flight',
      'flights',
      'volare',
      'aeroporto',
      'skyscanner',
      'google flight',
      'biglietto aereo',
      'biglietti aerei',
      'mostrami i voli',
      'cerca voli',
      'cerchiamo i voli',
    ];
    return flightTerms.any((term) => lower.contains(term));
  }

  static bool _isRailFavoriteDestination(String origin, String destination) {
    final orig = origin.toLowerCase();
    final dest = destination.toLowerCase();
    final railCities = [
      'milano',
      'milan',
      'firenze',
      'florence',
      'bologna',
      'napoli',
      'naples',
      'torino',
      'turin',
      'venezia',
      'venice',
    ];
    return (orig.contains('roma') || orig.contains('rome')) &&
        railCities.any((city) => dest.contains(city));
  }

  static bool _hasStayIntent(String text) {
    final lower = text.toLowerCase();
    return lower.contains('allogg') ||
        lower.contains('hotel') ||
        lower.contains('dormire') ||
        lower.contains('quartier') ||
        lower.contains('struttur');
  }

  Future<GeminiTripPlanDraft> _generateSmartFallback(
    String userPrompt,
    String departureCity,
    TripPlanningStage stage,
  ) async {
    final lower = userPrompt.toLowerCase();
    String dest = 'Barcellona';
    if (lower.contains('lisbona')) {
      dest = 'Lisbona';
    } else if (lower.contains('budapest')) {
      dest = 'Budapest';
    } else if (lower.contains('milano')) {
      dest = 'Milano';
    } else if (lower.contains('madrid')) {
      dest = 'Madrid';
    } else if (lower.contains('parigi')) {
      dest = 'Parigi';
    } else if (lower.contains('roma')) {
      dest = 'Roma';
    }

    final visual = await VisualMediaService().getVisualData(dest);

    if (stage == TripPlanningStage.attractions) {
      final attractions = dest.toLowerCase().contains('barcellona')
          ? const [
              AttractionItem(
                id: 'bcn_1',
                name: 'Sagrada Família',
                category: 'Architettura Modernista',
                why: 'La basilica capolavoro di Antoni Gaudí con fasci di luce magica dalle vetrate colorate.',
                imageUrl: 'https://images.unsplash.com/photo-1583422409516-2895a77efded?w=800&q=80',
                estimatedTimeMinutes: 120,
              ),
              AttractionItem(
                id: 'bcn_2',
                name: 'Park Güell',
                category: 'Panorami & Arte',
                why: 'Terrazza con mosaici ondulati e vista spettacolare su Barcellona e sul mare.',
                imageUrl: 'https://images.unsplash.com/photo-1539037116277-4db20889f2d4?w=800&q=80',
                estimatedTimeMinutes: 90,
              ),
              AttractionItem(
                id: 'bcn_3',
                name: 'Casa Batlló',
                category: 'Design & Magia',
                why: 'Facciata fiabesca e tetto che rievoca le scaglie del drago di San Giorgio.',
                imageUrl: 'https://images.unsplash.com/photo-1511527661048-7fe73d85e9a4?w=800&q=80',
                estimatedTimeMinutes: 75,
              ),
              AttractionItem(
                id: 'bcn_4',
                name: 'Bunkers del Carmel',
                category: 'Tramonto & Vibe',
                why: 'Il punto panoramico più alto e autentico per ammirare il tramonto a 360° senza folla.',
                imageUrl: 'https://images.unsplash.com/photo-1509840841025-9088ba78a826?w=800&q=80',
                estimatedTimeMinutes: 60,
              ),
            ]
          : const [
              AttractionItem(
                id: 'gen_1',
                name: 'Centro Storico & Quartieri',
                category: 'Passeggiata',
                why: 'Scorci pittoreschi e botteghe tipiche da vivere a piedi.',
                imageUrl: 'https://images.unsplash.com/photo-1509840841025-9088ba78a826?w=800&q=80',
                estimatedTimeMinutes: 90,
              ),
            ];

      return GeminiTripPlanDraft(
        message: 'Ecco i monumenti ed esperienze imperdibili di $dest. Fai swipe per comporre il tuo itinerario ideale!',
        destination: dest,
        durationDays: 3,
        stage: TripPlanningStage.attractions,
        attractions: attractions,
        suggestedReplies: const ['Ho scelto le attrazioni', 'Mostrami dove alloggiare'],
        destinationVisual: visual,
      );
    }

    if (stage == TripPlanningStage.stay) {
      final stays = await StaySearchService().searchStays(destination: dest);
      return GeminiTripPlanDraft(
        message: 'Ho calcolato la zona baricentrica perfetta per $dest rispetto alle tue preferenze. Ecco le migliori strutture:',
        destination: dest,
        durationDays: 3,
        stage: TripPlanningStage.stay,
        stayOffers: stays,
        suggestedReplies: const ['Salva alloggio', 'Crea itinerario giorno per giorno'],
        destinationVisual: visual,
      );
    }

    // Default stage: transport
    return GeminiTripPlanDraft(
      message: '$dest-$departureCity, ovviamente si vola! Preferisci voli diretti? E cosa più importante, in quante persone siete e in che date?',
      destination: dest,
      durationDays: 3,
      stage: TripPlanningStage.transport,
      shouldSearchFlights: false,
      suggestedReplies: const ['Voli diretti', 'In coppia', 'Prossimo weekend', '2 persone'],
      destinationVisual: visual,
    );
  }
}
