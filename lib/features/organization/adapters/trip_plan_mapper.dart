import '../../chat_first_prototype/plan_models.dart';
import '../models/organization_state.dart';

/// Mapper che trasforma uno stato di organizzazione completo di volo e alloggio
/// confermati in un [TripSnapshot] compatibile con il visualizzatore e l'editor di piano.
class TripPlanMapper {
  /// Converte lo stato di organizzazione in un [TripSnapshot] valido.
  /// Lancia [StateError] se il volo o l'alloggio non sono ancora stati confermati.
  static TripSnapshot mapStateToSnapshot(OrganizationState state) {
    final flight = state.confirmedFlight;
    final stay = state.confirmedStay;

    if (flight == null || stay == null) {
      throw StateError(
        'Impossibile generare il piano: volo e alloggio devono essere entrambi confermati.',
      );
    }

    final destination = flight.destination.isNotEmpty
        ? (flight.destination == 'LIS' ? 'Lisbona' : flight.destination)
        : (state.intent.candidateDestinations.isNotEmpty
              ? state.intent.candidateDestinations.first
              : 'Lisbona');

    final origin = flight.origin.isNotEmpty ? flight.origin : 'FCO';
    final depDate = flight.departureDate;
    final retDate = flight.returnDate ?? depDate.add(const Duration(days: 3));

    final durationDays = retDate.difference(depDate).inDays.clamp(1, 14);

    final travelOption = TravelOption(
      id: flight.id,
      label: 'Volo $origin - ${flight.destination}',
      priceCents: flight.priceCents,
      purchaseState: PurchaseState.purchased,
    );

    final stayOption = StayOption(
      id: stay.id,
      label: stay.tradeoffSummary.isNotEmpty
          ? stay.tradeoffSummary
          : 'Alloggio (${stay.destination})',
      priceCents: stay.priceCents,
      purchaseState: PurchaseState.purchased,
    );

    final days = List.generate(durationDays, (index) {
      final currentDay = depDate.add(Duration(days: index));
      return TripDaySnapshot(
        id: 'day-${index + 1}',
        date: currentDay,
        label: 'Giorno ${index + 1}',
        theme: index == 0
            ? 'Arrivo ed esplorazione iniziale'
            : (index == durationDays - 1
                  ? 'Ultime visite e rientro'
                  : 'Cultura, sapori e scoperte locali'),
        items: <TripItemSnapshot>[
          TripItemSnapshot(
            id: 'item-${index + 1}-1',
            title: index == 0
                ? 'Check-in e orientamento di quartiere'
                : 'Colazione tipica e passeggiata',
            category: 'Attività',
            startTime: '09:30',
            durationMinutes: 90,
            locked: false,
          ),
          TripItemSnapshot(
            id: 'item-${index + 1}-2',
            title: 'Visita ed esperienza consigliata',
            category: 'Cultura',
            startTime: '14:00',
            durationMinutes: 120,
            locked: false,
          ),
        ],
      );
    });

    final totalCents = flight.priceCents + stay.priceCents;

    return TripSnapshot(
      destinationTitle: destination,
      country: destination == 'Lisbona' ? 'Portogallo' : 'Europa',
      durationLabel: '$durationDays giorni',
      statusLabel: 'Confermato',
      dates:
          '${depDate.day}/${depDate.month} - ${retDate.day}/${retDate.month}/${retDate.year}',
      transport: 'Volo A/R $origin - ${flight.destination}',
      stay: stay.tradeoffSummary.isNotEmpty
          ? stay.tradeoffSummary
          : 'Alloggio confermato',
      travelSelection: TravelPlanSelection(option: travelOption),
      staySelection: StayPlanSelection(option: stayOption),
      costSummary: PlanCostSummary(projectedTotalCents: totalCents),
      days: days,
    );
  }
}
