import 'package:flutter/material.dart';

class DiscoverItem {
  const DiscoverItem({
    required this.name,
    required this.country,
    required this.highlights,
    required this.recommendedDays,
  });

  final String name;
  final String country;
  final String highlights;
  final int recommendedDays;
}

class HomeDiscoverSection extends StatelessWidget {
  const HomeDiscoverSection({
    super.key,
    required this.onSelectDestination,
  });

  final ValueChanged<String> onSelectDestination;

  static const List<DiscoverItem> _discoveries = [
    DiscoverItem(
      name: 'Kyoto',
      country: 'Giappone',
      highlights: 'Templi zen, boschi di bambù e cucina kaiseki.',
      recommendedDays: 5,
    ),
    DiscoverItem(
      name: 'Islanda del Sud',
      country: 'Islanda',
      highlights: 'Cascate potenti, spiagge nere vulcaniche e aurore.',
      recommendedDays: 6,
    ),
    DiscoverItem(
      name: 'Dolomiti',
      country: 'Italia',
      highlights: 'Sentieri tra vette alpine, rifugi storici e silenzi.',
      recommendedDays: 4,
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Scopri nuovi posti',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              'Mete d\'ispirazione',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.outline,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _discoveries.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = _discoveries[index];
            return InkWell(
              onTap: () => onSelectDestination(item.name),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.explore_rounded,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                item.name,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '• ${item.country}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.highlights,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      color: colorScheme.primary,
                      tooltip: 'Pianifica viaggio a ${item.name}',
                      onPressed: () => onSelectDestination(item.name),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
