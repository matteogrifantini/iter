import 'package:flutter/material.dart';
import '../../ai/gemini_models.dart';

class CostBreakdownCard extends StatelessWidget {
  const CostBreakdownCard({
    super.key,
    required this.destination,
    required this.durationDays,
    required this.plan,
    required this.onOpenSnapshot,
  });

  final String destination;
  final int durationDays;
  final GeminiTripPlanDraft plan;
  final VoidCallback onOpenSnapshot;

  int get _flightCost {
    if (plan.flight?.priceEstimate != null) {
      final match = RegExp(r'(\d+)').firstMatch(plan.flight!.priceEstimate);
      if (match != null) {
        return int.tryParse(match.group(1)!) ?? 75;
      }
    }
    return 75;
  }

  int get _stayCostPerNight {
    if (plan.selectedStay != null) {
      return plan.selectedStay!.pricePerNightEur.round();
    }
    return 85;
  }

  int get _stayTotal {
    final nights = (durationDays - 1).clamp(1, 30);
    return _stayCostPerNight * nights;
  }

  int get _attractionCost {
    // Media 10-15€ per attrazione scelta
    final count = plan.attractions.length.clamp(2, 8);
    return count * 12;
  }

  int get _dailyFoodAndTransport {
    // 40€ al giorno per pasti e mezzi
    return durationDays * 40;
  }

  int get _totalEstimatedCost {
    return _flightCost + _stayTotal + _attractionCost + _dailyFoodAndTransport;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final nights = (durationDays - 1).clamp(1, 30);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.teal, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preventivo Trasparente · $destination',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Stima completa per $durationDays giorni ($nights notti) a persona',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Voci di costo
          _CostRow(
            icon: Icons.flight_rounded,
            label: 'Volo a/r da Roma',
            sublabel: plan.flight?.priceEstimate.isNotEmpty == true
                ? plan.flight!.priceEstimate
                : 'Stima voli diretti',
            amount: '$_flightCost €',
            color: Colors.blue.shade700,
          ),
          const Divider(height: 16),

          _CostRow(
            icon: Icons.hotel_rounded,
            label: 'Soggiorno ($nights notti)',
            sublabel: plan.selectedStay != null
                ? '${plan.selectedStay!.name} ($_stayCostPerNight€/notte)'
                : 'Stima alloggio centrale baricentrico',

            amount: '$_stayTotal €',
            color: Colors.indigo.shade700,
          ),
          const Divider(height: 16),

          _CostRow(
            icon: Icons.confirmation_number_outlined,
            label: 'Monumenti & Ingressi',
            sublabel: '${plan.attractions.length > 1 ? plan.attractions.length : 3} tappe selezionate',
            amount: '$_attractionCost €',
            color: Colors.amber.shade800,
          ),
          const Divider(height: 16),

          _CostRow(
            icon: Icons.restaurant_rounded,
            label: 'Cibo, Caffè & Metro',
            sublabel: 'Stima pasti tipici & spostamenti (~40€/giorno)',
            amount: '$_dailyFoodAndTransport €',
            color: Colors.green.shade700,
          ),
          const SizedBox(height: 16),

          // Totale Finale Evidenziato
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TOTALE STIMATO VIAGGIO',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      'Zero costi nascosti · Tutto pianificato',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                Text(
                  '$_totalEstimatedCost €',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Action Button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onOpenSnapshot,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.map_rounded),
              label: const Text(
                'Salva viaggio & vedi itinerario completo',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CostRow extends StatelessWidget {
  const _CostRow({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.amount,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String sublabel;
  final String amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Text(
                sublabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        Text(
          amount,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }
}
