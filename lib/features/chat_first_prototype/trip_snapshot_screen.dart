import 'package:flutter/material.dart';

import 'package:iter/app/iter_theme.dart';

import 'chat_first_controller.dart';
import 'chat_first_data.dart';
import 'chat_first_models.dart';
import 'inspiration_import_sheet.dart';
import 'inspiration_models.dart';
import 'iter_glass_primitives.dart';
import 'iter_ui_primitives.dart';
import 'place_detail_sheet.dart';
import 'place_picker_sheet.dart';
import 'place_reel_screen.dart';
import 'plan_cost_sheet.dart';
import 'plan_exporter.dart';
import 'plan_external_launcher.dart';
import 'plan_editor.dart';
import 'plan_patch_sheet.dart';
import 'plan_timeline.dart';
import '../checklist/trip_checklist_screen.dart';
import '../expenses/trip_expense_sheet.dart';
import '../flights/flight_search_sheet.dart';
import '../food/food_guide_sheet.dart';
import '../map/trip_map_sheet.dart';
import '../places/real_place_sheet.dart';
import '../stays/stay_search_sheet.dart';
import '../translator/translator_sheet.dart';
import '../weather/weather_badge_widget.dart';
import '../weather/weather_models.dart';
import '../weather/weather_service.dart';

const double _globalPlanActionsBottomSpacing = 8;
const double _planContentBottomSpacing = 32;

enum _PlanOverflowAction {
  shareText,
  exportIcs,
  importInspiration,
  searchFlights,
  searchStays,
  foodGuide,
  translator,
  viewMap,
  viewWeather,
  packingChecklist,
  expenseBudget,
}

class TripSnapshotScreen extends StatefulWidget {
  const TripSnapshotScreen({
    super.key,
    required this.controller,
    required this.conversationId,
    this.initialSnapshot,
    this.externalLauncher,
  });

  final ChatFirstPrototypeController controller;
  final String conversationId;
  final TripSnapshot? initialSnapshot;
  final PlanExternalLauncher? externalLauncher;

  @override
  State<TripSnapshotScreen> createState() => _TripSnapshotScreenState();
}


class _TripSnapshotScreenState extends State<TripSnapshotScreen> {
  var _selectedDay = 0;
  String? _draggedItemId;
  late ChatFirstPrototypeController _controller;
  late String _conversationId;
  final _weatherService = WeatherService();

  void _openFlightSearch(TripSnapshot snapshot) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FlightSearchSheet(
        destination: snapshot.destinationTitle,
        onFlightSelected: (flight) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Volo ${flight.flightNumber} (${flight.airlineName}) selezionato!',
              ),
            ),
          );
        },
      ),
    );
  }

  void _openStays(TripSnapshot snapshot) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StaySearchSheet(
        destination: snapshot.destinationTitle,
        onStaySelected: (stay) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${stay.name} selezionato per il soggiorno!'),
            ),
          );
        },
      ),
    );
  }

  void _openFoodGuide(TripSnapshot snapshot) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FoodGuideSheet(destination: snapshot.destinationTitle),
    );
  }

  void _openTranslator(TripSnapshot snapshot) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) =>
          TravelTranslatorSheet(destination: snapshot.destinationTitle),
    );
  }

  void _openMap(TripSnapshot snapshot) {
    final day = snapshot.days.isNotEmpty ? snapshot.days[_selectedDay] : null;
    final titles =
        day?.items.map((i) => i.title).toList() ?? snapshot.placeLabels;
    final locs = TripMapSheet.resolveLocations(
      snapshot.destinationTitle,
      titles,
    );
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TripMapSheet(
        destination: snapshot.destinationTitle,
        dayTitle: day?.label ?? 'Giorno 1',
        places: locs,
      ),
    );
  }

  void _openChecklist(TripSnapshot snapshot) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (ctx) => TripChecklistScreen(
          tripId: _conversationId,
          destination: snapshot.destinationTitle,
        ),
      ),
    );
  }

  void _openExpenses(TripSnapshot snapshot) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TripExpenseSheet(
        tripId: _conversationId,
        destination: snapshot.destinationTitle,
      ),
    );
  }

  void _openWeather(TripSnapshot snapshot) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.60,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(100),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Previsioni Meteo · ${snapshot.destinationTitle}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<TripWeatherReport>(
                future: _weatherService.fetchWeather(snapshot.destinationTitle),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [WeatherBadgeWidget(report: snap.data!)],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _conversationId = widget.conversationId;
  }

  @override
  void didUpdateWidget(covariant TripSnapshotScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(widget.controller, oldWidget.controller) &&
        widget.conversationId == oldWidget.conversationId) {
      return;
    }
    _controller = widget.controller;
    _conversationId = widget.conversationId;
    _selectedDay = 0;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final snapshot =
            widget.initialSnapshot ??
            _controller.conversationOf(_conversationId).snapshot;
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
        final mediaGallery = fixture?.mediaGallery ?? const <PlanMedia>[];
        final savedInspirations = _controller.savedInspirationsFor(
          _conversationId,
        );
        return Scaffold(
          appBar: AppBar(
            title: Semantics(
              label: 'Piano di ${snapshot.destinationTitle}',
              header: true,
              child: ExcludeSemantics(
                child: Text(
                  snapshot.destinationTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            actions: <Widget>[
              PopupMenuButton<_PlanOverflowAction>(
                tooltip: 'Altre azioni',
                onSelected: (action) {
                  switch (action) {
                    case _PlanOverflowAction.shareText:
                      final text = PlanExporter.toFormattedText(snapshot);
                      PlanExporter.copyToClipboard(
                        context,
                        text: text,
                        message: 'Itinerario copiato negli appunti',
                      );
                    case _PlanOverflowAction.exportIcs:
                      final ics = PlanExporter.toIcs(snapshot);
                      PlanExporter.copyToClipboard(
                        context,
                        text: ics,
                        message: 'File calendario (.ics) copiato negli appunti',
                      );
                    case _PlanOverflowAction.importInspiration:
                      _openInspirationImport();
                    case _PlanOverflowAction.searchFlights:
                      _openFlightSearch(snapshot);
                    case _PlanOverflowAction.searchStays:
                      _openStays(snapshot);
                    case _PlanOverflowAction.foodGuide:
                      _openFoodGuide(snapshot);
                    case _PlanOverflowAction.translator:
                      _openTranslator(snapshot);
                    case _PlanOverflowAction.viewMap:
                      _openMap(snapshot);
                    case _PlanOverflowAction.viewWeather:
                      _openWeather(snapshot);
                    case _PlanOverflowAction.packingChecklist:
                      _openChecklist(snapshot);
                    case _PlanOverflowAction.expenseBudget:
                      _openExpenses(snapshot);
                  }
                },
                itemBuilder: (context) =>
                    const <PopupMenuEntry<_PlanOverflowAction>>[
                      PopupMenuItem<_PlanOverflowAction>(
                        value: _PlanOverflowAction.searchFlights,
                        child: Text('Voli reali'),
                      ),
                      PopupMenuItem<_PlanOverflowAction>(
                        value: _PlanOverflowAction.searchStays,
                        child: Text('Alloggi e hotel'),
                      ),
                      PopupMenuItem<_PlanOverflowAction>(
                        value: _PlanOverflowAction.foodGuide,
                        child: Text('Cosa mangiare e locali'),
                      ),
                      PopupMenuItem<_PlanOverflowAction>(
                        value: _PlanOverflowAction.translator,
                        child: Text('Frasario e traduttore'),
                      ),
                      PopupMenuItem<_PlanOverflowAction>(
                        value: _PlanOverflowAction.viewMap,
                        child: Text('Mappa e tappe'),
                      ),
                      PopupMenuItem<_PlanOverflowAction>(
                        value: _PlanOverflowAction.viewWeather,
                        child: Text('Previsioni meteo live'),
                      ),
                      PopupMenuItem<_PlanOverflowAction>(
                        value: _PlanOverflowAction.packingChecklist,
                        child: Text('Valigia e checklist'),
                      ),
                      PopupMenuItem<_PlanOverflowAction>(
                        value: _PlanOverflowAction.expenseBudget,
                        child: Text('Spese e budget'),
                      ),
                      PopupMenuDivider(),
                      PopupMenuItem<_PlanOverflowAction>(
                        value: _PlanOverflowAction.shareText,
                        child: Text('Condividi itinerario'),
                      ),
                      PopupMenuItem<_PlanOverflowAction>(
                        value: _PlanOverflowAction.exportIcs,
                        child: Text('Esporta calendario (.ics)'),
                      ),
                      PopupMenuItem<_PlanOverflowAction>(
                        value: _PlanOverflowAction.importInspiration,
                        child: Text('Importa ispirazione'),
                      ),
                    ],
              ),
            ],
          ),
          body: IterPageFrame(
            padding: EdgeInsets.zero,
            expandHeight: true,
            child: Column(
              children: <Widget>[
                Expanded(
                  child: Stack(
                    children: <Widget>[
                      ListView(
                        key: const Key('plan-scroll'),
                        padding: const EdgeInsets.fromLTRB(
                          0,
                          0,
                          0,
                          _planContentBottomSpacing,
                        ),
                        children: <Widget>[
                          _DestinationHero(
                            snapshot: snapshot,
                            media: media,
                            mediaGallery: mediaGallery,
                            onOpenMedia: () =>
                                _openDestinationMedia(mediaGallery),
                          ),
                          const SizedBox(height: 24),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _PlanFacts(snapshot: snapshot),
                          ),
                          if (savedInspirations.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 24),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: _SavedInspirationsSection(
                                items: savedInspirations,
                              ),
                            ),
                          ],
                          if (snapshot.days.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 24),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: _DayChips(
                                days: snapshot.days,
                                selectedIndex: _selectedDay,
                                onSelected: (index) =>
                                    setState(() => _selectedDay = index),
                              ),
                            ),
                            const SizedBox(height: 22),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: PlanTimeline(
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
                                onDragStarted: (itemId) =>
                                    setState(() => _draggedItemId = itemId),
                                onDragEnded: () {
                                  if (mounted) {
                                    setState(() => _draggedItemId = null);
                                  }
                                },
                                onAction: (item, action) =>
                                    _handleTimelineAction(
                                      snapshot: snapshot,
                                      item: item,
                                      action: action,
                                    ),
                              ),
                            ),
                          ] else if (snapshot
                              .unplacedItems
                              .isEmpty) ...<Widget>[
                            const SizedBox(height: 28),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: _UnplacedSection(
                                items: <TripItemSnapshot>[],
                              ),
                            ),
                          ],
                          if (snapshot.unplacedItems.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 28),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: PlanUnplacedItems(
                                items: snapshot.unplacedItems,
                                canMove: buildPlanMoveTargets(
                                  snapshot: snapshot,
                                ).isNotEmpty,
                                onAction: (item, action) =>
                                    _handleTimelineAction(
                                      snapshot: snapshot,
                                      item: item,
                                      action: action,
                                    ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (_draggedItemId case final itemId?)
                        Positioned(
                          left: 12,
                          right: 12,
                          bottom: 8,
                          child: PlanDragDestinations(
                            snapshot: snapshot,
                            itemId: itemId,
                            onAccept: (target) {
                              setState(() => _draggedItemId = null);
                              _previewMove(
                                itemId: itemId,
                                targetDayId: target.dayId,
                                targetIndex: target.targetIndex,
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                _GlobalPlanActions(
                  onAdd: () =>
                      _openPlacePicker(snapshot: snapshot, fixture: fixture),
                  onAsk: () => Navigator.of(context).maybePop(),
                  onCosts: _openCostSheet,
                ),
              ],
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
    if (place == null) {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => RealPlaceSheet(
          placeTitle: item.title,
          destination: snapshot.destinationTitle,
        ),
      );
      return;
    }
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

  void _openDestinationReel(PlanMedia media) {
    if (media.reelUrl == null || media.reelUrl!.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlaceReelScreen(
          placeTitle: _controller
              .conversationOf(_conversationId)
              .snapshot!
              .destinationTitle,
          media: media,
        ),
      ),
    );
  }

  Future<void> _openDestinationMedia(List<PlanMedia> media) async {
    if (media.isEmpty) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: _DestinationMediaRail(
          destination: _controller
              .conversationOf(_conversationId)
              .snapshot!
              .destinationTitle,
          media: media,
          onOpenReel: (item) {
            Navigator.of(sheetContext).pop();
            _openDestinationReel(item);
          },
        ),
      ),
    );
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

  Future<void> _openCostSheet() async {
    await showPlanCostSheet(
      context: context,
      controller: _controller,
      conversationId: _conversationId,
      externalLauncher: widget.externalLauncher ?? PlanExternalLauncher(),
    );
  }

  Future<void> _openInspirationImport() async {
    final proposed = await showInspirationImportSheet(
      context: context,
      controller: _controller,
      initialConversationId: _conversationId,
    );
    if (!mounted || proposed != true) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Proposta inviata nella chat del viaggio'),
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
  const _DestinationHero({
    required this.snapshot,
    required this.media,
    required this.mediaGallery,
    required this.onOpenMedia,
  });

  final TripSnapshot snapshot;
  final PlanMedia? media;
  final List<PlanMedia> mediaGallery;
  final VoidCallback onOpenMedia;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final image = media?.imageUrl;
    return Semantics(
      image: true,
      label: 'Foto di ${snapshot.destinationTitle}',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth > 0
              ? constraints.maxWidth
              : MediaQuery.sizeOf(context).width;
          final height = (width / (16 / 9)).clamp(180.0, 320.0);
          return SizedBox(
            key: const Key('plan-destination-hero'),
            height: height,
            width: double.infinity,
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
                const Positioned.fill(
                  child: IterHeroScrim(child: SizedBox.expand()),
                ),
                ExcludeSemantics(
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            '${snapshot.country} · ${snapshot.durationLabel}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: colors.onInverseSurface,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            snapshot.dates,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: colors.onInverseSurface.withValues(
                                    alpha: 0.86,
                                  ),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (mediaGallery.isNotEmpty)
                  Positioned(
                    right: 16,
                    top: MediaQuery.paddingOf(context).top + 8,
                    child: Material(
                      color: colors.inverseSurface.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(12),
                      child: TextButton.icon(
                        key: const Key('plan-destination-media'),
                        onPressed: onOpenMedia,
                        icon: Icon(
                          Icons.collections_outlined,
                          color: colors.onInverseSurface,
                          size: 18,
                        ),
                        label: Text(
                          '${snapshot.destinationTitle} · immagini e video',
                          style: TextStyle(color: colors.onInverseSurface),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
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

class _DestinationMediaRail extends StatelessWidget {
  const _DestinationMediaRail({
    required this.destination,
    required this.media,
    required this.onOpenReel,
  });

  final String destination;
  final List<PlanMedia> media;
  final ValueChanged<PlanMedia> onOpenReel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final firstReel = media.cast<PlanMedia?>().firstWhere(
      (item) => item?.reelUrl?.isNotEmpty ?? false,
      orElse: () => null,
    );
    return Column(
      key: const Key('plan-destination-media-sheet'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '$destination · immagini e video',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 132,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: media.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final item = media[index];
              final hasReel = item.reelUrl?.isNotEmpty ?? false;
              return Semantics(
                button: hasReel,
                label: hasReel
                    ? 'Apri video ${index + 1} di $destination'
                    : 'Immagine ${index + 1} di $destination',
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: hasReel ? () => onOpenReel(item) : null,
                  child: Container(
                    width: 156,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colors.outlineVariant),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        if (item.imageUrl case final image?)
                          Image.asset(
                            image,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                const _MediaTileFallback(),
                          )
                        else
                          const _MediaTileFallback(),
                        if (hasReel)
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: colors.inverseSurface.withValues(
                                    alpha: 0.88,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: Icon(
                                    Icons.play_arrow_rounded,
                                    color: colors.onInverseSurface,
                                    size: 18,
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
            },
          ),
        ),
        if (firstReel != null) ...<Widget>[
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => onOpenReel(firstReel),
              icon: const Icon(Icons.play_circle_outline),
              label: const Text('Vedi video della destinazione'),
            ),
          ),
        ],
      ],
    );
  }
}

class _MediaTileFallback extends StatelessWidget {
  const _MediaTileFallback();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colors.surfaceContainerHighest,
      child: Center(
        child: Icon(Icons.landscape_outlined, color: colors.primary, size: 32),
      ),
    );
  }
}

class _SavedInspirationsSection extends StatelessWidget {
  const _SavedInspirationsSection({required this.items});

  final List<SavedInspiration> items;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      key: const Key('plan-saved-inspirations'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Ispirazioni salvate',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        for (final item in items) ...<Widget>[
          Container(
            key: Key('saved-inspiration-${item.id}'),
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: Image.asset(
                      item.mediaAsset,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const _MediaTileFallback(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${item.placeName} · ${item.moment}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item.attachedToPlan
                            ? 'Integrata nel piano'
                            : 'Da integrare',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: item.attachedToPlan
                              ? colors.tertiary
                              : colors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (item != items.last) const SizedBox(height: 8),
        ],
      ],
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
    final glass =
        Theme.of(context).extension<IterGlassRoles>() ?? const IterGlassRoles();
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final selected = index == selectedIndex;
          return IterMaterialSurface(
            padding: EdgeInsets.zero,
            borderRadius: BorderRadius.circular(glass.pillRadius),
            translucent: true,
            child: Material(
              color: selected
                  ? colors.primaryContainer.withValues(alpha: 0.55)
                  : Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(glass.pillRadius),
                onTap: () => onSelected(index),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  child: Center(
                    child: Text(
                      days[index].label,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: selected
                            ? colors.onPrimaryContainer
                            : colors.onSurface,
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
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
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(
        12,
        0,
        12,
        _globalPlanActionsBottomSpacing,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: IterGlassBar(
            key: const Key('plan-global-actions'),
            padding: const EdgeInsets.all(6),
            child: SizedBox(
              height: 52,
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
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(icon, size: 18, color: colors.primary),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(fontSize: 11, height: 1),
                ),
              ],
            ),
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
