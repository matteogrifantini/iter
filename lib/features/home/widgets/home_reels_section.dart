import 'package:flutter/material.dart';

class ReelItem {

  const ReelItem({
    required this.destination,
    required this.title,
    required this.subtitle,
    required this.videoAsset,
    required this.posterAsset,
    required this.tag,
  });

  final String destination;
  final String title;
  final String subtitle;
  final String videoAsset;
  final String posterAsset;
  final String tag;
}

class HomeReelsSection extends StatelessWidget {
  const HomeReelsSection({
    super.key,
    required this.onSelectDestination,
  });

  final ValueChanged<String> onSelectDestination;

  static const List<ReelItem> _reels = [
    ReelItem(
      destination: 'Lisbona',
      title: 'Lisbona',
      subtitle: 'Tram 28 e le vie di Alfama',
      videoAsset: 'assets/videos/vertical/lisbon_street.mp4',
      posterAsset: 'assets/images/travel/lisbon_street.jpg',
      tag: 'Vibe urbana',
    ),
    ReelItem(
      destination: 'Porto',
      title: 'Porto',
      subtitle: 'Tramonto sul fiume Douro',
      videoAsset: 'assets/videos/vertical/porto_river.mp4',
      posterAsset: 'assets/images/travel/porto_river.jpg',
      tag: 'Scorci unici',
    ),
    ReelItem(
      destination: 'Roma',
      title: 'Roma',
      subtitle: 'I Fori Imperiali all\'ora d\'oro',
      videoAsset: 'assets/videos/vertical/rome_city.mp4',
      posterAsset: 'assets/images/travel/rome_city.jpg',
      tag: 'Storia viva',
    ),
    ReelItem(
      destination: 'Barcellona',
      title: 'Barcellona',
      subtitle: 'Architettura & Street life',
      videoAsset: 'assets/videos/vertical/barcelona_street.mp4',
      posterAsset: 'assets/images/travel/barcelona_street.jpg',
      tag: 'Arte & Mare',
    ),
    ReelItem(
      destination: 'Genova',
      title: 'Costa Ligure',
      subtitle: 'Rotta panoramica sul mare',
      videoAsset: 'assets/videos/coastal_rail.mp4',
      posterAsset: 'assets/images/travel/rail_coast.jpg',
      tag: 'In treno',
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
            Expanded(
              child: Row(
                children: [
                  const Text('🎬', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Momenti & Atmosfere',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Video dal vivo',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),
        Text(
          'Lasciati ispirare dai luoghi in movimento',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.outline,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 230,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _reels.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final reel = _reels[index];
              return _ReelCard(
                reel: reel,
                onTap: () => onSelectDestination(reel.destination),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ReelCard extends StatelessWidget {
  const _ReelCard({
    required this.reel,
    required this.onTap,
  });

  final ReelItem reel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 145,
        height: 230,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Copertina fotografica fluida e ad alte prestazioni
            Image.asset(
              reel.posterAsset,
              fit: BoxFit.cover,
            ),


            // Gradient per leggibilità testi
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.15),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.75),
                    Colors.black.withValues(alpha: 0.90),
                  ],
                  stops: const [0.0, 0.4, 0.75, 1.0],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // Tag in alto
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Text(
                  reel.tag,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            // Badge video live
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),

            // Info in basso
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    reel.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    reel.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 11,
                      height: 1.2,
                    ),
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
