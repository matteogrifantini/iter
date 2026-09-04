import 'package:flutter/material.dart';
import '../../ai/gemini_models.dart';

class AttractionsPickerSheet extends StatefulWidget {
  const AttractionsPickerSheet({
    super.key,
    required this.destination,
    required this.attractions,
    required this.initiallySelected,
    required this.onSave,
  });

  final String destination;
  final List<AttractionItem> attractions;
  final List<AttractionItem> initiallySelected;
  final ValueChanged<List<AttractionItem>> onSave;

  static Future<void> show(
    BuildContext context, {
    required String destination,
    required List<AttractionItem> attractions,
    required List<AttractionItem> initiallySelected,
    required ValueChanged<List<AttractionItem>> onSave,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AttractionsPickerSheet(
        destination: destination,
        attractions: attractions,
        initiallySelected: initiallySelected,
        onSave: onSave,
      ),
    );
  }

  @override
  State<AttractionsPickerSheet> createState() => _AttractionsPickerSheetState();
}

class _AttractionsPickerSheetState extends State<AttractionsPickerSheet> {
  late final Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = widget.initiallySelected.map((a) => a.id).toSet();
    // Se nessuna è inizialmente selezionata, pre-seleziona tutte
    if (_selectedIds.isEmpty) {
      _selectedIds.addAll(widget.attractions.map((a) => a.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.sizeOf(context);

    return Container(
      height: size.height * 0.85,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tappe & Monumenti',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_selectedIds.length} tappe selezionate per ${widget.destination}',
                      style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Chiudi',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: widget.attractions.length,
              itemBuilder: (context, index) {
                final item = widget.attractions[index];
                final isSelected = _selectedIds.contains(item.id);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected ? colorScheme.primary : colorScheme.outlineVariant.withValues(alpha: 0.3),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedIds.remove(item.id);
                        } else {
                          _selectedIds.add(item.id);
                        }
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: SizedBox(
                              width: 80,
                              height: 80,
                              child: Image.network(
                                item.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  color: colorScheme.primaryContainer,
                                  child: Icon(Icons.place_rounded, color: colorScheme.primary),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        item.category,
                                        style: TextStyle(
                                          color: colorScheme.onPrimaryContainer,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '~${item.estimatedTimeMinutes} min',
                                      style: TextStyle(color: colorScheme.outline, fontSize: 11),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.why,
                                  style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12, height: 1.25),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Checkbox(
                            value: isSelected,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedIds.add(item.id);
                                } else {
                                  _selectedIds.remove(item.id);
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom Action
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(top: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3))),
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    final selected = widget.attractions.where((a) => _selectedIds.contains(a.id)).toList();
                    widget.onSave(selected);
                    Navigator.of(context).pop();
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    'Salva ${_selectedIds.length} tappe nel viaggio',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
