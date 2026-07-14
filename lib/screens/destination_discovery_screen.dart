import 'package:flutter/material.dart';

import '../app/iter_theme.dart';
import '../models/trip_models.dart';
import '../widgets/ai_composer.dart';
import '../widgets/journey_media.dart';

class DestinationDiscoveryScreen extends StatefulWidget {
  const DestinationDiscoveryScreen({
    super.key,
    required this.journeys,
    required this.initialAnswers,
    required this.onAnswer,
    required this.onChatAnswer,
    required this.onChooseJourney,
  });

  final List<JourneyRoute> journeys;
  final Map<String, String> initialAnswers;
  final void Function(String key, String value) onAnswer;
  final void Function(String key, String value) onChatAnswer;
  final ValueChanged<JourneyRoute> onChooseJourney;

  @override
  State<DestinationDiscoveryScreen> createState() =>
      _DestinationDiscoveryScreenState();
}

class _DestinationDiscoveryScreenState
    extends State<DestinationDiscoveryScreen> {
  static const _questions = <_DiscoveryQuestion>[
    _DiscoveryQuestion(
      keyName: 'return_feeling',
      prompt: 'Come vuoi sentirti al ritorno?',
      support: 'Partiamo dall’effetto che vuoi portarti a casa.',
      options: <String>[
        'Rigenerato',
        'Ispirato',
        'Più vicino a qualcuno',
        'Pieno di energia',
      ],
    ),
    _DiscoveryQuestion(
      keyName: 'time',
      prompt: 'Quanto spazio hai?',
      support: 'Non servono ancora date precise.',
      options: <String>[
        'Un weekend',
        'Quattro o cinque giorni',
        'Una settimana',
        'Non lo so ancora',
      ],
    ),
    _DiscoveryQuestion(
      keyName: 'rhythm',
      prompt: 'Che ritmo ti somiglia?',
      support: 'Puoi cambiare idea più avanti.',
      options: <String>[
        'Una base, senza corse',
        'Spostarmi in treno',
        'Strade e borghi',
        'Mare e pause',
      ],
    ),
    _DiscoveryQuestion(
      keyName: 'company',
      prompt: 'Con chi parti?',
      support: 'Serve a dare spazio alle persone, non a compilare un profilo.',
      options: <String>['Da solo', 'In coppia', 'Con amici', 'In famiglia'],
    ),
    _DiscoveryQuestion(
      keyName: 'openness',
      prompt: 'Quanto vuoi lasciare al caso?',
      support: 'Iter costruirà un filo, non una gabbia.',
      options: <String>[
        'Quasi tutto',
        'Un equilibrio',
        'Preferisco un filo chiaro',
      ],
    ),
  ];

  late final Map<String, String> _answers;
  var _step = 0;
  String? _lastChatNote;

  bool get _isComplete => _step >= _questions.length;

  @override
  void initState() {
    super.initState();
    _answers = <String, String>{...widget.initialAnswers};
    _step = _questions.indexWhere(
      (question) => !_answers.containsKey(question.keyName),
    );
    if (_step < 0) _step = _questions.length;
  }

  void _select(String value) {
    final question = _questions[_step];
    setState(() => _answers[question.keyName] = value);
    widget.onAnswer(question.keyName, value);
    _advance();
  }

  void _sendChat(String value) {
    final key = _isComplete ? 'refinement' : _questions[_step].keyName;
    setState(() {
      _answers[key] = value;
      _lastChatNote = value;
    });
    widget.onChatAnswer(key, value);
    if (!_isComplete) _advance();
  }

  Future<void> _advance() async {
    final reducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (!reducedMotion) {
      await Future<void>.delayed(const Duration(milliseconds: 160));
    }
    if (mounted) setState(() => _step += 1);
  }

  void _goBack() {
    if (_step == 0) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() => _step -= 1);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final progress = (_step / _questions.length).clamp(0, 1).toDouble();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: _step == 0 ? 'Chiudi' : 'Domanda precedente',
          onPressed: _goBack,
          icon: Icon(_step == 0 ? Icons.close : Icons.arrow_back),
        ),
        title: const Text('Nuovo viaggio'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                _isComplete
                    ? 'Proposte'
                    : '${_step + 1} di ${_questions.length}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 46,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 18, 4, 18),
                      child: JourneyRouteLine(progress: progress),
                    ),
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 240),
                      switchInCurve: const Cubic(0.16, 1, 0.3, 1),
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) {
                        final reducedMotion = MediaQuery.of(
                          context,
                        ).disableAnimations;
                        if (reducedMotion) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        }
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(.08, 0),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: _isComplete
                          ? _JourneyResults(
                              key: const ValueKey('journey-results'),
                              journeys: widget.journeys,
                              onChoose: widget.onChooseJourney,
                            )
                          : _QuestionStep(
                              key: ValueKey(_questions[_step].keyName),
                              question: _questions[_step],
                              selected: _answers[_questions[_step].keyName],
                              onSelect: _select,
                            ),
                    ),
                  ),
                ],
              ),
            ),
            if (_lastChatNote != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      'Iter ha tenuto questa nota: “$_lastChatNote”',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: PersistentAiComposer(
                onSend: _sendChat,
                hint: _isComplete
                    ? 'Chiedi un’alternativa'
                    : 'Rispondi liberamente a Iter',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionStep extends StatelessWidget {
  const _QuestionStep({
    super.key,
    required this.question,
    required this.selected,
    required this.onSelect,
  });

  final _DiscoveryQuestion question;
  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(8, 28, 20, 24),
      children: [
        Text(question.prompt, style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 10),
        Text(
          question.support,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 34),
        Material(
          color: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: colors.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var index = 0; index < question.options.length; index++) ...[
                _AnswerRow(
                  label: question.options[index],
                  selected: selected == question.options[index],
                  onTap: () => onSelect(question.options[index]),
                ),
                if (index != question.options.length - 1)
                  Divider(height: 1, indent: 16, endIndent: 16),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _AnswerRow extends StatelessWidget {
  const _AnswerRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 62),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                ExcludeSemantics(
                  child: AnimatedSwitcher(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 140),
                    child: selected
                        ? Icon(
                            Icons.check_circle,
                            key: const ValueKey('selected'),
                            color: colors.primary,
                          )
                        : Icon(
                            Icons.arrow_forward,
                            key: const ValueKey('unselected'),
                            color: colors.onSurfaceVariant,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _JourneyResults extends StatefulWidget {
  const _JourneyResults({
    super.key,
    required this.journeys,
    required this.onChoose,
  });

  final List<JourneyRoute> journeys;
  final ValueChanged<JourneyRoute> onChoose;

  @override
  State<_JourneyResults> createState() => _JourneyResultsState();
}

class _JourneyResultsState extends State<_JourneyResults> {
  var _page = 0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 18, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tre viaggi, non tre città.',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'Scorri: ogni percorso nasce dalle risposte che hai dato.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: PageView.builder(
            onPageChanged: (value) => setState(() => _page = value),
            controller: PageController(viewportFraction: .92),
            itemCount: widget.journeys.length,
            itemBuilder: (context, index) {
              final journey = widget.journeys[index];
              return Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 12, 10),
                child: _JourneyResultCard(
                  journey: journey,
                  active: index == _page,
                  onChoose: () => widget.onChoose(journey),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _JourneyResultCard extends StatelessWidget {
  const _JourneyResultCard({
    required this.journey,
    required this.active,
    required this.onChoose,
  });

  final JourneyRoute journey;
  final bool active;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 520;
        return Material(
          color: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: colors.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: compact ? 4 : 5,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    JourneyVideo(
                      asset: journey.videoAsset,
                      autoplay: active,
                      borderRadius: BorderRadius.zero,
                    ),
                    Positioned(
                      left: 12,
                      bottom: 12,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: context.iterColors.videoScrim,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          child: Text(
                            '${journey.durationLabel} · ${journey.travelMode}',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: compact ? 6 : 6,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        journey.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        journey.stops.join('  →  '),
                        maxLines: compact ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      if (!compact) ...[
                        Text(
                          journey.whyItFits,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: onChoose,
                          child: const Text('Parti da questo viaggio'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DiscoveryQuestion {
  const _DiscoveryQuestion({
    required this.keyName,
    required this.prompt,
    required this.support,
    required this.options,
  });

  final String keyName;
  final String prompt;
  final String support;
  final List<String> options;
}
