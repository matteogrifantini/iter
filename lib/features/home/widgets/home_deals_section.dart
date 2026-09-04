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
      destination: 'Valencia',
      tag: 'Cultura & Paella',
      priceEstimate: 'da 54€',
      duration: '4 giorni',
      description: 'Città delle Arti, giardini del Turia e clima mite.',
      imageUrl: 'https://images.unsplash.com/photo-1579282240050-352db0a14c21?w=800&q=80',
    ),
    TravelDeal(
      destination: 'Lisbona',
      tag: 'Weekend sull\'Oceano',
      priceEstimate: 'da 48€',
      duration: '3 giorni',
      description: 'Miradouro panoramici, tram storici e pastel de nata caldi.',
      imageUrl: 'https://images.unsplash.com/photo-1508849789987-4e5333c12b78?w=800&q=80',
    ),
    TravelDeal(
      destination: 'Edimburgo',
      tag: 'Borghi & Castelli',
      priceEstimate: 'da 62€',
      duration: '4 giorni',
      description: 'Atmosfere gotiche, pub d\'epoca e natura incontaminata.',
      imageUrl: 'https://images.unsplash.com/photo-1506377247377-2a5b3b417ebb?w=800&q=80',
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
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 260,
        height: 220,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Immagine di copertina
            Image.network(
              deal.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: colorScheme.primaryContainer,
                child: Center(
                  child: Icon(Icons.photo_outlined, color: colorScheme.primary, size: 36),
                ),
              ),
            ),

            // Gradient per contrasto
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.75),
                    Colors.black.withValues(alpha: 0.92),
                  ],
                  stops: const [0.0, 0.30, 0.70, 1.0],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // Top: Tag + Prezzo
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        deal.tag,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE7FF67), // Possibilità Iter
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      deal.priceEstimate,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF18204B), // Ink
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom: Dettagli destinazione
            Positioned(
              left: 14,
              right: 14,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          deal.destination,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '• ${deal.duration}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    deal.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontSize: 11,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Pianifica con Iter',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE7FF67),
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 13,
                        color: Color(0xFFE7FF67),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
