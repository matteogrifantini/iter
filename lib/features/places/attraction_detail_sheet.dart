import 'package:flutter/material.dart';
import '../ai/gemini_models.dart';

class AttractionDetailSheet extends StatelessWidget {
  const AttractionDetailSheet({
    super.key,
    required this.attraction,
    this.onLike,
    this.onSkip,
  });

  final AttractionItem attraction;
  final VoidCallback? onLike;
  final VoidCallback? onSkip;

  static Future<void> show(
    BuildContext context, {
    required AttractionItem attraction,
    VoidCallback? onLike,
    VoidCallback? onSkip,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AttractionDetailSheet(
        attraction: attraction,
        onLike: onLike,
        onSkip: onSkip,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.45,
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
                    // Monument Photo Banner
                    Stack(
                      children: [
                        Image.network(
                          attraction.imageUrl,
                          height: 220,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 220,
                            color: colorScheme.surfaceContainerHighest,
                            child: const Icon(Icons.account_balance_rounded, size: 54),
                          ),
                        ),
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
                        Positioned(
                          bottom: 16,
                          left: 20,
                          right: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  attraction.category,
                                  style: TextStyle(
                                    color: colorScheme.onPrimary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                attraction.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
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
                          // Tempo di visita & Orario consigliato
                          Row(
                            children: [
                              _Pill(
                                icon: Icons.schedule_rounded,
                                label: '~${attraction.estimatedTimeMinutes} min di visita',
                                color: Colors.orange.shade800,
                                bg: Colors.orange.withValues(alpha: 0.12),
                              ),
                              const SizedBox(width: 8),
                              _Pill(
                                icon: Icons.wb_twilight_rounded,
                                label: 'Mattina o Tramonto',
                                color: Colors.indigo.shade800,
                                bg: Colors.indigo.withValues(alpha: 0.12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // Cosa sapere & Perché vederlo
                          Text(
                            'Perché non perderlo',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            attraction.why,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.4,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Consigli pratici di visita
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.info_outline_rounded, size: 18, color: Colors.teal),
                                    SizedBox(width: 8),
                                    Text(
                                      'Consigli pratici di visita',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '• Arriva con 15 minuti di anticipo se hai acquistato il biglietto orario salta-fila.\n• Scarica l\'audioguida ufficiale sul telefono per apprezzare i dettagli architettonici.\n• Scarpe comode: il pavimento storico può essere irregolare.',
                                  style: TextStyle(fontSize: 12, height: 1.4),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 28),

                          // Bottoni Azione
                          Row(
                            children: [
                              if (onSkip != null)
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      onSkip?.call();
                                    },
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                    child: const Text('Salta tappa'),
                                  ),
                                ),
                              if (onSkip != null) const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: FilledButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    onLike?.call();
                                  },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.green.shade600,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  icon: const Icon(Icons.favorite_rounded),
                                  label: const Text(
                                    'Aggiungi all\'itinerario',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
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
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
