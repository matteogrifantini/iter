import 'package:flutter/material.dart';
import '../../models/organization_card.dart';
import '../../models/organization_models.dart';

/// Widget per il confronto degli alloggi o la segnalazione onesta di assenza di provider alloggi.
class StayComparisonCardView extends StatelessWidget {
  const StayComparisonCardView({
    super.key,
    required this.card,
    required this.onOfferSelected,
    this.onSelfBookConfirmed,
  });

  final OrganizationCard card;
  final ValueChanged<ProviderOffer> onOfferSelected;
  final VoidCallback? onSelfBookConfirmed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final rawOffers = card.payload['offers'] as List?;
    final offers =
        rawOffers?.whereType<ProviderOffer>().toList() ??
        const <ProviderOffer>[];

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
                  color: theme.colorScheme.secondary.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.hotel_outlined,
                  size: 18,
                  color: theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  card.title ?? 'Alloggi consigliati',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (offers.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withAlpha(50),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withAlpha(80),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Nessun provider alloggi configurato o collegato. Nessun dato inventato.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Iter non genera hotel fittizi. Puoi prenotare autonomamente il tuo alloggio preferito nella zona selezionata e confermarlo per procedere con la generazione del piano di viaggio.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('Conferma alloggio autonomo'),
                    onPressed: onSelfBookConfirmed,
                  ),
                ],
              ),
            ),
          ] else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: offers.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final offer = offers[index];
                return ListTile(
                  title: Text(
                    offer.conditions['name']?.toString() ?? offer.destination,
                  ),
                  subtitle: Text(
                    '€ ${offer.priceEur.toStringAsFixed(2)} - ${offer.tradeoffSummary}',
                  ),
                  trailing: FilledButton(
                    onPressed: () => onOfferSelected(offer),
                    child: const Text('Seleziona'),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
