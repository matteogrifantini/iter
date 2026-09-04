import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../ai/gemini_models.dart';
import '../map/trip_map_models.dart';
import '../map/trip_map_sheet.dart';
import '../places/visual_media_service.dart';
import 'trip_entity.dart';

import 'trip_repository.dart';


/// Screen displaying the details, flights, stays, and daily itinerary of a saved TripEntity.
/// Features prominent booking buttons, persistent chat modification bar,
/// and direct itinerary reordering / editing without requiring AI prompts.
class TripDetailsScreen extends StatefulWidget {
  const TripDetailsScreen({
    super.key,
    required this.trip,
    this.onContinueChat,
  });

  final TripEntity trip;
  final ValueChanged<String>? onContinueChat;

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  late TripEntity _trip;
  late final TextEditingController _chatController;

  @override
  void initState() {
    super.initState();
    _trip = widget.trip;
    _chatController = TextEditingController();
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _openTripMap({String? dayTitle, List<String>? stopTitles}) {
    final titles = stopTitles ??
        (_trip.latestPlan?.days.expand((d) => d.stops).toList() ?? []);
    final locations = TripMapSheet.resolveLocations(_trip.destination, titles);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TripMapSheet(
        destination: _trip.destination,
        dayTitle: dayTitle ?? 'Tutte le tappe del viaggio',
        places: locations,
      ),
    );
  }

  void _submitChatPrompt(String text) {

    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    if (widget.onContinueChat != null) {
      widget.onContinueChat!(trimmed);
    } else {
      Navigator.of(context).pop(trimmed);
    }
  }

  Future<void> _saveCurrentTrip() async {
    await TripRepository().saveTrip(_trip);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Itinerario aggiornato e salvato con successo!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _moveStopWithinDay(int dayIndex, int stopIndex, int delta) {
    final plan = _trip.latestPlan;
    if (plan == null) return;

    final days = List<DailyPlanDraft>.from(plan.days);
    final targetDay = days[dayIndex];
    final stops = List<String>.from(targetDay.stops);

    final newIndex = stopIndex + delta;
    if (newIndex < 0 || newIndex >= stops.length) return;

    final item = stops.removeAt(stopIndex);
    stops.insert(newIndex, item);

    days[dayIndex] = DailyPlanDraft(
      dayNumber: targetDay.dayNumber,
      theme: targetDay.theme,
      stops: stops,
      diningRecommendation: targetDay.diningRecommendation,
    );

    setState(() {
      _trip = _trip.copyWith(latestPlan: plan.copyWith(days: days));
    });
    _saveCurrentTrip();
  }

  void _moveStopToDay(int fromDayIndex, int stopIndex, int toDayIndex) {
    final plan = _trip.latestPlan;
    if (plan == null || fromDayIndex == toDayIndex) return;

    final days = List<DailyPlanDraft>.from(plan.days);
    final fromDay = days[fromDayIndex];
    final toDay = days[toDayIndex];

    final fromStops = List<String>.from(fromDay.stops);
    final toStops = List<String>.from(toDay.stops);

    final item = fromStops.removeAt(stopIndex);
    toStops.add(item);

    days[fromDayIndex] = DailyPlanDraft(
      dayNumber: fromDay.dayNumber,
      theme: fromDay.theme,
      stops: fromStops,
      diningRecommendation: fromDay.diningRecommendation,
    );
    days[toDayIndex] = DailyPlanDraft(
      dayNumber: toDay.dayNumber,
      theme: toDay.theme,
      stops: toStops,
      diningRecommendation: toDay.diningRecommendation,
    );

    setState(() {
      _trip = _trip.copyWith(latestPlan: plan.copyWith(days: days));
    });
    _saveCurrentTrip();
  }

  String _computeDayDate(int dayIndex) {
    final baseDate = DateTime.now().add(const Duration(days: 14));
    final dayDate = baseDate.add(Duration(days: dayIndex));
    const weekdayNames = ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];
    const monthNames = ['Gen', 'Feb', 'Mar', 'Apr', 'Mag', 'Giu', 'Lug', 'Ago', 'Set', 'Ott', 'Nov', 'Dic'];
    final wName = weekdayNames[dayDate.weekday - 1];
    final mName = monthNames[dayDate.month - 1];
    return '$wName ${dayDate.day} $mName';
  }

  void _deleteStop(int dayIndex, int stopIndex) {

    final plan = _trip.latestPlan;
    if (plan == null) return;

    final days = List<DailyPlanDraft>.from(plan.days);
    final day = days[dayIndex];
    final stops = List<String>.from(day.stops);
    stops.removeAt(stopIndex);

    days[dayIndex] = DailyPlanDraft(
      dayNumber: day.dayNumber,
      theme: day.theme,
      stops: stops,
      diningRecommendation: day.diningRecommendation,
    );

    setState(() {
      _trip = _trip.copyWith(latestPlan: plan.copyWith(days: days));
    });
    _saveCurrentTrip();
  }

  Future<void> _addNewStop(int dayIndex) async {
    final textController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Aggiungi tappa al Giorno ${dayIndex + 1}'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Es: 15:00 · Visita al museo d\'arte contemporanea',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(textController.text.trim()),
            child: const Text('Aggiungi'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final plan = _trip.latestPlan;
      if (plan == null) return;

      final days = List<DailyPlanDraft>.from(plan.days);
      final day = days[dayIndex];
      final stops = List<String>.from(day.stops)..add(result);

      days[dayIndex] = DailyPlanDraft(
        dayNumber: day.dayNumber,
        theme: day.theme,
        stops: stops,
        diningRecommendation: day.diningRecommendation,
      );

      setState(() {
        _trip = _trip.copyWith(latestPlan: plan.copyWith(days: days));
      });
      _saveCurrentTrip();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final plan = _trip.latestPlan;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          _trip.destination.isNotEmpty ? _trip.destination : 'Itinerario Viaggio',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Condividi',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Link itinerario copiato negli appunti!')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Image
            Stack(
              children: [
                Container(
                  height: 200,
                  width: double.infinity,
                  color: colorScheme.primaryContainer,
                  child: _trip.coverImageUrl.isNotEmpty
                      ? Image.network(
                          _trip.coverImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Icon(Icons.flight_takeoff_rounded, size: 48, color: colorScheme.primary),
                          ),
                        )
                      : null,
                ),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.75),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _trip.destination,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_trip.durationDays} giorni • Creato con Iter AI',
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Booking Action Bar se voli o hotel sono presenti
                  if (plan?.flight != null || plan?.selectedStay != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          if (plan?.flight != null)
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => _launchUrl(plan!.flight!.searchUrl),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.blue.shade700,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: const Icon(Icons.flight_takeoff_rounded, size: 18),
                                label: const Text('Compra Volo', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          if (plan?.flight != null && plan?.selectedStay != null)
                            const SizedBox(width: 10),
                          if (plan?.selectedStay != null)
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => _launchUrl(
                                  plan!.selectedStay?.bookingUrl ??
                                  'https://www.google.com/travel/hotels/${Uri.encodeComponent(_trip.destination)}',
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.teal.shade700,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: const Icon(Icons.hotel_rounded, size: 18),
                                label: const Text('Prenota Hotel', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Volo
                  if (plan?.flight != null) ...[
                    _sectionTitle(context, 'Voli e Trasporti', Icons.flight_takeoff_rounded),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  plan!.flight!.outbound,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ),
                              if (plan.flight!.priceEstimate.isNotEmpty)
                                Text(
                                  plan.flight!.priceEstimate,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                            ],
                          ),
                          if (plan.flight!.searchUrl.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: () => _launchUrl(plan.flight!.searchUrl),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.blue.shade700,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                                label: const Text(
                                  'Compra biglietti aerei su Google Flights',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Monumenti e attrazioni scelte
                  if (plan?.attractions.isNotEmpty == true) ...[
                    _sectionTitle(context, 'Monumenti & Tappe scelte', Icons.account_balance_rounded),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: plan!.attractions.map((a) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.place_rounded, size: 14, color: Colors.redAccent),
                              const SizedBox(width: 4),
                              Text(a.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Dove dormire (Alloggio salvato o quartieri consigliati)
                  if (plan?.selectedStay != null || plan?.neighborhoods.isNotEmpty == true) ...[
                    _sectionTitle(context, 'Dove alloggiare', Icons.hotel_rounded),
                    const SizedBox(height: 8),
                    if (plan?.selectedStay != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        plan!.selectedStay!.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${plan.selectedStay!.pricePerNightEur.toStringAsFixed(0)}€/notte · ${plan.selectedStay!.neighborhood}',
                                        style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: () => _launchUrl(
                                  plan.selectedStay?.bookingUrl ??
                                  'https://www.google.com/travel/hotels/${Uri.encodeComponent(_trip.destination)}',
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.teal.shade700,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                                label: Text(
                                  'Prenota ${plan.selectedStay!.name} su Google Hotels',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...plan!.neighborhoods.map((n) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(n.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 4),
                              Text(n.why, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
                            ],
                          ),
                        );
                      }),
                    const SizedBox(height: 24),
                  ],

                  // Itinerario giorno per giorno con gestione e spostamento tappe manuale
                  _sectionTitle(context, 'Itinerario Giorno per Giorno', Icons.calendar_today_rounded),
                  const SizedBox(height: 4),
                  Text(
                    'Puoi riordinare o spostare liberamente le tappe tra i giorni usando i pulsanti dedicati.',
                    style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
                  ),
                  const SizedBox(height: 8),

                  // Date del Viaggio in bella vista
                  if (plan != null && plan.days.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.event_available_rounded, size: 20, color: colorScheme.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Date del viaggio: ${_computeDayDate(0)} – ${_computeDayDate(plan.days.length - 1)} • ${plan.days.length} Giorni (${plan.days.length - 1} notti)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Anteprima Mappa OpenStreetMap interattiva
                  if (plan != null && plan.days.isNotEmpty)
                    _ItineraryMapPreviewCard(
                      destination: _trip.destination,
                      locations: TripMapSheet.resolveLocations(
                        _trip.destination,
                        plan.days.expand((d) => d.stops).toList(),
                      ),
                      onExpand: () => _openTripMap(),
                    ),

                  const SizedBox(height: 12),
                  if (plan != null && plan.days.isNotEmpty)
                    ...plan.days.asMap().entries.map((entry) {
                      final dayIndex = entry.key;
                      final d = entry.value;
                      final totalDays = plan.days.length;

                      return _InteractiveDayCard(
                        day: d,
                        dayIndex: dayIndex,
                        totalDays: totalDays,
                        destination: _trip.destination,
                        formattedDate: _computeDayDate(dayIndex),
                        onMoveStopWithinDay: (stopIdx, delta) => _moveStopWithinDay(dayIndex, stopIdx, delta),
                        onMoveStopToDay: (stopIdx, targetDayIdx) => _moveStopToDay(dayIndex, stopIdx, targetDayIdx),
                        onDeleteStop: (stopIdx) => _deleteStop(dayIndex, stopIdx),
                        onAddStop: () => _addNewStop(dayIndex),
                        onOpenDayMap: () => _openTripMap(dayTitle: 'Giorno ${d.dayNumber}: ${d.theme}', stopTitles: d.stops),
                      );
                    })


                  else
                    Container(
                      padding: const EdgeInsets.all(20),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.map_outlined, size: 40, color: colorScheme.outline),
                          const SizedBox(height: 8),
                          const Text(
                            'Itinerario non ancora creato',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Chiedi a Iter in chat cosa fare e vedere per creare il programma giornaliero!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
      // Box Chat persistente in basso: modifica qualsiasi cosa del viaggio
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 10,
          bottom: MediaQuery.paddingOf(context).bottom + 10,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(top: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3))),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _chatController,
                decoration: InputDecoration(
                  hintText: 'Modifica il tuo itinerario, chiedi qualsiasi cosa...',
                  hintStyle: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                  prefixIcon: Icon(Icons.auto_awesome_rounded, color: colorScheme.primary, size: 20),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHigh,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                ),
                onSubmitted: _submitChatPrompt,
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: () => _submitChatPrompt(_chatController.text),
              icon: const Icon(Icons.arrow_upward_rounded),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _InteractiveDayCard extends StatelessWidget {
  const _InteractiveDayCard({
    required this.day,
    required this.dayIndex,
    required this.totalDays,
    required this.destination,
    required this.formattedDate,
    required this.onMoveStopWithinDay,
    required this.onMoveStopToDay,
    required this.onDeleteStop,
    required this.onAddStop,
    required this.onOpenDayMap,
  });

  final DailyPlanDraft day;
  final int dayIndex;
  final int totalDays;
  final String destination;
  final String formattedDate;
  final void Function(int stopIndex, int delta) onMoveStopWithinDay;
  final void Function(int stopIndex, int targetDayIndex) onMoveStopToDay;
  final ValueChanged<int> onDeleteStop;
  final VoidCallback onAddStop;
  final VoidCallback onOpenDayMap;

  String _getEstimatedTime(int stopIdx) {
    switch (stopIdx) {
      case 0:
        return '09:30';
      case 1:
        return '12:00';
      case 2:
        return '15:15';
      case 3:
        return '17:45';
      default:
        return 'Tappa ${stopIdx + 1}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isIslandOrLarge = destination.toLowerCase().contains('tenerife') ||
        destination.toLowerCase().contains('canarie');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Giorno ${day.dayNumber}',
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  formattedDate,
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),

              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  day.theme,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.map_outlined, size: 18),
                tooltip: 'Mappa di questa giornata',
                onPressed: onOpenDayMap,
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                tooltip: 'Aggiungi tappa a questo giorno',
                onPressed: onAddStop,
              ),
            ],
          ),
          if (day.diningRecommendation != null && day.diningRecommendation!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.restaurant_rounded, size: 14, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      day.diningRecommendation!,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (day.stops.isNotEmpty) ...[
            const SizedBox(height: 12),
            Column(
              children: day.stops.asMap().entries.expand((entry) {
                final stopIdx = entry.key;
                final stopText = entry.value;
                final isFirst = stopIdx == 0;
                final isLast = stopIdx == day.stops.length - 1;

                return [
                  Container(
                    margin: const EdgeInsets.only(bottom: 2),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        // Foto Thumbnail reale del monumento / luogo
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: 50,
                            height: 50,
                            child: Image.network(
                              VisualMediaService.getPhotoForStop(destination, stopText),
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                color: colorScheme.primaryContainer,
                                child: Icon(Icons.place_rounded, size: 24, color: colorScheme.primary),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Dettagli Tappa
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                stopText,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Icon(Icons.access_time_rounded, size: 11, color: colorScheme.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    _getEstimatedTime(stopIdx),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Frecce per spostare su/giù
                        if (!isFirst)
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                            icon: const Icon(Icons.arrow_upward_rounded, size: 16),
                            tooltip: 'Sposta su',
                            onPressed: () => onMoveStopWithinDay(stopIdx, -1),
                          ),
                        if (!isLast)
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                            icon: const Icon(Icons.arrow_downward_rounded, size: 16),
                            tooltip: 'Sposta giù',
                            onPressed: () => onMoveStopWithinDay(stopIdx, 1),
                          ),
                        // Menu per spostare ad un altro giorno
                        if (totalDays > 1)
                          PopupMenuButton<int>(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                            tooltip: 'Sposta in un altro giorno',
                            onSelected: (targetDayIdx) => onMoveStopToDay(stopIdx, targetDayIdx),
                            itemBuilder: (ctx) {
                              return List.generate(totalDays, (idx) {
                                return PopupMenuItem<int>(
                                  value: idx,
                                  enabled: idx != dayIndex,
                                  child: Text('Sposta al Giorno ${idx + 1}'),
                                );
                              });
                            },
                          ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                          icon: const Icon(Icons.close_rounded, size: 16, color: Colors.grey),
                          tooltip: 'Elimina tappa',
                          onPressed: () => onDeleteStop(stopIdx),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Padding(
                      padding: const EdgeInsets.only(left: 24, top: 4, bottom: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 2,
                            height: 18,
                            color: colorScheme.primary.withValues(alpha: 0.35),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isIslandOrLarge ? Icons.directions_car_rounded : Icons.directions_walk_rounded,
                                  size: 13,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  isIslandOrLarge
                                      ? '~20-25 min in auto o bus'
                                      : '10-15 min a piedi (800 m)',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ];
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}


class _ItineraryMapPreviewCard extends StatelessWidget {
  const _ItineraryMapPreviewCard({
    required this.destination,
    required this.locations,
    required this.onExpand,
  });

  final String destination;
  final List<MapPoiLocation> locations;
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final initialCoord = locations.isNotEmpty
        ? LatLng(locations.first.latitude, locations.first.longitude)
        : const LatLng(28.2916, -16.6291);

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.35)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.map_rounded, size: 16, color: colorScheme.primary),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mappa dell\'Itinerario',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          '${locations.length} tappe con percorso consigliato',
                          style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: onExpand,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    backgroundColor: colorScheme.surfaceContainerHigh,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.fullscreen_rounded, size: 16),
                  label: const Text('Espandi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 170,
            width: double.infinity,
            child: Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: initialCoord,
                    initialZoom: 11.0,
                    interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'it.iter.travel',
                    ),
                    MarkerLayer(
                      markers: locations.take(6).map((loc) {
                        return Marker(
                          point: loc.latLng,
                          width: 26,
                          height: 26,
                          child: Container(
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 4),
                              ],
                            ),
                            child: const Icon(Icons.place, color: Colors.white, size: 13),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onExpand,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.touch_app_rounded, color: Colors.white, size: 12),
                        SizedBox(width: 4),
                        Text(
                          'Tocca per esplorare a schermo intero',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
