import '../../data/mock_data.dart';
import '../../models/trip_models.dart' show JourneyRoute, Place, StayZone;
import '../../widgets/journey_media.dart';
import 'chat_first_models.dart';

/// Stable id of the intake proposal beat. Accepting it hooks the F5
/// refinement modules (curation, transport, zone, itinerary) to the thread.
const String kIntakeProposalId = 'intake-proposal';

/// Stable id of the F5 itinerary proposal beat. Its snapshot is assembled at
/// emission time from the curated thread state.
const String kItineraryProposalId = 'f5-itinerary-proposal';

/// Stable conversation id of the free-talk "idea" thread that lets a traveler
/// start a new trip with their own words, before any destination is chosen.
const String kFreeTalkConversationId = 'c-free-talk';

/// Stable id of the free-talk wish echo beat. Its text is filled in at emission
/// time from the traveler's captured wish.
const String kFreeTalkAckId = 'free-talk-ack';

/// Stable id of the free-talk destination question. Its answer never pins the
/// journey: the thread converges every meta choice on the Porto route.
const String kFreeTalkDestinationId = 'free-talk-destination';

/// Typed, deterministic content for the operational plan prototype. It stays
/// separate from live providers: prices are EUR cents and provider links are
/// display-only demo links.
class OperationalTripFixture {
  OperationalTripFixture({
    required this.destinationId,
    required this.snapshot,
    required this.media,
    List<PlanMedia> mediaGallery = const <PlanMedia>[],
    required List<OperationalPlaceFixture> placeCatalog,
    required List<FlightFixture> flights,
    required List<HotelFixture> hotels,
    required this.quotedAt,
  }) : mediaGallery = List<PlanMedia>.unmodifiable(mediaGallery),
       placeCatalog = List<OperationalPlaceFixture>.unmodifiable(placeCatalog),
       flights = List<FlightFixture>.unmodifiable(flights),
       hotels = List<HotelFixture>.unmodifiable(hotels);

  final String destinationId;
  final TripSnapshot snapshot;
  final PlanMedia media;
  final List<PlanMedia> mediaGallery;
  final List<OperationalPlaceFixture> placeCatalog;
  final List<FlightFixture> flights;
  final List<HotelFixture> hotels;
  final DateTime quotedAt;
}

class OperationalPlaceFixture {
  const OperationalPlaceFixture({
    required this.id,
    required this.destinationId,
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.description,
    this.media,
  });

  final String id;
  final String destinationId;
  final String name;
  final String category;
  final double latitude;
  final double longitude;
  final String description;
  final PlanMedia? media;
}

abstract class OperationalPurchaseFixture {
  const OperationalPurchaseFixture({
    required this.id,
    required this.priceCents,
    required this.provider,
    required this.providerUrl,
    required this.tradeoff,
  });

  final String id;
  final int priceCents;
  final String provider;
  final Uri providerUrl;
  final String tradeoff;
}

class FlightFixture extends OperationalPurchaseFixture {
  const FlightFixture({
    required super.id,
    required super.priceCents,
    required super.provider,
    required super.providerUrl,
    required super.tradeoff,
    required this.departureAirport,
    required this.arrivalAirport,
    required this.departureAt,
    required this.arrivalAt,
    required this.durationMinutes,
    required this.stops,
    required this.baggage,
  });

  final String departureAirport;
  final String arrivalAirport;
  final DateTime departureAt;
  final DateTime arrivalAt;
  final int durationMinutes;
  final int stops;
  final String baggage;
}

class HotelFixture extends OperationalPurchaseFixture {
  const HotelFixture({
    required super.id,
    required super.priceCents,
    required super.provider,
    required super.providerUrl,
    required super.tradeoff,
    required this.name,
    required this.zone,
    required this.nights,
    required this.nightlyPriceCents,
    required this.conditions,
    required this.averageWalkMinutes,
    required this.atmosphere,
  });

  final String name;
  final String zone;
  final int nights;
  final int nightlyPriceCents;
  final String conditions;
  final int averageWalkMinutes;
  final String atmosphere;
}

/// A canned exchange used to advance a thread deterministically. Sending a
/// message (typed or via a choice) appends the traveler text plus [assistant].
class ScriptedBeat {
  ScriptedBeat(this.assistant);

  final ChatMessage assistant;
}

/// A conversation plus the mutable messages currently shown and the progress
/// through its script. The prototype keeps this isolated and deterministic.
class ChatThread {
  ChatThread({
    required this.summary,
    required this.script,
    List<ChatMessage>? openedWith,
  }) : messages = List<ChatMessage>.of(openedWith ?? const <ChatMessage>[]);

  Conversation summary;
  final List<ScriptedBeat> script;
  final List<ChatMessage> messages;

  /// How many of [messages] have already been persisted by the data source.
  /// Threads restored from the DB start with all messages persisted; seeded
  /// demo threads start at zero and are only persisted after a real change.
  int persistedCount = 0;
  int scriptIndex = 0;
  int _id = 0;

  String _nextId() => 'm-${_id++}';

  ChatMessage travelerMessage(String text) {
    final message = ChatMessage(
      id: _nextId(),
      role: ChatRole.traveler,
      kind: ChatMessageKind.text,
      text: text,
      sentAt: DateTime(2026, 10, 16, 10, 30),
    );
    messages.add(message);
    return message;
  }

  ChatMessage travelerAudioMessage({String duration = '0:14'}) {
    final message = ChatMessage(
      id: _nextId(),
      role: ChatRole.traveler,
      kind: ChatMessageKind.audio,
      text: '',
      sentAt: DateTime(2026, 10, 16, 10, 31),
      audioDuration: duration,
    );
    messages.add(message);
    return message;
  }

  ChatMessage travelerMediaMessage(String asset, {required bool isVideo}) {
    final message = ChatMessage(
      id: _nextId(),
      role: ChatRole.traveler,
      kind: ChatMessageKind.media,
      media: ChatMedia(asset: asset, isVideo: isVideo),
      sentAt: DateTime(2026, 10, 16, 10, 32),
    );
    messages.add(message);
    return message;
  }

  /// Advances to the next canned assistant message. Returns false when the
  /// script is over; the caller appends a gentle closing line instead.
  ///
  /// A tripSummary beat without a baked snapshot inherits the conversation's
  /// current snapshot, so the plan shown after a proposal decision always
  /// reflects what was actually accepted or rejected.
  bool advance() {
    if (scriptIndex >= script.length) return false;
    final beat = script[scriptIndex];
    messages.add(
      ChatMessage(
        id: _nextId(),
        role: beat.assistant.role,
        kind: beat.assistant.kind,
        text: beat.assistant.text,
        sentAt: beat.assistant.sentAt,
        media: beat.assistant.media,
        choices: beat.assistant.choices,
        audioDuration: beat.assistant.audioDuration,
        summary: beat.assistant.kind == ChatMessageKind.tripSummary
            ? beat.assistant.summary ?? summary.snapshot
            : beat.assistant.summary,
        proposal: beat.assistant.proposal,
      ),
    );
    scriptIndex++;
    return true;
  }

  /// Settles a pending [ChatMessageKind.planProposal]. Accepting replaces the
  /// conversation snapshot with the proposed one; rejecting keeps it. Either
  /// way the outcome is recorded (once), a traveler confirmation is appended
  /// and the script advances. No-op on non-proposal or already settled
  /// messages.
  void respondToProposal(ChatMessage message, {required bool accept}) {
    final proposal = message.proposal;
    if (proposal == null || proposal.outcome != null) return;
    proposal.outcome = accept
        ? PlanProposalOutcome.accepted
        : PlanProposalOutcome.rejected;
    travelerMessage(
      accept ? 'Sì, applica questa modifica.' : 'No, lascia il piano come ora.',
    );
    if (accept) {
      summary = summary.copyWith(snapshot: proposal.snapshot);
    }
    advance();
  }

  /// Whether a chip from [messageId] is still actionable: only the latest
  /// message offering choices accepts input. Everything older is read-only, so
  /// stale taps can never settle a question twice.
  bool acceptsChoiceFrom(String messageId) {
    for (var i = messages.length - 1; i >= 0; i--) {
      if (messages[i].choices.isNotEmpty) return messages[i].id == messageId;
    }
    return false;
  }
}

/// A planning thread driven by guided questions: each answer advances to the
/// next question and the final proposal is assembled from the recorded answers
/// instead of being baked into the script. Still fully deterministic: for the
/// same answers it always produces the same [PlanProposal].
class IntakeThread extends ChatThread {
  IntakeThread({
    this.journey,
    required super.summary,
    required super.script,
    super.openedWith,
  });

  /// The journey the traveler started from; drives the final proposal content.
  /// A [FreeTalkThread] leaves it null until the traveler pins a destination
  /// mid-conversation, so only mutable state is shared here.
  JourneyRoute? journey;

  /// Answers keyed by the question message id (e.g. 'q-duration').
  final Map<String, String> answers = <String, String>{};

  /// Places the traveler explicitly kept or marked must during the F5
  /// curation, in decision order. Drives the refined snapshot's labels and days.
  final List<Place> _savedPlaces = <Place>[];

  /// Place ids the traveler marked as irrinunciabile (locked in the days).
  final Set<String> _mustPlaceIds = <String>{};

  /// F5 question ids already settled, so repeated taps never double-apply.
  final Set<String> _answeredF5 = <String>{};

  /// Maps a free-text clarification id ('f5-clarify-N') back to the place-card
  /// question it re-asks, so the eventual chip answer lands on the right place.
  final Map<String, String> _clarificationToQuestion = <String, String>{};

  int _clarification = 0;

  /// True while the next [advance] must be consumed by a just-emitted
  /// clarification instead of emitting the following script beat.
  bool _clarificationPending = false;

  /// Records the answer whenever a traveler text follows a question with
  /// choices, keyed by that question id. Typed replies are captured too, so a
  /// free-text answer still advances the intake. F5 module answers (curation,
  /// transport, stay) are applied to the thread snapshot right here, so the
  /// next assistant beat always reflects the latest decision.
  ///
  /// A free-text reply that a place card does not understand (anything other
  /// than Passa/Salva/Irrinunciabile) does not advance: the thread re-asks the
  /// same question as a clarification with the three choices.
  @override
  ChatMessage travelerMessage(String text) {
    final message = super.travelerMessage(text);
    if (messages.length >= 2) {
      final question = messages[messages.length - 2];
      if (question.role == ChatRole.assistant && question.choices.isNotEmpty) {
        final isClarification = _clarificationToQuestion.containsKey(
          question.id,
        );
        final resolvedId = _clarificationToQuestion[question.id] ?? question.id;
        if (!isClarification && _needsClarification(question, text)) {
          _emitClarification(question);
        } else {
          answers[resolvedId] = text;
          _applyF5Answer(resolvedId, text);
        }
      }
    }
    return message;
  }

  bool _needsClarification(ChatMessage question, String text) =>
      question.kind == ChatMessageKind.placeCard &&
      text != 'Passa' &&
      text != 'Salva' &&
      text != 'Irrinunciabile';

  void _emitClarification(ChatMessage question) {
    final clarification = ChatMessage(
      id: 'f5-clarify-${_clarification++}',
      role: ChatRole.assistant,
      kind: ChatMessageKind.choices,
      text: 'Non ho capito: Passa, Salva o Irrinunciabile?',
      choices: const <ChatChoice>[
        ChatChoice(label: 'Passa'),
        ChatChoice(label: 'Salva'),
        ChatChoice(label: 'Irrinunciabile'),
      ],
      sentAt: DateTime(2026, 10, 16, 10, 30),
    );
    _clarificationToQuestion[clarification.id] = question.id;
    messages.add(clarification);
    _clarificationPending = true;
  }

  /// Accepting the intake proposal appends the F5 refinement modules to the
  /// script and lets the thread advance through the transition beats (summary,
  /// operational, curation intro) without free-text input, landing straight on
  /// the first place card. The proposal handling itself stays identical to the
  /// base thread.
  @override
  void respondToProposal(ChatMessage message, {required bool accept}) {
    final proposal = message.proposal;
    if (proposal == null || proposal.outcome != null) return;
    if (accept && message.id == kIntakeProposalId) {
      _queueRefinement();
    }
    super.respondToProposal(message, accept: accept);
  }

  /// Emits every beat keeping the script's stable id, so answers can be
  /// matched back to their question, and builds the final proposal from
  /// [answers] when the script reaches the proposal beat. The F5 itinerary
  /// proposal is assembled at emission time from the curated thread state.
  /// Transition beats (no choices, no proposal) are consumed automatically, so
  /// the thread never asks the traveler for free text on a message that has no
  /// decision: it stops exactly on a question with choices or on a proposal,
  /// never past one.
  @override
  bool advance() {
    if (_clarificationPending) {
      _clarificationPending = false;
      return true;
    }
    if (scriptIndex >= script.length) return false;
    final beat = script[scriptIndex];
    final isProposal = beat.assistant.kind == ChatMessageKind.planProposal;
    messages.add(
      ChatMessage(
        id: beat.assistant.id,
        role: beat.assistant.role,
        kind: beat.assistant.kind,
        text: beat.assistant.text,
        sentAt: beat.assistant.sentAt,
        media: beat.assistant.media,
        choices: beat.assistant.choices,
        audioDuration: beat.assistant.audioDuration,
        summary: beat.assistant.kind == ChatMessageKind.tripSummary
            ? beat.assistant.summary ?? summary.snapshot
            : beat.assistant.summary,
        proposal: isProposal
            ? beat.assistant.proposal ??
                  (beat.assistant.id == kItineraryProposalId
                      ? _buildItineraryProposal()
                      : buildFinalProposal())
            : beat.assistant.proposal,
        placeCard: beat.assistant.placeCard,
        transport: beat.assistant.transport,
        stayZone: beat.assistant.stayZone,
        flightCompare: beat.assistant.flightCompare,
        stayCompare: beat.assistant.stayCompare,
      ),
    );
    scriptIndex++;
    final requiresInput = beat.assistant.choices.isNotEmpty || isProposal;
    if (requiresInput) return true;
    if (scriptIndex >= script.length) return true;
    return advance();
  }

  /// Appends the F5 refinement beats after the intake tail. Script index keeps
  /// its position, so the next user action continues straight into curation.
  void _queueRefinement() {
    final destinationId = journey!.destinationIds.first;
    script.addAll(
      ChatFirstDemoData.refinementBeats(destinationId, journeyCity(journey!)),
    );
  }

  TripSnapshot _snapshot() =>
      summary.snapshot ??
      TripSnapshot(
        destinationTitle: '',
        country: '',
        durationLabel: '',
        statusLabel: '',
        dates: '',
        transport: '',
        stay: '',
        placeLabels: const <String>[],
        days: const <TripDaySnapshot>[],
      );

  void _applyF5Answer(String questionId, String answer) {
    if (!_answeredF5.add(questionId)) return;
    if (questionId.startsWith('f5-place-')) {
      _applyCuration(questionId, answer);
      return;
    }
    if (questionId == 'f5-transport') {
      summary = summary.copyWith(
        snapshot: _snapshot().copyWith(
          transport: ChatFirstDemoData.transportSummaryFor(answer),
        ),
      );
      return;
    }
    if (questionId == 'f5-stay') {
      final stay = answer == 'Consigliami tu'
          ? ChatFirstDemoData.preferredStayFor(journey!.destinationIds.first)
          : answer;
      summary = summary.copyWith(snapshot: _snapshot().copyWith(stay: stay));
    }
  }

  /// Resolves the [Place] behind a curation question id, e.g. 'f5-place-...'.
  Place? _placeForQuestion(String questionId) {
    final id = questionId.replaceFirst('f5-place-', '');
    for (final place in MockData.places) {
      if (place.id == id) return place;
    }
    return null;
  }

  /// Passa (or any free-text reply) keeps the snapshot untouched; Salva and
  /// Irrinunciabile add the place to the plan and rebuild labels + days.
  void _applyCuration(String questionId, String answer) {
    if (answer != 'Salva' && answer != 'Irrinunciabile') return;
    final place = _placeForQuestion(questionId);
    if (place == null) return;
    if (_savedPlaces.any((saved) => saved.id == place.id)) return;
    _savedPlaces.add(place);
    if (answer == 'Irrinunciabile') _mustPlaceIds.add(place.id);
    _rebuildDays();
  }

  void _rebuildDays() {
    if (_savedPlaces.isEmpty) return;
    final days = ChatFirstDemoData.intakeDays(
      List<Place>.of(_savedPlaces),
      itemsPerDay: _f5ItemsPerDay(),
      mustIds: _mustPlaceIds,
    );
    final current = _snapshot();
    summary = summary.copyWith(
      snapshot: current.copyWith(
        placeLabels: _savedPlaces
            .map((place) => place.name)
            .toList(growable: false),
        days: days,
      ),
    );
  }

  /// The daily items count from the intake pace answer, reusing the same
  /// mapping as [buildFinalProposal].
  int _f5ItemsPerDay() => switch (answers['q-pace']) {
    'Rilassato: un paio di tappe al giorno' => 1,
    'Pieno, ma con pause vere' => 3,
    _ => 2,
  };

  /// The concrete F5 edit Iter proposes before saving: a gentle closing walk
  /// on the last day. Built from the curated thread state, so accepting both
  /// applies the change and persists the fully refined plan.
  PlanProposal _buildItineraryProposal() {
    final current = _snapshot();
    final days = List<TripDaySnapshot>.of(current.days);
    if (days.isNotEmpty) {
      final last = days.removeLast();
      days.add(
        TripDaySnapshot(
          label: last.label,
          theme: last.theme,
          items: <TripItemSnapshot>[
            ...last.items,
            const TripItemSnapshot(
              title: 'Passeggiata finale',
              category: 'Passeggiata',
              time: '18:30',
              locked: false,
            ),
          ],
        ),
      );
    }
    return PlanProposal(
      changeLabel: 'Aggiungo una passeggiata finale senza orari fissi.',
      snapshot: current.copyWith(days: days),
    );
  }

  /// The concrete plan built from [answers], tied to the journey destination.
  /// Missing or unexpected answers fall back to the balanced defaults.
  PlanProposal buildFinalProposal() {
    final destinationId = journey!.destinationIds.first;
    final city = journeyCity(journey!);
    final durationLabel = switch (answers['q-duration']) {
      'Un weekend, 3 giorni' => '3 giorni',
      'Una settimana o più' => '5–7 giorni',
      _ => '4–5 giorni',
    };
    final dayCount = switch (durationLabel) {
      '3 giorni' => 2,
      '5–7 giorni' => 4,
      _ => 3,
    };
    final itemsPerDay = switch (answers['q-pace']) {
      'Rilassato: un paio di tappe al giorno' => 1,
      'Pieno, ma con pause vere' => 3,
      _ => 2,
    };
    final transport = switch (answers['q-transport']) {
      'Soprattutto a piedi' => 'A piedi',
      'Treno o metro + passi' => 'Treno e metro + passi',
      _ => 'Treno, metro e qualche camminata',
    };
    final stay = switch (answers['q-base']) {
      'Quartiere vissuto, più locale' =>
        'Quartiere vissuto, fuori dal classico',
      'Consigliami tu' => ChatFirstDemoData.preferredStayFor(destinationId),
      _ => 'Base nel centro, tutto a piedi',
    };
    final budgetNote = switch (answers['q-budget']) {
      'Leggero: zero extra' => 'con un budget leggero',
      'Aperto: non è un limite' => 'con budget aperto',
      _ => 'con un budget moderato',
    };
    final places = ChatFirstDemoData.topPlacesFor(
      destinationId,
      take: dayCount * itemsPerDay,
    );
    final days = ChatFirstDemoData.intakeDays(places, itemsPerDay: itemsPerDay);
    final placeLabels = places
        .take(3)
        .map((place) => place.name)
        .toList(growable: false);
    return PlanProposal(
      changeLabel:
          'Bozza: $city, $durationLabel, $stay, $transport, $budgetNote.',
      snapshot: TripSnapshot(
        destinationTitle: city,
        country: ChatFirstDemoData._countryFor(destinationId),
        durationLabel: durationLabel,
        statusLabel: 'In pianificazione',
        dates: 'giorni da confermare insieme',
        transport: transport,
        stay: stay,
        placeLabels: placeLabels,
        days: days,
      ),
    );
  }
}

/// The single city name a journey is presented under in the prototype.
/// The demo copy keeps the evocative route titles in the shared mock, but the
/// chat-first surfaces show one clean city name, never a slogan.
String journeyCity(JourneyRoute journey) =>
    journey.stops.isNotEmpty ? journey.stops.first : journey.title;

/// Formats EUR cents as a compact, deterministic demo price, e.g. `189 €`.
String formatEuroCents(int cents) => '${(cents / 100).toStringAsFixed(0)} €';

/// Shared nightly-rate formula used by the in-chat stay stepper and by the
/// controller proposal, so the preview and the confirmed proposal always
/// agree for the same option. Prefers the fixture nightly rate; falls back to
/// the rounded per-night share without ever dividing by zero.
int stayNightlyPriceCents({
  required int priceCents,
  required int nights,
  int nightlyPriceCents = 0,
}) {
  if (nightlyPriceCents > 0) return nightlyPriceCents;
  if (nights <= 0) return priceCents;
  return (priceCents / nights).round();
}

/// A conversation started from the traveler's own words before a destination is
/// named. It first reflects the clues, asks which trend meta calls the
/// traveler, then converges the whole intake on the Porto route: every answer
/// to the meta question lands on the same deterministic proposal and F5 tail.
class FreeTalkThread extends IntakeThread {
  FreeTalkThread({
    required this.viewDestinations,
    required JourneyRoute convergenceJourney,
    required super.summary,
    required super.script,
    super.openedWith,
  }) : super(journey: convergenceJourney);

  /// Trend catalog shown as the meta question choices and used to strip
  /// destination names from the wish echo.
  final List<JourneyRoute> viewDestinations;

  /// The traveler's free-form wish, captured from the first reply.
  String? _wish;

  @override
  ChatMessage travelerMessage(String text) {
    final message = super.travelerMessage(text);
    _wish ??= text.trim();
    return message;
  }

  @override
  bool advance() {
    if (scriptIndex >= script.length) return false;
    final beat = script[scriptIndex];
    if (beat.assistant.id == kFreeTalkAckId) {
      scriptIndex++;
      _emit(
        ChatMessage(
          id: kFreeTalkAckId,
          role: ChatRole.assistant,
          kind: ChatMessageKind.text,
          text: 'Ho capito: ${_cluePreview(_wish)}.',
          sentAt: beat.assistant.sentAt,
        ),
      );
      // The first intent earns both the acknowledgement and the next guarded
      // question. Do not require an unexplained extra traveler message.
      return advance();
    }
    final advanced = super.advance();
    if (advanced && journey != null) {
      final last = messages.isNotEmpty ? messages.last : null;
      if (last?.kind == ChatMessageKind.planProposal &&
          last!.proposal?.outcome == null) {
        summary = summary.copyWith(title: journeyCity(journey!));
      }
    }
    return advanced;
  }

  String _cluePreview(String? value) {
    var preview = value?.trim() ?? 'la tua idea';
    for (final destination in viewDestinations) {
      preview = preview.replaceAllMapped(
        RegExp(
          '(^|[^\\p{L}\\p{N}_])${RegExp.escape(journeyCity(destination))}(?=\$|[^\\p{L}\\p{N}_])',
          caseSensitive: false,
          unicode: true,
        ),
        (match) => match.group(1)!,
      );
    }
    preview = preview.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
    // A wish that was only a meta name strips down to function words
    // ("Vorrei andare a "): fall back gently instead of echoing the stumps.
    final significant = preview
        .replaceAll(
          RegExp(
            r'\b(a|di|in|da|al|alla|nel|nella|per|verso|con|il|la|lo|gli|le|un|una|e|o|che|vorrei|andare)\b',
            caseSensitive: false,
          ),
          ' ',
        )
        .trim();
    return significant.isEmpty ? 'la tua idea' : preview;
  }

  void _emit(ChatMessage message) {
    messages.add(message);
  }
}

/// Deterministic demo content for the chat-first prototype.
abstract final class ChatFirstDemoData {
  static final DateTime _fixtureQuotedAt = DateTime.utc(2026, 8, 11, 9);

  /// Returns the complete local fixture for a supported operational destination.
  static OperationalTripFixture operationalFixtureFor(String destinationId) {
    switch (destinationId) {
      case 'porto':
        return _portoOperationalFixture();
      case 'roma':
        return _romaOperationalFixture();
      default:
        throw ArgumentError.value(destinationId, 'destinationId');
    }
  }

  /// Place catalogue scoped to one destination; no provider or runtime fetch.
  static List<OperationalPlaceFixture> placeCatalogFor(String destinationId) =>
      List<OperationalPlaceFixture>.unmodifiable(
        operationalFixtureFor(destinationId).placeCatalog,
      );

  /// Resolves the deterministic operational inventory owned by [snapshot].
  /// Unknown destinations intentionally return null instead of inventing
  /// provider data.
  static OperationalTripFixture? operationalFixtureForSnapshot(
    TripSnapshot snapshot,
  ) {
    final destination = snapshot.destinationTitle
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ');
    return switch (destination) {
      'porto' => operationalFixtureFor('porto'),
      'roma' => operationalFixtureFor('roma'),
      _ => null,
    };
  }

  /// Maps every flight fixture without changing fixture order or state.
  static List<TravelOption> travelOptionsFor(TripSnapshot snapshot) {
    final fixture = operationalFixtureForSnapshot(snapshot);
    if (fixture == null) return const <TravelOption>[];
    return List<TravelOption>.unmodifiable(
      fixture.flights.map(
        (flight) => TravelOption(
          id: flight.id,
          label:
              '${flight.provider} · ${flight.departureAirport}–${flight.arrivalAirport}',
          priceCents: flight.priceCents,
        ),
      ),
    );
  }

  /// Maps one flight fixture into the canonical selected-option shape.
  static TravelOption? travelOptionFor({
    required TripSnapshot snapshot,
    required String optionId,
  }) {
    for (final option in travelOptionsFor(snapshot)) {
      if (option.id != optionId) continue;
      return TravelOption(
        id: option.id,
        label: option.label,
        priceCents: option.priceCents,
        purchaseState: PurchaseState.selected,
      );
    }
    return null;
  }

  /// Maps every hotel fixture without changing fixture order or state.
  static List<StayOption> stayOptionsFor(TripSnapshot snapshot) {
    final fixture = operationalFixtureForSnapshot(snapshot);
    if (fixture == null) return const <StayOption>[];
    return List<StayOption>.unmodifiable(
      fixture.hotels.map(
        (hotel) => StayOption(
          id: hotel.id,
          label: hotel.name,
          priceCents: hotel.priceCents,
        ),
      ),
    );
  }

  /// Maps one hotel fixture into the canonical selected-option shape.
  static StayOption? stayOptionFor({
    required TripSnapshot snapshot,
    required String optionId,
  }) {
    for (final option in stayOptionsFor(snapshot)) {
      if (option.id != optionId) continue;
      return StayOption(
        id: option.id,
        label: option.label,
        priceCents: option.priceCents,
        purchaseState: PurchaseState.selected,
      );
    }
    return null;
  }

  /// Rich, immutable chat view of every local flight fixture.
  static FlightCompare flightCompareFor(TripSnapshot snapshot) {
    final fixture = operationalFixtureForSnapshot(snapshot);
    final options =
        fixture?.flights
            .map(
              (flight) => FlightOptionInfo(
                id: flight.id,
                provider: flight.provider,
                departureAirport: flight.departureAirport,
                arrivalAirport: flight.arrivalAirport,
                departureAt: flight.departureAt,
                arrivalAt: flight.arrivalAt,
                durationMinutes: flight.durationMinutes,
                stops: flight.stops,
                baggage: flight.baggage,
                priceCents: flight.priceCents,
                tradeoff: flight.tradeoff,
              ),
            )
            .toList(growable: false) ??
        const <FlightOptionInfo>[];
    return FlightCompare(
      options: options,
      recommendedId: options.isEmpty ? '' : options.first.id,
      quotedAt:
          fixture?.quotedAt ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  /// Rich, immutable chat view of every local hotel fixture.
  static StayCompare stayCompareFor(TripSnapshot snapshot) {
    final fixture = operationalFixtureForSnapshot(snapshot);
    final options =
        fixture?.hotels
            .map(
              (hotel) => StayOptionInfo(
                id: hotel.id,
                name: hotel.name,
                zone: hotel.zone,
                nights: hotel.nights,
                priceCents: hotel.priceCents,
                conditions: hotel.conditions,
                averageWalkMinutes: hotel.averageWalkMinutes,
                atmosphere: hotel.atmosphere,
                tradeoff: hotel.tradeoff,
                provider: hotel.provider,
              ),
            )
            .toList(growable: false) ??
        const <StayOptionInfo>[];
    return StayCompare(
      options: options,
      recommendedId: options.isEmpty ? '' : options.first.id,
    );
  }

  static OperationalTripFixture _portoOperationalFixture() {
    final media = PlanMedia(
      imageUrl: 'assets/images/travel/porto_livraria_lello.jpg',
      reelUrl: 'assets/videos/vertical/porto_livraria_lello_reel.mp4',
      photoAttribution: const MediaAttribution(
        author: 'JaimeMSilva',
        sourceUrl:
            'https://commons.wikimedia.org/wiki/File:Porto_-_Livraria_Lello.jpg',
      ),
      reelAttribution: const MediaAttribution(
        author: 'JaimeMSilva / Iter demo edit',
        sourceUrl:
            'https://commons.wikimedia.org/wiki/File:Porto_-_Livraria_Lello.jpg',
      ),
    );
    return OperationalTripFixture(
      destinationId: 'porto',
      media: media,
      mediaGallery: <PlanMedia>[
        media,
        const PlanMedia(
          imageUrl: 'assets/images/travel/porto_river.jpg',
          reelUrl: 'assets/videos/vertical/porto_river.mp4',
        ),
        const PlanMedia(
          imageUrl: 'assets/images/travel/porto_rooftops.jpg',
          reelUrl: 'assets/videos/vertical/porto_rooftops.mp4',
        ),
      ],
      quotedAt: _fixtureQuotedAt,
      snapshot: TripSnapshot(
        destinationTitle: 'Porto',
        country: 'Portogallo',
        durationLabel: '2 giorni',
        statusLabel: 'In pianificazione',
        dates: '17–18 ottobre 2026',
        transport: 'Volo da Roma',
        stay: 'Cedofeita',
        destinationMedia: media,
        placeLabels: const <String>[
          'Livraria Lello',
          'Torre dos Clérigos',
          'Ribeira',
          'Jardins do Palácio de Cristal',
        ],
        days: <TripDaySnapshot>[
          TripDaySnapshot(
            id: 'porto-day-1',
            date: DateTime.utc(2026, 10, 17),
            label: 'Giorno 1',
            theme: 'Libri e centro storico',
            items: const <TripItemSnapshot>[
              TripItemSnapshot(
                id: 'porto-livraria-lello-stop',
                title: 'Livraria Lello',
                category: 'Libreria storica',
                startTime: '10:00',
                durationMinutes: 75,
                place: PlanPlaceDetails(
                  id: 'porto-livraria-lello',
                  title: 'Livraria Lello',
                  description:
                      'Scalone in legno e scaffali Liberty nel centro di Porto.',
                ),
                locked: false,
              ),
              TripItemSnapshot(
                id: 'porto-clerigos-stop',
                title: 'Torre dos Clérigos',
                category: 'Panorama',
                startTime: '12:00',
                durationMinutes: 60,
                place: PlanPlaceDetails(
                  id: 'porto-clerigos',
                  title: 'Torre dos Clérigos',
                  description: 'Torre barocca con vista compatta sulla città.',
                ),
                locked: false,
              ),
            ],
          ),
          TripDaySnapshot(
            id: 'porto-day-2',
            date: DateTime.utc(2026, 10, 18),
            label: 'Giorno 2',
            theme: 'Fiume e giardini',
            items: const <TripItemSnapshot>[
              TripItemSnapshot(
                id: 'porto-ribeira-stop',
                title: 'Ribeira',
                category: 'Quartiere',
                startTime: '10:30',
                durationMinutes: 120,
                place: PlanPlaceDetails(
                  id: 'porto-ribeira',
                  title: 'Ribeira',
                  description:
                      'Rive del Douro per una passeggiata senza fretta.',
                ),
                locked: false,
              ),
              TripItemSnapshot(
                id: 'porto-cristal-stop',
                title: 'Jardins do Palácio de Cristal',
                category: 'Giardini',
                startTime: '16:00',
                durationMinutes: 90,
                place: PlanPlaceDetails(
                  id: 'porto-palacio-cristal',
                  title: 'Jardins do Palácio de Cristal',
                  description: 'Verde, pavoni e viste sul Douro.',
                ),
                locked: false,
              ),
            ],
          ),
        ],
      ),
      placeCatalog: <OperationalPlaceFixture>[
        OperationalPlaceFixture(
          id: 'porto-livraria-lello',
          destinationId: 'porto',
          name: 'Livraria Lello',
          category: 'Libreria storica',
          latitude: 41.146905,
          longitude: -8.614732,
          description:
              'Scalone in legno e scaffali Liberty nel centro di Porto.',
          media: media,
        ),
        const OperationalPlaceFixture(
          id: 'porto-clerigos',
          destinationId: 'porto',
          name: 'Torre dos Clérigos',
          category: 'Panorama',
          latitude: 41.145837,
          longitude: -8.614032,
          description: 'Torre barocca con vista compatta sulla città.',
        ),
        const OperationalPlaceFixture(
          id: 'porto-ribeira',
          destinationId: 'porto',
          name: 'Ribeira',
          category: 'Quartiere',
          latitude: 41.140613,
          longitude: -8.611019,
          description: 'Rive del Douro per una passeggiata senza fretta.',
        ),
        const OperationalPlaceFixture(
          id: 'porto-palacio-cristal',
          destinationId: 'porto',
          name: 'Jardins do Palácio de Cristal',
          category: 'Giardini',
          latitude: 41.148369,
          longitude: -8.626047,
          description: 'Verde, pavoni e viste sul Douro.',
        ),
      ],
      flights: <FlightFixture>[
        FlightFixture(
          id: 'porto-flight-tap-direct',
          priceCents: 18900,
          provider: 'TAP Air Portugal',
          providerUrl: Uri.parse('https://www.flytap.com/'),
          tradeoff: 'Diretto e comodo, ma non il più economico.',
          departureAirport: 'FCO',
          arrivalAirport: 'OPO',
          departureAt: DateTime.utc(2026, 10, 17, 7, 15),
          arrivalAt: DateTime.utc(2026, 10, 17, 10, 20),
          durationMinutes: 185,
          stops: 0,
          baggage: 'Bagaglio a mano 10 kg',
        ),
        FlightFixture(
          id: 'porto-flight-ryanair-direct',
          priceCents: 11900,
          provider: 'Ryanair',
          providerUrl: Uri.parse('https://www.ryanair.com/'),
          tradeoff: 'Prezzo migliore; orario molto presto.',
          departureAirport: 'FCO',
          arrivalAirport: 'OPO',
          departureAt: DateTime.utc(2026, 10, 17, 6, 20),
          arrivalAt: DateTime.utc(2026, 10, 17, 9, 25),
          durationMinutes: 185,
          stops: 0,
          baggage: 'Zaino piccolo incluso',
        ),
        FlightFixture(
          id: 'porto-flight-iberia-mad',
          priceCents: 15600,
          provider: 'Iberia',
          providerUrl: Uri.parse('https://www.iberia.com/'),
          tradeoff: 'Parte più tardi, con scalo a Madrid.',
          departureAirport: 'FCO',
          arrivalAirport: 'OPO',
          departureAt: DateTime.utc(2026, 10, 17, 9, 35),
          arrivalAt: DateTime.utc(2026, 10, 17, 14, 10),
          durationMinutes: 275,
          stops: 1,
          baggage: 'Bagaglio a mano 10 kg',
        ),
        FlightFixture(
          id: 'porto-flight-vueling-bcn',
          priceCents: 14300,
          provider: 'Vueling',
          providerUrl: Uri.parse('https://www.vueling.com/'),
          tradeoff: 'Buon compromesso di prezzo, con cambio a Barcellona.',
          departureAirport: 'FCO',
          arrivalAirport: 'OPO',
          departureAt: DateTime.utc(2026, 10, 17, 8, 50),
          arrivalAt: DateTime.utc(2026, 10, 17, 13, 35),
          durationMinutes: 285,
          stops: 1,
          baggage: 'Bagaglio a mano 10 kg',
        ),
      ],
      hotels: <HotelFixture>[
        HotelFixture(
          id: 'porto-hotel-torel-avantgarde',
          priceCents: 48200,
          provider: 'Booking.com',
          providerUrl: Uri.parse('https://www.booking.com/'),
          tradeoff: 'Design e vista sul fiume, prezzo più alto.',
          name: 'Torel Avantgarde',
          zone: 'Cedofeita',
          nights: 1,
          nightlyPriceCents: 48200,
          conditions: 'Cancellazione gratuita fino a 7 giorni prima',
          averageWalkMinutes: 18,
          atmosphere: 'Boutique creativo',
        ),
        HotelFixture(
          id: 'porto-hotel-moov-centro',
          priceCents: 23600,
          provider: 'Booking.com',
          providerUrl: Uri.parse('https://www.booking.com/'),
          tradeoff: 'Essenziale e centrale, meno atmosfera.',
          name: 'Moov Hotel Porto Centro',
          zone: 'Sé',
          nights: 1,
          nightlyPriceCents: 23600,
          conditions: 'Pagamento in struttura',
          averageWalkMinutes: 13,
          atmosphere: 'Semplice e pratico',
        ),
        HotelFixture(
          id: 'porto-hotel-yotel',
          priceCents: 31800,
          provider: 'Hotels.com',
          providerUrl: Uri.parse('https://www.hotels.com/'),
          tradeoff: 'Camere compatte, posizione molto comoda.',
          name: 'YOTEL Porto',
          zone: 'Trindade',
          nights: 1,
          nightlyPriceCents: 31800,
          conditions: 'Non rimborsabile',
          averageWalkMinutes: 15,
          atmosphere: 'Contemporaneo',
        ),
        HotelFixture(
          id: 'porto-hotel-ribeira',
          priceCents: 39600,
          provider: 'Expedia',
          providerUrl: Uri.parse('https://www.expedia.com/'),
          tradeoff: 'Sul fiume, più affollato la sera.',
          name: 'Eurostars Porto Douro',
          zone: 'Ribeira',
          nights: 1,
          nightlyPriceCents: 39600,
          conditions: 'Cancellazione gratuita fino a 3 giorni prima',
          averageWalkMinutes: 8,
          atmosphere: 'Classico sul Douro',
        ),
      ],
    );
  }

  static OperationalTripFixture _romaOperationalFixture() =>
      OperationalTripFixture(
        destinationId: 'roma',
        quotedAt: _fixtureQuotedAt,
        media: const PlanMedia(imageUrl: 'assets/images/travel/rome_vespa.jpg'),
        mediaGallery: const <PlanMedia>[
          PlanMedia(
            imageUrl: 'assets/images/travel/rome_vespa.jpg',
            reelUrl: 'assets/videos/vertical/rome_vespa.mp4',
          ),
          PlanMedia(
            imageUrl: 'assets/images/travel/rome_city.jpg',
            reelUrl: 'assets/videos/vertical/rome_city.mp4',
          ),
        ],
        snapshot: TripSnapshot(
          destinationTitle: 'Roma',
          country: 'Italia',
          durationLabel: '2 giorni',
          statusLabel: 'In viaggio',
          dates: '14–15 ottobre 2026',
          transport: 'A piedi e metro',
          stay: 'Trastevere',
          placeLabels: const <String>[
            'Foro Romano',
            'Villa Borghese',
            'Campo de’ Fiori',
            'Trastevere',
          ],
          days: <TripDaySnapshot>[
            TripDaySnapshot(
              id: 'roma-day-1',
              date: DateTime.utc(2026, 10, 14),
              label: 'Giorno 1',
              theme: 'Fori e piazze',
              items: const <TripItemSnapshot>[
                TripItemSnapshot(
                  id: 'roma-foro-stop',
                  title: 'Foro Romano',
                  category: 'Archeologia',
                  startTime: '10:00',
                  durationMinutes: 120,
                  place: PlanPlaceDetails(
                    id: 'roma-foro-romano',
                    title: 'Foro Romano',
                    description: 'Il cuore archeologico della Roma antica.',
                  ),
                  locked: true,
                ),
              ],
            ),
            TripDaySnapshot(
              id: 'roma-day-2',
              date: DateTime.utc(2026, 10, 15),
              label: 'Giorno 2',
              theme: 'Verde e tavola',
              items: const <TripItemSnapshot>[
                TripItemSnapshot(
                  id: 'roma-borghese-stop',
                  title: 'Villa Borghese',
                  category: 'Verde',
                  startTime: '10:30',
                  durationMinutes: 120,
                  place: PlanPlaceDetails(
                    id: 'roma-villa-borghese',
                    title: 'Villa Borghese',
                    description: 'Pausa verde tra museo e belvedere.',
                  ),
                  locked: false,
                ),
              ],
            ),
          ],
        ),
        placeCatalog: const <OperationalPlaceFixture>[
          OperationalPlaceFixture(
            id: 'roma-foro-romano',
            destinationId: 'roma',
            name: 'Foro Romano',
            category: 'Archeologia',
            latitude: 41.892462,
            longitude: 12.485325,
            description: 'Il cuore archeologico della Roma antica.',
          ),
          OperationalPlaceFixture(
            id: 'roma-villa-borghese',
            destinationId: 'roma',
            name: 'Villa Borghese',
            category: 'Verde',
            latitude: 41.914181,
            longitude: 12.492301,
            description: 'Pausa verde tra museo e belvedere.',
          ),
          OperationalPlaceFixture(
            id: 'roma-campo-fiori',
            destinationId: 'roma',
            name: 'Campo de’ Fiori',
            category: 'Mercato',
            latitude: 41.895822,
            longitude: 12.472241,
            description: 'Piazza viva per mercato e cena.',
          ),
          OperationalPlaceFixture(
            id: 'roma-trastevere',
            destinationId: 'roma',
            name: 'Trastevere',
            category: 'Quartiere',
            latitude: 41.889727,
            longitude: 12.470806,
            description: 'Vicoli e tavole per la sera.',
          ),
        ],
        flights: const <FlightFixture>[],
        hotels: const <HotelFixture>[],
      );

  static List<ChatThread> seedThreads() => List<ChatThread>.of(<ChatThread>[
    _planningPorto(),
    _activeRoma(),
  ], growable: true);

  /// Trend destinations shown on the Home. Each gets an editorial city sheet
  /// and an "Organizza un viaggio" entry that opens a fresh planning thread.
  static List<JourneyRoute> trendJourneys() =>
      MockData.journeys.take(4).toList();

  /// Opens the guided intake for a home destination trend: one question at a
  /// time as messages with [ChatChoice]s (duration, pace, base, transport,
  /// budget) and a final proposal assembled from the answers. Deterministic
  /// for the same answers and tied to the journey destination.
  static IntakeThread intakeThreadFor(JourneyRoute journey) {
    final destinationId = journey.destinationIds.first;
    final posters = DemoMedia.postersForDestination(destinationId);
    final city = journeyCity(journey);
    final summary = TripSnapshot(
      destinationTitle: city,
      country: _countryFor(destinationId),
      durationLabel: journey.durationLabel,
      statusLabel: 'In pianificazione',
      dates: 'giorni da scegliere insieme',
      transport: 'da definire',
      stay: 'da definire',
      placeLabels: const <String>[],
      days: const <TripDaySnapshot>[],
    );
    return IntakeThread(
      journey: journey,
      summary: Conversation(
        id: 'c-${journey.id}',
        title: city,
        subtitle: 'Nuovo piano',
        avatar: ChatAvatar(
          posters.isNotEmpty
              ? posters.first
              : 'assets/images/travel/rail_coast.jpg',
          label: city,
        ),
        timestamp: DateTime(2026, 10, 16, 10, 0),
        lastPreview: 'Poche domande e ti preparo una prima proposta.',
        snapshot: summary,
        isTrending: true,
      ),
      openedWith: <ChatMessage>[
        ChatMessage(
          id: 'q-duration',
          role: ChatRole.assistant,
          kind: ChatMessageKind.text,
          text: 'Prima di tutto: quanti giorni vuoi dedicare a $city?',
          sentAt: DateTime(2026, 10, 16, 10, 0),
          choices: const <ChatChoice>[
            ChatChoice(label: 'Un weekend, 3 giorni'),
            ChatChoice(label: '4–5 giorni, senza fretta'),
            ChatChoice(label: 'Una settimana o più'),
          ],
        ),
      ],
      script: restIntakeScript(journey),
    );
  }

  /// Picks the journey the free talk converges on, with an explicit guard:
  /// the dedicated `porto-slow` route wins, then any porto-leading journey,
  /// then the first catalog entry. An empty catalog falls back to the demo
  /// `porto-slow` route instead of throwing.
  static JourneyRoute _convergenceJourney(List<JourneyRoute> journeys) {
    for (final journey in journeys) {
      if (journey.id == 'porto-slow') return journey;
    }
    for (final journey in journeys) {
      if (journey.destinationIds.first == 'porto') return journey;
    }
    if (journeys.isNotEmpty) return journeys.first;
    return MockData.journeys.firstWhere(
      (journey) => journey.id == 'porto-slow',
      orElse: () => MockData.journeys.first,
    );
  }

  /// Opens a free-talk conversation: the traveler starts with their own words
  /// (no destination pinned) and is offered the trend metas as an explicit
  /// choice. Whatever they pick (including "Consigliami tu"), the thread
  /// converges on the Porto route and the classic guided intake via
  /// [FreeTalkThread], so the final proposal always builds the operational
  /// Porto snapshot.
  static FreeTalkThread freeTalkThread(
    List<JourneyRoute> journeys, {
    String conversationId = kFreeTalkConversationId,
  }) {
    // The free talk always converges on Porto: its operational fixture drives
    // the rich FlightCompare/StayCompare modules during the F5 tail. Porto must
    // be the leading destination — atlantic-rail also touches Porto, but its
    // home base is Lisbon, so the operational snapshot would miss the fixture.
    final convergence = _convergenceJourney(journeys);
    final posters = DemoMedia.postersForDestination(
      convergence.destinationIds.first,
    );
    final metaChoices = <String>[];
    for (final journey in journeys) {
      final city = journeyCity(journey);
      if (!metaChoices.contains(city)) metaChoices.add(city);
    }
    metaChoices.add('Consigliami tu');
    return FreeTalkThread(
      viewDestinations: journeys,
      convergenceJourney: convergence,
      summary: Conversation(
        id: conversationId,
        title: 'Nuova idea',
        subtitle: 'Inizia libera',
        avatar: ChatAvatar(
          posters.isNotEmpty
              ? posters.first
              : 'assets/images/travel/rail_coast.jpg',
          label: 'Nuova idea',
        ),
        timestamp: DateTime(2026, 10, 16, 10, 0),
        lastPreview: 'Parlane: non serve una città per iniziare.',
        snapshot: null,
        isTrending: false,
      ),
      openedWith: <ChatMessage>[
        ChatMessage(
          id: 'k-free-open',
          role: ChatRole.assistant,
          kind: ChatMessageKind.text,
          text:
              'Raccontami il viaggio che hai in mente: un periodo, un '
              'desiderio, un luogo che ti chiama. Quello che viene.',
          sentAt: DateTime(2026, 10, 16, 10, 0),
        ),
      ],
      // The destination choice never pins the journey: whatever the traveler
      // answers, the thread keeps converging on the Porto route below, which
      // contains the standard guided questions (duration, pace, base,
      // transport, budget) and the final proposal.
      script: <ScriptedBeat>[
        ScriptedBeat(
          ChatMessage(
            id: kFreeTalkAckId,
            role: ChatRole.assistant,
            kind: ChatMessageKind.text,
            text: '',
            sentAt: DateTime(2026, 10, 16, 10, 0),
          ),
        ),
        ScriptedBeat(
          ChatMessage(
            id: kFreeTalkDestinationId,
            role: ChatRole.assistant,
            kind: ChatMessageKind.text,
            text:
                'Sento che ci sono posti che ti chiamano. Quale ti suona più '
                'giusto?',
            sentAt: DateTime(2026, 10, 16, 10, 1),
            choices: <ChatChoice>[
              for (final city in metaChoices) ChatChoice(label: city),
            ],
          ),
        ),
        ScriptedBeat(
          ChatMessage(
            id: 'q-duration',
            role: ChatRole.assistant,
            kind: ChatMessageKind.text,
            text: 'E per quanto tempo vuoi viaggiare?',
            sentAt: DateTime(2026, 10, 16, 10, 1),
            choices: const <ChatChoice>[
              ChatChoice(label: 'Un weekend, 3 giorni'),
              ChatChoice(label: '4–5 giorni, senza fretta'),
              ChatChoice(label: 'Una settimana o più'),
            ],
          ),
        ),
        ...restIntakeScript(
          convergence,
          proposalDisclosure:
              'Per la demo convergo su ${journeyCity(convergence)}, che ha il '
              'piano completo: da qui volo, hotel e mete sono dati demo.',
        ),
      ],
    );
  }

  /// The guided script that follows the duration question: pace, base,
  /// transport, budget, the final intake proposal and the operational tail.
  /// Shared verbatim by [intakeThreadFor] and the [FreeTalkThread] tail, so the
  /// two flows converge on the same deterministic proposal after the
  /// destination is pinned. [proposalDisclosure] is an optional honest note
  /// appended to the proposal text; only the free talk passes it, to tell the
  /// traveler that the demo converges on the Porto route.
  static List<ScriptedBeat> restIntakeScript(
    JourneyRoute journey, {
    String? proposalDisclosure,
  }) {
    final city = journeyCity(journey);
    return <ScriptedBeat>[
      ScriptedBeat(
        ChatMessage(
          id: 'q-pace',
          role: ChatRole.assistant,
          kind: ChatMessageKind.text,
          text: 'Che ritmo preferisci per le tue giornate a $city?',
          sentAt: DateTime(2026, 10, 16, 10, 1),
          choices: const <ChatChoice>[
            ChatChoice(label: 'Rilassato: un paio di tappe al giorno'),
            ChatChoice(label: 'Bilanciato: cultura e pause'),
            ChatChoice(label: 'Pieno, ma con pause vere'),
          ],
        ),
      ),
      ScriptedBeat(
        ChatMessage(
          id: 'q-base',
          role: ChatRole.assistant,
          kind: ChatMessageKind.text,
          text: 'Dove preferisci dormire a $city?',
          sentAt: DateTime(2026, 10, 16, 10, 2),
          choices: const <ChatChoice>[
            ChatChoice(label: 'Centro, per spostarmi a piedi'),
            ChatChoice(label: 'Quartiere vissuto, più locale'),
            ChatChoice(label: 'Consigliami tu'),
          ],
        ),
      ),
      ScriptedBeat(
        ChatMessage(
          id: 'q-transport',
          role: ChatRole.assistant,
          kind: ChatMessageKind.text,
          text: 'Come vuoi spostarti in città?',
          sentAt: DateTime(2026, 10, 16, 10, 3),
          choices: const <ChatChoice>[
            ChatChoice(label: 'Soprattutto a piedi'),
            ChatChoice(label: 'Treno o metro + passi'),
            ChatChoice(label: 'Misto, senza pensare troppo'),
          ],
        ),
      ),
      ScriptedBeat(
        ChatMessage(
          id: 'q-budget',
          role: ChatRole.assistant,
          kind: ChatMessageKind.text,
          text: 'Come inquadro il budget?',
          sentAt: DateTime(2026, 10, 16, 10, 4),
          choices: const <ChatChoice>[
            ChatChoice(label: 'Leggero: zero extra'),
            ChatChoice(label: 'Moderato: qualche tavola bella'),
            ChatChoice(label: 'Aperto: non è un limite'),
          ],
        ),
      ),
      ScriptedBeat(
        ChatMessage(
          id: 'intake-proposal',
          role: ChatRole.assistant,
          kind: ChatMessageKind.planProposal,
          text:
              'Ecco la prima proposta per $city, costruita sulle tue risposte.'
              '${proposalDisclosure == null ? '' : ' $proposalDisclosure'}',
          sentAt: DateTime(2026, 10, 16, 10, 5),
        ),
      ),
      ScriptedBeat(
        ChatMessage(
          id: 'intake-summary',
          role: ChatRole.assistant,
          kind: ChatMessageKind.tripSummary,
          text: 'Il piano, aggiornato con la tua decisione.',
          sentAt: DateTime(2026, 10, 16, 10, 6),
        ),
      ),
      ScriptedBeat(
        ChatMessage(
          id: 'intake-operational',
          role: ChatRole.assistant,
          kind: ChatMessageKind.operational,
          text:
              'Ho salvato il piano come bozza. Potremo rifinirlo qui quando '
              'vuoi.',
          sentAt: DateTime(2026, 10, 16, 10, 7),
        ),
      ),
    ];
  }

  /// The best-matching stay zone name for a destination, or a generic label
  /// when the catalog has none. Used for the "Consigliami tu" answer.
  static String preferredStayFor(String destinationId) {
    final zones = _stayZonesSorted(destinationId);
    return zones.isEmpty ? 'In un quartiere vissuto' : zones.first.name;
  }

  /// The destination's stay zones ordered by average walk minutes, shortest
  /// first. The first is the recommended one; the second is the alternative.
  static List<StayZone> _stayZonesSorted(String destinationId) {
    final zones =
        MockData.stayZones
            .where((zone) => zone.destinationId == destinationId)
            .toList(growable: false)
          ..sort(
            (a, b) => a.averageWalkMinutes.compareTo(b.averageWalkMinutes),
          );
    return zones;
  }

  /// The demo transport comparison: reaching the destination by plane, train
  /// or car, with fake but coherent price and duration. Fully deterministic.
  static List<TransportOptionView> transportOptions() =>
      const <TransportOptionView>[
        TransportOptionView(
          label: 'Aereo diretto',
          priceLabel: 'da 89 €',
          durationLabel: '1h 30m',
          isRecommended: true,
        ),
        TransportOptionView(
          label: 'Treno ad alta velocità',
          priceLabel: 'da 54 €',
          durationLabel: '4h 45m',
        ),
        TransportOptionView(
          label: 'In auto',
          priceLabel: 'da 46 €',
          durationLabel: '3h 50m',
        ),
      ];

  /// The transport line stored in the snapshot after the traveler picks a
  /// demo option, e.g. 'Aereo diretto · 1h 30m'.
  static String transportSummaryFor(String label) {
    for (final option in transportOptions()) {
      if (option.label == label) {
        return '${option.label} · ${option.durationLabel}';
      }
    }
    return label;
  }

  /// The F5 refinement modules appended to an accepted intake thread:
  /// curation (places one at a time), transport comparison, stay zone, then
  /// the visual itinerary with the final edit proposal. Deterministic for the
  /// same destination.
  static List<ScriptedBeat> refinementBeats(String destinationId, String city) {
    final places = topPlacesFor(destinationId, take: 6);
    final zones = _stayZonesSorted(destinationId);
    final hasZones = zones.isNotEmpty;
    final recommended = zones.isNotEmpty ? zones.first : null;
    final alternative = zones.length > 1 ? zones[1] : null;
    final options = transportOptions();
    final posters = DemoMedia.postersForDestination(destinationId);
    final operationalSnapshot = TripSnapshot(
      destinationTitle: city,
      country: '',
      durationLabel: '',
      statusLabel: '',
      dates: '',
      transport: '',
      stay: '',
    );
    final flightCompare = flightCompareFor(operationalSnapshot);
    final stayCompare = stayCompareFor(operationalSnapshot);
    return <ScriptedBeat>[
      ScriptedBeat(
        ChatMessage(
          id: 'f5-curation-intro',
          role: ChatRole.assistant,
          kind: ChatMessageKind.text,
          text:
              'Bene. Ora rifiniamo il piano: ti mostro i luoghi di $city uno '
              'alla volta e mi dici come trattarli.',
          sentAt: DateTime(2026, 10, 16, 10, 8),
        ),
      ),
      for (var i = 0; i < places.length; i++)
        ScriptedBeat(
          ChatMessage(
            id: 'f5-place-${places[i].id}',
            role: ChatRole.assistant,
            kind: ChatMessageKind.placeCard,
            text: 'Luogo ${i + 1} di ${places.length}',
            sentAt: DateTime(2026, 10, 16, 10, 9, i),
            placeCard: placeCardFor(
              places[i],
              imageAsset: posters[i % posters.length],
            ),
            choices: const <ChatChoice>[
              ChatChoice(label: 'Passa'),
              ChatChoice(label: 'Salva'),
              ChatChoice(label: 'Irrinunciabile'),
            ],
          ),
        ),
      ScriptedBeat(
        ChatMessage(
          id: 'f5-transport',
          role: ChatRole.assistant,
          kind: ChatMessageKind.transport,
          text:
              'Come arrivi a $city? Ecco le opzioni demo con prezzi e '
              'durata indicativi.',
          sentAt: DateTime(2026, 10, 16, 10, 15),
          transport: TransportCompare(options: options),
          flightCompare: flightCompare.options.isNotEmpty
              ? flightCompare
              : null,
          choices: <ChatChoice>[
            for (final option in options) ChatChoice(label: option.label),
          ],
        ),
      ),
      ScriptedBeat(
        ChatMessage(
          id: 'f5-stay',
          role: ChatRole.assistant,
          kind: ChatMessageKind.stayZone,
          text:
              'Dove dormire a $city? Ti consiglio '
              '${recommended?.name ?? 'un quartiere vissuto'} per atmosfera e '
              'tempi a piedi. Prezzi e durate dei mezzi sono dimostrativi: non '
              'prenotiamo niente.',
          sentAt: DateTime(2026, 10, 16, 10, 16),
          stayZone: recommended != null ? stayZoneInfoFor(recommended) : null,
          stayCompare: stayCompare.options.isNotEmpty ? stayCompare : null,
          choices: <ChatChoice>[
            if (recommended != null) ChatChoice(label: recommended.name),
            if (alternative != null) ChatChoice(label: alternative.name),
            if (!hasZones) const ChatChoice(label: 'Consigliami tu'),
          ],
        ),
      ),
      ScriptedBeat(
        ChatMessage(
          id: kItineraryProposalId,
          role: ChatRole.assistant,
          kind: ChatMessageKind.planProposal,
          text:
              'Prima di salvare, un ritocco: chiudo il piano con una '
              'passeggiata finale senza orari fissi.',
          sentAt: DateTime(2026, 10, 16, 10, 18),
        ),
      ),
      ScriptedBeat(
        ChatMessage(
          id: 'f5-operational',
          role: ChatRole.assistant,
          kind: ChatMessageKind.operational,
          text:
              'Il piano è pronto e resta qui: quando vuoi, proponiamo il '
              'prossimo ritocco.',
          sentAt: DateTime(2026, 10, 16, 10, 19),
        ),
      ),
    ];
  }

  /// Light view of a catalog [Place] for the in-chat curation card.
  static PlaceCard placeCardFor(Place place, {String? imageAsset}) => PlaceCard(
    id: place.id,
    name: place.name,
    category: place.category,
    neighborhood: place.neighborhood,
    durationMinutes: place.durationMinutes,
    whyFits: place.whyItFits,
    bestMoment: place.bestMoment,
    imageAsset: imageAsset,
  );

  /// Light view of a catalog [StayZone] for the in-chat zone context.
  static StayZoneInfo stayZoneInfoFor(StayZone zone) => StayZoneInfo(
    name: zone.name,
    summary: zone.summary,
    whyFits: zone.whyItFits,
    averageWalkMinutes: zone.averageWalkMinutes,
  );

  /// The highest-scoring places of a destination, used to shape the proposal.
  static List<Place> topPlacesFor(String destinationId, {required int take}) {
    final places =
        MockData.places
            .where((place) => place.destinationId == destinationId)
            .toList(growable: false)
          ..sort((a, b) => b.matchScore.compareTo(a.matchScore));
    return places.take(take).toList(growable: false);
  }

  /// Chunks [places] into daily itineraries of at most [itemsPerDay] items,
  /// with deterministic times and light themes. Places whose id is in
  /// [mustIds] are locked (time-fixed) in the itinerary.
  static List<TripDaySnapshot> intakeDays(
    List<Place> places, {
    required int itemsPerDay,
    Set<String>? mustIds,
  }) {
    const themes = <String>[
      'Arrivo senza fretta',
      'Quartieri e pause',
      'Ultimo giro con calma',
      'Chiusura lenta',
    ];
    const times = <String>['09:30', '13:00', '16:30', '19:30'];
    final days = <TripDaySnapshot>[];
    for (
      var day = 0;
      day * itemsPerDay < places.length && day < themes.length;
      day++
    ) {
      final start = day * itemsPerDay;
      final end = start + itemsPerDay < places.length
          ? start + itemsPerDay
          : places.length;
      days.add(
        TripDaySnapshot(
          label: 'Giorno ${day + 1}',
          theme: themes[day],
          items: <TripItemSnapshot>[
            for (var i = start; i < end; i++)
              TripItemSnapshot(
                title: places[i].name,
                category: places[i].category,
                time: times[i % times.length],
                locked: mustIds?.contains(places[i].id) ?? false,
              ),
          ],
        ),
      );
    }
    return days;
  }

  static ChatThread planningThreadFor(JourneyRoute journey) {
    final destinationId = journey.destinationIds.first;
    final posters = DemoMedia.postersForDestination(destinationId);
    final summary = TripSnapshot(
      destinationTitle: journeyCity(journey),
      country: _countryFor(destinationId),
      durationLabel: journey.durationLabel,
      statusLabel: 'In pianificazione',
      dates: 'giorni da scegliere insieme',
      transport: 'da definire',
      stay: 'da definire',
      placeLabels: const <String>[],
      days: const <TripDaySnapshot>[],
    );
    return ChatThread(
      summary: Conversation(
        id: 'c-${journey.id}',
        title: journeyCity(journey),
        subtitle: 'Nuovo piano',
        avatar: ChatAvatar(
          posters.isNotEmpty
              ? posters.first
              : 'assets/images/travel/rail_coast.jpg',
          label: journeyCity(journey),
        ),
        timestamp: DateTime(2026, 10, 16, 10, 0),
        lastPreview: 'Prendiamoci un momento per capire come vuoi partire.',
        snapshot: summary,
        isTrending: true,
      ),
      openedWith: <ChatMessage>[
        ChatMessage(
          id: 'seed-0',
          role: ChatRole.assistant,
          kind: ChatMessageKind.text,
          text:
              '${journeyCity(journey)}. Mi sembra che ti stia bene ritmo lento, '
              'tavole locali e un viaggio che resta aperto. Da dove vuoi partire '
              'a raccontarmelo?',
          sentAt: DateTime(2026, 10, 16, 10, 0),
          choices: const <ChatChoice>[
            ChatChoice(label: 'Ho un paio di giorni liberi'),
            ChatChoice(label: 'Preferisco partire in autunno'),
            ChatChoice(label: 'Solo ispirazione, per ora'),
          ],
        ),
      ],
      script: <ScriptedBeat>[
        ScriptedBeat(
          ChatMessage(
            id: 's1',
            role: ChatRole.assistant,
            kind: ChatMessageKind.text,
            text:
                'Perfetto. Tengo da parte due o tre giornate libere e un ritmo '
                'senza orari fissi. Ti buttiamo giù una prima struttura.',
            sentAt: DateTime(2026, 10, 16, 10, 5),
            choices: <ChatChoice>[
              ChatChoice(label: 'Mostra il piano'),
              ChatChoice(label: 'Cambiamo destinazione'),
            ],
          ),
        ),
        ScriptedBeat(
          ChatMessage(
            id: 's2',
            role: ChatRole.assistant,
            kind: ChatMessageKind.planProposal,
            text:
                'Ecco la prima struttura che ho preparato. Se ti va, la '
                'imposto come bozza del piano.',
            sentAt: DateTime(2026, 10, 16, 10, 6),
            proposal: PlanProposal(
              changeLabel:
                  'Bozza: Porto 4–5 giorni, base vicino alla Ribeira, tre tappe.',
              snapshot: TripSnapshot(
                destinationTitle: 'Porto',
                country: 'Portogallo',
                durationLabel: '4–5 giorni',
                statusLabel: 'In pianificazione',
                dates: 'giorni da confermare',
                transport: 'Treno e cammini',
                stay: 'Vicino alla Ribeira',
                placeLabels: <String>[
                  'Mercado do Bolhão',
                  'Miradouro da Vitória',
                  'Jardins do Palácio de Cristal',
                ],
                days: <TripDaySnapshot>[
                  TripDaySnapshot(
                    label: 'Giorno 1',
                    theme: 'Arrivo senza fretta',
                    items: <TripItemSnapshot>[
                      TripItemSnapshot(
                        title: 'Arrivo e quartiere Ribeira',
                        category: 'Quartiere',
                        time: '15:30',
                        locked: false,
                      ),
                      TripItemSnapshot(
                        title: 'Passeggiata fino alla Foz',
                        category: 'Mare',
                        time: '17:30',
                        locked: false,
                      ),
                    ],
                  ),
                  TripDaySnapshot(
                    label: 'Giorno 2',
                    theme: 'Mercati e cortili',
                    items: <TripItemSnapshot>[
                      TripItemSnapshot(
                        title: 'Mercado do Bolhão',
                        category: 'Cibo',
                        time: '09:30',
                        locked: false,
                      ),
                      TripItemSnapshot(
                        title: 'Miradouro da Vitória',
                        category: 'Panorama',
                        time: '18:00',
                        locked: false,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        ScriptedBeat(
          ChatMessage(
            id: 's3',
            role: ChatRole.assistant,
            kind: ChatMessageKind.tripSummary,
            text: 'Il piano, aggiornato con la tua decisione.',
            sentAt: DateTime(2026, 10, 16, 10, 7),
          ),
        ),
        ScriptedBeat(
          ChatMessage(
            id: 's4',
            role: ChatRole.assistant,
            kind: ChatMessageKind.operational,
            text:
                'Ho salvato il piano come bozza. Potremo aprirlo dall’icona del '
                'piano in questa conversazione quando vuoi.',
            sentAt: DateTime(2026, 10, 16, 10, 8),
          ),
        ),
      ],
    );
  }

  static ChatThread _planningPorto() {
    final journey = MockData.journeyById('porto-slow');
    final thread = planningThreadFor(journey);
    return thread;
  }

  static ChatThread _activeRoma() {
    return ChatThread(
      summary: Conversation(
        id: 'c-roma-active',
        title: 'Roma',
        subtitle: 'In viaggio · oggi',
        avatar: ChatAvatar(
          'assets/images/travel/rome_vespa.jpg',
          label: 'Roma',
        ),
        timestamp: DateTime(2026, 10, 16, 9, 45),
        unread: 2,
        lastPreview: 'Domani mattina ti suggerisco un ritmo più lento.',
        snapshot: TripSnapshot(
          destinationTitle: 'Roma',
          country: 'Italia',
          durationLabel: '3–4 giorni',
          statusLabel: 'In viaggio',
          dates: '14–17 ottobre',
          transport: 'A piedi e metro',
          stay: 'Trastevere',
          placeLabels: <String>[
            'Foro Romano',
            'Palatino',
            'Borghese',
            'Tavola a Campo de’ Fiori',
          ],
          days: <TripDaySnapshot>[
            TripDaySnapshot(
              label: 'Oggi',
              theme: 'Centro storico',
              items: <TripItemSnapshot>[
                TripItemSnapshot(
                  title: 'Foro Romano',
                  category: 'Archeologia',
                  time: '09:30',
                  locked: true,
                ),
                TripItemSnapshot(
                  title: 'Passeggiata ai Fori',
                  category: 'Passeggiata',
                  time: '13:30',
                  locked: false,
                ),
              ],
            ),
            TripDaySnapshot(
              label: 'Domani',
              theme: 'Mattina lenta',
              items: <TripItemSnapshot>[
                TripItemSnapshot(
                  title: 'Parco di Villa Borghese',
                  category: 'Verde',
                  time: '10:00',
                  locked: false,
                ),
                TripItemSnapshot(
                  title: 'Tavola a Campo de’ Fiori',
                  category: 'Cibo',
                  time: '19:00',
                  locked: false,
                ),
              ],
            ),
          ],
        ),
      ),
      openedWith: <ChatMessage>[
        ChatMessage(
          id: 'roma-greet',
          role: ChatRole.assistant,
          kind: ChatMessageKind.text,
          text:
              'Buongiorno! Sei a Roma, oggi hai il Foro al mattino e la serata '
              'libera. Come vuoi gestire la giornata?',
          sentAt: DateTime(2026, 10, 16, 9, 45),
          choices: <ChatChoice>[
            ChatChoice(label: 'Rallenta la mattina'),
            ChatChoice(label: 'Aggiungi un tramonto'),
            ChatChoice(label: 'È tutto giusto così'),
          ],
        ),
      ],
      script: <ScriptedBeat>[
        ScriptedBeat(
          ChatMessage(
            id: 'roma-s1',
            role: ChatRole.assistant,
            kind: ChatMessageKind.planProposal,
            text:
                'Vorrei rendere la mattinata più lenta: un solo sito '
                'archeologico e il resto del tempo libero per una '
                'passeggiata senza fretta.',
            sentAt: DateTime(2026, 10, 16, 9, 48),
            proposal: PlanProposal(
              changeLabel:
                  'Foro Romano alle 10:30, passeggiata ai Fori alle 14:00.',
              snapshot: TripSnapshot(
                destinationTitle: 'Roma',
                country: 'Italia',
                durationLabel: '3–4 giorni',
                statusLabel: 'In viaggio',
                dates: '14–17 ottobre',
                transport: 'A piedi e metro',
                stay: 'Trastevere',
                placeLabels: <String>[
                  'Foro Romano',
                  'Passeggiata ai Fori',
                  'Borghese',
                  'Tavola a Campo de’ Fiori',
                ],
                days: <TripDaySnapshot>[
                  TripDaySnapshot(
                    label: 'Oggi',
                    theme: 'Mattina più lenta',
                    items: <TripItemSnapshot>[
                      TripItemSnapshot(
                        title: 'Foro Romano',
                        category: 'Archeologia',
                        time: '10:30',
                        locked: true,
                      ),
                      TripItemSnapshot(
                        title: 'Passeggiata ai Fori',
                        category: 'Passeggiata',
                        time: '14:00',
                        locked: false,
                      ),
                    ],
                  ),
                  TripDaySnapshot(
                    label: 'Domani',
                    theme: 'Mattina lenta',
                    items: <TripItemSnapshot>[
                      TripItemSnapshot(
                        title: 'Parco di Villa Borghese',
                        category: 'Verde',
                        time: '10:00',
                        locked: false,
                      ),
                      TripItemSnapshot(
                        title: 'Tavola a Campo de’ Fiori',
                        category: 'Cibo',
                        time: '19:00',
                        locked: false,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        ScriptedBeat(
          ChatMessage(
            id: 'roma-s2',
            role: ChatRole.assistant,
            kind: ChatMessageKind.tripSummary,
            text: 'Il piano attuale, aggiornato con le tue indicazioni.',
            sentAt: DateTime(2026, 10, 16, 9, 49),
          ),
        ),
        ScriptedBeat(
          ChatMessage(
            id: 'roma-s3',
            role: ChatRole.assistant,
            kind: ChatMessageKind.audio,
            text: 'Ti lascio un riepilogo vocale del resto della giornata.',
            sentAt: DateTime(2026, 10, 16, 9, 50),
            audioDuration: '0:22',
          ),
        ),
      ],
    );
  }

  static String _countryFor(String id) {
    try {
      return MockData.destinationById(id).country;
    } catch (_) {
      return '';
    }
  }

  static ChatMessage closingReply() => ChatMessage(
    id: 'closing',
    role: ChatRole.assistant,
    kind: ChatMessageKind.text,
    text:
        'Ricevuto. Il piano resta aperto qui: quando vuoi, apri l’icona del '
        'piano per vederlo e continuiamo da lì.',
    sentAt: DateTime(2026, 10, 16, 10, 30),
  );
}
