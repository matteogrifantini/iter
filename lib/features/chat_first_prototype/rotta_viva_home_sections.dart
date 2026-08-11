import 'package:flutter/material.dart';

import 'chat_first_data.dart';
import 'chat_first_models.dart';

const rottaVivaSeeds = <({String label, String clue, String semantics})>[
  (
    label: '🌊 Mare e pause',
    clue: 'Mare e pause',
    semantics: 'Segnale: mare e pause',
  ),
  (
    label: '🚆 Partire in treno',
    clue: 'Partire in treno',
    semantics: 'Segnale: partire in treno',
  ),
  (
    label: '🍝 Mangiare bene',
    clue: 'Mangiare bene',
    semantics: 'Segnale: mangiare bene',
  ),
];

class RottaVivaComposer extends StatelessWidget {
  const RottaVivaComposer({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onSubmit,
    required this.onVoice,
    required this.onPhoto,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;
  final VoidCallback onVoice;
  final VoidCallback onPhoto;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = colors.brightness == Brightness.dark;
    final composerBackground = isDark ? colors.surface : colors.inverseSurface;
    final composerForeground = isDark
        ? colors.onSurface
        : colors.onInverseSurface;
    final enabled = controller.text.trim().isNotEmpty;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: 'Composer per raccontare il viaggio',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: composerBackground,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Semantics(
                label: 'Scrivi il viaggio che hai in mente',
                textField: true,
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  minLines: 2,
                  maxLines: 5,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: composerForeground),
                  decoration: InputDecoration(
                    labelText: 'Scrivi il viaggio che hai in mente',
                    labelStyle: TextStyle(color: composerForeground),
                    hintText: 'Un momento, una disponibilità, un desiderio…',
                    hintStyle: TextStyle(
                      color: composerForeground.withValues(alpha: .72),
                    ),
                    filled: false,
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: <Widget>[
                  Semantics(
                    label: 'Aggiungi una foto',
                    button: true,
                    child: IconButton(
                      tooltip: 'Aggiungi una foto',
                      onPressed: onPhoto,
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      color: composerForeground,
                    ),
                  ),
                  Semantics(
                    label: 'Invia un messaggio vocale',
                    button: true,
                    child: IconButton(
                      tooltip: 'Invia un messaggio vocale',
                      onPressed: onVoice,
                      icon: const Icon(Icons.mic_none_rounded),
                      color: composerForeground,
                    ),
                  ),
                  const Spacer(),
                  IconButton.filled(
                    tooltip: 'Invia il desiderio',
                    onPressed: enabled ? onSubmit : null,
                    icon: const Icon(Icons.arrow_upward_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RottaVivaSeedRow extends StatelessWidget {
  const RottaVivaSeedRow({
    super.key,
    required this.selectedClues,
    required this.onToggle,
  });

  final Set<String> selectedClues;
  final ValueChanged<({String label, String clue, String semantics})> onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: rottaVivaSeeds
          .map((seed) {
            final selected = selectedClues.contains(seed.clue);
            return Semantics(
              container: true,
              explicitChildNodes: true,
              label: seed.semantics,
              selected: selected,
              button: true,
              onTap: () => onToggle(seed),
              child: ExcludeSemantics(
                child: ActionChip(
                  avatar: const SizedBox.shrink(),
                  label: Semantics(
                    label: seed.semantics,
                    child: Text(seed.label),
                  ),
                  onPressed: () => onToggle(seed),
                  backgroundColor: selected
                      ? Theme.of(context).colorScheme.tertiary
                      : Theme.of(context).colorScheme.surfaceContainer,
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              ),
            );
          })
          .toList(growable: false),
    );
  }
}

class AdaptivePlanningSection extends StatelessWidget {
  const AdaptivePlanningSection({
    super.key,
    required this.thread,
    required this.onOpenThread,
    this.onStartAnotherJourney,
  });

  final ChatThread thread;
  final ValueChanged<ChatThread> onOpenThread;
  final Future<void> Function()? onStartAnotherJourney;

  @override
  Widget build(BuildContext context) {
    final snapshot = thread.summary.snapshot;
    if (snapshot == null) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    final signals = <String>[
      snapshot.dates,
      snapshot.durationLabel,
      snapshot.stay,
    ].where((signal) => signal.isNotEmpty).toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'La tua rotta prende forma',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          '${snapshot.destinationTitle} è già nel piano. Chiudiamo una scelta alla volta.',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        Card(
          color: colors.surfaceContainerLow,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colors.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Prossima scelta',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Decidiamo il ritmo del viaggio',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Iter ha abbastanza contesto per proporti il passo giusto.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => onOpenThread(thread),
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Continua il viaggio'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onStartAnotherJourney == null
                      ? null
                      : () => onStartAnotherJourney!(),
                  child: const Text('Inizia un altro viaggio'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('Cosa ho capito', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: signals
              .map((signal) => Chip(label: Text(signal)))
              .toList(growable: false),
        ),
      ],
    );
  }
}

class ActiveTimelineSection extends StatelessWidget {
  const ActiveTimelineSection({
    super.key,
    required this.thread,
    required this.onOpenThread,
  });

  final ChatThread thread;
  final ValueChanged<ChatThread> onOpenThread;

  @override
  Widget build(BuildContext context) {
    final snapshot = thread.summary.snapshot;
    if (snapshot == null || snapshot.days.isEmpty) {
      return const SizedBox.shrink();
    }
    final day = snapshot.days.first;
    final colors = Theme.of(context).colorScheme;
    String? update;
    for (final message in thread.messages.reversed) {
      if (message.text.isNotEmpty &&
          (message.kind == ChatMessageKind.operational ||
              (message.kind == ChatMessageKind.planProposal &&
                  message.proposal?.outcome == null))) {
        update = message.text;
        break;
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '${snapshot.destinationTitle} · ${day.label}',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          day.theme,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        Semantics(
          container: true,
          explicitChildNodes: true,
          label: 'Timeline di oggi, ${day.items.length} tappe',
          child: Column(
            children: day.items
                .map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        SizedBox(
                          width: 54,
                          child: Text(
                            item.time,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Icon(
                            item.locked
                                ? Icons.lock_rounded
                                : Icons.location_on_outlined,
                            semanticLabel: item.locked
                                ? 'Tappa bloccata'
                                : 'Tappa flessibile',
                            color: item.locked
                                ? colors.primary
                                : colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                item.title,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                '${item.category}${item.locked ? ' · bloccata' : ''}',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: colors.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                })
                .toList(growable: false),
          ),
        ),
        if (update != null) ...<Widget>[
          const SizedBox(height: 4),
          Card(
            color: colors.secondaryContainer,
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Icon(Icons.notifications_active_outlined),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Aggiornamento da confermare',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(update, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 16),
                  FilledButton.tonal(
                    onPressed: () => onOpenThread(thread),
                    child: const Text('Apri il piano di oggi'),
                  ),
                ],
              ),
            ),
          ),
        ] else ...<Widget>[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => onOpenThread(thread),
              child: const Text('Apri il piano di oggi'),
            ),
          ),
        ],
      ],
    );
  }
}

Future<void> showDemoPhotoPicker(
  BuildContext context, {
  required ValueChanged<String> onSelected,
}) {
  const photos = <({String label, String path})>[
    (label: 'Roma al mattino', path: 'assets/images/travel/rome_city.jpg'),
    (
      label: 'Finestrino sul mare',
      path: 'assets/images/travel/rail_window.jpg',
    ),
    (label: 'Porto sul fiume', path: 'assets/images/travel/porto_river.jpg'),
  ];
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
            child: Text(
              'Scegli una foto demo',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          for (final photo in photos)
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: Text(photo.label),
              onTap: () {
                Navigator.of(sheetContext).pop();
                onSelected(photo.path);
              },
            ),
        ],
      ),
    ),
  );
}
