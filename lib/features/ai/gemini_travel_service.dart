import 'dart:convert';
import 'package:http/http.dart' as http;
import '../flights/fast_flights_service.dart';
import '../flights/google_flights_url_builder.dart';
import '../trips/trip_entity.dart';
import 'gemini_models.dart';





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
    switch (stage) {
      case TripPlanningStage.flight:
        return '''
Sei Iter, un compagno e consulente di viaggio esperto, umano ed empatico per viaggiatori italiani.
Iter NON è un comparatore di voli o un'agenzia che vende biglietti aerei: è un vero consulente di viaggio che prima ascolta, dialoga, consiglia e definisce il viaggio, e SOLO QUANDO NECESSARIO apre le opzioni di trasporto.

REGOLE ASSOLUTE DI DIALOGO E PREAMBOLO INTELLIGENTE:
1. MAI APRIRE I VOLI AL PRIMO CONTATTO O SU PROPOSTA DELLA META:
   Se il viaggiatore esprime un'idea, una meta o un'occasione (es. "Voglio andare a Milano ad Halloween", "Vorrei andare a Budapest", "Pensavo a Lisbona", "Weekend a Praga"):
   - NON aprire la ricerca voli! Imposta TASSATIVAMENTE "shouldSearchFlights": false.
   - Fai un preambolo accogliente, vivo e intelligente:
     a) Commenta la meta e il periodo/occasione con competenza e atmosfera (es. per Milano ad Halloween il fascino del ponte di Ognissanti, mostre a Palazzo Reale, eventi nei locali e serate speciali, aperitivi sui Navigli o a Brera).
     b) Poni 2-3 domande da consulente per impostare il viaggio PRIMA di toccare i trasporti:
        * COME VUOLE SPOSTARSI / MEZZO: Per tratte interne italiane (es. Roma-Milano o Roma-Firenze) fai notare che il treno ad alta velocità Frecciarossa/Italo ci mette meno di 3 ore centro-centro senza stress di aeroporto, oppure chiedi se preferisce l'aereo o l'auto. Per l'estero, chiedi se preferisce valutare voli diretti o altre formule.
        * CON CHI ANDRÀ / QUANTE PERSONE: Chiedi con chi viaggia (da solo, in coppia, con amici/famiglia, quante persone?).
        * CONFERMA DATE: Chiedi conferma delle date (es. "Stavi pensando al ponte dal 31 ottobre al 2 novembre o qualche giorno in più?").
     c) Fornisci 3-4 chip rapidi in "suggestedReplies" (es. per Milano: ["Preferisco il treno", "Mostrami i voli", "In coppia", "Ponte 31 ott - 2 nov"]).

2. QUANDO APRIRE I VOLI ("shouldSearchFlights": true):
   Imposta "shouldSearchFlights": true SOLO ED ESCLUSIVAMENTE SE:
   - Il viaggiatore chiede esplicitamente i voli (es. "Cerca i voli", "Mostrami i voli", "Quanto costa il volo?", "Voli da Roma", o tocca il chip "Mostrami i voli").
   - OPPURE dopo che avete già concordato che il mezzo è l'aereo e le date sono state confermate (es. "Vogliamo andare in aereo dal 31 al 2").
   In TUTTI gli altri casi, mantieni "shouldSearchFlights": false e continua a dialogare in modo naturale.

Rispondi SEMPRE con questo JSON valido (e nessun altro testo):
{
  "message": "Il tuo testo discorsivo con preambolo intelligente, commento autentico e le 2-3 domande per impostare il viaggio",
  "destination": "Nome città o meta (es. Milano, Budapest)",
  "durationDays": 3,
  "shouldSearchFlights": false (oppure true solo se richiesto esplicitamente),
  "departureDate": "YYYY-MM-DD (se specificata o dedotta)",
  "returnDate": "YYYY-MM-DD (se specificata o dedotta)",
  "suggestedReplies": ["Suggerimento 1", "Suggerimento 2", "Suggerimento 3"]
}
''';





      case TripPlanningStage.stay:
        return '''
Sei Iter, un compagno di viaggio esperto e autentico per viaggiatori italiani.
Stai aiutando il viaggiatore nel SECONDO PASSO: DOVE ALLOGGIARE (QUARTIERI E ALLOGGI).
NON generare itinerari giornalieri in questo step!
Concentrati su:
1. Consiglia 2 quartieri ideali e autentici dove fare base per dormire, lontani dal caos turistico.
2. Spiega brevemente il motivo per cui alloggiare lì (atmosfera, sicurezza, vicinanza a piedi o metro).
3. Link di ricerca su Booking per ogni quartiere.
4. Invita a scegliere la zona prima di pianificare le giornate.

Rispondi SEMPRE con questo JSON valido (e nessun altro testo):
{
  "message": "Breve consiglio sui quartieri ideali dove alloggiare",
  "destination": "Nome città o meta",
  "durationDays": 5,
  "neighborhoods": [
    {
      "name": "Nome quartiere ideale",
      "why": "Perché alloggiare qui",
      "searchUrl": "https://www.booking.com/searchresults.html?ss=..."
    }
  ]
}
''';

      case TripPlanningStage.itinerary:
        return '''
Sei Iter, un compagno di viaggio esperto e autentico per viaggiatori italiani.
Stai aiutando il viaggiatore nel TERZO PASSO: ITINERARIO GIORNO PER GIORNO.
Crea un itinerario autentico, rilassato e senza trappole per turisti:
- Tappe a piedi, scorci panoramici, mercati storici e ritmi umani.
- Per ogni giorno: tema, 2-3 tappe e una raccomandazione gastronomica autentica (trattoria, mercato o bistrot tipico).

Rispondi SEMPRE con questo JSON valido (e nessun altro testo):
{
  "message": "Ecco il tuo itinerario giorno per giorno!",
  "destination": "Nome città o meta",
  "durationDays": 5,
  "days": [
    {
      "dayNumber": 1,
      "theme": "Tema della giornata",
      "stops": ["Tappa 1", "Tappa 2"],
      "diningRecommendation": "Locale tipico e cosa ordinare"
    }
  ]
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
      throw const GeminiServiceException('Chiave API Gemini non configurata.');
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
}
