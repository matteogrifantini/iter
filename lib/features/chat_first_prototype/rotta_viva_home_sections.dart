import 'package:flutter/material.dart';

import '../../app/iter_theme.dart';
import 'chat_first_data.dart';
import 'chat_first_models.dart';
import 'iter_glass_primitives.dart';
import 'iter_ui_primitives.dart';

// NOTE: seed set predates Task 4 (3 signals @9007e49 → 5 destinations) —
// pre-existing drift, preserved as-is by Task 4 (no copy changes).
const rottaVivaSeeds = <({String label, String clue, String semantics})>[
  (
    label: '🌊 Mare e pause',
    clue: 'Mare e pause',
    semantics: 'Segnale: mare e pause',
  ),
  (
    label: '🇵🇹 Lisbona a novembre',
    clue: 'Lisbona a novembre',
    semantics: 'Destinazione: Lisbona a novembre',
  ),
  (
    label: '🍷 Weekend a Porto',
    clue: 'Weekend a Porto',
    semantics: 'Destinazione: Weekend a Porto',
  ),
  (
    label: '🌸 Giappone in primavera',
    clue: 'Giappone in primavera',
    semantics: 'Destinazione: Giappone in primavera',
  ),
  (
    label: '🍝 Città d’arte e buon cibo',
    clue: 'Città d’arte e buon cibo',
    semantics: 'Segnale: città d’arte e buon cibo',
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
    final composerForeground = colors.onSurface;
    final enabled = controller.text.trim().isNotEmpty;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: 'Composer per raccontare il viaggio',
      child: IterGlassBar(
        padding: const EdgeInsets.fromLTRB(14, 6, 8, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // NOTE: hintText/minLines drift predates Task 4 (was minLines: 2 +
            // 'Un momento, una disponibilità, un desiderio…' @9007e49) — kept.
            Semantics(
              label: 'Scrivi il viaggio che hai in mente',
              textField: true,
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                minLines: 1,
                maxLines: 4,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: composerForeground),
                decoration: InputDecoration(
                  labelText: 'Scrivi il viaggio che hai in mente',
                  labelStyle: TextStyle(color: composerForeground),
                  hintText: 'Es. 4 giorni di buon cibo a Lisbona…',
                  hintStyle: TextStyle(
                    color: composerForeground.withValues(alpha: .72),
                  ),
                  filled: false,
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 2),
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
    final pillRadius =
        Theme.of(context).extension<IterGlassRoles>()?.pillRadius ?? 20.0;
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(pillRadius),
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
    if (snapshot == null) {
      final colors = Theme.of(context).colorScheme;
      return Column(
        key: const Key('planning-new-idea'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'La tua idea prende forma',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'La chat è aperta. Ogni risposta sposta il viaggio verso qualcosa '
            'che ti somiglia di più.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          IterMaterialSurface(
            key: const Key('planning-chat-next-step'),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Prossimo passo',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  thread.summary.lastPreview,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () => onOpenThread(thread),
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  label: const Text('Riprendi la chat'),
                ),
              ],
            ),
          ),
        ],
      );
    }
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
        IterMaterialSurface(
          key: const Key('planning-next-choice'),
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
      key: const Key('home-route'),
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
                        Semantics(
                          label: item.locked
                              ? 'Tappa bloccata'
                              : 'Tappa flessibile',
                          child: IterRouteDivider(active: item.locked),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(Icons.notifications_active_outlined, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Nuovo nel piano',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                update,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.tonal(
                  onPressed: () => onOpenThread(thread),
                  child: const Text('Vedi il piano completo'),
                ),
              ),
            ],
          ),
        ] else ...<Widget>[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => onOpenThread(thread),
              child: const Text('Vedi il piano completo'),
            ),
          ),
        ],
      ],
    );
  }
}

class ActiveDestinationStage extends StatelessWidget {
  const ActiveDestinationStage({
    super.key,
    required this.thread,
    required this.onOpenThread,
  });

  final ChatThread thread;
  final ValueChanged<ChatThread> onOpenThread;

  @override
  Widget build(BuildContext context) {
    final snapshot = thread.summary.snapshot;
    if (snapshot == null) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    final image = _destinationImage(snapshot.destinationTitle);
    final stopCount = snapshot.days.isEmpty
        ? 0
        : snapshot.days.first.items.length;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: 'hero: Scena della destinazione ${snapshot.destinationTitle}',
      child: SizedBox(
        key: const Key('home-destination-stage'),
        height: 250,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Image.asset(
              image,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => ColoredBox(
                color: colors.inverseSurface,
                child: const SizedBox.expand(),
              ),
            ),
            const Positioned.fill(
              child: IterHeroScrim(child: SizedBox.expand()),
            ),
            // NOTE (task-4 fix): hero bleeds behind the status bar and the
            // home topbar is overlaid top-left, so the badge sits top-right
            // (topbar row ends with a Spacer) clearing topInset for the notch.
            Positioned(
              right: 18,
              top: MediaQuery.paddingOf(context).top + 8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surface.withValues(alpha: .86),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Text(
                    'In viaggio',
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(color: colors.onSurface),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 18,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          snapshot.destinationTitle,
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(color: colors.onInverseSurface),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Oggi · $stopCount ${stopCount == 1 ? 'tappa' : 'tappe'} · ${snapshot.days.firstOrNull?.theme ?? snapshot.stay}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: colors.onInverseSurface),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filledTonal(
                    tooltip: 'Apri la chat del viaggio',
                    onPressed: () => onOpenThread(thread),
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _destinationImage(String title) {
    final normalized = title.toLowerCase();
    if (normalized.contains('porto')) {
      return 'assets/images/travel/porto_livraria_lello.jpg';
    }
    if (normalized.contains('parigi')) {
      return 'assets/images/travel/paris_eiffel.jpg';
    }
    if (normalized.contains('barcellona')) {
      return 'assets/images/travel/barcelona_square.jpg';
    }
    if (normalized.contains('lisbona')) {
      return 'assets/images/travel/lisbon_street.jpg';
    }
    return 'assets/images/travel/rome_city.jpg';
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
