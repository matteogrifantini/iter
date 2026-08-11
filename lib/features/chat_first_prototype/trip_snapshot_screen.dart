import 'package:flutter/material.dart';

import 'chat_first_controller.dart';
import 'chat_first_data.dart';
import 'chat_first_models.dart';
import 'place_detail_sheet.dart';
import 'place_picker_sheet.dart';
import 'place_reel_screen.dart';
import 'plan_external_launcher.dart';
import 'plan_editor.dart';
import 'plan_patch_sheet.dart';
import 'plan_timeline.dart';

typedef LegacyTripSnapshotControllerFactory =
    ChatFirstPrototypeController Function(TripSnapshot snapshot);

class TripSnapshotScreen extends StatefulWidget {
  factory TripSnapshotScreen({
    Key? key,
    ChatFirstPrototypeController? controller,
    String? conversationId,
    PlanExternalLauncher? externalLauncher,
    @Deprecated('Use controller and conversationId') TripSnapshot? snapshot,
    LegacyTripSnapshotControllerFactory legacyControllerFactory =
        _legacyControllerFor,
  }) {
    assert(
      (controller != null && conversationId != null && snapshot == null) ||
          (controller == null && conversationId == null && snapshot != null),
    );
    return TripSnapshotScreen._(
      key: key,
      controller: controller,
      conversationId: conversationId,
      legacySnapshot: snapshot,
      legacyControllerFactory: legacyControllerFactory,
      externalLauncher: externalLauncher,
    );
  }

  const TripSnapshotScreen._({
    super.key,
    required this.controller,
    required this.conversationId,
    required this.legacySnapshot,
    required this.legacyControllerFactory,
    required this.externalLauncher,
  });

  final ChatFirstPrototypeController? controller;
  final String? conversationId;
  final TripSnapshot? legacySnapshot;
  final LegacyTripSnapshotControllerFactory legacyControllerFactory;
  final PlanExternalLauncher? externalLauncher;

  @override
  State<TripSnapshotScreen> createState() => _TripSnapshotScreenState();
}

class _TripSnapshotScreenState extends State<TripSnapshotScreen> {
  var _selectedDay = 0;
  late ChatFirstPrototypeController _controller;
  late String _conversationId;
  var _ownsController = false;

  @override
  void initState() {
    super.initState();
    _adoptConfiguration();
  }

  @override
  void didUpdateWidget(covariant TripSnapshotScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final legacyChanged =
        widget.legacySnapshot != null &&
        (!identical(widget.legacySnapshot, oldWidget.legacySnapshot) ||
            widget.legacyControllerFactory !=
                oldWidget.legacyControllerFactory);
    final productionChanged =
        widget.legacySnapshot == null &&
        (!identical(widget.controller, oldWidget.controller) ||
            widget.conversationId != oldWidget.conversationId);
    if (!legacyChanged && !productionChanged) return;
    final previousController = _controller;
    final disposedByThisWidget = _ownsController;
    _adoptConfiguration();
    if (disposedByThisWidget) previousController.dispose();
    _selectedDay = 0;
  }

  void _adoptConfiguration() {
    final legacySnapshot = widget.legacySnapshot;
    if (legacySnapshot != null) {
      _controller = widget.legacyControllerFactory(legacySnapshot);
      _conversationId = _legacyConversationId;
      _ownsController = true;
      return;
    }
    _controller = widget.controller!;
    _conversationId = widget.conversationId!;
    _ownsController = false;
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final snapshot = _controller.conversationOf(_conversationId).snapshot;
        if (snapshot == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Piano')),
            body: const Center(child: Text('Piano non disponibile')),
          );
        }
        if (_selectedDay >= snapshot.days.length) _selectedDay = 0;
        final fixture = ChatFirstDemoData.operationalFixtureForSnapshot(
          snapshot,
        );
        final media = snapshot.destinationMedia ?? fixture?.media;
        return Scaffold(
          appBar: AppBar(
            title: Semantics(
              label: 'Piano di ${snapshot.destinationTitle}',
              header: true,
              child: Text(
                snapshot.destinationTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          body: ListView(
            key: const Key('plan-scroll'),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: <Widget>[
              _DestinationHero(snapshot: snapshot, media: media),
              const SizedBox(height: 24),
              _PlanFacts(snapshot: snapshot),
              if (snapshot.days.isNotEmpty) ...<Widget>[
                const SizedBox(height: 24),
                _DayChips(
                  days: snapshot.days,
                  selectedIndex: _selectedDay,
                  onSelected: (index) => setState(() => _selectedDay = index),
                ),
                const SizedBox(height: 22),
                PlanTimeline(
                  day: snapshot.days[_selectedDay],
                  mediaForItem: (item) =>
                      _cataloguePlaceFor(fixture, item)?.media,
                  canOpenPlace: (item) =>
                      _cataloguePlaceFor(fixture, item) != null ||
                      item.place != null,
                  onOpenPlace: (item, index) => _openPlace(
                    snapshot: snapshot,
                    fixture: fixture,
                    day: snapshot.days[_selectedDay],
                    item: item,
                    index: index,
                  ),
                  onMovePreview: (itemId, targetDayId, targetIndex) =>
                      _previewMove(
                        itemId: itemId,
                        targetDayId: targetDayId,
                        targetIndex: targetIndex,
                      ),
                  onAction: (item, action) => _handleTimelineAction(
                    snapshot: snapshot,
                    item: item,
                    action: action,
                  ),
                ),
              ] else ...<Widget>[
                const SizedBox(height: 28),
                const _UnplacedSection(items: <TripItemSnapshot>[]),
              ],
              if (snapshot.unplacedItems.isNotEmpty) ...<Widget>[
                const SizedBox(height: 28),
                _UnplacedSection(items: snapshot.unplacedItems),
              ],
              if (_ownsController) ...<Widget>[
                if (snapshot.placeLabels.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      for (final label in snapshot.placeLabels)
                        Chip(label: Text(label)),
                    ],
                  ),
                ],
                const SizedBox(height: 18),
                Text(
                  'Modifiche solo tramite chat nella precedente anteprima.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
          bottomNavigationBar: _GlobalPlanActions(
            onAdd: () => _openPlacePicker(snapshot: snapshot, fixture: fixture),
            onAsk: () => Navigator.of(context).maybePop(),
            onCosts: () => _showPlannedAction(
              'Riepilogo costi disponibile nel prossimo passaggio.',
            ),
          ),
        );
      },
    );
  }

  Future<void> _openPlace({
    required TripSnapshot snapshot,
    required OperationalTripFixture? fixture,
    required TripDaySnapshot day,
    required TripItemSnapshot item,
    required int index,
  }) async {
    final cataloguePlace = _cataloguePlaceFor(fixture, item);
    final media = cataloguePlace?.media;
    final place =
        item.place ??
        (cataloguePlace == null
            ? null
            : PlanPlaceDetails(
                id: cataloguePlace.id,
                title: cataloguePlace.name,
                description: cataloguePlace.description,
              ));
    if (place == null) return;
    final directionsUri = cataloguePlace == null
        ? null
        : GoogleMapsDirectionsUri.build(
            latitude: cataloguePlace.latitude,
            longitude: cataloguePlace.longitude,
          );
    final sheetData = PlanPlaceSheetData(
      place: place,
      category: item.category,
      neighborhood: 'Centro di ${snapshot.destinationTitle}',
      durationLabel: _durationLabel(item.durationMinutes),
      costLabel: 'Ingresso da verificare',
      bestMomentLabel: item.startTime.isEmpty
          ? 'Momento da definire'
          : 'Verso le ${item.startTime}',
      whyIterRecommends:
          'Si inserisce nel ritmo “${day.theme}” senza spezzare la sequenza della giornata.',
      positionLabel: 'Tappa ${index + 1} di ${day.items.length} · ${day.label}',
      distanceLabel: index == 0
          ? 'Prima tappa della giornata'
          : 'Distanza demo dalla tappa precedente da verificare',
      entranceLabel: 'Ingresso e orari da verificare prima della visita',
      accessibilityLabel: 'Accessibilità da verificare con il luogo',
      media: media,
      directionsAvailable: directionsUri != null,
    );
    final action = await showPlanPlaceDetailSheet(
      context: context,
      data: sheetData,
      onOpenReel: () {
        if (media == null) return;
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                PlaceReelScreen(placeTitle: place.title, media: media),
          ),
        );
      },
      onOpenDirections: () => _openDirections(directionsUri),
    );
    if (!mounted || action != PlaceDetailAction.askIter) return;
    _controller.setPlaceComposerContext(_conversationId, place);
    Navigator.of(context).pop();
  }

  Future<void> _openPlacePicker({
    required TripSnapshot snapshot,
    required OperationalTripFixture? fixture,
  }) async {
    if (fixture == null) {
      _showPlannedAction('Catalogo luoghi non disponibile per questo piano.');
      return;
    }
    final selection = await showPlacePickerSheet(
      context: context,
      fixture: fixture,
      snapshot: snapshot,
    );
    if (!mounted || selection == null) return;
    final place = selection.place;
    final preview = _controller.previewAddPlace(
      conversationId: _conversationId,
      item: TripItemSnapshot(
        id: '${place.id}-manual-stop',
        title: place.name,
        category: place.category,
        durationMinutes: 60,
        source: PlanItemSource.manual,
        place: PlanPlaceDetails(
          id: place.id,
          title: place.name,
          description: place.description,
        ),
        locked: false,
      ),
      targetDayId: selection.targetDayId,
      targetIndex: selection.targetIndex,
    );
    await _showPatch(preview);
  }

  Future<void> _previewMove({
    required String itemId,
    required String targetDayId,
    required int targetIndex,
  }) async {
    final preview = _controller.previewMoveStop(
      conversationId: _conversationId,
      itemId: itemId,
      targetDayId: targetDayId,
      targetIndex: targetIndex,
    );
    await _showPatch(preview);
  }

  Future<void> _handleTimelineAction({
    required TripSnapshot snapshot,
    required TripItemSnapshot item,
    required PlanTimelineAction action,
  }) async {
    switch (action) {
      case PlanTimelineAction.move:
        final selection = await showPlanMoveSheet(
          context: context,
          snapshot: snapshot,
          itemId: item.id,
        );
        if (!mounted || selection == null) return;
        await _previewMove(
          itemId: item.id,
          targetDayId: selection.targetDayId,
          targetIndex: selection.targetIndex,
        );
        return;
      case PlanTimelineAction.changeTime:
        final initial =
            _parseTime(item.startTime) ?? const TimeOfDay(hour: 9, minute: 0);
        final selected = await showTimePicker(
          context: context,
          initialTime: initial,
          helpText: 'Cambia orario',
          cancelText: 'Annulla',
          confirmText: 'OK',
        );
        if (!mounted || selected == null) return;
        final preview = _controller.previewChangeTime(
          conversationId: _conversationId,
          itemId: item.id,
          startTime:
              '${selected.hour.toString().padLeft(2, '0')}:${selected.minute.toString().padLeft(2, '0')}',
        );
        await _showPatch(preview);
        return;
      case PlanTimelineAction.toggleLock:
        final preview = _controller.previewToggleLock(
          conversationId: _conversationId,
          itemId: item.id,
        );
        await _showPatch(preview);
        return;
      case PlanTimelineAction.remove:
        final preview = _controller.previewRemoveStop(
          conversationId: _conversationId,
          itemId: item.id,
        );
        await _showPatch(preview);
        return;
    }
  }

  Future<void> _showPatch(PlanPatchPreview preview) async {
    final applied = await showPlanPatchSheet(
      context: context,
      preview: preview,
      onApply: () => _controller.confirmPlanPatch(_conversationId),
      onCancel: () => _controller.cancelPlanPatch(_conversationId),
    );
    if (!mounted || !applied) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Modifica applicata'),
          action: SnackBarAction(
            label: 'Annulla',
            onPressed: () => _controller.undoLastPlanRevision(_conversationId),
          ),
        ),
      );
  }

  Future<void> _openDirections(Uri? uri) async {
    final opened = await (widget.externalLauncher ?? PlanExternalLauncher())
        .open(uri);
    if (!mounted || opened) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Non riesco ad aprire le indicazioni. Riprova.'),
      ),
    );
  }

  void _showPlannedAction(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _DestinationHero extends StatelessWidget {
  const _DestinationHero({required this.snapshot, required this.media});

  final TripSnapshot snapshot;
  final PlanMedia? media;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final image = media?.imageUrl;
    return Semantics(
      image: true,
      label: 'Foto di ${snapshot.destinationTitle}',
      child: AspectRatio(
        key: const Key('plan-destination-hero'),
        aspectRatio: 16 / 9,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              if (image == null || image.isEmpty)
                _HeroFallback(destination: snapshot.destinationTitle)
              else
                ExcludeSemantics(
                  child: Image.asset(
                    image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        _HeroFallback(destination: snapshot.destinationTitle),
                  ),
                ),
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Material(
                    color: colors.inverseSurface.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            '${snapshot.country} · ${snapshot.durationLabel}',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: colors.onInverseSurface,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            snapshot.dates,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: colors.onInverseSurface.withValues(
                                    alpha: 0.82,
                                  ),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroFallback extends StatelessWidget {
  const _HeroFallback({required this.destination});

  final String destination;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colors.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.landscape_outlined,
          semanticLabel: 'Immagine non disponibile per $destination',
          size: 48,
          color: colors.primary,
        ),
      ),
    );
  }
}

class _PlanFacts extends StatelessWidget {
  const _PlanFacts({required this.snapshot});

  final TripSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          <Widget>[
                _Fact(label: snapshot.statusLabel, icon: Icons.route_outlined),
                _Fact(
                  label: snapshot.transport,
                  icon: Icons.flight_takeoff_outlined,
                ),
                _Fact(label: snapshot.stay, icon: Icons.bed_outlined),
              ]
              .map((fact) {
                return DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: fact,
                );
              })
              .toList(growable: false),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 18),
          const SizedBox(width: 7),
          Flexible(child: Text(label)),
        ],
      ),
    );
  }
}

class _DayChips extends StatelessWidget {
  const _DayChips({
    required this.days,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<TripDaySnapshot> days;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) => ChoiceChip(
          selected: index == selectedIndex,
          onSelected: (_) => onSelected(index),
          label: Text(days[index].label),
        ),
      ),
    );
  }
}

class _UnplacedSection extends StatelessWidget {
  const _UnplacedSection({required this.items});

  final List<TripItemSnapshot> items;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text('Da sistemare', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          if (items.isEmpty)
            Text(
              'Qui compariranno le tappe ancora senza giorno o orario.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            )
          else
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('• ${item.title}'),
              ),
        ],
      ),
    );
  }
}

class _GlobalPlanActions extends StatelessWidget {
  const _GlobalPlanActions({
    required this.onAdd,
    required this.onAsk,
    required this.onCosts,
  });

  final VoidCallback onAdd;
  final VoidCallback onAsk;
  final VoidCallback onCosts;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Material(
        elevation: 3,
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          key: const Key('plan-global-actions'),
          height: 64,
          child: Row(
            children: <Widget>[
              Expanded(
                child: _PlanAction(
                  icon: Icons.add_location_alt_outlined,
                  label: 'Aggiungi luogo',
                  onTap: onAdd,
                ),
              ),
              Expanded(
                child: _PlanAction(
                  icon: Icons.chat_outlined,
                  label: 'Chiedi',
                  onTap: onAsk,
                ),
              ),
              Expanded(
                child: _PlanAction(
                  icon: Icons.receipt_long_outlined,
                  label: 'Costi',
                  onTap: onCosts,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanAction extends StatelessWidget {
  const _PlanAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(icon, size: 22, color: colors.primary),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _durationLabel(int minutes) {
  if (minutes <= 0) return 'Durata da definire';
  final hours = minutes ~/ 60;
  final remaining = minutes % 60;
  if (hours == 0) return '$remaining min';
  if (remaining == 0) return '$hours h';
  return '$hours h $remaining min';
}

OperationalPlaceFixture? _cataloguePlaceFor(
  OperationalTripFixture? fixture,
  TripItemSnapshot item,
) {
  final placeId = item.place?.id;
  final itemTitle = item.title.trim().toLowerCase();
  for (final candidate
      in fixture?.placeCatalog ?? const <OperationalPlaceFixture>[]) {
    if (placeId != null && candidate.id == placeId) return candidate;
    final candidateName = candidate.name.toLowerCase();
    if (candidateName == itemTitle ||
        (candidateName.length > 5 && itemTitle.contains(candidateName))) {
      return candidate;
    }
  }
  return null;
}

TimeOfDay? _parseTime(String value) {
  final match = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(value);
  if (match == null) return null;
  final hour = int.tryParse(match.group(1)!);
  final minute = int.tryParse(match.group(2)!);
  if (hour == null || minute == null || hour > 23 || minute > 59) return null;
  return TimeOfDay(hour: hour, minute: minute);
}

const _legacyConversationId = 'legacy-plan-preview';

ChatFirstPrototypeController _legacyControllerFor(TripSnapshot snapshot) {
  return ChatFirstPrototypeController(
    seed: <ChatThread>[
      ChatThread(
        summary: Conversation(
          id: _legacyConversationId,
          title: snapshot.destinationTitle,
          subtitle: snapshot.statusLabel,
          avatar: const ChatAvatar('', label: 'Piano'),
          timestamp: DateTime.fromMillisecondsSinceEpoch(0),
          lastPreview: 'Anteprima Piano',
          snapshot: snapshot,
        ),
        script: const <ScriptedBeat>[],
      ),
    ],
  );
}
