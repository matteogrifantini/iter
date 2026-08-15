import 'package:flutter/material.dart';

import 'chat_first_controller.dart';
import 'chat_first_data.dart';
import 'chat_first_models.dart';
import 'plan_external_launcher.dart';

/// Deterministic demo estimates for on-site costs (spec §7.1, "Stime non
/// acquistate"). Inline in the cost sheet so the data model stays untouched.
const List<({String label, String detail, int priceCents})>
_demoOnSiteEstimates = <({String label, String detail, int priceCents})>[
  (label: 'Ingressi', detail: '2 × 18 €', priceCents: 3600),
  (label: 'Pasti al giorno', detail: '3 × 25 €', priceCents: 7500),
  (label: 'Trasporto locale', detail: '1 × 15 €', priceCents: 1500),
];

/// One cost row: a purchase (flight/hotel), an on-site estimate or a total.
@immutable
class PlanCostRowData {
  const PlanCostRowData({
    this.kind = ExternalPurchaseKind.travel,
    this.optionId = '',
    required this.label,
    this.subtitle = '',
    required this.priceCents,
    required this.state,
    this.purchaseUri,
    this.actionEnabled = false,
    this.hasAction = false,
    this.emphasized = false,
    this.showState = true,
  });

  final ExternalPurchaseKind kind;
  final String optionId;
  final String label;
  final String subtitle;

  /// The detail behind a demo estimate, e.g. `2 × 18 €`.
  final int priceCents;
  final PurchaseState state;
  final Uri? purchaseUri;

  /// Whether the external action is safe to offer: HTTPS on an allowlisted
  /// host. Non-allowlisted or non-HTTPS links keep the button inert.
  final bool actionEnabled;

  /// Whether this row exposes an external action button at all. Flight/hotel
  /// rows do; estimates and totals do not.
  final bool hasAction;

  /// The final "Totale previsto" row is emphasized in bold.
  final bool emphasized;

  /// Totals carry no purchase-state chip.
  final bool showState;
}

/// A linear cost section: title, subtitle and its rows.
@immutable
class PlanCostSectionData {
  const PlanCostSectionData({
    required this.title,
    required this.subtitle,
    required this.rows,
  });

  final String title;
  final String subtitle;
  final List<PlanCostRowData> rows;
}

/// Fully built cost sheet content: the linear sections of spec §7.1.
@immutable
class PlanCostSheetData {
  const PlanCostSheetData({required this.sections});

  final List<PlanCostSectionData> sections;

  bool get canConfirmMockPurchases {
    if (sections.isEmpty) return false;
    return sections.first.rows.any(
      (row) =>
          (row.kind == ExternalPurchaseKind.travel ||
              row.kind == ExternalPurchaseKind.stay) &&
          row.priceCents > 0,
    );
  }
}

/// Builds the linear cost sheet from a plan snapshot and its operational
/// fixture (spec §7.1):
///
/// 1. **Da acquistare:** the selected flight and hotel, with state and the
///    external action (enabled only when the launcher allows it);
/// 2. **Stime non acquistate:** deterministic demo rows for entrances, meals
///    and local transport, origin `stima`, no external action;
/// 3. **Totali:** da acquistare fuori da Iter, stime sul posto and the final
///    projected total (the breakdown always sums to the total).
PlanCostSheetData buildPlanCostSheetData(
  TripSnapshot snapshot,
  PlanExternalLauncher launcher,
) {
  final fixture = ChatFirstDemoData.operationalFixtureForSnapshot(snapshot);
  final travelRow = _travelRow(snapshot, fixture, launcher);
  final stayRow = _stayRow(snapshot, fixture, launcher);
  final purchaseRows = <PlanCostRowData>[travelRow, stayRow];

  final toBuyCents = purchaseRows.fold<int>(
    0,
    (sum, row) =>
        sum + (row.state == PurchaseState.estimate ? 0 : row.priceCents),
  );
  final onSiteCents = _demoOnSiteEstimates.fold<int>(
    0,
    (sum, estimate) => sum + estimate.priceCents,
  );
  final estimateRows = <PlanCostRowData>[
    for (final estimate in _demoOnSiteEstimates)
      PlanCostRowData(
        label: estimate.label,
        subtitle: estimate.detail,
        priceCents: estimate.priceCents,
        state: PurchaseState.estimate,
      ),
  ];
  final totalCents = toBuyCents + onSiteCents;

  return PlanCostSheetData(
    sections: <PlanCostSectionData>[
      PlanCostSectionData(
        title: 'Da acquistare',
        subtitle: 'Volo e hotel selezionati',
        rows: purchaseRows,
      ),
      PlanCostSectionData(
        title: 'Stime non acquistate',
        subtitle: 'Ingressi, pasti e trasporto locale',
        rows: estimateRows,
      ),
      PlanCostSectionData(
        title: 'Totali',
        subtitle: '',
        rows: <PlanCostRowData>[
          PlanCostRowData(
            label: 'Da acquistare fuori da Iter',
            priceCents: toBuyCents,
            state: PurchaseState.estimate,
            showState: false,
          ),
          PlanCostRowData(
            label: 'Stime sul posto',
            priceCents: onSiteCents,
            state: PurchaseState.estimate,
            showState: false,
          ),
          PlanCostRowData(
            label: 'Totale previsto',
            priceCents: totalCents,
            state: PurchaseState.estimate,
            showState: false,
            emphasized: true,
          ),
        ],
      ),
    ],
  );
}

PlanCostRowData _travelRow(
  TripSnapshot snapshot,
  OperationalTripFixture? fixture,
  PlanExternalLauncher launcher,
) {
  final option = snapshot.travelSelection?.option;
  if (option == null) {
    final flights = fixture?.flights;
    final recommended = (flights == null || flights.isEmpty)
        ? null
        : flights.first;
    return PlanCostRowData(
      kind: ExternalPurchaseKind.travel,
      optionId: recommended?.id ?? '',
      label: recommended == null
          ? 'Da scegliere'
          : 'Da scegliere · ${recommended.provider}',
      priceCents: recommended?.priceCents ?? 0,
      state: PurchaseState.estimate,
    );
  }
  final flight = _flightFor(fixture, option.id);
  return PlanCostRowData(
    kind: ExternalPurchaseKind.travel,
    optionId: option.id,
    label: option.label,
    subtitle: flight == null
        ? ''
        : 'Andata e ritorno · ${flight.departureAirport}–${flight.arrivalAirport}',
    priceCents: option.priceCents,
    state: option.purchaseState,
    purchaseUri: flight?.providerUrl,
    actionEnabled: launcher.canOpen(flight?.providerUrl),
    hasAction: true,
  );
}

PlanCostRowData _stayRow(
  TripSnapshot snapshot,
  OperationalTripFixture? fixture,
  PlanExternalLauncher launcher,
) {
  final option = snapshot.staySelection?.option;
  if (option == null) {
    final hotels = fixture?.hotels;
    final recommended = (hotels == null || hotels.isEmpty)
        ? null
        : hotels.first;
    return PlanCostRowData(
      kind: ExternalPurchaseKind.stay,
      optionId: recommended?.id ?? '',
      label: recommended == null
          ? 'Da scegliere'
          : 'Da scegliere · ${recommended.name}',
      priceCents: recommended?.priceCents ?? 0,
      state: PurchaseState.estimate,
    );
  }
  final hotel = _hotelFor(fixture, option.id);
  return PlanCostRowData(
    kind: ExternalPurchaseKind.stay,
    optionId: option.id,
    label: option.label,
    subtitle: hotel == null
        ? ''
        : '${hotel.zone} · ${hotel.nights == 1 ? '1 notte' : '${hotel.nights} notti'}',
    priceCents: option.priceCents,
    state: option.purchaseState,
    purchaseUri: hotel?.providerUrl,
    actionEnabled: launcher.canOpen(hotel?.providerUrl),
    hasAction: true,
  );
}

FlightFixture? _flightFor(OperationalTripFixture? fixture, String optionId) {
  for (final flight in fixture?.flights ?? const <FlightFixture>[]) {
    if (flight.id == optionId) return flight;
  }
  return null;
}

HotelFixture? _hotelFor(OperationalTripFixture? fixture, String optionId) {
  for (final hotel in fixture?.hotels ?? const <HotelFixture>[]) {
    if (hotel.id == optionId) return hotel;
  }
  return null;
}

String purchaseStateLabel(PurchaseState state) => switch (state) {
  PurchaseState.estimate => 'stima',
  PurchaseState.selected => 'selezionato',
  PurchaseState.purchaseOpened => 'acquisto aperto',
  PurchaseState.purchased => 'acquistato',
};

/// Opens the linear cost sheet for the conversation's plan. The sheet reads
/// the live snapshot through [controller], so state changes (e.g. a successful
/// external launch) refresh the rows immediately.
Future<void> showPlanCostSheet({
  required BuildContext context,
  required ChatFirstPrototypeController controller,
  required String conversationId,
  required PlanExternalLauncher externalLauncher,
}) {
  final scaledBody = MediaQuery.textScalerOf(context).scale(16);
  final largeText = scaledBody >= 24;
  final reducedMotion = MediaQuery.disableAnimationsOf(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    sheetAnimationStyle: reducedMotion ? AnimationStyle.noAnimation : null,
    backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0),
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: largeText ? 0.92 : 0.72,
      minChildSize: largeText ? 0.72 : 0.46,
      maxChildSize: 0.96,
      snap: !reducedMotion,
      snapSizes: largeText
          ? const <double>[0.92, 0.96]
          : const <double>[0.72, 0.96],
      builder: (context, scrollController) => ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final snapshot = controller.conversationOf(conversationId).snapshot;
          final data = snapshot == null
              ? const PlanCostSheetData(sections: <PlanCostSectionData>[])
              : buildPlanCostSheetData(snapshot, externalLauncher);
          return PlanCostSheet(
            sections: data.sections,
            scrollController: scrollController,
            mockPurchasesConfirmed: controller.mockPurchasesConfirmed(
              conversationId,
            ),
            showNoPurchasesMessage:
                !data.canConfirmMockPurchases &&
                !controller.mockPurchasesConfirmed(conversationId),
            onConfirmMockPurchases: data.canConfirmMockPurchases
                ? () {
                    controller.confirmMockPurchases(conversationId);
                  }
                : null,
            onOpenPurchase: (row) {
              final uri = row.purchaseUri;
              if (uri == null) return Future<void>.value();
              return controller.openExternalPurchase(
                conversationId: conversationId,
                kind: row.kind,
                optionId: row.optionId,
                uri: uri,
                launcher: externalLauncher,
              );
            },
          );
        },
      ),
    ),
  );
}

/// Readable Material panel with the three linear cost sections and the total
/// breakdown. Kept scrollable so large text (1.5) never overflows.
class PlanCostSheet extends StatelessWidget {
  const PlanCostSheet({
    super.key,
    required this.sections,
    required this.onOpenPurchase,
    this.mockPurchasesConfirmed = false,
    this.onConfirmMockPurchases,
    this.showNoPurchasesMessage = false,
    this.scrollController,
  });

  final List<PlanCostSectionData> sections;
  final Future<void> Function(PlanCostRowData row) onOpenPurchase;
  final bool mockPurchasesConfirmed;
  final VoidCallback? onConfirmMockPurchases;
  final bool showNoPurchasesMessage;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: <Widget>[
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: colors.onSurfaceVariant.withValues(alpha: 0.42),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              key: const Key('plan-cost-sheet-scroll'),
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
              children: <Widget>[
                Focus(
                  key: const Key('plan-cost-sheet-focus'),
                  autofocus: true,
                  child: Semantics(
                    header: true,
                    child: Text(
                      'Costi del piano',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Stime demo: prezzi e disponibilità non sono in tempo reale.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                if (showNoPurchasesMessage) ...<Widget>[
                  const SizedBox(height: 10),
                  Text(
                    'Nessuna scelta demo da confermare',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                for (final section in sections) ...<Widget>[
                  _CostSectionHeader(section: section),
                  const SizedBox(height: 8),
                  for (final row in section.rows) ...<Widget>[
                    _CostRow(
                      row: row,
                      onOpen: row.hasAction && row.actionEnabled
                          ? () => onOpenPurchase(row)
                          : null,
                    ),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 10),
                ],
                if (onConfirmMockPurchases != null) ...<Widget>[
                  const SizedBox(height: 4),
                  if (mockPurchasesConfirmed)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Icon(
                            Icons.check_circle_outline,
                            color: colors.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Scelte confermate',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        key: const Key('plan-cost-confirm-demo'),
                        onPressed: () => _confirmMockPurchases(context),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Conferma acquisti demo'),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'Demo: nessun pagamento reale',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  'Dati demo · prezzi e disponibilità non sono in tempo reale.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmMockPurchases(BuildContext context) async {
    final total = sections
        .expand((section) => section.rows)
        .where((row) => row.emphasized)
        .firstOrNull;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Conferma le scelte del piano?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Volo, hotel e totale restano una simulazione locale. '
              'Nessun ordine verrà inviato.',
            ),
            if (total != null) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                'Totale previsto · ${formatEuroCents(total.priceCents)}',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              'Demo: nessun pagamento reale',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            key: const Key('plan-cost-confirm-dialog'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Conferma acquisti demo'),
          ),
        ],
      ),
    );
    if (confirmed == true) onConfirmMockPurchases?.call();
  }
}

class _CostSectionHeader extends StatelessWidget {
  const _CostSectionHeader({required this.section});

  final PlanCostSectionData section;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      header: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            section.title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (section.subtitle.isNotEmpty) ...<Widget>[
            const SizedBox(height: 2),
            Text(
              section.subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

class _CostRow extends StatelessWidget {
  const _CostRow({required this.row, required this.onOpen});

  final PlanCostRowData row;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final provider = row.label.split(' · ').first;
    final emphasized = row.emphasized;
    return Container(
      key: Key('plan-cost-row-${row.optionId}'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  row.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: emphasized ? FontWeight.w800 : FontWeight.w700,
                  ),
                ),
                if (row.subtitle.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    row.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 3),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    Text(
                      formatEuroCents(row.priceCents),
                      style: emphasized
                          ? Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: colors.primary,
                            )
                          : Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: colors.primary,
                            ),
                    ),
                    if (row.showState)
                      Text(
                        purchaseStateLabel(row.state),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (row.hasAction && onOpen != null)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Semantics(
                  button: true,
                  label: 'Si apre la pagina di $provider',
                  child: FilledButton.tonalIcon(
                    onPressed: onOpen,
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Apri nel sito'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(48, 48),
                    ),
                  ),
                ),
              ),
            )
          else if (row.hasAction)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Semantics(
                  label: 'Acquisto non disponibile per ${row.label}',
                  child: Tooltip(
                    message: 'Pagina esterna non disponibile per questa voce',
                    child: OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Apri nel sito'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(48, 48),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
