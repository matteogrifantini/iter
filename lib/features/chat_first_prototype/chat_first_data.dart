import '../../data/mock_data.dart';
import '../../models/trip_models.dart' show JourneyRoute, Place;
import '../../widgets/journey_media.dart';
import 'chat_first_models.dart';

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
}

/// A planning thread driven by guided questions: each answer advances to the
/// next question and the final proposal is assembled from the recorded answers
/// instead of being baked into the script. Still fully deterministic: for the
/// same answers it always produces the same [PlanProposal].
class IntakeThread extends ChatThread {
  IntakeThread({
    required this.journey,
    required super.summary,
    required super.script,
    super.openedWith,
  });

  /// The journey the traveler started from; drives the final proposal content.
  final JourneyRoute journey;

  /// Answers keyed by the question message id (e.g. 'q-duration').
  final Map<String, String> answers = <String, String>{};

  /// Records the answer whenever a traveler text follows a question with
  /// choices, keyed by that question id. Typed replies are captured too, so a
  /// free-text answer still advances the intake.
  @override
  ChatMessage travelerMessage(String text) {
    final message = super.travelerMessage(text);
    if (messages.length >= 2) {
      final question = messages[messages.length - 2];
      if (question.role == ChatRole.assistant && question.choices.isNotEmpty) {
        answers[question.id] = text;
      }
    }
    return message;
  }

  /// Emits every beat keeping the script's stable id, so answers can be
  /// matched back to their question, and builds the final proposal from
  /// [answers] when the script reaches the proposal beat.
  @override
  bool advance() {
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
            ? beat.assistant.proposal ?? buildFinalProposal()
            : beat.assistant.proposal,
      ),
    );
    scriptIndex++;
    return true;
  }

  /// The concrete plan built from [answers], tied to the journey destination.
  /// Missing or unexpected answers fall back to the balanced defaults.
  PlanProposal buildFinalProposal() {
    final destinationId = journey.destinationIds.first;
    final city = journeyCity(journey);
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
      'Quartiere vissuto, più locale' => 'Quartiere vissuto, fuori dal classico',
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
    final placeLabels =
        places.take(3).map((place) => place.name).toList(growable: false);
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

/// Deterministic demo content for the chat-first prototype.
abstract final class ChatFirstDemoData {
  static List<ChatThread> seedThreads() => List<ChatThread>.of(
        <ChatThread>[_planningPorto(), _activeRoma()],
        growable: true,
      );

  /// Trend destinations shown on the Home. Each gets an editorial city sheet
  /// and an "Organizza un viaggio" entry that opens a fresh planning thread.
  static List<JourneyRoute> trendJourneys() => MockData.journeys.take(4).toList();

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
      script: <ScriptedBeat>[
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
                'Ecco la prima proposta per $city, costruita sulle tue risposte.',
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
      ],
    );
  }

  /// The best-matching stay zone name for a destination, or a generic label
  /// when the catalog has none. Used for the "Consigliami tu" answer.
  static String preferredStayFor(String destinationId) {
    final zones = MockData.stayZones
        .where((zone) => zone.destinationId == destinationId)
        .toList(growable: false)
      ..sort((a, b) => a.averageWalkMinutes.compareTo(b.averageWalkMinutes));
    return zones.isEmpty ? 'In un quartiere vissuto' : zones.first.name;
  }

  /// The highest-scoring places of a destination, used to shape the proposal.
  static List<Place> topPlacesFor(String destinationId, {required int take}) {
    final places = MockData.places
        .where((place) => place.destinationId == destinationId)
        .toList(growable: false)
      ..sort((a, b) => b.matchScore.compareTo(a.matchScore));
    return places.take(take).toList(growable: false);
  }

  /// Chunks [places] into daily itineraries of at most [itemsPerDay] items,
  /// with deterministic times and light themes.
  static List<TripDaySnapshot> intakeDays(
    List<Place> places, {
    required int itemsPerDay,
  }) {
    const themes = <String>[
      'Arrivo senza fretta',
      'Quartieri e pause',
      'Ultimo giro con calma',
      'Chiusura lenta',
    ];
    const times = <String>['09:30', '13:00', '16:30', '19:30'];
    final days = <TripDaySnapshot>[];
    for (var day = 0;
        day * itemsPerDay < places.length && day < themes.length;
        day++) {
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
                locked: false,
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
          posters.isNotEmpty ? posters.first : 'assets/images/travel/rail_coast.jpg',
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
              changeLabel: 'Bozza: Porto 4–5 giorni, base vicino alla Ribeira, tre tappe.',
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
                days: const <TripDaySnapshot>[
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
              changeLabel: 'Foro Romano alle 10:30, passeggiata ai Fori alle 14:00.',
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