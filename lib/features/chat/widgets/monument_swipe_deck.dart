import 'package:flutter/material.dart';
import '../../ai/gemini_models.dart';
import '../../places/attraction_detail_sheet.dart';


class MonumentSwipeDeck extends StatefulWidget {
  const MonumentSwipeDeck({
    super.key,
    required this.destination,
    required this.attractions,
    required this.durationDays,
    required this.onConfirmed,
  });

  final String destination;
  final List<AttractionItem> attractions;
  final int durationDays;
  final ValueChanged<List<AttractionItem>> onConfirmed;

  @override
  State<MonumentSwipeDeck> createState() => _MonumentSwipeDeckState();
}

class _MonumentSwipeDeckState extends State<MonumentSwipeDeck> {
  int _currentIndex = 0;
  final List<AttractionItem> _accepted = [];
  final List<AttractionItem> _rejected = [];
  bool _isFinished = false;

  void _swipe(bool accept) {
    if (_currentIndex >= widget.attractions.length) return;
    final item = widget.attractions[_currentIndex];
    setState(() {
      if (accept) {
        _accepted.add(item);
      } else {
        _rejected.add(item);
      }
      _currentIndex++;
      if (_currentIndex >= widget.attractions.length) {
        _isFinished = true;
      }
    });
  }

  int get _totalVisitingMinutes {
    return _accepted.fold(0, (sum, item) => sum + item.estimatedTimeMinutes);
  }

  double get _totalVisitingHours => _totalVisitingMinutes / 60.0;

  bool get _isOverloaded {
    // Più di 2 attrazioni grandi al giorno comincia a essere denso
    final maxRecommended = widget.durationDays * 2;
    return _accepted.length > maxRecommended;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isFinished) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '✓ ${_accepted.length} attrazioni scelte per ${widget.destination}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        'Stima visite: ${_totalVisitingHours.toStringAsFixed(1)} ore complessive',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _currentIndex = 0;
                      _accepted.clear();
                      _rejected.clear();
                      _isFinished = false;
                    });
                  },
                  child: const Text('Ricomincia'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _accepted.map((item) {
                return Chip(
                  avatar: const Icon(Icons.place_rounded, size: 14, color: Colors.green),
                  label: Text(item.name, style: const TextStyle(fontSize: 12)),
                  backgroundColor: colorScheme.surface,
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => widget.onConfirmed(_accepted),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: const Text(
                  'Conferma scelte e trova alloggi nella zona ideale',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final currentItem = widget.attractions[_currentIndex];
    final remainingCount = widget.attractions.length - _currentIndex;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('🏛️', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scegli cosa vedere a ${widget.destination}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Swipa o tocca ❤️ per salvare le tue tappe imperdibili ($remainingCount rimanenti)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Physical Card stile Tinder con gesture
          Dismissible(
            key: ValueKey(currentItem.id),
            onDismissed: (direction) {
              if (direction == DismissDirection.endToStart) {
                _swipe(false); // Swipe sinistra = Salta
              } else {
                _swipe(true); // Swipe destra = Mi piace
              }
            },
            background: Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 24),
              decoration: BoxDecoration(
                color: Colors.green.shade600,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.favorite_rounded, color: Colors.white, size: 36),
                  SizedBox(width: 8),
                  Text('MI PIACE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
            secondaryBackground: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              decoration: BoxDecoration(
                color: Colors.red.shade400,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('SALTA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(width: 8),
                  Icon(Icons.close_rounded, color: Colors.white, size: 36),
                ],
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Immagine + Categoria
                  Stack(
                    children: [
                      Image.network(
                        currentItem.imageUrl,
                        height: 170,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 170,
                          color: colorScheme.surfaceContainerHighest,
                          child: const Center(child: Icon(Icons.photo_library_outlined, size: 48)),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            currentItem.category,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.schedule_rounded, size: 14, color: Colors.orange),
                              const SizedBox(width: 4),
                              Text(
                                '~${currentItem.estimatedTimeMinutes} min',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Info & Why
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                currentItem.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.info_outline_rounded, size: 20),
                              tooltip: 'Scheda approfondita',
                              onPressed: () => AttractionDetailSheet.show(
                                context,
                                attraction: currentItem,
                                onLike: () => _swipe(true),
                                onSkip: () => _swipe(false),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentItem.why,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),


                  // Bottoni interattivi Salta / Mi piace
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _swipe(false),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              foregroundColor: colorScheme.onSurfaceVariant,
                            ),
                            icon: const Icon(Icons.close_rounded),
                            label: const Text('Salta'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _swipe(true),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: const Icon(Icons.favorite_rounded),
                            label: const Text('Mi piace', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Stima carico e avviso di sovraccarico (Overload Warning)
          if (_accepted.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _isOverloaded
                    ? Colors.amber.withValues(alpha: 0.15)
                    : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isOverloaded ? Colors.amber.shade700 : colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isOverloaded ? Icons.warning_amber_rounded : Icons.speed_rounded,
                    size: 18,
                    color: _isOverloaded ? Colors.amber.shade800 : colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isOverloaded
                          ? 'Ritmo intenso: ${_accepted.length} tappe (~${_totalVisitingHours.toStringAsFixed(1)}h) in ${widget.durationDays} giorni. Considera di tenerne qualcuna in meno per non correre!'
                          : '${_accepted.length} attrazioni scelte (~${_totalVisitingHours.toStringAsFixed(1)}h totali). Ritmo equilibrato!',
                      style: TextStyle(
                        fontSize: 11,
                        color: _isOverloaded ? Colors.amber.shade900 : colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
