import 'package:flutter/material.dart';
import '../../places/visual_media_service.dart';
import '../../places/destination_detail_sheet.dart';

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
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final images = widget.visualData.images;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Visual Carousel (toccabile per aprire la scheda a tutto schermo)
          InkWell(
            onTap: () => DestinationDetailSheet.show(
              context,
              visualData: widget.visualData,
            ),
            child: SStack(
              images: images,
              pageController: _pageController,
              onPageChanged: (idx) => setState(() => _currentPage = idx),
              currentPage: _currentPage,
              destination: widget.visualData.destination,
            ),
          ),


          // Content & Insights
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.visualData.tagline,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),

                // Pillole Informative Veloci (Clima, Mobilità, Prezzo)
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _PillBadge(
                      icon: Icons.wb_sunny_outlined,
                      label: widget.visualData.climatePill,
                      color: Colors.orange.shade700,
                      bg: Colors.orange.withValues(alpha: 0.12),
                    ),
                    _PillBadge(
                      icon: Icons.directions_subway_outlined,
                      label: widget.visualData.transportPill,
                      color: Colors.blue.shade700,
                      bg: Colors.blue.withValues(alpha: 0.12),
                    ),
                    _PillBadge(
                      icon: Icons.confirmation_number_outlined,
                      label: widget.visualData.flightAdvicePill,
                      color: Colors.teal.shade700,
                      bg: Colors.teal.withValues(alpha: 0.12),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: () => DestinationDetailSheet.show(
                      context,
                      visualData: widget.visualData,
                    ),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.info_outline_rounded, size: 18),
                    label: Text(
                      'Scopri ${widget.visualData.destination} · Info, periodo & costi',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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

class SStack extends StatelessWidget {
  const SStack({
    super.key,
    required this.images,
    required this.pageController,
    required this.onPageChanged,
    required this.currentPage,
    required this.destination,
  });

  final List<String> images;
  final PageController pageController;
  final ValueChanged<int> onPageChanged;
  final int currentPage;
  final String destination;

  @override
  Widget build(BuildContext context) {
    return SizedBox(

      height: 200,
      width: double.infinity,
      child: Stack(
        children: [
          PageView.builder(
            controller: pageController,
            onPageChanged: onPageChanged,
            itemCount: images.length,
            itemBuilder: (context, index) {
              return Image.network(
                images[index],
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey.shade300,
                  child: const Center(child: Icon(Icons.image_not_supported_outlined, size: 40)),
                ),
              );
            },
          ),

          // Gradient overlay
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.65),
                  ],
                ),
              ),
            ),
          ),

          // Destination title on photo
          Positioned(
            bottom: 12,
            left: 16,
            child: Text(
              destination,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
              ),
            ),
          ),

          // Dots Indicator
          if (images.length > 1)
            Positioned(
              bottom: 14,
              right: 16,
              child: Row(
                children: List.generate(images.length, (idx) {
                  final isActive = idx == currentPage;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    width: isActive ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isActive ? Colors.white : Colors.white54,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

class _PillBadge extends StatelessWidget {
  const _PillBadge({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
