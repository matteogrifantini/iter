import 'package:flutter/material.dart';
import '../../../widgets/journey_media.dart';

class HomeHeroBanner extends StatelessWidget {
  const HomeHeroBanner({
    super.key,
    required this.onOpenNewTripChat,
    this.onSelectDestination,
  });

  final VoidCallback onOpenNewTripChat;
  final ValueChanged<String>? onSelectDestination;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Video con fallback foto ad alta risoluzione (IgnorePointer evita che il platform-view Web catturi tap)
          Positioned.fill(
            child: IgnorePointer(
              child: JourneyVideo(
                asset: 'assets/videos/coastal_rail.mp4',
                placeholderAsset: 'assets/images/travel/rail_coast.jpg',
                autoplay: true,
                showControl: false,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),

          // Vignette gradient per leggibilità perfetta del testo e del bottone
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.30),
                    Colors.black.withValues(alpha: 0.55),
                    Colors.black.withValues(alpha: 0.85),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // Contenuto testuale snello e diretto
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Headline forte e pulita
                const Text(
                  'Dove ti porta il tuo\nprossimo viaggio?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    height: 1.15,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 18),

                // Bottone Principale CTA
                ElevatedButton.icon(
                  onPressed: onOpenNewTripChat,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: colorScheme.primary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.flight_takeoff_rounded, size: 20),
                  label: const Text(
                    'Organizza un nuovo viaggio',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
