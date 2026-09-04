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
    'gemini-3.5-flash-lite',
    'gemini-3.1-flash-lite',
    'gemini-2.5-flash',
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
4. Fornisci 3-4 "suggestedReplies" con i nomi delle mete proposte o opzioni pertinenti.

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
STATO: INQUADRAMENTO CONVERSAZIONALE STEP-BY-STEP (UNA SOLA DOMANDA ALLA VOLTA).

REGOLA FONDAMENTALE DI CONVERSAZIONE:
- Fai SEMPRE UNA SOLA domanda per messaggio, naturale e mirata! Non elencare mai più domande e non inserire mai form o filtri!
- Guarda attentamente la cronologia della conversazione per capire cosa l'utente ha già detto o scelto:
  * Se non sappiamo con chi viaggia: accogli la meta con 1 frase da insider e chiedi con quante persone viaggia.
  * Se l'utente ha detto o scelto "Date flessibili" o periodo generico: chiedi quanti giorni desidera fare o in quale mese/stagione.
  * Se l'utente specifica la durata (es. "3-5 giorni", "un weekend"): chiedi in quale mese o periodo dell'anno vorrebbe partire.
  * Se non sappiamo che tipo di vacanza/vibe desidera: chiedi che tipo di esperienza cerca a destinazione.
  * Se le date o periodo sono definiti o l'utente chiede voli: chiedi se preferisce voli diretti e se ha orari preferiti.
  * Se l'utente ha espresso la preferenza sui voli (es. "Solo voli diretti", "Anche con scalo", "Mattina", ecc.):
    - Conferma in modo caloroso e conciso di aver trovato le soluzioni migliori (es. "Perfetto, ho filtrato le migliori combinazioni per le tue date. Clicca su 'Scegli volo' qui sotto per bloccare l'orario ideale e proseguire!").
    - IMPOSTA "shouldSearchFlights": true!
    - È SEVERAMENTE VIETATO fare domande su alloggi, hotel o tappe in questo messaggio! Il viaggiatore deve prima scegliere e confermare il volo!
    - In "suggestedReplies": [] lascia lista vuota!
- NON generare MAI itinerario giorno per giorno ("days") o monumenti ("attractions") in questo step di inquadramento!
- "shouldSearchFlights": true SOLO quando ci sono date definite o richiesta esplicita di voli o risposta alle preferenze di volo.

REGOLA CRUCIALE PER LE "suggestedReplies" (BOTTONI/CHIP CLICCABILI SOTTO LA TUA DOMANDA):
- "suggestedReplies" DEVE contenere ESATTAMENTE da 3 a 4 opzioni brevi (2-3 parole max ciascuna) che siano le RISPOSTE DIRETTE alla domanda che poni in "message"!
- I bottoni appariranno sotto la tua bolla, quindi devono permettere all'utente di rispondere con 1 tap coerente alla TUA domanda:
  * Se chiedi QUANTI GIORNI / DURATA: suggerisci opzioni di durata (es. ["Weekend (2-3 gg)", "4-5 giorni", "1 settimana", "Più di 7 giorni"]).
  * Se chiedi IL MESE o IL PERIODO: suggerisci mesi o stagioni (es. ["Primavera (Mar-Mag)", "Estate (Giu-Ago)", "Settembre / Ottobre", "Inverno"]).
  * Se chiedi DATE / FLESSIBILITÀ: suggerisci (es. ["Prossimo weekend", "Tra 2 settimane", "Ponte festivo", "Date flessibili"]).
  * Se chiedi CON CHI VIAGGIA: suggerisci (es. ["In coppia", "Da solo", "Con amici", "In famiglia"]).
  * Se chiedi IL TIPO DI VACANZA / VIBE: suggerisci (es. ["Cultura & Musei", "Relax & Parchi", "Vita serale & Locali", "Scorci & Quartieri"]).
  * Se chiedi VOLI DIRETTI o SCALI: suggerisci (es. ["Solo voli diretti", "Anche con 1 scalo", "Valuta treno"]).
- È SEVERAMENTE VIETATO proporre opzioni che non c'entrano con la domanda appena fatta (es. non proporre "In coppia" se hai chiesto quanti giorni o quale mese)!

Rispondi SOLO con questo JSON valido:
{
  "message": "Frase calorosa da insider + 1 SINGOLA domanda chiara",
  "destination": "Nome città",
  "durationDays": 3,
  "shouldSearchFlights": false,
  "suggestedReplies": ["Opzione coerente 1", "Opzione coerente 2", "Opzione coerente 3", "Opzione coerente 4"]
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
    TripPlanningContext? planningContext,
  }) async {
    if (apiKey.trim().isEmpty) {
      return _generateSmartFallback(userPrompt, departureCity, stage, planningContext: planningContext);
    }

    final today = DateTime.now();
    final todayIso = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final todayStr = GoogleFlightsUrlBuilder.formatShortDate(today);

    final fullPrompt = StringBuffer()
      ..writeln('[Contesto temporale: oggi è $todayStr ($todayIso)]')
      ..writeln('Partenza confermata: $departureCity')
      ..writeln(directOnly ? 'Preferenza volo: SOLO VOLI DIRETTI (senza scali)' : '')
      ..writeln(userStyle != null ? 'Stile preferito: $userStyle' : '')
      ..writeln(budget != null ? 'Budget indicativo: $budget' : '');

    if (planningContext != null) {
      fullPrompt.writeln('[STATO DEL VIAGGIO ACCUMULATO FINORA:');
      if (planningContext.destination != null) fullPrompt.writeln('- Destinazione: ${planningContext.destination}');
      if (planningContext.travelers != null) fullPrompt.writeln('- Viaggiatori: ${planningContext.travelers}');
      if (planningContext.tripStyle != null) fullPrompt.writeln('- Stile/Vibe: ${planningContext.tripStyle}');
      if (planningContext.month != null) fullPrompt.writeln('- MESE FISSATO: ${planningContext.month} (MOLTO IMPORTANTE: qualsiasi data "11-19" o simili si riferisce TASSATIVAMENTE a questo mese!)');
      if (planningContext.dates != null) fullPrompt.writeln('- Date/Periodo: ${planningContext.dates}');
      if (planningContext.durationDays != null) fullPrompt.writeln('- Durata: ${planningContext.durationDays} giorni');
      fullPrompt.writeln(']');
    }

    fullPrompt.writeln('Nuovo messaggio del viaggiatore: $userPrompt');

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
          defaultMonth: planningContext?.monthIndex,
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
    TripPlanningStage stage, {
    TripPlanningContext? planningContext,
  }) async {
    final lower = userPrompt.toLowerCase();
    String dest = planningContext?.destination ?? 'Barcellona';

    if (lower.contains('tenerife') || lower.contains('canarie')) {
      dest = 'Tenerife';
    } else if (lower.contains('new york') || lower.contains('nyc')) {
      dest = 'New York';
    } else if (lower.contains('berlino') || lower.contains('berlin')) {

      dest = 'Berlino';
    } else if (lower.contains('monaco') || lower.contains('munich')) {
      dest = 'Monaco di Baviera';
    } else if (lower.contains('stoccarda') || lower.contains('stuttgart')) {
      dest = 'Stoccarda';
    } else if (lower.contains('messina')) {

      dest = 'Messina';


    } else if (lower.contains('palermo')) {
      dest = 'Palermo';
    } else if (lower.contains('lisbona')) {
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

    int duration = 3;
    final matchDays = RegExp(r'(\d+)\s*giorn').firstMatch(lower);
    if (matchDays != null) {
      duration = int.tryParse(matchDays.group(1)!) ?? 3;
    }

    final visual = await VisualMediaService().getVisualData(dest);

    if (stage == TripPlanningStage.attractions) {
      final List<AttractionItem> attractions;
      if (dest.toLowerCase().contains('tenerife') || dest.toLowerCase().contains('canarie')) {
        attractions = const [
          AttractionItem(
            id: 'tfs_1',
            name: 'Parco Nazionale del Teide & Teleférico',
            category: 'Vulcano & Natura UNESCO',
            why: 'La vetta più alta di Spagna (3.718 m), circondata da un paesaggio lunare di colate laviche straordinario.',
            imageUrl: 'https://images.unsplash.com/photo-1588668214407-6ea9a6d8c272?w=800&q=80',
            estimatedTimeMinutes: 180,
          ),
          AttractionItem(
            id: 'tfs_2',
            name: 'Gola di Masca & Scogliere dei Giganti',
            category: 'Paesaggi & Panorami',
            why: 'Un villaggio incastonato tra gole spettacolari che scendono verso scogliere verticali a picco sull\'Atlantico.',
            imageUrl: 'https://images.unsplash.com/photo-1544644181-1484b3fdfc62?w=800&q=80',
            estimatedTimeMinutes: 120,
          ),
          AttractionItem(
            id: 'tfs_3',
            name: 'San Cristóbal de La Laguna',
            category: 'Borgo Coloniale UNESCO',
            why: 'L\'antica capitale con eleganti palazzi colorati del XVI-XVIII secolo, cortili fioriti e atmosfera universitaria vivace.',
            imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800&q=80',
            estimatedTimeMinutes: 90,
          ),
          AttractionItem(
            id: 'tfs_4',
            name: 'Parco Rurale di Anaga & Foreste di Laurisilva',
            category: 'Trekking & Foreste Primordiali',
            why: 'Una delle foreste pluviali primordiali più antiche d\'Europa tra crinali montuosi e nebbie oceaniche incantate.',
            imageUrl: 'https://images.unsplash.com/photo-1518684079-3c830dcef090?w=800&q=80',
            estimatedTimeMinutes: 150,
          ),
          AttractionItem(
            id: 'tfs_5',
            name: 'Playa de Las Teresitas & Santa Cruz',
            category: 'Spiaggia & Relax Oceanico',
            why: 'La spiaggia più famosa dell\'isola con sabbia dorata del Sahara, palme e acque calme protette dalla scogliera.',
            imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800&q=80',
            estimatedTimeMinutes: 120,
          ),
        ];
      } else if (dest.toLowerCase().contains('new york') || dest.toLowerCase().contains('nyc')) {

        attractions = const [
          AttractionItem(
            id: 'nyc_1',
            name: 'Statua della Libertà & Ellis Island',
            category: 'Icona Mondiale',
            why: 'Simbolo eterno di New York e degli Stati Uniti, affacciata sulla baia dell\'Hudson.',
            imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a1/Statue_of_Liberty_70.jpg/1280px-Statue_of_Liberty_70.jpg',
            estimatedTimeMinutes: 120,
          ),
          AttractionItem(
            id: 'nyc_2',
            name: 'Central Park & Bethesda Terrace',
            category: 'Natura & Vibe',
            why: 'Il polmone verde di Manhattan tra laghi, ponti in ghisa e viali alberati leggendari.',
            imageUrl: 'https://images.unsplash.com/photo-1534430480872-3498386e7856?w=800&q=80',
            estimatedTimeMinutes: 90,
          ),
          AttractionItem(
            id: 'nyc_3',
            name: 'Empire State Building & Top of the Rock',
            category: 'Panorama Skyline',
            why: 'Gli osservatori più iconici dello skyline per ammirare Manhattan al tramonto.',
            imageUrl: 'https://images.unsplash.com/photo-1538688525198-9b88f6f53126?w=800&q=80',
            estimatedTimeMinutes: 75,
          ),
          AttractionItem(
            id: 'nyc_4',
            name: 'Ponte di Brooklyn & DUMBO',
            category: 'Architettura & Passeggiata',
            why: 'Passeggiata sospesa tra i cavi d\'acciaio del 1883 con vista mozzafiato su Lower Manhattan.',
            imageUrl: 'https://images.unsplash.com/photo-1496442226666-8d4d0e62e6e9?w=800&q=80',
            estimatedTimeMinutes: 60,
          ),
          AttractionItem(
            id: 'nyc_5',
            name: 'The Met (Metropolitan Museum of Art)',
            category: 'Arte & Cultura',
            why: 'Uno dei musei più straordinari al mondo, dal tempio egizio di Dendur alla terrazza panoramica.',
            imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/30/Metropolitan_Museum_of_Art_%28The_Met%29_-_Central_Park%2C_NYC.jpg/1280px-Metropolitan_Museum_of_Art_%28The_Met%29_-_Central_Park%2C_NYC.jpg',
            estimatedTimeMinutes: 120,
          ),
          AttractionItem(
            id: 'nyc_6',
            name: 'High Line & Hudson Yards (The Vessel)',
            category: 'Design Urbano',
            why: 'Parco lineare sopraelevato ricavato da una vecchia ferrovia merci tra architettura contemporanea.',
            imageUrl: 'https://images.unsplash.com/photo-1541336032412-2048a678540d?w=800&q=80',
            estimatedTimeMinutes: 60,
          ),
        ];
      } else if (dest.toLowerCase().contains('berlin')) {

        attractions = const [
          AttractionItem(
            id: 'ber_1',
            name: 'Porta di Brandeburgo & Pariser Platz',
            category: 'Icona Storica',
            why: 'Simbolo della riunificazione tedesca e del cuore monumentale di Berlino.',
            imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a6/Brandenburger_Tor_abends.jpg/1280px-Brandenburger_Tor_abends.jpg',
            estimatedTimeMinutes: 45,
          ),
          AttractionItem(
            id: 'ber_2',
            name: 'Isola dei Musei & Berliner Dom',
            category: 'Arte & Architettura',
            why: 'Complesso UNESCO con 5 musei leggendari e il maestoso duomo barocco sulla Sprea.',
            imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/84/141227_Berliner_Dom.jpg/1280px-141227_Berliner_Dom.jpg',
            estimatedTimeMinutes: 120,
          ),
          AttractionItem(
            id: 'ber_3',
            name: 'East Side Gallery (Muro di Berlino)',
            category: 'Storia & Street Art',
            why: '1,3 km di Muro originale trasformato nella più grande galleria d\'arte a cielo aperto del pianeta.',
            imageUrl: 'https://images.unsplash.com/photo-1560969184-10fe8719e047?w=800&q=80',
            estimatedTimeMinutes: 75,
          ),
          AttractionItem(
            id: 'ber_4',
            name: 'Cupola del Reichstag (Norman Foster)',
            category: 'Panorama & Istituzioni',
            why: 'Vista panoramica a 360° sulla città dalla spettacolare spirale di vetro e specchi.',
            imageUrl: 'https://images.unsplash.com/photo-1599946347371-68eb71b16afc?w=800&q=80',
            estimatedTimeMinutes: 90,
          ),
          AttractionItem(
            id: 'ber_5',
            name: 'Memoriale per gli Ebrei Assassinati d\'Europa',
            category: 'Memoria & Spazio',
            why: 'Labirinto suggestivo di 2.711 stele di cemento nel pieno centro di Berlino.',
            imageUrl: 'https://images.unsplash.com/photo-1587330979470-3595ac045ab0?w=800&q=80',
            estimatedTimeMinutes: 45,
          ),
        ];
      } else if (dest.toLowerCase().contains('monaco')) {
        attractions = const [
          AttractionItem(
            id: 'muc_1',
            name: 'Marienplatz & Neues Rathaus',
            category: 'Icona Storica & Carillon',
            why: 'Cuore pulsante di Monaco con lo spettacolo quotidiano del Glockenspiel sulla torre neogotica.',
            imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c9/Neues_Rathaus_M%C3%BCnchen_2018.jpg/1280px-Neues_Rathaus_M%C3%BCnchen_2018.jpg',
            estimatedTimeMinutes: 60,
          ),
          AttractionItem(
            id: 'muc_2',
            name: 'Frauenkirche (Duomo di Monaco)',
            category: 'Arte Sacra & Leggenda',
            why: 'Le celebri cupole a cipolla e la misteriosa "impronta del diavolo" sul pavimento della navata.',
            imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/da/Frauenkirche_Munich_-_View_from_Peterskirche_Tower2.jpg/1280px-Frauenkirche_Munich_-_View_from_Peterskirche_Tower2.jpg',
            estimatedTimeMinutes: 45,
          ),
          AttractionItem(
            id: 'muc_3',
            name: 'Englischer Garten & Eisbachwelle',
            category: 'Natura & Surf Urbano',
            why: 'Uno dei parchi urbani più estesi d\'Europa dove i surfisti cavalcano l\'onda continua del fiume Eisbach.',
            imageUrl: 'https://images.unsplash.com/photo-1595867818082-083862f3d630?w=800&q=80',
            estimatedTimeMinutes: 90,
          ),
          AttractionItem(
            id: 'muc_4',
            name: 'Viktualienmarkt',
            category: 'Mercato Storico & Sapori',
            why: 'Bancarelle storiche di specialità bavaresi, brezel caldi e un celebre Biergarten all\'aperto.',
            imageUrl: 'https://images.unsplash.com/photo-1533105079780-92b9be482077?w=800&q=80',
            estimatedTimeMinutes: 60,
          ),
          AttractionItem(
            id: 'muc_5',
            name: 'Residenz di Monaco',
            category: 'Palazzo Reale & Musei',
            why: 'Grandioso palazzo ducale con l\'Antiquarium rinascimentale e la stanza del tesoro dei Wittelsbach.',
            imageUrl: 'https://images.unsplash.com/photo-1513581166391-887a96ddeafd?w=800&q=80',
            estimatedTimeMinutes: 120,
          ),
        ];
      } else if (dest.toLowerCase().contains('stoccarda') || dest.toLowerCase().contains('stuttgart')) {
        attractions = const [
          AttractionItem(
            id: 'str_1',
            name: 'Mercedes-Benz Museum',
            category: 'Museo Iconico & Design',
            why: 'Architettura avveniristica a doppia elica con 130 anni di storia automobilistica.',
            imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/26/Mercedes-Benz_Museum_201312_08_blue_hour.jpg/1280px-Mercedes-Benz_Museum_201312_08_blue_hour.jpg',
            estimatedTimeMinutes: 120,
          ),
          AttractionItem(
            id: 'str_2',
            name: 'Schlossplatz & Neues Schloss',
            category: 'Piazza Reale & Cuore Storico',
            why: 'Il salotto elegante di Stoccarda con la Colonna del Giubileo e il monumentale palazzo barocco.',
            imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b3/StuttgartSchlossPlatz.JPG/1280px-StuttgartSchlossPlatz.JPG',
            estimatedTimeMinutes: 60,
          ),
          AttractionItem(
            id: 'str_3',
            name: 'Staatsgalerie Stuttgart',
            category: 'Arte Classica & Contemporanea',
            why: 'Edificio postmoderno di James Stirling con opere di Rembrandt, Monet, Picasso e Beuys.',
            imageUrl: 'https://images.unsplash.com/photo-1542282088-72c9c27ed0cd?w=800&q=80',
            estimatedTimeMinutes: 90,
          ),
          AttractionItem(
            id: 'str_4',
            name: 'Stadtbibliothek Stuttgart',
            category: 'Architettura Moderna & Spazio',
            why: 'Il celebre cubo bianco candido progettato da Eun Young Yi, tra le biblioteche più fotogeniche al mondo.',
            imageUrl: 'https://images.unsplash.com/photo-1507842229451-7f01be7fe802?w=800&q=80',
            estimatedTimeMinutes: 45,
          ),
          AttractionItem(
            id: 'str_5',
            name: 'Wilhelma Giardino Zoologico & Botanico',
            category: 'Natura & Architettura Moresca',
            why: 'L\'unico parco in Europa che fonde serre esotiche moresche dell\'800 con un vasto giardino botanico e zoologico.',
            imageUrl: 'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=800&q=80',
            estimatedTimeMinutes: 120,
          ),
        ];
      } else if (dest.toLowerCase().contains('messina')) {



        attractions = const [
          AttractionItem(
            id: 'ms_1',
            name: 'Duomo & Orologio Astronomico',
            category: 'Architettura & Tradizione',
            why: 'A mezzogiorno il campanile attiva lo spettacolo del meccanismo semovente più complesso al mondo.',
            imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/c/cc/Duomo_di_Messina.jpg',
            estimatedTimeMinutes: 75,
          ),
          AttractionItem(
            id: 'ms_2',
            name: 'Fontana di Orione',
            category: 'Scultura Rinascimentale',
            why: 'Definita dal Berenson la più bella fontana del Cinquecento europeo, opera del Montorsoli.',
            imageUrl: 'https://images.unsplash.com/photo-1533105079780-92b9be482077?w=800&q=80',
            estimatedTimeMinutes: 45,
          ),
          AttractionItem(
            id: 'ms_3',
            name: 'Sacrario di Cristo Re (Belvedere)',
            category: 'Panorama & Tramonto',
            why: 'La vista più spettacolare a 360° sull\'intera falce naturale del porto e sullo Stretto.',
            imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/1/17/MessinaStrait.jpg',
            estimatedTimeMinutes: 60,
          ),
          AttractionItem(
            id: 'ms_4',
            name: 'Chiesa dei Catalani',
            category: 'Arte Arabo-Bizantina',
            why: 'Gioiello del XII secolo miracolosamente scampato al terremoto del 1908.',
            imageUrl: 'https://images.unsplash.com/photo-1516483638261-f4dbaf036963?w=800&q=80',
            estimatedTimeMinutes: 45,
          ),
          AttractionItem(
            id: 'ms_5',
            name: 'Capo Peloro & Laghi di Ganzirri',
            category: 'Natura & Due Mari',
            why: 'Punta estrema della Sicilia tra correnti mitiche e borgo marinaro verace.',
            imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800&q=80',
            estimatedTimeMinutes: 120,
          ),
        ];
      } else if (dest.toLowerCase().contains('palermo')) {
        attractions = const [
          AttractionItem(
            id: 'pal_1',
            name: 'Cattedrale di Palermo',
            category: 'Arte Arabo-Normanna',
            why: 'Maestosa cattedrale patrimonio UNESCO con terrazze panoramiche sui tetti e sulle cupole.',
            imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/45/Palermo_Cathedral_Facade.jpg/1280px-Palermo_Cathedral_Facade.jpg',
            estimatedTimeMinutes: 75,
          ),
          AttractionItem(
            id: 'pal_2',
            name: 'Cappella Palatina & Palazzo Reale',
            category: 'Mosaici & Storia',
            why: 'Mosaici dorati bizantini tra i più splendidi al mondo e soffitto arabo in legno intagliato.',
            imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a9/16._Mai_1897_An_diesem_Tag_wurde_die_Oper_von_Palermo_er%C3%B6ffnet._02.jpg/1280px-16._Mai_1897_An_diesem_Tag_wurde_die_Oper_von_Palermo_er%C3%B6ffnet._02.jpg',
            estimatedTimeMinutes: 90,
          ),
          AttractionItem(
            id: 'pal_3',
            name: 'Mercato Storico di Ballarò',
            category: 'Street Food & Vita Verace',
            why: 'Un souk vivente tra profumi di panelle, sfincione caldo e le voci storiche dei venditori.',
            imageUrl: 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=800&q=80',
            estimatedTimeMinutes: 60,
          ),
          AttractionItem(
            id: 'pal_4',
            name: 'Teatro Massimo & Quattro Canti',
            category: 'Architettura & Passeggiata',
            why: 'Il teatro lirico monumentale e la piazza ottagonale crocevia scenografico della città barocca.',
            imageUrl: 'https://images.unsplash.com/photo-1516483638261-f4dbaf036963?w=800&q=80',
            estimatedTimeMinutes: 60,
          ),
          AttractionItem(
            id: 'pal_5',
            name: 'Spiaggia di Mondello',
            category: 'Mare & Relax Liberty',
            why: 'Sabbia chiarissima, mare caraibico e villette d\'epoca a soli 20 minuti di bus dal centro.',
            imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/5/52/Il_golfo_di_Mondello.jpg/1280px-Il_golfo_di_Mondello.jpg',
            estimatedTimeMinutes: 120,
          ),
        ];
      } else if (dest.toLowerCase().contains('barcellona')) {
        attractions = const [
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
        ];
      } else {
        attractions = const [
          AttractionItem(
            id: 'gen_1',
            name: 'Centro Storico & Quartieri',
            category: 'Passeggiata',
            why: 'Scorci pittoreschi e botteghe tipiche da vivere a piedi.',
            imageUrl: 'https://images.unsplash.com/photo-1509840841025-9088ba78a826?w=800&q=80',
            estimatedTimeMinutes: 90,
          ),
        ];
      }

      return GeminiTripPlanDraft(
        message: 'Ecco i monumenti ed esperienze imperdibili di $dest. Fai swipe per comporre il tuo itinerario ideale!',
        destination: dest,
        durationDays: duration,
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
        durationDays: duration,
        stage: TripPlanningStage.stay,
        stayOffers: stays,
        suggestedReplies: const ['Salva alloggio', 'Crea itinerario giorno per giorno'],
        destinationVisual: visual,
      );
    }

    if (stage == TripPlanningStage.itinerary) {
      final List<DailyPlanDraft> days;
      if (dest.toLowerCase().contains('messina')) {
        days = [
          const DailyPlanDraft(
            dayNumber: 1,
            theme: 'Centro Storico, Arte Normanna & Panorama dello Stretto',
            stops: [
              '09:30 · Piazza Duomo & Orologio Astronomico',
              '11:15 · Fontana di Orione & Chiesa dei Catalani (350m · 5 min a piedi)',
              '16:30 · Sacrario di Cristo Re per il tramonto sullo Stretto (800m · 11 min a piedi)',
            ],
            diningRecommendation: 'Pausa pranzo: Focaccia tradizionale messinese con tuma e scarola da Tommasino (~7€)',
          ),
          const DailyPlanDraft(
            dayNumber: 2,
            theme: 'Brezza Marina, Capo Peloro & I Due Mari',
            stops: [
              '10:00 · Riserva Naturale dei Laghi di Ganzirri & Borgo marinaro',
              '12:30 · Spiaggia di Capo Peloro (Punta estrema della Sicilia)',
              '17:00 · Passeggiata lungomare e granita al caffè con brioche da De Pasquale',
            ],
            diningRecommendation: 'Cena: Spaghetto alle vongole di Ganzirri alla trattoria del lago (~28€)',
          ),
          if (duration >= 3)
            const DailyPlanDraft(
              dayNumber: 3,
              theme: 'Borghi dello Stretto & Escursione Panoramica',
              stops: [
                '10:00 · Forte Gonzaga con vista panoramica sui Peloritani',
                '13:00 · Escursione pomeridiana a Taormina o Scilla (35 min)',
                '19:00 · Rientro e brindisi sul rooftop bar con vista Stretto',
              ],
              diningRecommendation: 'Aperitivo siciliano con arancini e calice di Faro DOC (~15€)',
            ),
        ];
      } else if (dest.toLowerCase().contains('palermo')) {
        days = [
          const DailyPlanDraft(
            dayNumber: 1,
            theme: 'Barocco Dorato, Cattedrale & Street Food Verace',
            stops: [
              '09:30 · Cattedrale di Palermo & Terrazze panoramiche',
              '11:30 · Quattro Canti & Piazza Pretoria (Fontana della Vergogna)',
              '13:00 · Pranzo tra i banchi storici di Ballarò (panelle e sfincione)',
              '16:00 · Cappella Palatina & Palazzo dei Normanni',
            ],
            diningRecommendation: 'Cena alla Kalsa: pasta con le sarde e cannolo espresso (~24€)',
          ),
          const DailyPlanDraft(
            dayNumber: 2,
            theme: 'Teatri Monumentali & Spiaggia Liberty di Mondello',
            stops: [
              '10:00 · Teatro Massimo & Via Maqueda',
              '12:30 · Bus 806 verso Mondello: sabbia bianca e acqua caraibica',
              '17:30 · Rientro al centro e passeggiata sul Foro Italico',
            ],
            diningRecommendation: 'Pranzo vista mare a Mondello con polpo e frittura mista (~22€)',
          ),
          if (duration >= 3)
            const DailyPlanDraft(
              dayNumber: 3,
              theme: 'Mosaici di Monreale & Atmosfera Marinara',
              stops: [
                '09:30 · Duomo di Monreale e chiostro benedettino',
                '14:00 · Passeggiata al porticciolo della Cala',
                '18:00 · Aperitivo al tramonto in Piazza Marina',
              ],
              diningRecommendation: 'Street food gourmet e birra artigianale siciliana (~16€)',
            ),
        ];
      } else if (dest == 'Tenerife') {
        days = [
          const DailyPlanDraft(
            dayNumber: 1,
            theme: 'Il Vulcano Teide & Paesaggi Lunari',
            stops: [
              '09:30 · Salita in quota al Parco Nazionale del Teide (Roques de García)',
              '12:00 · Funivia del Teide fino a 3.555 metri con vista sulle altre isole',
              '16:30 · Discesa verso i vigneti e aperitivo vista oceano',
            ],
            diningRecommendation: 'Pranzo in un "Guachinche" tipico a La Orotava con papas arrugadas e coniglio al salmorejo (~16€)',
          ),
          const DailyPlanDraft(
            dayNumber: 2,
            theme: 'Borghi Coloniali UNESCO & Costa Nord',
            stops: [
              '10:00 · Passeggiata tra i palazzi nobiliari di San Cristóbal de La Laguna',
              '13:30 · Spiaggia dorata di Las Teresitas con palme e acque calme',
              '17:30 · Piscine naturali vulcaniche di Bajamar al tramonto',
            ],
            diningRecommendation: 'Pesce freschissimo del giorno grigliato al porticciolo di San Andrés (~22€)',
          ),
          if (duration >= 3)
            const DailyPlanDraft(
              dayNumber: 3,
              theme: 'Strada Panoramica di Masca & Scogliere dei Giganti',
              stops: [
                '10:00 · Guida panoramica tra i tornanti mozzafiato verso il borgo di Masca',
                '13:30 · Vista sulle scogliere verticali a picco di Los Gigantes',
                '16:30 · Relax e tramonto dorato sulla spiaggia vulcanica di Playa de la Arena',
              ],
              diningRecommendation: 'Tapas canarie e vino vulcanico locale vista tramonto atlantico (~20€)',
            ),
        ];
      } else if (dest == 'Berlino') {

        days = [
          const DailyPlanDraft(
            dayNumber: 1,
            theme: 'Il Cuore Storico & L\'Isola dei Musei',
            stops: [
              '09:30 · Porta di Brandeburgo & Pariser Platz',
              '11:00 · Memoriale dell\'Olocausto (350m · 5 min a piedi)',
              '14:00 · Isola dei Musei (Pergamonmuseum o Neues Museum)',
              '17:30 · Duomo di Berlino e passeggiata lungo la Sprea',
            ],
            diningRecommendation: 'Currywurst storico con salsa artigianale da Curry 36 (~8€)',
          ),
          const DailyPlanDraft(
            dayNumber: 2,
            theme: 'Muro di Berlino, Street Art & Vibe di Kreuzberg',
            stops: [
              '10:00 · East Side Gallery (1,3 km di murales del Muro)',
              '12:30 · Ponte Oberbaumbrücke e quartiere Friedrichshain',
              '15:30 · Kreuzberg, canali di Paul-Lincke-Ufer e boutique vintage',
              '19:00 · Sunset drink al Monkey Bar vista Tiergarten',
            ],
            diningRecommendation: 'Kebab gourmet da Mustafa Gemüse Kebap o spätzle bavaresi (~12€)',
          ),
          if (duration >= 3)
            const DailyPlanDraft(
              dayNumber: 3,
              theme: 'Architettura, Parchi & Cupola del Reichstag',
              stops: [
                '10:00 · Giro in bici o passeggiata all\'ex aeroporto di Tempelhof',
                '14:00 · Hackescher Markt e cortili nascosti (Hackesche Höfe)',
                '17:30 · Cupola di vetro del Reichstag al tramonto (prenotata)',
              ],
              diningRecommendation: 'Cena tipica berlinese con birra artigianale a Mitte (~25€)',
            ),
        ];
      } else if (dest == 'Monaco di Baviera') {
        days = [
          const DailyPlanDraft(
            dayNumber: 1,
            theme: 'Il Cuore della Baviera: Marienplatz & Viktualienmarkt',
            stops: [
              '09:30 · Marienplatz, Neues Rathaus e carillon del Glockenspiel',
              '11:30 · Salita sulla torre di Alter Peter per la vista panoramica',
              '13:00 · Pranzo al Viktualienmarkt tra brezel e Weißwurst',
              '15:30 · Frauenkirche e passeggiata fino a Karlsplatz (Stachus)',
            ],
            diningRecommendation: 'Bratwurst e crauti nella storica birreria Augustiner Großgaststätte (~18€)',
          ),
          const DailyPlanDraft(
            dayNumber: 2,
            theme: 'Arte Reale & Natura all\'Englischer Garten',
            stops: [
              '10:00 · Residenz di Monaco e cortili reali di corte',
              '13:30 · Odeonsplatz e giardini Hofgarten',
              '15:00 · Surfisti all\'Eisbachwelle ed esplorazione dell\'Englischer Garten',
              '18:00 · Birra al Biergarten della Chinesischer Turm',
            ],
            diningRecommendation: 'Stinco di maiale croccante con canederli di patate (~22€)',
          ),
          if (duration >= 3)
            const DailyPlanDraft(
              dayNumber: 3,
              theme: 'Quartieri Creativi & Castelli Bavaresi',
              stops: [
                '10:00 · Schloss Nymphenburg e i suoi padiglioni barocchi',
                '14:30 · Glockenbachviertel: caffè d\'autore e boutique di design',
                '18:30 · Tramonto lungo le sponde del fiume Isar',
              ],
              diningRecommendation: 'Cena bavarese contemporanea e birra artigianale a Glockenbach (~26€)',
            ),
        ];
      } else if (dest == 'Stoccarda') {
        days = [
          const DailyPlanDraft(
            dayNumber: 1,
            theme: 'Il Salotto Svevo: Schlossplatz & Staatsgalerie',
            stops: [
              '09:30 · Schlossplatz, Neues Schloss e giardini barocchi',
              '11:30 · Staatsgalerie Stuttgart (capolavori e architettura Stirling)',
              '13:30 · Pranzo tipico svevo in una Weinstube storica',
              '15:30 · Passeggiata lungo la Königstraße e il centro pedonale',
            ],
            diningRecommendation: 'Maultaschen tradizionali con insalata tiepida di patate (~16€)',
          ),
          const DailyPlanDraft(
            dayNumber: 2,
            theme: 'La Culla dell\'Auto & i Vigneti del Neckar',
            stops: [
              '10:00 · Mercedes-Benz Museum (viaggio su 9 piani e architettura a doppia elica)',
              '13:30 · Pranzo al bistrot del museo o lungo il fiume',
              '15:00 · Passeggiata panoramica tra le vigne del colle Württemberg',
              '17:30 · Cappella sepolcrale di Württemberg con vista su tutta la valle',
            ],
            diningRecommendation: 'Spätzle freschi al formaggio montano e vino bianco locale (~19€)',
          ),
          if (duration >= 3)
            const DailyPlanDraft(
              dayNumber: 3,
              theme: 'Modernismo, Oasi Verde & Panorama al Tramonto',
              stops: [
                '10:00 · Stadtbibliothek Stuttgart (il cubo bianco d\'autore)',
                '12:30 · Wilhelma Giardino Zoologico e serre moresche ottocentesche',
                '16:30 · Gerberviertel: negozi indipendenti e boutique cafè',
                '18:30 · Belvedere panoramico di Monte Birkenkopf al tramonto',
              ],
              diningRecommendation: 'Cena sveva contemporanea con birra artigianale locale (~24€)',
            ),
        ];
      } else {
        days = [



          DailyPlanDraft(
            dayNumber: 1,
            theme: 'Centro Storico & Prime Scoperte a Piedi',
            stops: [
              '09:30 · Passeggiata tra i vicoli storici e piazze centrali',
              '12:00 · Tappa culturale e punto panoramico',
              '17:00 · Tramonto e passeggiata nei quartieri caratteristici',
            ],
            diningRecommendation: 'Sosta gastronomica tipica in trattoria storica locale (~20€)',
          ),
          DailyPlanDraft(
            dayNumber: 2,
            theme: 'Arte, Monumenti & Vita di Quartiere',
            stops: [
              '10:00 · Visita al monumento principale scelto',
              '14:30 · Mercato coperto o botteghe artigiane',
              '18:30 · Aperitivo in piazza o lungo il fiume/mare',
            ],
            diningRecommendation: 'Cena tradizionale con piatti tipici della città (~30€)',
          ),
        ];
      }

      return GeminiTripPlanDraft(
        message: 'Ho ottimizzato il tuo itinerario giorno per giorno con tempi e percorsi a piedi realistici per $dest. Puoi salvarlo direttamente nelle tue pianificazioni!',
        destination: dest,
        durationDays: duration,
        stage: TripPlanningStage.itinerary,
        days: days,
        suggestedReplies: const ['Salva viaggio', 'Modifica tappe'],
        destinationVisual: visual,
      );
    }

    // Inquadramento Step-by-Step intelligente:
    final hasCompanions = lower.contains('coppia') ||
        lower.contains('solo') ||
        lower.contains('solitario') ||
        lower.contains('amici') ||
        lower.contains('famiglia') ||
        lower.contains('persona') ||
        lower.contains('persone') ||
        lower.contains('2 ') ||
        lower.contains('due');

    final hasVibe = lower.contains('cultur') ||
        lower.contains('muse') ||
        lower.contains('relax') ||
        lower.contains('park') ||
        lower.contains('parch') ||
        lower.contains('seral') ||
        lower.contains('night') ||
        lower.contains('local') ||
        lower.contains('architett') ||
        lower.contains('scorc') ||
        lower.contains('passeggiat');

    final hasFlexibleDates = lower.contains('flessibil');

    final hasDuration = lower.contains('giorn') ||
        lower.contains('weekend') ||
        lower.contains('settiman') ||
        RegExp(r'\b\d+\s*(?:-|ai|a)?\s*\d*\s*g(?:iorn)?\b').hasMatch(lower);

    final hasSeasonOrMonth = lower.contains('maggio') ||
        lower.contains('giugno') ||
        lower.contains('luglio') ||
        lower.contains('agosto') ||
        lower.contains('settembre') ||
        lower.contains('ottobre') ||
        lower.contains('novembre') ||
        lower.contains('dicembre') ||
        lower.contains('gennaio') ||
        lower.contains('febbraio') ||
        lower.contains('marzo') ||
        lower.contains('aprile') ||
        lower.contains('primavera') ||
        lower.contains('estate') ||
        lower.contains('autunno') ||
        lower.contains('inverno');

    final hasSpecificDates = lower.contains('prossimo weekend') ||
        lower.contains('tra 2 settimane') ||
        lower.contains('tra due settimane') ||
        lower.contains('ponte');

    // Integrazione planningContext per scrematura rigorosa
    final companionsKnown = (planningContext?.travelers != null && planningContext!.travelers!.isNotEmpty) || hasCompanions;
    final vibeKnown = (planningContext?.tripStyle != null && planningContext!.tripStyle!.isNotEmpty) || hasVibe;
    final datesOrMonthKnown = (planningContext?.month != null && planningContext!.month!.isNotEmpty) ||
        (planningContext?.dates != null && planningContext!.dates!.isNotEmpty) ||
        hasSeasonOrMonth || hasSpecificDates;

    final String transportMsg;
    final List<String> suggested;

    if (!companionsKnown) {
      if (dest == 'Tenerife') {
        transportMsg = 'Tenerife è una meta spettacolare tra il vulcano Teide, borghi coloniali e oceano con clima primaverile perenne!\n\nIn quanti avete intenzione di viaggiare?';
      } else if (dest == 'New York') {

        transportMsg = 'New York è una metropoli straordinaria: l\'energia di Manhattan, i musei leggendari e lo skyline più famoso al mondo!\n\nIn quanti avete intenzione di viaggiare?';
      } else if (dest == 'Berlino') {
        transportMsg = 'Berlino è straordinaria: un concentrato unico di storia recente, musei imperdibili e quartieri creativi!\n\nCon quante persone hai intenzione di viaggiare?';
      } else if (dest == 'Monaco di Baviera') {
        transportMsg = 'Monaco di Baviera è magnifica: un perfetto connubio tra maestosità bavarese, birrerie storiche e ampi parchi!\n\nCon quante persone hai intenzione di viaggiare?';
      } else if (dest == 'Stoccarda') {
        transportMsg = 'Stoccarda è affascinante: un connubio tra musei dell\'auto all\'avanguardia, palazzi reali barocchi e splendidi vigneti sul Neckar!\n\nCon quante persone hai intenzione di viaggiare?';
      } else if (dest == 'Messina') {
        transportMsg = 'Messina è splendida per lo Stretto e la granita! Per arrivarci il volo più comodo da $departureCity è su Catania Fontanarossa (CTA, 55 min) con rapido collegamento in treno/bus lungo la costa (~50 min).\n\nCon quante persone hai intenzione di viaggiare?';
      } else if (dest == 'Palermo') {
        transportMsg = 'Palermo in $duration giorni è un\'ottima idea per staccare la spina tra street food a Ballarò e il barocco dei Quattro Canti!\n\nIn quante persone viaggiate?';
      } else if (dest == 'Milano' && (departureCity.toLowerCase().contains('roma') || departureCity.toLowerCase().contains('rome'))) {
        transportMsg = 'Per Milano da $departureCity il Frecciarossa o Italo AV (3h centro-centro) è imbattibile.\n\nIn quante persone viaggiate?';
      } else {
        transportMsg = '$dest è una meta fantastica per un viaggio di $duration giorni!\n\nCon quante persone hai intenzione di viaggiare?';
      }
      suggested = const ['In coppia', 'Da solo', 'Con amici', 'In famiglia'];
    } else if (!vibeKnown) {
      transportMsg = 'Ottima scelta! Che tipo di vacanza avete in mente per questo viaggio a $dest?';
      suggested = const ['Cultura & Musei', 'Relax & Parchi', 'Vita serale & Locali', 'Scorci & Quartieri'];
    } else if (hasFlexibleDates && !hasDuration) {
      transportMsg = 'Le date flessibili sono perfette per trovare le tariffe migliori! Quanti giorni vorreste dedicare a $dest?';
      suggested = const ['Weekend (2-3 gg)', '4-5 giorni', '1 settimana', 'Più di 7 giorni'];
    } else if (!datesOrMonthKnown) {
      transportMsg = 'Perfetto! In quali date o periodo preferite partire per $dest?';
      suggested = const ['Date flessibili', 'Prossimo mese', 'Ponte festivo', 'Date precise'];
    } else {
      transportMsg = 'Tutto chiaro! Preferisci dare prima un\'occhiata alle opzioni di volo o passiamo direttamente a scegliere le tappe di $dest?';
      suggested = const ['Scegliamo le tappe e monumenti', 'Cerca voli adesso', 'Scegli dove alloggiare'];
    }




    return GeminiTripPlanDraft(
      message: transportMsg,
      destination: dest,
      durationDays: duration,
      stage: TripPlanningStage.transport,
      shouldSearchFlights: false,
      suggestedReplies: suggested,
      destinationVisual: visual,
    );
  }
}
