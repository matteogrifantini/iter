import 'package:flutter/material.dart';
import 'visual_media_service.dart';

class DestinationDetailSheet extends StatelessWidget {
  const DestinationDetailSheet({
    super.key,
    required this.visualData,
    this.onStartPlanning,
  });

  final DestinationVisualData visualData;
  final VoidCallback? onStartPlanning;

  static Future<void> show(
    BuildContext context, {
    required DestinationVisualData visualData,
    VoidCallback? onStartPlanning,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DestinationDetailSheet(
        visualData: visualData,
        onStartPlanning: onStartPlanning,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryImg = visualData.images.isNotEmpty ? visualData.images.first : '';

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.zero,
                  children: [
                    // Hero Image Banner
                    Stack(
                      children: [
                        if (primaryImg.isNotEmpty)
                          Image.network(
                            primaryImg,
                            height: 220,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 220,
                              color: colorScheme.surfaceContainerHighest,
                              child: const Icon(Icons.image_not_supported_outlined, size: 48),
                            ),
                          )
                        else
                          Container(
                            height: 220,
                            color: colorScheme.primaryContainer,
                          ),

                        // Gradient
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.75),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Close button
                        Positioned(
                          top: 12,
                          right: 16,
                          child: CircleAvatar(
                            backgroundColor: Colors.black45,
                            radius: 18,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                        ),

                        // Destination Title
                        Positioned(
                          bottom: 16,
                          left: 20,
                          right: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                visualData.destination,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                visualData.tagline,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Sezione 1: Quando andare
                          _SectionCard(
                            icon: Icons.calendar_month_rounded,
                            iconColor: Colors.orange.shade700,
                            title: 'Quando andare',
                            content: visualData.bestPeriod,
                            badge: visualData.climatePill,
                          ),
                          const SizedBox(height: 14),

                          // Sezione 2: Costi medi & Budget
                          _SectionCard(
                            icon: Icons.account_balance_wallet_rounded,
                            iconColor: Colors.teal.shade700,
                            title: 'Budget & Costi medi',
                            content: visualData.averageDailyCost,
                            badge: visualData.flightAdvicePill,
                          ),
                          const SizedBox(height: 14),

                          // Sezione 3: Mobilità
                          _SectionCard(
                            icon: Icons.directions_subway_rounded,
                            iconColor: Colors.blue.shade700,
                            title: 'Come muoversi',
                            content: visualData.transportPill,
                          ),
                          const SizedBox(height: 20),

                          // Sezione 4: Consigli Insider
                          Row(
                            children: [
                              const Text('💡', style: TextStyle(fontSize: 18)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Consigli da Insider per ${visualData.destination}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),
                          ...visualData.insiderTips.map((tip) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.check_circle_outline_rounded, size: 18, color: Colors.green),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      tip,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        height: 1.35,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),

                          if (visualData.highlights.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(
                              'Cosa non perdere',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: visualData.highlights.map((h) {
                                return Chip(
                                  avatar: const Icon(Icons.place_rounded, size: 14, color: Colors.redAccent),
                                  label: Text(h, style: const TextStyle(fontSize: 12)),
                                  backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                );
                              }).toList(),
                            ),
                          ],

                          const SizedBox(height: 28),

                          // CTA Button
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop();
                                onStartPlanning?.call();
                              },
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              icon: const Icon(Icons.flight_takeoff_rounded),
                              label: Text(
                                'Pianifica viaggio a ${visualData.destination}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.content,
    this.badge,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String content;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          if (badge != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: iconColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline_rounded, size: 13, color: iconColor),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      badge!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: iconColor,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
