import 'package:flutter/material.dart';

import 'chat_first_models.dart';
import 'plan_editor.dart';

typedef PlanPatchApply = PlanPatchPreview? Function();

Future<bool> showPlanPatchSheet({
  required BuildContext context,
  required PlanPatchPreview preview,
  required PlanPatchApply onApply,
  required VoidCallback onCancel,
}) async {
  final applied = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: false,
    enableDrag: false,
    builder: (_) => _PlanPatchSheet(preview: preview, onApply: onApply),
  );
  if (applied != true) onCancel();
  return applied == true;
}

class _PlanPatchSheet extends StatefulWidget {
  const _PlanPatchSheet({required this.preview, required this.onApply});

  final PlanPatchPreview preview;
  final PlanPatchApply onApply;

  @override
  State<_PlanPatchSheet> createState() => _PlanPatchSheetState();
}

class _PlanPatchSheetState extends State<_PlanPatchSheet> {
  late PlanPatchPreview _preview = widget.preview;
  var _strongConfirmed = false;
  var _rebased = false;

  bool get _canApply =>
      _preview.canApply &&
      (!_preview.requiresStrongConfirmation || _strongConfirmed);

  void _apply() {
    final result = widget.onApply();
    if (!mounted || result == null) return;
    if (result.status == PlanPatchStatus.applied) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _preview = result;
      _rebased = true;
      _strongConfirmed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Padding(
        key: const Key('plan-patch-sheet'),
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          key: const Key('plan-patch-scroll'),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Focus(
                key: const Key('plan-patch-title-focus'),
                autofocus: true,
                child: Semantics(
                  header: true,
                  child: Text(
                    'Rivedi modifica',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
              if (_rebased) ...<Widget>[
                const SizedBox(height: 12),
                Text(
                  'Piano aggiornato: ricontrolla la modifica.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              for (final effect in _preview.effects)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Icon(Icons.arrow_forward, size: 20),
                      const SizedBox(width: 10),
                      Expanded(child: Text(effect)),
                    ],
                  ),
                ),
              for (final conflict in _preview.conflicts)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(Icons.warning_amber, size: 20, color: colors.error),
                      const SizedBox(width: 10),
                      Expanded(child: Text(conflict)),
                    ],
                  ),
                ),
              if (_preview.requiresStrongConfirmation) ...<Widget>[
                const SizedBox(height: 4),
                CheckboxListTile(
                  key: const Key('plan-patch-strong-check'),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _strongConfirmed,
                  title: const Text(
                    'Confermo la modifica a tappe bloccate o acquisti collegati',
                  ),
                  onChanged: (value) =>
                      setState(() => _strongConfirmed = value ?? false),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('plan-patch-cancel'),
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Annulla'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      key: const Key('plan-patch-apply'),
                      onPressed: _canApply ? _apply : null,
                      child: const Text('Applica'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

@immutable
class PlanMoveSelection {
  const PlanMoveSelection({
    required this.targetDayId,
    required this.targetIndex,
  });

  final String targetDayId;
  final int targetIndex;
}

@immutable
class PlanMoveTarget {
  const PlanMoveTarget({
    required this.keyId,
    required this.dayId,
    required this.targetIndex,
    required this.label,
  });

  final String keyId;
  final String dayId;
  final int targetIndex;
  final String label;
}

List<PlanMoveTarget> buildPlanMoveTargets({
  required TripSnapshot snapshot,
  String? movingItemId,
}) => <PlanMoveTarget>[
  for (final day in snapshot.days)
    ..._targetsForDay(day: day, movingItemId: movingItemId),
];

Future<PlanMoveSelection?> showPlanMoveSheet({
  required BuildContext context,
  required TripSnapshot snapshot,
  required String itemId,
}) => showModalBottomSheet<PlanMoveSelection>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => _PlanMoveSheet(snapshot: snapshot, itemId: itemId),
);

class _PlanMoveSheet extends StatefulWidget {
  const _PlanMoveSheet({required this.snapshot, required this.itemId});

  final TripSnapshot snapshot;
  final String itemId;

  @override
  State<_PlanMoveSheet> createState() => _PlanMoveSheetState();
}

class _PlanMoveSheetState extends State<_PlanMoveSheet> {
  late final List<PlanMoveTarget> _options = buildPlanMoveTargets(
    snapshot: widget.snapshot,
    movingItemId: widget.itemId,
  );
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 18, 12, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Semantics(
                header: true,
                child: Text(
                  'Sposta tappa',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: RadioGroup<int>(
                groupValue: _selected,
                onChanged: (value) => setState(() => _selected = value ?? 0),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _options.length,
                  itemBuilder: (context, index) => RadioListTile<int>(
                    value: index,
                    title: Text(_options[index].label),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _options.isEmpty
                    ? null
                    : () {
                        final selected = _options[_selected];
                        Navigator.of(context).pop(
                          PlanMoveSelection(
                            targetDayId: selected.dayId,
                            targetIndex: selected.targetIndex,
                          ),
                        );
                      },
                child: const Text('Rivedi modifica'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

List<PlanMoveTarget> _targetsForDay({
  required TripDaySnapshot day,
  required String? movingItemId,
}) {
  final remaining = day.items
      .where((item) => item.id != movingItemId)
      .toList(growable: false);
  if (remaining.isEmpty) {
    return <PlanMoveTarget>[
      PlanMoveTarget(
        keyId: '${day.id}-empty',
        dayId: day.id,
        targetIndex: 0,
        label: '${day.label} · giornata vuota',
      ),
    ];
  }
  return <PlanMoveTarget>[
    PlanMoveTarget(
      keyId: '${day.id}-start',
      dayId: day.id,
      targetIndex: 0,
      label: 'Inizio di ${day.label}',
    ),
    for (var index = 0; index < remaining.length; index += 1)
      PlanMoveTarget(
        keyId: '${day.id}-before-${remaining[index].id}',
        dayId: day.id,
        targetIndex: index,
        label: 'Prima di ${remaining[index].title}',
      ),
    for (var index = 0; index < remaining.length; index += 1)
      PlanMoveTarget(
        keyId: '${day.id}-after-${remaining[index].id}',
        dayId: day.id,
        targetIndex: index + 1,
        label: 'Dopo ${remaining[index].title}',
      ),
    PlanMoveTarget(
      keyId: '${day.id}-end',
      dayId: day.id,
      targetIndex: remaining.length,
      label: 'Fine di ${day.label}',
    ),
  ];
}
