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
  late TransportKind _kind;
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _kind = widget.initialSelection?.kind ?? TransportKind.flight;
    _selectedId = widget.initialSelection?.id;
  }

  List<TransportOption> get _visibleOptions => widget.options
      .where((option) => option.kind == _kind)
      .toList(growable: false);

  TransportOption? get _selectedOption {
    for (final option in widget.options) {
      if (option.id == _selectedId) return option;
    }
    return null;
  }

  void _changeKind(TransportKind kind) {
    final firstForKind = widget.options
        .where((option) => option.kind == kind)
        .firstOrNull;
    setState(() {
      _kind = kind;
      _selectedId = firstForKind?.id;
    });
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
        title: Text(widget.journeyTitle),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const PlanningProgress(currentStep: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Come comincia il viaggio?',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Partenza da Milano. Scegli l’incastro, non il biglietto.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<TransportKind>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: TransportKind.flight,
                          icon: Icon(Icons.flight_outlined),
                          label: Text('Volo'),
                        ),
                        ButtonSegment(
                          value: TransportKind.train,
                          icon: Icon(Icons.train_outlined),
                          label: Text('Treno'),
                        ),
                      ],
                      selected: <TransportKind>{_kind},
                      onSelectionChanged: (selection) =>
                          _changeKind(selection.first),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 200),
                child: ListView.separated(
                  key: ValueKey(_kind),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                  itemCount: _visibleOptions.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final option = _visibleOptions[index];
                    return _TransportOptionTile(
                      option: option,
                      selected: option.id == _selectedId,
                      onSelect: () => setState(() => _selectedId = option.id),
                      onOpenSearch: () => widget.onOpenSearch(option.searchUrl),
                    );
                  },
                ),
              ),
            ),
            Material(
              color: colors.surface,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Stime demo · nessun acquisto',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ),
                      const SizedBox(width: 12),
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
    final kindLabel = option.kind == TransportKind.flight ? 'Volo' : 'Treno';
    return Semantics(
      button: true,
      selected: selected,
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
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      option.kind == TransportKind.flight
                          ? Icons.flight_takeoff
                          : Icons.train,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        option.isRecommended
                            ? '$kindLabel · il più semplice'
                            : kindLabel,
                        style: Theme.of(
                          context,
                        ).textTheme.labelLarge?.copyWith(color: colors.primary),
                      ),
                    ),
                    Icon(
                      selected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: selected ? colors.primary : colors.outline,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  option.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _RouteEndpoints(option: option),
                const SizedBox(height: 14),
                Text(
                  option.timingLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Divider(color: colors.outlineVariant),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _TransportFact(
                        label: 'Durata',
                        value: option.durationLabel,
                      ),
                    ),
                    Expanded(
                      child: _TransportFact(
                        label: 'Cambi',
                        value: option.changesLabel,
                      ),
                    ),
                    Expanded(
                      child: _TransportFact(
                        label: 'Stima',
                        value: option.priceLabel,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(option.whyItFits),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: onOpenSearch,
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('Controlla fuori da Iter'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RouteEndpoints extends StatelessWidget {
  const _RouteEndpoints({required this.option});

  final TransportOption option;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            option.origin,
            maxLines: 2,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: SizedBox(
            width: 54,
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: colors.secondary,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(child: Divider(color: colors.primary, thickness: 2)),
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Text(
            option.destination,
            textAlign: TextAlign.end,
            maxLines: 2,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
      ],
    );
  }
}

class _TransportFact extends StatelessWidget {
  const _TransportFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 3),
        Text(value, maxLines: 2, style: Theme.of(context).textTheme.labelLarge),
      ],
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    for (final value in this) {
      return value;
    }
    return null;
  }
}
