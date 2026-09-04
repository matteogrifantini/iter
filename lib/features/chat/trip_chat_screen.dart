import 'dart:async';
import 'package:flutter/material.dart';
import '../../app/app_config.dart';

import '../ai/gemini_models.dart';
import '../ai/gemini_travel_service.dart';
import '../chat_first_prototype/local_preferences_service.dart';
import '../flights/google_flights_url_builder.dart';
import '../stays/stay_models.dart';
import '../stays/stay_search_service.dart';
import '../trips/trip_entity.dart';
import '../trips/trip_repository.dart';
import 'widgets/attractions_picker_sheet.dart';
import 'widgets/destination_hero_card.dart';
import 'widgets/flight_picker_sheet.dart';
import 'widgets/interactive_question_options.dart';
import 'widgets/stay_picker_sheet.dart';

class TripChatScreen extends StatefulWidget {
  const TripChatScreen({
    super.key,
    this.initialPrompt,
    this.initialTripId,
    this.tripRepository,
    this.aiService,
    required this.onOpenSnapshot,
  });

  final String? initialPrompt;
  final String? initialTripId;
  final TripRepository? tripRepository;
  final GeminiTravelService? aiService;
  final ValueChanged<TripEntity> onOpenSnapshot;

  @override
  State<TripChatScreen> createState() => _TripChatScreenState();
}

class _TripChatScreenState extends State<TripChatScreen> {
  late final TripRepository _repo;
  late final GeminiTravelService _ai;
  late final String _tripId;

  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _scrollSecondaryTimer;

  List<ChatMessage> _messages = [];
  bool _isThinking = false;
  bool _isFlightSaved = false;
  bool _areAttractionsConfirmed = false;
  List<AttractionItem> _selectedAttractions = [];
  StayOffer? _selectedStay;
  FlightRealOffer? _selectedFlight;
  GeminiTripPlanDraft? _latestDraft;
  String _destination = 'Nuovo viaggio';
  int _durationDays = 3;
  TripPlanningStage _currentStage = TripPlanningStage.transport;
  TripPlanningContext _planningContext = const TripPlanningContext();
  bool _userHasAnsweredActive = false;

  @override
  void initState() {
    super.initState();
    _repo = widget.tripRepository ?? TripRepository();
    _tripId = widget.initialTripId ?? 'trip_${DateTime.now().millisecondsSinceEpoch}';
    _setupAiService();
    if (widget.initialPrompt != null && widget.initialPrompt!.trim().isNotEmpty) {
      _messages.add(
        ChatMessage(
          role: 'user',
          text: widget.initialPrompt!.trim(),
          timestamp: DateTime.now(),
        ),
      );
      _updateContextFromUserText(widget.initialPrompt!.trim());
      _isThinking = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _queryAi(widget.initialPrompt!.trim());
      });
    } else {
      _initChat();
    }
  }

  @override
  void dispose() {
    _scrollSecondaryTimer?.cancel();
    _scrollController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  void _setupAiService() {
    if (widget.aiService != null) {
      _ai = widget.aiService!;
      return;
    }
    final storedKey = LocalPreferencesService().geminiApiKey;
    final apiKey = (storedKey != null && storedKey.trim().isNotEmpty)
        ? storedKey.trim()
        : AppConfig.geminiApiKey;
    _ai = GeminiTravelService(apiKey: apiKey);
  }

  Future<void> _initChat() async {
    if (widget.initialTripId != null) {
      final existing = await _repo.getTripById(widget.initialTripId!);
      if (existing != null && mounted) {
        setState(() {
          _messages = List.from(existing.messages);
          _latestDraft = existing.latestPlan;
          _destination = existing.destination;
          _durationDays = existing.durationDays;
          if (existing.latestPlan != null) {
            _selectedStay = existing.latestPlan!.selectedStay;
            _selectedAttractions = existing.latestPlan!.attractions;
            _isFlightSaved = existing.latestPlan!.flight != null;
            _areAttractionsConfirmed = _selectedAttractions.isNotEmpty;
          }
        });
        return;
      }
    }

    _isThinking = true;
    _queryAi('Vorrei organizzare un nuovo viaggio. Da dove cominciamo?');
  }

  void _updateContextFromUserText(String text) {
    final lower = text.toLowerCase();

    // Companions
    if (lower.contains('coppia') || lower.contains('in due') || lower.contains('fidanzat')) {
      _planningContext = _planningContext.copyWith(travelers: 'In coppia');
    } else if (lower.contains('solo') || lower.contains('solitario') || lower.contains('da sol')) {
      _planningContext = _planningContext.copyWith(travelers: 'Da solo');
    } else if (lower.contains('amici') || lower.contains('gruppo')) {
      _planningContext = _planningContext.copyWith(travelers: 'Con amici');
    } else if (lower.contains('famiglia') || lower.contains('bambin')) {
      _planningContext = _planningContext.copyWith(travelers: 'In famiglia');
    }

    // Vibe
    if (lower.contains('cultur') || lower.contains('muse')) {
      _planningContext = _planningContext.copyWith(tripStyle: 'Cultura & Musei');
    } else if (lower.contains('relax') || lower.contains('parch')) {
      _planningContext = _planningContext.copyWith(tripStyle: 'Relax & Parchi');
    } else if (lower.contains('seral') || lower.contains('local') || lower.contains('notturn')) {
      _planningContext = _planningContext.copyWith(tripStyle: 'Vita serale & Locali');
    } else if (lower.contains('scorc') || lower.contains('quartier') || lower.contains('avventur')) {
      _planningContext = _planningContext.copyWith(tripStyle: 'Scorci & Quartieri');
    }

    // Month detection
    for (final m in GoogleFlightsUrlBuilder.italianMonths.keys) {
      if (lower.contains(m)) {
        _planningContext = _planningContext.copyWith(month: m);
        break;
      }
    }

    // Dates detection con defaultMonth dal contesto
    final (dep, ret) = GoogleFlightsUrlBuilder.extractDatesFromText(
      text,
      defaultMonth: _planningContext.monthIndex,
    );
    if (dep != null && ret != null) {
      final rangeStr = GoogleFlightsUrlBuilder.formatDateRange(dep, ret);
      final days = ret.difference(dep).inDays;
      _planningContext = _planningContext.copyWith(
        dates: rangeStr,
        durationDays: days > 0 ? days : 3,
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
        // Secondo passaggio per garantire che le action card e i widget asincroni abbiano completato il layout
        _scrollSecondaryTimer?.cancel();
        _scrollSecondaryTimer = Timer(const Duration(milliseconds: 200), () {
          if (mounted && _scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
  }

  Future<void> _sendMessage(String text, {TripPlanningStage? explicitStage}) async {
    final clean = text.trim();
    if (clean.isEmpty) return;

    final userMessage = ChatMessage(
      role: 'user',
      text: clean,
      timestamp: DateTime.now(),
    );

    _updateContextFromUserText(clean);

    setState(() {
      _messages.add(userMessage);
      _userHasAnsweredActive = true;
    });
    _inputController.clear();
    _scrollToBottom();

    final lower = clean.toLowerCase();
    if (lower == 'salva viaggio' || lower == 'salva il viaggio' || lower == 'salva questo viaggio') {
      await _saveCurrentTrip(status: TripStatus.ready);
      setState(() {
        _isThinking = false;
        _messages.add(
          ChatMessage(
            role: 'assistant',
            text: '🎉 **Viaggio a $_destination salvato con successo!**\n\n'
                'Tutti i dettagli (voli, alloggio baricentrico e tappe a piedi) sono stati salvati nelle tue pianificazioni.\n'
                'Puoi consultare l\'itinerario giorno per giorno e tutti i dettagli dalla tab **Viaggi**.',
            timestamp: DateTime.now(),
          ),
        );
      });
      _scrollToBottom();
      return;
    }

    setState(() {
      _isThinking = true;
    });
    _queryAi(clean, explicitStage: explicitStage);
  }

  String? _detectedOriginCity;
  bool _directOnly = false;

  Future<void> _queryAi(String text, {TripPlanningStage? explicitStage}) async {
    final detectedOrigin = GoogleFlightsUrlBuilder.extractOriginCity(text);
    if (detectedOrigin != null) {
      _detectedOriginCity = detectedOrigin;
    }

    if (GoogleFlightsUrlBuilder.isDirectFlightRequested(text)) {
      _directOnly = true;
    }

    final lower = text.toLowerCase();
    TripPlanningStage stage = explicitStage ?? _currentStage;
    String queryPrompt = text;

    if (explicitStage == null) {
      final isContinue = lower == 'continua' ||
          lower == 'avanti' ||
          lower == 'prosegui' ||
          lower == 'ok' ||
          lower == 'va bene' ||
          lower == 'proseguiamo' ||
          lower == 'vai avanti';

      if (isContinue) {
        if (!_isFlightSaved && _latestDraft?.flight != null) {
          _isFlightSaved = true;
          stage = TripPlanningStage.attractions;
          queryPrompt = 'Quali sono le tappe e attrazioni imperdibili da vedere a $_destination?';
        } else if (!_areAttractionsConfirmed) {
          stage = TripPlanningStage.attractions;
          queryPrompt = 'Quali sono le tappe e attrazioni imperdibili da vedere a $_destination?';
        } else if (_selectedStay == null) {
          stage = TripPlanningStage.stay;
          queryPrompt = 'Dove conviene alloggiare a $_destination? Consigliami quartieri e hotel.';
        } else {
          stage = TripPlanningStage.itinerary;
          queryPrompt = 'Mostrami l\'itinerario giorno per giorno per $_destination.';
        }
      } else if (lower.contains('non so dove') || lower.contains('ispirami') || lower.contains('idee per') || lower.contains('dove potrei')) {
        stage = TripPlanningStage.inspiration;
      } else if (lower.contains('cosa vedere') || lower.contains('monumenti') || lower.contains('attrazioni') || lower.contains('esperienze imperdibili') || lower.contains('scegliamo le tappe') || lower.contains('tappe')) {
        stage = TripPlanningStage.attractions;
      } else if (lower.contains('dove alloggiare') || lower.contains('consigliami un hotel') || lower.contains('dove dormire') || lower.contains('quale quartiere') || lower.contains('scegli dove alloggiare') || lower.contains('alloggi')) {
        stage = TripPlanningStage.stay;
      } else if (lower.contains('crea itinerario') || lower.contains('mostrami l\'itinerario') || lower.contains('itinerario giorno per giorno') || lower.contains('programma completo')) {
        stage = TripPlanningStage.itinerary;
      } else if (lower.contains('cerca voli') || lower.contains('mostrami i voli') || lower.contains('voli diretti') || lower.contains('trova volo')) {
        stage = TripPlanningStage.flight;
      } else if (_isFlightSaved) {
        stage = TripPlanningStage.attractions;
      } else if (_latestDraft?.flight == null && !lower.contains('salva') && !lower.contains('conferma')) {
        stage = TripPlanningStage.transport;
      }
    }


    setState(() {
      _currentStage = stage;
    });

    final departureCity = _detectedOriginCity
        ?? LocalPreferencesService().departureCity;

    try {
      final draft = await _ai.generateTripAdvice(
        queryPrompt,

        departureCity: departureCity,
        userStyle: LocalPreferencesService().travelStyle,
        budget: LocalPreferencesService().budget,
        stage: stage,
        directOnly: _directOnly,
        conversationHistory: _messages.where((m) => m.text.trim().isNotEmpty).toList(),
        planningContext: _planningContext,
      );

      final enrichedDraft = draft.copyWith(
        flight: draft.flight ?? _latestDraft?.flight,
        destinationVisual: draft.destinationVisual ?? _latestDraft?.destinationVisual,
      );

      final assistantMessage = ChatMessage(
        role: 'assistant',
        text: draft.message,
        planDraft: enrichedDraft,
        timestamp: DateTime.now(),
      );

      if (mounted) {
        setState(() {
          _messages.add(assistantMessage);
          _userHasAnsweredActive = false; // resetta per la nuova domanda attiva
          if (_latestDraft == null) {
            _latestDraft = draft;
          } else {
            _latestDraft = _latestDraft!.copyWith(
              destination: draft.destination.isNotEmpty ? draft.destination : _latestDraft!.destination,
              durationDays: draft.durationDays > 0 ? draft.durationDays : _latestDraft!.durationDays,
              stage: stage,
              flight: draft.flight ?? _latestDraft!.flight,
              neighborhoods: draft.neighborhoods.isNotEmpty ? draft.neighborhoods : _latestDraft!.neighborhoods,
              days: draft.days.isNotEmpty ? draft.days : _latestDraft!.days,
              message: draft.message,
              attractions: draft.attractions.isNotEmpty ? draft.attractions : _latestDraft!.attractions,
              stayOffers: draft.stayOffers.isNotEmpty ? draft.stayOffers : _latestDraft!.stayOffers,
              selectedStay: draft.selectedStay ?? _latestDraft!.selectedStay,
            );
          }
          if (draft.destination.isNotEmpty) {
            _destination = draft.destination;
            _planningContext = _planningContext.copyWith(destination: draft.destination);
          }
          if (draft.durationDays > 0) {
            _durationDays = draft.durationDays;
            _planningContext = _planningContext.copyWith(durationDays: draft.durationDays);
          }
          _isThinking = false;
        });

        _saveCurrentTrip(status: TripStatus.planning);
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isThinking = false;
          _messages.add(
            ChatMessage(
              role: 'assistant',
              text: 'Si è verificato un problema di connessione. Puoi riprovare o specificare un\'altra richiesta per il viaggio a $_destination.',
              timestamp: DateTime.now(),
            ),
          );
        });
        _scrollToBottom();
      }
    }
  }

  Future<TripEntity> _saveCurrentTrip({required TripStatus status}) async {
    final now = DateTime.now();
    final coverUrl = _latestDraft?.destinationVisual?.images.firstOrNull ??
        'https://images.unsplash.com/photo-1488646953014-85cb44e25828?w=800';

    final entity = TripEntity(
      id: _tripId,
      destination: _destination,
      durationDays: _durationDays,
      status: status,
      coverImageUrl: coverUrl,
      createdAt: now,
      latestPlan: _latestDraft,
      messages: List.from(_messages),
    );

    await _repo.saveTrip(entity);
    return entity;
  }

  // --- Handlers dei Picker Dedicati (Nessun messaggio di chat artificiale!) ---

  void _openFlightPicker(FlightAdvice flight) {
    FlightPickerSheet.show(
      context,
      flight: flight,
      onSaveFlight: ({combined, outbound, returnOffer, required totalPrice, required bookingUrl}) {
        setState(() {
          _isFlightSaved = true;
          _selectedFlight = combined ?? outbound;
          if (_latestDraft != null) {
            _latestDraft = _latestDraft!.copyWith(
              flight: flight.copyWith(
                priceEstimate: '$totalPrice € a/r',
                searchUrl: bookingUrl,
              ),
            );
          }
        });
        _saveCurrentTrip(status: TripStatus.planning);
        // Avanza naturalmente alla fase successiva (attrazioni) senza snackbar né pop-up
        if (!_areAttractionsConfirmed) {
          _queryAi(
            'Quali sono le tappe e attrazioni imperdibili da vedere a $_destination?',
            explicitStage: TripPlanningStage.attractions,
          );
        }
      },
    );
  }

  void _openAttractionsPicker(List<AttractionItem> attractions) {
    AttractionsPickerSheet.show(
      context,
      destination: _destination,
      attractions: attractions,
      initiallySelected: _selectedAttractions,
      onSave: (selected) {
        setState(() {
          _selectedAttractions = selected;
          _areAttractionsConfirmed = true;
          if (_latestDraft != null) {
            _latestDraft = _latestDraft!.copyWith(attractions: selected);
          }
        });
        _saveCurrentTrip(status: TripStatus.planning);
        // Avanza naturalmente alla fase successiva (alloggio) senza snackbar
        if (_selectedStay == null) {
          _queryAi(
            'Dove conviene alloggiare a $_destination? Quali quartieri e hotel consigli?',
            explicitStage: TripPlanningStage.stay,
          );
        }
      },
    );
  }

  Future<void> _openStayPicker(GeminiTripPlanDraft draft) async {
    // Se non ci sono offerte caricate nel draft, caricale al volo dal service
    List<StayOffer> stays = draft.stayOffers;
    if (stays.isEmpty) {
      stays = await const StaySearchService().searchStays(destination: _destination);
    }

    if (!mounted) return;

    StayPickerSheet.show(
      context,
      destination: _destination,
      stays: stays,
      neighborhoods: draft.neighborhoods,
      selectedStay: _selectedStay ?? draft.selectedStay,
      onStayBooked: (stay) {
        setState(() {
          _selectedStay = stay;
          if (_latestDraft != null) {
            _latestDraft = _latestDraft!.copyWith(selectedStay: stay);
          }
        });
        _saveCurrentTrip(status: TripStatus.planning);
        // Avanza all'itinerario giorno per giorno
        _queryAi(
          'Perfetto, ho scelto ${stay.name}. Ora mostrami l\'itinerario completo giorno per giorno per $_destination.',
          explicitStage: TripPlanningStage.itinerary,
        );
      },
      onSkip: () {
        // L'utente salta l'alloggio: procedi direttamente all'itinerario giorno per giorno!
        _saveCurrentTrip(status: TripStatus.planning);
        _queryAi(
          'Ho già un alloggio. Mostrami direttamente l\'itinerario completo giorno per giorno per $_destination.',
          explicitStage: TripPlanningStage.itinerary,
        );
      },
      onCustomQuery: (q) {
        _queryAi(
          q,
          explicitStage: TripPlanningStage.stay,
        );
      },
    );
  }



  Future<void> _handleOpenSnapshot() async {
    final trip = await _saveCurrentTrip(status: TripStatus.ready);
    widget.onOpenSnapshot(trip);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _destination,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            if (_isThinking)
              Text(
                'Iter sta elaborando...',
                style: TextStyle(fontSize: 12, color: colorScheme.primary),
              )
            else
              Text(
                'Organizzazione viaggio',
                style: TextStyle(fontSize: 12, color: colorScheme.outline),
              ),
          ],
        ),
        actions: [
          if (_latestDraft != null)
            TextButton.icon(
              onPressed: _handleOpenSnapshot,
              icon: const Icon(Icons.map_outlined, size: 18),
              label: const Text('Itinerario'),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Area Messaggi
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg.role == 'user';

                  // Mostra DestinationHeroCard solo sul primissimo messaggio dell'assistente con visual
                  final firstVisualIndex = _messages.indexWhere(
                    (m) => m.role != 'user' && m.planDraft?.destinationVisual != null,
                  );
                  final showDestinationHero = !isUser &&
                      msg.planDraft?.destinationVisual != null &&
                      index == firstVisualIndex;

                  // Calcolo indici per mostrare ciascuna card ESATTAMENTE UNA SOLA VOLTA nella cronologia!
                  int activeFlightCardIndex = -1;
                  if (_isFlightSaved) {
                    // Quando il volo è salvato, resta agganciato al messaggio dove è stata fatta l'offerta
                    activeFlightCardIndex = _messages.indexWhere(
                      (m) => m.role != 'user' && m.planDraft?.flight != null,
                    );
                  } else {
                    for (int i = _messages.length - 1; i >= 0; i--) {
                      final m = _messages[i];
                      if (m.role != 'user' && m.planDraft?.flight != null) {
                        final t = m.text.toLowerCase();
                        final isFlightTopic = (t.contains('volo') || t.contains('voli') || t.contains('scalo') || t.contains('scali')) &&
                            !t.contains('hotel') && !t.contains('allogg') && !t.contains('dormire');
                        final isQuestion = t.contains('?');
                        final isAskingFlight = isFlightTopic && isQuestion && (
                          t.contains('preferisci') ||
                          t.contains('mattina') ||
                          t.contains('pomeriggio') ||
                          t.contains('dirett') ||
                          t.contains('orari') ||
                          t.contains('scalo')
                        );
                        // Se è l'ultimo messaggio assistente e sta attivamente chiedendo le preferenze volo,
                        // attendiamo la risposta dell'utente prima di mostrare il selettore volo.
                        if (i == _messages.lastIndexWhere((msg) => msg.role != 'user') && isAskingFlight) {
                          continue;
                        }
                        activeFlightCardIndex = i;
                        break;
                      }
                    }
                  }

                  final showFlightCard = !isUser &&
                      msg.planDraft?.flight != null &&
                      index == activeFlightCardIndex;

                  final singleAttractionsIndex = _messages.lastIndexWhere(
                    (m) => m.role != 'user' && m.planDraft?.attractions.isNotEmpty == true,
                  );
                  final showAttractionsCard = !isUser &&
                      msg.planDraft?.attractions.isNotEmpty == true &&
                      (_isFlightSaved || msg.planDraft?.flight == null) &&
                      (index == singleAttractionsIndex);

                  final singleStayIndex = _messages.lastIndexWhere(
                    (m) => m.role != 'user' && (m.planDraft?.stayOffers.isNotEmpty == true || m.planDraft?.neighborhoods.isNotEmpty == true),
                  );
                  final showStayCard = !isUser &&
                      (msg.planDraft?.stayOffers.isNotEmpty == true || msg.planDraft?.neighborhoods.isNotEmpty == true) &&
                      (_isFlightSaved || msg.planDraft?.flight == null) &&
                      (_areAttractionsConfirmed || _selectedStay != null || _currentStage == TripPlanningStage.stay || _currentStage == TripPlanningStage.itinerary) &&
                      (index == singleStayIndex);

                  final singleItineraryIndex = _messages.lastIndexWhere(
                    (m) => m.role != 'user' && m.planDraft?.days.isNotEmpty == true,
                  );
                  final showItineraryCard = !isUser &&
                      msg.planDraft?.days.isNotEmpty == true &&
                      (_isFlightSaved || msg.planDraft?.flight == null) &&
                      (_areAttractionsConfirmed || _selectedStay != null || _currentStage == TripPlanningStage.itinerary) &&
                      (index == singleItineraryIndex);

                  // Le chip dinamiche appaiono ESCLUSIVAMENTE sull'ultimo messaggio assistente e solo se non si è ancora risposto!
                  final lastAssistantIndex = _messages.lastIndexWhere((m) => m.role != 'user');
                  final showInteractiveOptions = index == lastAssistantIndex &&
                      !_isThinking &&
                      !_userHasAnsweredActive;

                  List<String>? cleanReplies = showInteractiveOptions ? msg.planDraft?.suggestedReplies : null;
                  if (cleanReplies != null) {
                    final isItineraryStage = showItineraryCard || _currentStage == TripPlanningStage.itinerary || (msg.planDraft?.days.isNotEmpty == true);
                    cleanReplies = cleanReplies.where((opt) {
                      final o = opt.toLowerCase();
                      if (isItineraryStage) {
                        if (o.contains('volo') || o.contains('voli') || o.contains('hotel') || o.contains('allogg') || o.contains('mostrami l\'itinerario') || o.contains('cerchiamo') || o.contains('partire')) return false;
                      }
                      if (showFlightCard || _isFlightSaved) {
                        if (o.contains('volo') || o.contains('voli') || o.contains('orari') || o.contains('compagnia') || o.contains('prezzo')) return false;
                      }
                      if (showStayCard || _selectedStay != null) {
                        if (o.contains('hotel') || o.contains('allogg') || o.contains('dormire') || o.contains('quartier')) return false;
                      }
                      if (showAttractionsCard || _areAttractionsConfirmed) {
                        if (o.contains('monument') || o.contains('attrazion') || o.contains('tappe') || o.contains('vedere')) return false;
                      }
                      return true;
                    }).toList();
                    if (isItineraryStage && cleanReplies.isEmpty) {
                      cleanReplies = ['Cosa mangiare di tipico?', 'Consigli sui trasporti', 'Meteo e periodo migliore'];
                    } else if (cleanReplies.isEmpty) {
                      cleanReplies = null;
                    }
                  }

                  // Non mostrare chip testuali contrastanti o ridondanti sotto le card di azione principali
                  if ((showFlightCard && !_isFlightSaved) ||
                      (showStayCard && _selectedStay == null) ||
                      (showAttractionsCard && !_areAttractionsConfirmed)) {
                    cleanReplies = null;
                  }



                  return _MessageBubble(
                    message: msg,
                    isUser: isUser,
                    showDestinationHero: showDestinationHero,
                    showFlightCard: showFlightCard,
                    showAttractionsCard: showAttractionsCard,
                    showStayCard: showStayCard,
                    showItineraryCard: showItineraryCard,
                    interactiveOptions: cleanReplies,
                    isFlightSaved: _isFlightSaved,
                    selectedFlight: _selectedFlight,
                    areAttractionsConfirmed: _areAttractionsConfirmed,
                    selectedAttractionsCount: _selectedAttractions.length,
                    selectedStay: _selectedStay,
                    onSelectOption: (opt) => _sendMessage(opt),
                    onOpenFlightPicker: (flight) => _openFlightPicker(flight),
                    onOpenAttractionsPicker: (attractions) => _openAttractionsPicker(attractions),
                    onOpenStayPicker: (draft) => _openStayPicker(draft),
                    onOpenItinerary: _handleOpenSnapshot,
                  );

                },
              ),
            ),

            if (_isThinking)
              _DynamicLoadingIndicator(
                stage: _currentStage,
                destination: _destination,
              ),

            // Composer Inferiore
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      decoration: InputDecoration(
                        hintText: 'Scrivi un messaggio a Iter...',
                        hintStyle: TextStyle(color: colorScheme.outline, fontSize: 14),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: colorScheme.outlineVariant),
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHigh,
                      ),
                      onSubmitted: (v) => _sendMessage(v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () => _sendMessage(_inputController.text),
                    icon: const Icon(Icons.arrow_upward_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isUser,
    required this.onOpenItinerary,
    this.showDestinationHero = true,
    this.showFlightCard = true,
    this.showAttractionsCard = true,
    this.showStayCard = true,
    this.showItineraryCard = true,
    this.interactiveOptions,
    this.isFlightSaved = false,
    this.selectedFlight,
    this.areAttractionsConfirmed = false,
    this.selectedAttractionsCount = 0,
    this.selectedStay,
    this.onSelectOption,
    this.onOpenFlightPicker,
    this.onOpenAttractionsPicker,
    this.onOpenStayPicker,
  });

  final ChatMessage message;
  final bool isUser;
  final bool showDestinationHero;
  final bool showFlightCard;
  final bool showAttractionsCard;
  final bool showStayCard;
  final bool showItineraryCard;
  final List<String>? interactiveOptions;
  final bool isFlightSaved;
  final FlightRealOffer? selectedFlight;
  final bool areAttractionsConfirmed;
  final int selectedAttractionsCount;
  final StayOffer? selectedStay;
  final ValueChanged<String>? onSelectOption;
  final ValueChanged<FlightAdvice>? onOpenFlightPicker;
  final ValueChanged<List<AttractionItem>>? onOpenAttractionsPicker;
  final ValueChanged<GeminiTripPlanDraft>? onOpenStayPicker;
  final VoidCallback onOpenItinerary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // 1. Scheda visiva della destinazione (mostrata per prima come hero card)
          if (showDestinationHero && message.planDraft?.destinationVisual != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: DestinationHeroCard(
                visualData: message.planDraft!.destinationVisual!,
                onExploreAttractions: () => onOpenAttractionsPicker?.call(message.planDraft!.attractions),
              ),
            ),

          // 2. Bolla testuale del messaggio
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isUser ? colorScheme.primary : colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isUser ? 18 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 18),
              ),
            ),
            child: Text(
              message.text,
              style: TextStyle(
                color: isUser ? colorScheme.onPrimary : colorScheme.onSurface,
                fontSize: 15,
                height: 1.35,
              ),
            ),
          ),

          // 3. Action Cards Compatte e Snelle (al posto dei vecchi muri di card invasive!)
          if (message.planDraft != null) ...[
            const SizedBox(height: 8),

            // Action Card Volo (UNICA e in-place!)
            if (showFlightCard && message.planDraft!.flight != null)
              _ActionPillCard(
                icon: Icons.flight_takeoff_rounded,
                iconColor: isFlightSaved ? Colors.green : Colors.blue,
                title: isFlightSaved
                    ? 'Volo Selezionato: ${message.planDraft!.destination}'
                    : 'Opzioni Volo per ${message.planDraft!.destination}',
                subtitle: isFlightSaved
                    ? '✓ ${selectedFlight?.airline ?? 'Volo confermato'} • ${selectedFlight?.price ?? ''}€ a/r'
                    : 'Tariffe analizzate • Clicca per vedere le opzioni',
                actionLabel: isFlightSaved ? 'Modifica' : 'Scegli volo',
                onTap: () => onOpenFlightPicker?.call(message.planDraft!.flight!),
              ),

            // Action Card Monumenti & Tappe (UNICA!)
            if (showAttractionsCard && message.planDraft!.attractions.isNotEmpty)
              _ActionPillCard(
                icon: Icons.account_balance_rounded,
                iconColor: areAttractionsConfirmed ? Colors.green : Colors.purple,
                title: areAttractionsConfirmed
                    ? 'Tappe Salvate: ${message.planDraft!.destination}'
                    : 'Tappe & Monumenti a ${message.planDraft!.destination}',
                subtitle: areAttractionsConfirmed
                    ? '✓ $selectedAttractionsCount tappe salvate nel viaggio'
                    : '${message.planDraft!.attractions.length} tappe con foto reali disponibili',
                actionLabel: areAttractionsConfirmed ? 'Modifica' : 'Seleziona tappe',
                onTap: () => onOpenAttractionsPicker?.call(message.planDraft!.attractions),
              ),

            // Action Card Alloggio & Zone (UNICA!)
            if (showStayCard && (message.planDraft!.stayOffers.isNotEmpty || message.planDraft!.neighborhoods.isNotEmpty))
              _ActionPillCard(
                icon: Icons.hotel_rounded,
                iconColor: selectedStay != null ? Colors.green : Colors.teal,
                title: selectedStay != null ? 'Alloggio Prenotato' : 'Alloggi & Zone Consigliate',
                subtitle: selectedStay != null
                    ? '✓ ${selectedStay!.name} (${selectedStay!.neighborhood})'
                    : 'Analisi quartieri e hotel con simulazione Vio.com',
                actionLabel: selectedStay != null ? 'Modifica' : 'Scegli hotel',
                onTap: () => onOpenStayPicker?.call(message.planDraft!),
              ),

            // Action Card Itinerario Completo Pronto
            if (showItineraryCard && message.planDraft!.days.isNotEmpty)
              _ActionPillCard(
                icon: Icons.map_rounded,
                iconColor: Colors.deepOrange,
                isHighlight: true,
                title: 'Itinerario ${message.planDraft!.days.length} Giorni Pronto!',
                subtitle: 'Guida completa giorno per giorno e mappa OpenStreetMap',
                actionLabel: 'Apri Itinerario & Mappa',
                onTap: onOpenItinerary,
              ),
          ],

          // 4. Opzioni interattive a chip dinamiche (mostrate in fondo sotto il messaggio/azioni)
          if (interactiveOptions != null && interactiveOptions!.isNotEmpty)
            InteractiveQuestionOptions(
              options: interactiveOptions!,
              onSelect: (opt) => onSelectOption?.call(opt),
            ),
        ],
      ),
    );
  }

}


class _ActionPillCard extends StatelessWidget {
  const _ActionPillCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
    this.isHighlight = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;
  final bool isHighlight;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.90),
      decoration: BoxDecoration(
        color: isHighlight
            ? colorScheme.primaryContainer.withValues(alpha: 0.4)
            : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlight ? colorScheme.primary : colorScheme.outlineVariant.withValues(alpha: 0.35),
          width: isHighlight ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isHighlight ? colorScheme.primary : colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isHighlight ? colorScheme.primary : colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actionLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isHighlight ? colorScheme.onPrimary : colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 11,
                      color: isHighlight ? colorScheme.onPrimary : colorScheme.onSurface,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DynamicLoadingIndicator extends StatefulWidget {
  const _DynamicLoadingIndicator({
    required this.stage,
    required this.destination,
  });

  final TripPlanningStage stage;
  final String destination;

  @override
  State<_DynamicLoadingIndicator> createState() => _DynamicLoadingIndicatorState();
}

class _DynamicLoadingIndicatorState extends State<_DynamicLoadingIndicator> {
  int _tipIndex = 0;
  Timer? _timer;

  static const _tips = [
    'Confronto rotte aeree e tariffe in tempo reale...',
    'Analisi dei quartieri baricentrici per muoversi a piedi...',
    'Calcolo tempi ottimali di visita tra i monumenti...',
    'Composizione dell\'itinerario giorno per giorno...',
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 2200), (timer) {
      if (mounted) {
        setState(() {
          _tipIndex = (_tipIndex + 1) % _tips.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator.adaptive(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _tips[_tipIndex],
                key: ValueKey<int>(_tipIndex),
                style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
