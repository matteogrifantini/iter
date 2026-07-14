import 'package:flutter/material.dart';

import '../models/trip_models.dart';
import '../widgets/iter_ui.dart';

class TransportSelectionScreen extends StatefulWidget {
  const TransportSelectionScreen({
    super.key,
    required this.journeyTitle,
    required this.options,
    required this.initialSelection,
    required this.onConfirm,
    required this.onOpenSearch,
  });

  final String journeyTitle;
  final List<TransportOption> options;
  final TransportOption? initialSelection;
  final ValueChanged<TransportOption> onConfirm;
  final ValueChanged<Uri> onOpenSearch;

  @override
  State<TransportSelectionScreen> createState() =>
      _TransportSelectionScreenState();
}

class _TransportSelectionScreenState extends State<TransportSelectionScreen> {
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.initialSelection?.id;
  }

  TransportOption? get _selectedOption {
    for (final option in widget.options) {
      if (option.id == _selectedId) return option;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Indietro',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Come arrivare'),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const PlanningProgress(
              currentStep: 1,
              padding: EdgeInsets.fromLTRB(16, 2, 16, 10),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Da Milano',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  const Icon(Icons.arrow_forward, size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      widget.options.firstOrNull?.destination ?? 'Destinazione',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: widget.options.length,
                separatorBuilder: (_, _) => const SizedBox(height: 9),
                itemBuilder: (context, index) {
                  final option = widget.options[index];
                  return _TransportOptionTile(
                    option: option,
                    selected: option.id == _selectedId,
                    onSelect: () => setState(() => _selectedId = option.id),
                    onOpenSearch: () => widget.onOpenSearch(option.searchUrl),
                  );
                },
              ),
            ),
            Material(
              color: colors.surface,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Prezzi demo',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ),
                      FilledButton(
                        onPressed: _selectedOption == null
                            ? null
                            : () => widget.onConfirm(_selectedOption!),
                        child: const Text('Continua'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransportOptionTile extends StatelessWidget {
  const _TransportOptionTile({
    required this.option,
    required this.selected,
    required this.onSelect,
    required this.onOpenSearch,
  });

  final TransportOption option;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onOpenSearch;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label:
          '${_kindLabel(option.kind)}, ${option.company}, ${option.priceLabel}',
      child: Material(
        color: selected ? colors.primaryContainer : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: selected ? colors.primary : colors.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onSelect,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 11, 8, 11),
            child: Row(
              children: [
                Container(
                  width: 68,
                  height: 48,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Image.asset(
                    option.logoAsset,
                    fit: BoxFit.contain,
                    semanticLabel: 'Logo ${option.company}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _kindIcon(option.kind),
                            size: 17,
                            color: colors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _kindLabel(option.kind),
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(color: colors.primary),
                          ),
                          if (selected) ...[
                            const SizedBox(width: 6),
                            Icon(
                              Icons.check_circle,
                              size: 16,
                              color: colors.primary,
                            ),
                          ] else if (option.isRecommended) ...[
                            const SizedBox(width: 6),
                            Icon(
                              Icons.auto_awesome,
                              size: 15,
                              color: colors.secondary,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        option.timingLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${option.durationLabel} · ${option.changesLabel}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      option.priceLabel,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: IconButton(
                        tooltip: 'Apri ${option.company}',
                        onPressed: onOpenSearch,
                        icon: Icon(
                          Icons.open_in_new,
                          color: colors.onSurfaceVariant,
                          size: 21,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _kindLabel(TransportKind kind) => switch (kind) {
  TransportKind.flight => 'Volo',
  TransportKind.train => 'Treno',
  TransportKind.bus => 'Bus',
  TransportKind.car => 'Auto',
};

IconData _kindIcon(TransportKind kind) => switch (kind) {
  TransportKind.flight => Icons.flight_takeoff,
  TransportKind.train => Icons.train,
  TransportKind.bus => Icons.directions_bus,
  TransportKind.car => Icons.directions_car,
};

extension<T> on Iterable<T> {
  T? get firstOrNull {
    for (final value in this) {
      return value;
    }
    return null;
  }
}
