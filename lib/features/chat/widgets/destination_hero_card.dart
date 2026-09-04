import 'package:flutter/material.dart';
import '../../places/visual_media_service.dart';
import '../../places/destination_detail_sheet.dart';

/// Redesigned Destination Hero Card for chat:
/// - Vertical, sleek proportions (~220px height) like home reels.
/// - Vibrant, clear photos (no muddy black overlays).
/// - Swipeable photo carousel with smooth dot indicators.
/// - Prominent, clean CTA pill "[ ℹ️ Scopri di più su Destination ]" opening DestinationDetailSheet.
class DestinationHeroCard extends StatefulWidget {
  const DestinationHeroCard({
    super.key,
    required this.visualData,
    this.onExploreAttractions,
  });

  final DestinationVisualData visualData;
  final VoidCallback? onExploreAttractions;

  @override
  State<DestinationHeroCard> createState() => _DestinationHeroCardState();
}

class _DestinationHeroCardState extends State<DestinationHeroCard> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openDetails() {
    DestinationDetailSheet.show(
      context,
      visualData: widget.visualData,
      onStartPlanning: () {
        widget.onExploreAttractions?.call();
      },
    );
  }




  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final images = widget.visualData.images.isNotEmpty
        ? widget.visualData.images
        : ['https://images.unsplash.com/photo-1534447677768-be436bb09401?w=800&q=80'];

    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 10),
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Carosello Foto ad alta definizione
          PageView.builder(
            controller: _pageController,
            itemCount: images.length,
            onPageChanged: (page) => setState(() => _currentPage = page),
            itemBuilder: (context, index) {
              return Image.network(
                images[index],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: colorScheme.primaryContainer,
                  child: Center(
                    child: Icon(Icons.landscape_rounded, color: colorScheme.primary, size: 48),
                  ),
                ),
              );
            },
          ),

          // 2. Scrim sfumato trasparente SOLO in basso (nessun nero fango totale!)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.15),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.4),
                    Colors.black.withValues(alpha: 0.85),
                  ],
                  stops: const [0.0, 0.35, 0.65, 1.0],
                ),
              ),
            ),
          ),

          // 3. Indicatore dot carousel in alto a destra
          if (images.length > 1)
            Positioned(
              top: 14,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(images.length, (idx) {
                    final isSel = idx == _currentPage;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      width: isSel ? 14 : 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isSel ? Colors.white : Colors.white54,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ),
            ),

          // 4. Badge Destinazione & Tagline in alto a sinistra
          Positioned(
            top: 14,
            left: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 0.8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.photo_library_outlined, color: Colors.white, size: 13),
                  SizedBox(width: 5),
                  Text(
                    'Scorri foto',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),

          // 5. Contenuto Inferiore: Destinazione, Clima e CTA "Scopri di più"
          Positioned(
            left: 16,
            right: 16,
            bottom: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.visualData.destination,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.visualData.climatePill,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _openDetails,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.info_outline_rounded, size: 15, color: colorScheme.primary),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Scopri di più su ${widget.visualData.destination}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: colorScheme.primary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.arrow_forward_ios_rounded, size: 11, color: colorScheme.primary),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
