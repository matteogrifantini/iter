import 'package:flutter/material.dart';

import 'chat_first_data.dart';
import 'chat_first_models.dart';

@immutable
class PlacePickerSelection {
  const PlacePickerSelection({
    required this.place,
    required this.targetDayId,
    required this.targetIndex,
  });

  final OperationalPlaceFixture place;
  final String? targetDayId;
  final int? targetIndex;
}

Future<PlacePickerSelection?> showPlacePickerSheet({
  required BuildContext context,
  required OperationalTripFixture fixture,
  required TripSnapshot snapshot,
}) => showModalBottomSheet<PlacePickerSelection>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => _PlacePickerSheet(fixture: fixture, snapshot: snapshot),
);

enum _PickerStep { search, detail, placement }

class _PlacePickerSheet extends StatefulWidget {
  const _PlacePickerSheet({required this.fixture, required this.snapshot});

  final OperationalTripFixture fixture;
  final TripSnapshot snapshot;

  @override
  State<_PlacePickerSheet> createState() => _PlacePickerSheetState();
}

class _PlacePickerSheetState extends State<_PlacePickerSheet> {
  final _searchController = TextEditingController();
  var _step = _PickerStep.search;
  OperationalPlaceFixture? _selectedPlace;
  String? _targetDayId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<OperationalPlaceFixture> get _availablePlaces {
    final plannedIds = <String>{
      for (final item in widget.snapshot.days.expand((day) => day.items))
        ?item.place?.id,
      for (final item in widget.snapshot.unplacedItems) ?item.place?.id,
    };
    final plannedTitles = <String>{
      ...widget.snapshot.days
          .expand((day) => day.items)
          .map((item) => item.title.trim().toLowerCase()),
      ...widget.snapshot.unplacedItems.map(
        (item) => item.title.trim().toLowerCase(),
      ),
    };
    final query = _searchController.text.trim().toLowerCase();
    return widget.fixture.placeCatalog
        .where((place) {
          if (plannedIds.contains(place.id) ||
              plannedTitles.contains(place.name.toLowerCase())) {
            return false;
          }
          return query.isEmpty ||
              place.name.toLowerCase().contains(query) ||
              place.category.toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  void _back() {
    setState(() {
      _step = switch (_step) {
        _PickerStep.search => _PickerStep.search,
        _PickerStep.detail => _PickerStep.search,
        _PickerStep.placement => _PickerStep.detail,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.88;
    return PopScope(
      canPop: _step == _PickerStep.search,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: SizedBox(
        height: height,
        child: Column(
          children: <Widget>[
            const SizedBox(height: 8),
            ExcludeSemantics(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            SizedBox(
              height: 56,
              child: Row(
                children: <Widget>[
                  if (_step != _PickerStep.search)
                    IconButton(
                      tooltip: 'Indietro',
                      onPressed: _back,
                      icon: const Icon(Icons.arrow_back),
                    )
                  else
                    const SizedBox(width: 16),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(switch (_step) {
                        _PickerStep.search => 'Aggiungi un luogo',
                        _PickerStep.detail => 'Dettagli luogo',
                        _PickerStep.placement => 'Dove lo inseriamo?',
                      }, style: Theme.of(context).textTheme.titleLarge),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Chiudi',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(child: _body(context)),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context) => switch (_step) {
    _PickerStep.search => _search(context),
    _PickerStep.detail => _details(context),
    _PickerStep.placement => _placement(context),
  };

  Widget _search(BuildContext context) {
    final places = _availablePlaces;
    return ListView(
      key: const Key('place-picker-scroll'),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: <Widget>[
        Focus(
          key: const Key('place-picker-search'),
          autofocus: true,
          child: TextField(
            key: const Key('place-picker-search-field'),
            controller: _searchController,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              labelText: 'Cerca per nome o categoria',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 16),
        if (places.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Text('Nessun luogo disponibile per questa ricerca.'),
          )
        else
          for (final place in places)
            ListTile(
              key: Key('place-picker-result-${place.id}'),
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              minTileHeight: 64,
              title: Text(place.name),
              subtitle: Text(place.category),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => setState(() {
                _selectedPlace = place;
                _step = _PickerStep.detail;
              }),
            ),
      ],
    );
  }

  Widget _details(BuildContext context) {
    final place = _selectedPlace!;
    return ListView(
      key: const Key('place-picker-detail-scroll'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            place.name,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          place.category,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 18),
        Text(place.description),
        const SizedBox(height: 28),
        FilledButton.icon(
          onPressed: () => setState(() {
            _targetDayId = widget.snapshot.days.isEmpty
                ? null
                : widget.snapshot.days.first.id;
            _step = _PickerStep.placement;
          }),
          icon: const Icon(Icons.add_location_alt_outlined),
          label: const Text('Scegli luogo'),
        ),
      ],
    );
  }

  Widget _placement(BuildContext context) {
    return ListView(
      key: const Key('place-picker-placement-scroll'),
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.fromLTRB(8, 8, 8, 4),
          child: Text('Iter propone il primo spazio disponibile.'),
        ),
        RadioGroup<String?>(
          groupValue: _targetDayId,
          onChanged: (value) => setState(() => _targetDayId = value),
          child: Column(
            children: <Widget>[
              for (final day in widget.snapshot.days)
                RadioListTile<String?>(
                  key: Key('place-picker-day-${day.id}'),
                  value: day.id,
                  title: Text(day.label),
                  subtitle: const Text('Dopo le tappe già previste'),
                ),
              const RadioListTile<String?>(
                key: Key('place-picker-unplaced'),
                value: null,
                title: Text('Da sistemare'),
                subtitle: Text('Senza giorno o orario per ora'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () {
            final dayId = _targetDayId;
            final day = dayId == null
                ? null
                : widget.snapshot.days.singleWhere(
                    (value) => value.id == dayId,
                  );
            Navigator.of(context).pop(
              PlacePickerSelection(
                place: _selectedPlace!,
                targetDayId: dayId,
                targetIndex: day?.items.length,
              ),
            );
          },
          child: const Text('Rivedi modifica'),
        ),
      ],
    );
  }
}
