import 'package:flutter/material.dart';

class DiscoverItem {
  const DiscoverItem({
    required this.name,
    required this.country,
    required this.highlights,
    required this.recommendedDays,
    required this.imageUrl,
    required this.tag,
  });

  final String name;
  final String country;
  final String highlights;
  final int recommendedDays;
  final String imageUrl;
  final String tag;
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
      highlights: 'Templi zen millenari, boschi di bambù ad Arashiyama e giardini meditativi.',
      recommendedDays: 5,
      imageUrl: 'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?w=800&q=80',
      tag: 'Spiritualità & Tradizione',
    ),
    DiscoverItem(
      name: 'Dolomiti',
      country: 'Italia',
      highlights: 'Vette maestose al tramonto, rifugi alpini e il foliage dorato dei larici.',
      recommendedDays: 4,
      imageUrl: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=800&q=80',
      tag: 'Natura & Panorami',
    ),
    DiscoverItem(
      name: 'Islanda del Sud',
      country: 'Islanda',
      highlights: 'Cascate potenti tra i ghiacciai, spiagge vulcaniche nere e sorgenti geotermali.',
      recommendedDays: 6,
      imageUrl: 'https://images.unsplash.com/photo-1504893524553-b855bce32c67?w=800&q=80',
      tag: 'Avventura Incontaminata',
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
          separatorBuilder: (_, _) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final item = _discoveries[index];
            return InkWell(
              onTap: () => onSelectDestination(item.name),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                height: 120,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Immagine foto quadrata con bordi arrotondati
                    SizedBox(
                      width: 120,
                      height: double.infinity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            item.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              color: colorScheme.primaryContainer,
                              child: Icon(Icons.terrain_rounded, color: colorScheme.primary),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.35),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${item.recommendedDays} giorni',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Testi e dettagli
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    item.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '• ${item.country}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.outline,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.tag,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.highlights,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 11,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Icona freccia
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: colorScheme.outline,
                      ),
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
