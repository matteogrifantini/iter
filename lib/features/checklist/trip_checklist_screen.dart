import 'package:flutter/material.dart';
import 'trip_checklist_models.dart';
import 'trip_checklist_service.dart';

/// Screen allowing travelers to manage packing checklist and required documents.
class TripChecklistScreen extends StatefulWidget {
  const TripChecklistScreen({
    super.key,
    required this.tripId,
    required this.destination,
  });

  final String tripId;
  final String destination;

  @override
  State<TripChecklistScreen> createState() => _TripChecklistScreenState();
}

class _TripChecklistScreenState extends State<TripChecklistScreen> {
  final _service = const TripChecklistService();
  List<ChecklistItem> _items = [];
  bool _loading = true;
  final _newItemController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _newItemController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final list = await _service.loadChecklist(
      widget.tripId,
      widget.destination,
    );
    if (mounted) {
      setState(() {
        _items = list;
        _loading = false;
      });
    }
  }

  void _toggleItem(ChecklistItem item) {
    setState(() {
      item.isDone = !item.isDone;
    });
    _service.saveChecklist(widget.tripId, _items);
  }

  void _addItem(String title, String category) {
    if (title.trim().isEmpty) return;
    setState(() {
      _items.add(
        ChecklistItem(
          id: 'custom-${DateTime.now().millisecondsSinceEpoch}',
          title: title.trim(),
          category: category,
        ),
      );
    });
    _service.saveChecklist(widget.tripId, _items);
    _newItemController.clear();
  }

  void _removeItem(String id) {
    setState(() {
      _items.removeWhere((it) => it.id == id);
    });
    _service.saveChecklist(widget.tripId, _items);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final doneCount = _items.where((i) => i.isDone).length;
    final totalCount = _items.length;
    final progress = totalCount > 0 ? doneCount / totalCount : 0.0;

    final grouped = <String, List<ChecklistItem>>{};
    for (final item in _items) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Valigia & Documenti · ${widget.destination}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_task_rounded),
            tooltip: 'Aggiungi voce',
            onPressed: () => _showAddDialog(context),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Progress banner
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E232A)
                        : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.white12
                          : Colors.blue.withAlpha(40),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progresso preparazione',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '$doneCount su $totalCount (${(progress * 100).round()}%)',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: isDark
                              ? Colors.white12
                              : Colors.blue.withAlpha(30),
                        ),
                      ),
                    ],
                  ),
                ),
                // Checklist Items by category
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: grouped.keys.length,
                    itemBuilder: (context, index) {
                      final category = grouped.keys.elementAt(index);
                      final categoryItems = grouped[category]!;

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: Card(
                          elevation: 0,
                          color: isDark
                              ? const Color(0xFF191D24)
                              : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isDark
                                  ? Colors.white12
                                  : Colors.black.withAlpha(15),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _categoryIcon(category),
                                      size: 18,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      category,
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.2,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ...categoryItems.map((it) {
                                  return CheckboxListTile(
                                    contentPadding: EdgeInsets.zero,
                                    dense: true,
                                    title: Text(
                                      it.title,
                                      style: TextStyle(
                                        fontSize: 14,
                                        decoration: it.isDone
                                            ? TextDecoration.lineThrough
                                            : null,
                                        color: it.isDone
                                            ? theme.colorScheme.onSurfaceVariant
                                            : null,
                                      ),
                                    ),
                                    subtitle: it.isEssential
                                        ? const Text(
                                            'Essenziale',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.deepOrange,
                                            ),
                                          )
                                        : null,
                                    value: it.isDone,
                                    onChanged: (_) => _toggleItem(it),
                                    secondary: IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        size: 18,
                                      ),
                                      onPressed: () => _removeItem(it.id),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  IconData _categoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'documenti':
        return Icons.badge_outlined;
      case 'abbigliamento':
        return Icons.checkroom_outlined;
      case 'elettronica':
        return Icons.power_outlined;
      case 'salute & bagno':
        return Icons.medical_services_outlined;
      case 'specifici meta':
        return Icons.explore_outlined;
      default:
        return Icons.checklist_outlined;
    }
  }

  void _showAddDialog(BuildContext context) {
    String selectedCat = 'Abbigliamento';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Aggiungi voce in valigia'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _newItemController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Cosa vuoi portare?',
                  hintText: 'Es. Adattatore presa, Sciarpa...',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedCat,
                items: const [
                  DropdownMenuItem(
                    value: 'Documenti',
                    child: Text('Documenti'),
                  ),
                  DropdownMenuItem(
                    value: 'Abbigliamento',
                    child: Text('Abbigliamento'),
                  ),
                  DropdownMenuItem(
                    value: 'Elettronica',
                    child: Text('Elettronica'),
                  ),
                  DropdownMenuItem(
                    value: 'Salute & Bagno',
                    child: Text('Salute & Bagno'),
                  ),
                  DropdownMenuItem(
                    value: 'Specifici meta',
                    child: Text('Specifici meta'),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) setDialogState(() => selectedCat = v);
                },
                decoration: const InputDecoration(labelText: 'Categoria'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () {
                _addItem(_newItemController.text, selectedCat);
                Navigator.of(ctx).pop();
              },
              child: const Text('Aggiungi'),
            ),
          ],
        ),
      ),
    );
  }
}
