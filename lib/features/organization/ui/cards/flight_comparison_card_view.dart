import 'package:flutter/material.dart';
import '../../adapters/flight_search_adapter.dart';
import '../../models/organization_card.dart';
import '../../models/organization_models.dart';

/// Widget per il confronto verticale completo dei voli con filtri e compromessi spiegati.
class FlightComparisonCardView extends StatefulWidget {
  const FlightComparisonCardView({
    super.key,
    required this.card,
    required this.onOfferSelected,
    this.onContinueToProvider,
    this.onSortCriterionChanged,
  });

  final OrganizationCard card;
  final ValueChanged<ProviderOffer> onOfferSelected;
  final ValueChanged<ProviderOffer>? onContinueToProvider;
  final ValueChanged<FlightSortCriterion>? onSortCriterionChanged;

  @override
  State<FlightComparisonCardView> createState() =>
      _FlightComparisonCardViewState();
}

class _FlightComparisonCardViewState extends State<FlightComparisonCardView> {
  FlightSortCriterion _selectedSort = FlightSortCriterion.best;
  String? _selectedOfferId;

  @override
  void initState() {
    super.initState();
    _selectedOfferId = widget.card.payload['selectedOfferId'] as String?;
    final sortStr = widget.card.payload['sortBy'] as String?;
    if (sortStr != null) {
      for (final c in FlightSortCriterion.values) {
        if (c.name == sortStr) {
          _selectedSort = c;
          break;
        }
      }
    }
  }

  @override
  void didUpdateWidget(covariant FlightComparisonCardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newSelected = widget.card.payload['selectedOfferId'] as String?;
    if (newSelected != null) {
      _selectedOfferId = newSelected;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final rawOffers = widget.card.payload['offers'] as List?;
    final offers =
        rawOffers?.whereType<ProviderOffer>().toList() ??
        const <ProviderOffer>[];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF181E26) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black.withAlpha(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 10),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.flight_takeoff_rounded,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.card.title ?? 'Confronto Voli',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.card.description != null)
                      Text(
                        widget.card.description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Sort Filter Segmented Button
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<FlightSortCriterion>(
              segments: const [
                ButtonSegment(
                  value: FlightSortCriterion.best,
                  label: Text('Equilibrio'),
                ),
                ButtonSegment(
                  value: FlightSortCriterion.cheapest,
                  label: Text('Economici'),
                ),
                ButtonSegment(
                  value: FlightSortCriterion.fastest,
                  label: Text('Diretti'),
                ),
              ],
              selected: {_selectedSort},
              onSelectionChanged: (newSet) {
                setState(() => _selectedSort = newSet.first);
                widget.onSortCriterionChanged?.call(_selectedSort);
              },
            ),
          ),
          const SizedBox(height: 14),

          // Offers Vertical List
          if (offers.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Nessuna offerta volo disponibile con questi criteri.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: offers.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final offer = offers[index];
                return _buildFlightOfferItem(context, offer, isDark, theme);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFlightOfferItem(
    BuildContext context,
    ProviderOffer offer,
    bool isDark,
    ThemeData theme,
  ) {
    final cond = offer.conditions;
    final airline = (cond['airlineName'] as String?) ?? 'Volo';
    final flightNum = (cond['flightNumber'] as String?) ?? '';
    final depTime = (cond['departureTime'] as String?) ?? '08:00';
    final arrTime = (cond['arrivalTime'] as String?) ?? '10:30';
    final duration = (cond['durationLabel'] as String?) ?? '2h 30m';
    final isDirect = (cond['isDirect'] as bool?) ?? true;
    final isSelected = _selectedOfferId == offer.id;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF222933) : const Color(0xFFF9FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.primary
              : (isDark ? Colors.white10 : Colors.black.withAlpha(12)),
          width: isSelected ? 2.0 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top: Airline & Badge
          Row(
            children: [
              Text(
                '$airline $flightNum'.trim(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (offer.badgeLabel != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    offer.badgeLabel!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Flight times & Route
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    depTime,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    offer.origin,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    duration,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.circle, size: 5, color: Colors.grey),
                      Container(
                        width: 20,
                        height: 1.5,
                        color: Colors.grey.withAlpha(120),
                      ),
                      Icon(
                        Icons.flight,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                      Container(
                        width: 20,
                        height: 1.5,
                        color: Colors.grey.withAlpha(120),
                      ),

                      const Icon(Icons.circle, size: 5, color: Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isDirect ? 'Diretto' : 'Con scalo',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDirect ? Colors.green[700] : Colors.orange[800],
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    arrTime,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    offer.destination,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Compromesso / Tradeoff
          Text(
            offer.tradeoffSummary,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Price & CTA Select
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '€ ${offer.priceEur.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    'a persona',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              if (isSelected)
                FilledButton.icon(
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: const Text('Continua sul sito del provider'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(48, 44),
                  ),
                  onPressed: () {
                    if (widget.onContinueToProvider != null) {
                      widget.onContinueToProvider!(offer);
                    } else {
                      widget.onOfferSelected(offer);
                    }
                  },
                )
              else
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Seleziona'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(48, 44),
                  ),
                  onPressed: () {
                    setState(() => _selectedOfferId = offer.id);
                    widget.onOfferSelected(offer);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}
