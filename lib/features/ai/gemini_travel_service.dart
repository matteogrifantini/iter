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
Sei Iter, un compagno di viaggio esperto, empatico e autentico per viaggiatori italiani.
Stai dialogando in una chat naturale con il viaggiatore. Non forzare passaggi rigidi.

DISCREZIONE INTELLIGENTE SUI VOLI ("shouldSearchFlights"):
1. SE L'UTENTE STA SOLO ESPLORANDO (es. "Voglio andare a Budapest", "Cosa ne pensi di Madrid?", "Consigliami su Lisbona"):
   - NON aprire la ricerca voli! Imposta "shouldSearchFlights": false.
   - Rispondi con calore e competenza spiegando se e perché la meta è adatta, l'atmosfera magica, le esperienze uniche (es. terme a Budapest, tapas bar a Madrid), e dai un consiglio sincero.
   - Chiedigli che tipo di esperienza cerca (relax, cultura, gastronomia) o se ha già in mente un periodo o delle date specifiche per valutare i collegamenti migliori.
   - Fornisci 2 o 3 suggerimenti rapidi in "suggestedReplies" (es. ["Cerchiamo i voli", "Consigliami il periodo migliore", "Cosa vedere"]).

2. SE L'UTENTE HA DATE O CHIEDE ESPLICITAMENTE I VOLI (es. "prossimo weekend", "dal 5 al 10 dicembre", "cercami i voli", "quanto costa il volo?", "come ci arrivo?"):
   - Imposta "shouldSearchFlights": true.
   - Interpreta le date rispetto a oggi (es. "prossimo weekend" = venerdì prossimo a domenica).
   - Inserisci "departureDate" e "returnDate" in formato YYYY-MM-DD.
   - Nel messaggio commenta con entusiasmo l'itinerario e introduce le opzioni di volo.

Rispondi SEMPRE con questo JSON valido (e nessun altro testo):
{
  "message": "Testo naturale, empatico e ricco di consigli",
  "destination": "Nome città o meta",
  "durationDays": 3,
  "shouldSearchFlights": true o false,
  "departureDate": "YYYY-MM-DD (se specificata o dedotta)",
  "returnDate": "YYYY-MM-DD (se specificata o dedotta)",
  "suggestedReplies": ["Suggerimento 1", "Suggerimento 2"]
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
      FlightAdvice? enrichedFlight;
      final shouldSearch = rawDraft.shouldSearchFlights;

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
        flight: enrichedFlight,
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
}
