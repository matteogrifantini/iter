import 'package:flutter/material.dart';
import '../../ai/gemini_models.dart';

class AttractionCurationCard extends StatefulWidget {
  const AttractionCurationCard({
    super.key,
    required this.destination,
    required this.attractions,
    required this.onConfirmed,
  });

  final String destination;
  final List<AttractionItem> attractions;
  final ValueChanged<List<AttractionItem>> onConfirmed;

  @override
  State<AttractionCurationCard> createState() => _AttractionCurationCardState();
}

class _AttractionCurationCardState extends State<AttractionCurationCard> {
  final Set<String> _selectedIds = {};
  bool _isConfirmed = false;

  @override
  void initState() {
    super.initState();
    // Di default seleziona le prime 2 per agevolare il viaggiatore
    if (widget.attractions.isNotEmpty) {
      _selectedIds.add(widget.attractions.first.id);
      if (widget.attractions.length > 1) {
        _selectedIds.add(widget.attractions[1].id);
      }
    }
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  List<AttractionItem> get _selectedItems {
    return widget.attractions.where((a) => _selectedIds.contains(a.id)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isConfirmed) {
      final names = _selectedItems.map((a) => a.name).join(', ');
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
        ),
        child: Row(
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
                    '✓ ${_selectedItems.length} attrazioni scelte per ${widget.destination}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    names,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _isConfirmed = false),
              child: const Text('Modifica'),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
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
                      'Cosa vorresti vedere a ${widget.destination}?',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Scegli cosa ti ispira: calcoleremo la zona migliore per dormire.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Lista Attrazioni interattive
          ...widget.attractions.map((item) {
            final isLiked = _selectedIds.contains(item.id);
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isLiked
                    ? colorScheme.primaryContainer.withValues(alpha: 0.25)
                    : colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isLiked
                      ? colorScheme.primary.withValues(alpha: 0.6)
                      : colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Immagine
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      item.imageUrl,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 72,
                        height: 72,
                        color: colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.photo_size_select_actual_outlined, size: 28),
                      ),

                    ),
                  ),
                  const SizedBox(width: 12),

                  // Dettagli
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.category,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSecondaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.why,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Azioni Mi piace / Salta
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                if (isLiked) _toggleSelection(item.id);
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                foregroundColor: !isLiked ? colorScheme.outline : colorScheme.onSurfaceVariant,
                              ),
                              icon: const Icon(Icons.close_rounded, size: 16),
                              label: const Text('Salta', style: TextStyle(fontSize: 12)),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.tonalIcon(
                              onPressed: () => _toggleSelection(item.id),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                backgroundColor: isLiked ? Colors.green.shade600 : colorScheme.primaryContainer,
                                foregroundColor: isLiked ? Colors.white : colorScheme.onPrimaryContainer,
                              ),
                              icon: Icon(
                                isLiked ? Icons.check_circle_rounded : Icons.favorite_border_rounded,
                                size: 16,
                              ),
                              label: Text(
                                isLiked ? 'Mi piace' : 'Mi piace',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
          }),

          // Riepilogo & Conferma
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '${_selectedIds.length} selezionati',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: _selectedIds.isNotEmpty ? colorScheme.primary : colorScheme.outline,
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _selectedIds.isEmpty
                    ? null
                    : () {
                        setState(() => _isConfirmed = true);
                        widget.onConfirmed(_selectedItems);
                      },
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: const Text(
                  'Conferma e trova alloggi',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
