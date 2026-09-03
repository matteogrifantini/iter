import 'package:flutter/material.dart';
import '../../models/organization_card.dart';

/// Widget per la proposta e selezione delle zone consigliate della destinazione.
class ZoneProposalCardView extends StatelessWidget {
  const ZoneProposalCardView({
    super.key,
    required this.card,
    required this.onZoneSelected,
  });

  final OrganizationCard card;
  final ValueChanged<String> onZoneSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final rawZones =
        card.payload['zoneNames'] as List? ?? card.payload['zones'] as List?;
    final zones =
        rawZones?.map((e) => e.toString()).toList() ??
        card.actions.map((a) => a.label).toList();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B222C) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black.withAlpha(15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 25 : 8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.location_on_outlined,
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
                      card.title ?? 'Scegli dove alloggiare',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (card.description != null)
                      Text(
                        card.description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (zones.isEmpty)
            Text(
              'Nessuna zona consigliata disponibile.',
              style: theme.textTheme.bodySmall,
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: zones.map((zone) {
                return ActionChip(
                  avatar: const Icon(Icons.maps_home_work_outlined, size: 16),
                  label: Text(zone),
                  onPressed: () => onZoneSelected(zone),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
