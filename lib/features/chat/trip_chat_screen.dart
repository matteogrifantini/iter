import 'package:flutter/material.dart';
import '../../app/app_config.dart';
import '../ai/gemini_models.dart';
import '../ai/gemini_travel_service.dart';
import '../chat_first_prototype/local_preferences_service.dart';
import '../flights/google_flights_url_builder.dart';
import '../trips/trip_entity.dart';
import '../trips/trip_repository.dart';
import 'widgets/daily_plan_card.dart';
import 'widgets/flight_selector_card.dart';
import 'widgets/stay_neighborhood_card.dart';
import 'widgets/monument_swipe_deck.dart';
import 'widgets/destination_hero_card.dart';
import 'widgets/animated_route_map_card.dart';
import 'widgets/stay_selector_card.dart';
import 'widgets/cost_breakdown_card.dart';
import 'widgets/trip_profiling_card.dart';
import '../stays/stay_models.dart';
import '../stays/centroid_solver.dart';




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

  List<ChatMessage> _messages = [];
  bool _isThinking = false;
  GeminiTripPlanDraft? _latestDraft;
  String _destination = 'Nuovo viaggio';
  int _durationDays = 3;
  TripPlanningStage _currentStage = TripPlanningStage.flight;

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
      _isThinking = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _queryAi(widget.initialPrompt!.trim());
      });
    } else {
      _initChat();
    }
  }

  void _setupAiService() {
    if (widget.aiService != null) {
      _ai = widget.aiService!;
      return;
    }
    // Leggi da preferenze locali o .env
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
            _currentStage = existing.latestPlan!.stage;
          }
        });
        return;
      }
    }

    setState(() {
      _messages.add(
        ChatMessage(
          role: 'assistant',
          text: 'Ciao! Sono Iter. Raccontami dove vorresti andare, in quali date o quanti giorni hai a disposizione. Iniziamo subito dal volo e dai collegamenti ideali.',
          timestamp: DateTime.now(),
        ),
      );
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text, {TripPlanningStage? explicitStage}) async {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(
      role: 'user',
      text: text,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isThinking = true;
    });
    _inputController.clear();
    _scrollToBottom();
    _queryAi(text, explicitStage: explicitStage);
  }

  String? _detectedOriginCity;
  bool _directOnly = false;

  Future<void> _queryAi(String text, {TripPlanningStage? explicitStage}) async {
    // Detect origin city from user text (e.g. "sono di Roma", "parto da Milano")
    final detectedOrigin = GoogleFlightsUrlBuilder.extractOriginCity(text);
    if (detectedOrigin != null) {
      _detectedOriginCity = detectedOrigin;
    }

    // Detect directOnly preference
    if (GoogleFlightsUrlBuilder.isDirectFlightRequested(text)) {
      _directOnly = true;
    }

    final lower = text.toLowerCase();
    TripPlanningStage stage = explicitStage ?? _currentStage;

    if (explicitStage == null) {
      if (lower.contains('non so dove') || lower.contains('ispirami') || lower.contains('idee per') || lower.contains('dove potrei')) {
        stage = TripPlanningStage.inspiration;
      } else if (lower.contains('monument') || lower.contains('attrazion') || lower.contains('cosa vedere') || lower.contains('vedere') || lower.contains('visitare')) {
        stage = TripPlanningStage.attractions;
      } else if (lower.contains('dormire') || lower.contains('hotel') || lower.contains('allogg') || lower.contains('quartier')) {
        stage = TripPlanningStage.stay;
      } else if (lower.contains('itinerario') || lower.contains('cosa fare') || lower.contains('programma') || lower.contains('tappe') || lower.contains('giorn')) {
        stage = TripPlanningStage.itinerary;
      }
    }

    setState(() {
      _currentStage = stage;
    });

    // Determine departure city: from user text > preferences > default Roma
    final departureCity = _detectedOriginCity
        ?? LocalPreferencesService().departureCity;

    try {
      final draft = await _ai.generateTripAdvice(
        text,
        departureCity: departureCity,
        userStyle: LocalPreferencesService().travelStyle,
        budget: LocalPreferencesService().budget,
        stage: stage,
        directOnly: _directOnly,
        conversationHistory: _messages.where((m) => m.text.trim().isNotEmpty).toList(),
      );


      final assistantMessage = ChatMessage(
        role: 'assistant',
        text: draft.message,
        planDraft: draft,
        timestamp: DateTime.now(),
      );

      if (mounted) {
        setState(() {
          _messages.add(assistantMessage);
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
              destinationVisual: draft.destinationVisual ?? _latestDraft!.destinationVisual,
            );
          }


          if (draft.destination.isNotEmpty) {
            _destination = draft.destination;
          }
          if (draft.durationDays > 0) {
            _durationDays = draft.durationDays;
          }
          _isThinking = false;
        });
        _scrollToBottom();
        await _saveCurrentTrip();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              role: 'assistant',
              text: 'Si è verificato un problema con l\'IA: $e\n\nPuoi verificare la tua chiave Gemini gratuita nella tab Profilo.',
              timestamp: DateTime.now(),
            ),
          );
          _isThinking = false;
        });
        _scrollToBottom();
      }
    }
  }



  Future<TripEntity> _saveCurrentTrip({TripStatus status = TripStatus.planning}) async {
    final trip = TripEntity(
      id: _tripId,
      destination: _destination,
      durationDays: _durationDays,
      status: status,
      coverImageUrl: 'https://images.unsplash.com/photo-1488646953014-85cb44e25828?w=800&q=80',
      createdAt: DateTime.now(),
      messages: _messages,
      latestPlan: _latestDraft,
    );
    await _repo.saveTrip(trip);
    return trip;
  }

  void _onFlightOptionSaved({
    FlightRealOffer? outbound,
    FlightRealOffer? returnOffer,
    FlightRealOffer? combined,
    required int totalPrice,
    required String bookingUrl,
  }) {
    if (_latestDraft?.flight != null) {
      final updatedFlight = _latestDraft!.flight!.copyWith(
        priceEstimate: '$totalPrice €',
        searchUrl: bookingUrl,
      );
      _latestDraft = _latestDraft!.copyWith(flight: updatedFlight);
      _saveCurrentTrip(status: TripStatus.planning);
    }

    final descOut = outbound != null ? '${outbound.airline} (${outbound.departureTime})' : '';
    final descRet = returnOffer != null ? '${returnOffer.airline} (${returnOffer.departureTime})' : '';
    final descComb = combined != null ? '${combined.airline} (${combined.departureTime})' : '';
    final flightSummary = descComb.isNotEmpty ? descComb : '$descOut andata, $descRet ritorno';

    final assistantMsg = ChatMessage(
      role: 'assistant',
      text: "Perfetto! Ho salvato l'opzione volo ($flightSummary per $totalPrice€ a/r) nel tuo piano di viaggio. Ora proseguiamo: hai preferenze su dove alloggiare o vuoi che ti consigli i quartieri migliori di $_destination?",
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(assistantMsg);
    });
    _saveCurrentTrip(status: TripStatus.planning);
    _scrollToBottom();
  }

  void _onAttractionsConfirmed(List<AttractionItem> selected) {
    final names = selected.map((a) => a.name).join(', ');
    _sendMessage(
      'Ho scelto queste attrazioni a $_destination: $names. Quali alloggi e hotel mi consigli per fare base vicino a queste zone?',
    );
  }

  void _onStaySelected(StayOffer stay) {
    setState(() {
      if (_latestDraft != null) {
        _latestDraft = _latestDraft!.copyWith(selectedStay: stay);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ ${stay.name} salvato nel viaggio (${stay.pricePerNightEur.toStringAsFixed(0)}€/notte)'),
        backgroundColor: Colors.green.shade700,
        duration: const Duration(seconds: 2),
      ),
    );
    _saveCurrentTrip(status: TripStatus.planning);
    _sendMessage(
      'Ho salvato ${stay.name} per dormire. Ora generiamo l\'itinerario giorno per giorno ottimizzato?',
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg.role == 'user';
                  return _MessageBubble(
                    message: msg,
                    isUser: isUser,
                    onOpenSnapshot: _handleOpenSnapshot,
                    onOptionSaved: _onFlightOptionSaved,
                    onSelectSuggestion: (s) => _sendMessage(s),
                    onAttractionsConfirmed: _onAttractionsConfirmed,
                    onStaySelected: _onStaySelected,
                  );



                },
              ),
            ),

            if (_isThinking)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Gemini sta elaborando il passo...',
                      style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.primary),
                    ),
                  ],
                ),
              ),

            // Composer Inferiore
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(top: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Scrivi qui le tue idee o domande...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: colorScheme.outlineVariant),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      ),
                      onSubmitted: (v) => _sendMessage(v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () => _sendMessage(_inputController.text),
                    icon: const Icon(Icons.arrow_upward_rounded),
                    tooltip: 'Invia',
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
    required this.onOpenSnapshot,
    this.onOptionSaved,
    this.onSelectSuggestion,
    this.onAttractionsConfirmed,
    this.onStaySelected,
  });

  final ChatMessage message;
  final bool isUser;
  final VoidCallback onOpenSnapshot;
  final void Function({
    FlightRealOffer? outbound,
    FlightRealOffer? returnOffer,
    FlightRealOffer? combined,
    required int totalPrice,
    required String bookingUrl,
  })? onOptionSaved;
  final ValueChanged<String>? onSelectSuggestion;
  final ValueChanged<List<AttractionItem>>? onAttractionsConfirmed;
  final ValueChanged<StayOffer>? onStaySelected;

  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
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

          // Blocchi interattivi in base al contenuto (senza passi forzati)
          if (message.planDraft != null) ...[
            const SizedBox(height: 8),

            // Card Visiva della Destinazione (Zero token Gemini)
            if (message.planDraft!.destinationVisual != null)
              DestinationHeroCard(
                visualData: message.planDraft!.destinationVisual!,
                onExploreAttractions: () => onSelectSuggestion?.call('Cosa vedere a ${message.planDraft!.destination}?'),
              ),

            // Profilazione rapida se siamo in fase esplorativa
            if (message.planDraft!.stage == TripPlanningStage.inspiration)
              TripProfilingCard(
                destination: message.planDraft!.destination.isNotEmpty ? message.planDraft!.destination : 'la tua meta ideale',
                onProfileConfirmed: (prompt) => onSelectSuggestion?.call(prompt),
              ),

            // Volo: FlightSelectorCard con scelta andata/ritorno
            if (message.planDraft!.flight != null)
              FlightSelectorCard(
                flight: message.planDraft!.flight!,
                onOptionSaved: onOptionSaved,
              ),

            // Attrazioni / Monumenti a Swipe stile Tinder con Pace Calculator
            if (message.planDraft!.attractions.isNotEmpty)
              MonumentSwipeDeck(
                destination: message.planDraft!.destination,
                attractions: message.planDraft!.attractions,
                durationDays: message.planDraft!.durationDays,
                onConfirmed: (selected) => onAttractionsConfirmed?.call(selected),
              ),

            // Alloggi e hotel veri nella zona baricentrica scelta (senza uscire dall'app)
            if (message.planDraft!.stayOffers.isNotEmpty)
              StaySelectorCard(
                destination: message.planDraft!.destination,
                stays: message.planDraft!.stayOffers,
                selectedStay: message.planDraft!.selectedStay,
                centroidRecommendation: const CentroidSolver().solveOptimalArea(
                  destination: message.planDraft!.destination,
                  chosenAttractions: message.planDraft!.attractions,
                ),
                onSelectStay: (stay) => onStaySelected?.call(stay),
                onSkipStay: () => onSelectSuggestion?.call(
                  'Proseguiamo con l\'itinerario giorno per giorno, l\'alloggio lo sceglierò più tardi.',
                ),
              )
            else if (message.planDraft!.neighborhoods.isNotEmpty)
              StayNeighborhoodCard(neighborhoods: message.planDraft!.neighborhoods),

            // Itinerario: Mappa Rotta Animata, Programma Giornaliero & Preventivo Trasparente
            if (message.planDraft!.days.isNotEmpty) ...[
              AnimatedRouteMapCard(
                destination: message.planDraft!.destination,
                day: message.planDraft!.days.first,
              ),
              DailyPlanCard(days: message.planDraft!.days),
              const SizedBox(height: 8),
              CostBreakdownCard(
                destination: message.planDraft!.destination,
                durationDays: message.planDraft!.durationDays,
                plan: message.planDraft!,
                onOpenSnapshot: onOpenSnapshot,
              ),
            ],
          ],


          // Suggerimenti rapidi di dialogo
          if (!isUser &&
              message.planDraft?.suggestedReplies != null &&
              message.planDraft!.suggestedReplies.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: message.planDraft!.suggestedReplies.map((reply) {
                return ActionChip(
                  label: Text(
                    reply,
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.35),
                  side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.25)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  onPressed: () => onSelectSuggestion?.call(reply),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
