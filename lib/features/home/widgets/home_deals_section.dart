import 'package:flutter/material.dart';

class TravelDeal {
  const TravelDeal({
    required this.destination,
    required this.tag,
    required this.priceEstimate,
    required this.duration,
    required this.description,
    required this.imageUrl,
  });

  final String destination;
  final String tag;
  final String priceEstimate;
  final String duration;
  final String description;
  final String imageUrl;
}

class HomeDealsSection extends StatelessWidget {
  const HomeDealsSection({
    super.key,
    required this.onSelectDestination,
  });

  final ValueChanged<String> onSelectDestination;

  static const List<TravelDeal> _sampleDeals = [
    TravelDeal(
      destination: 'Siviglia',
      tag: 'Cultura & Tapas',
      priceEstimate: 'da 54€',
      duration: '4 giorni',
      description: 'Quartieri storici, flamenco autentico e clima mite.',
      imageUrl: 'https://images.unsplash.com/photo-1559564484-e48b3e040ff4?w=600&q=80',
    ),
    TravelDeal(
      destination: 'Lisbona',
      tag: 'Weekend sull\'Oceano',
      priceEstimate: 'da 48€',
      duration: '3 giorni',
      description: 'Miradouro panoramici, tram storici e pastel de nata caldi.',
      imageUrl: 'https://images.unsplash.com/photo-1508849789987-4e5333c12b78?w=600&q=80',
    ),
    TravelDeal(
      destination: 'Edimburgo',
      tag: 'Borghi & Castelli',
      priceEstimate: 'da 62€',
      duration: '4 giorni',
      description: 'Atmosfere gotiche, pub d\'epoca e natura incontaminata.',
      imageUrl: 'https://images.unsplash.com/photo-1506377247377-2a5b3b417ebb?w=600&q=80',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Consigli & Offerte per te',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Basati sul tuo profilo',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _sampleDeals.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final deal = _sampleDeals[index];
              return _DealCard(
                deal: deal,
                onTap: () => onSelectDestination(deal.destination),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DealCard extends StatelessWidget {
  const _DealCard({
    required this.deal,
    required this.onTap,
  });

  final TravelDeal deal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      deal.tag,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  deal.priceEstimate,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              deal.destination,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              deal.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Flexible(
                  child: Text(
                    'Pianifica con Iter',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: colorScheme.primary,
                ),
              ],
            ),
          ],
        ),
      ),

    );
  }
}

