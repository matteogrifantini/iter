import 'package:flutter/material.dart';

import 'new_trip_lab_controller.dart';
import 'new_trip_lab_models.dart';
import 'new_trip_lab_proposals.dart';
import 'new_trip_lab_results.dart';
import 'new_trip_lab_shells.dart';
import 'new_trip_origin_resolver.dart';

class NewTripLabScreen extends StatefulWidget {
  const NewTripLabScreen({
    super.key,
    this.savedFreeDays = const <DateTime>[],
    this.clock,
    this.originResolver,
    this.proposalSource = const DeterministicPrototypeProposalSource(),
    this.autoAdvanceDelay = const Duration(milliseconds: 200),
    this.searchStageDelay = const Duration(milliseconds: 360),
  });

  final List<DateTime> savedFreeDays;
  final DateTime Function()? clock;
  final OriginResolver? originResolver;
  final PrototypeProposalSource proposalSource;
  final Duration autoAdvanceDelay;
  final Duration searchStageDelay;

  @override
  State<NewTripLabScreen> createState() => _NewTripLabScreenState();
}

class _NewTripLabScreenState extends State<NewTripLabScreen> {
  late final NewTripPrototypeController _controller;
  late final OriginResolver _originResolver;
  bool _closing = false;
  bool _didOfferManualOrigin = false;
  int _originRequestId = 0;

  @override
  void initState() {
    super.initState();
    _originResolver = widget.originResolver ?? const DeviceOriginResolver();
    _controller = NewTripPrototypeController(
      clock: widget.clock,
      savedFreeDays: widget.savedFreeDays,
      proposalSource: widget.proposalSource,
      autoAdvanceDelay: widget.autoAdvanceDelay,
      searchStageDelay: widget.searchStageDelay,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveOrigin());
  }

  @override
  void dispose() {
    _originRequestId += 1;
    _controller.dispose();
    super.dispose();
  }

  Future<void> _resolveOrigin() async {
    final requestId = ++_originRequestId;
    _controller.beginOriginResolution();
    final result = await _originResolver.resolve();
    if (!mounted || requestId != _originRequestId) return;
    _controller.applyOriginResolution(result);
    if (!result.isResolved && !_didOfferManualOrigin) {
      _didOfferManualOrigin = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _editOrigin();
      });
    }
  }

  Future<void> _editOrigin() async {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      sheetAnimationStyle: reduceMotion ? AnimationStyle.noAnimation : null,
      builder: (context) => _OriginEditorSheet(
        initialValue: _controller.origin ?? '',
        support: _controller.hasOrigin
            ? 'La posizione rilevata è solo un punto di partenza: puoi cambiarla sempre.'
            : _controller.originFailureMessage(),
      ),
    );
    if (!mounted || result == null || result.trim().isEmpty) return;
    _originRequestId += 1;
    _controller.setManualOrigin(result);
  }

  void _back() {
    if (!_controller.consumeBack()) _finish();
  }

  void _finish() {
    if (_closing) return;
    _closing = true;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.stage == NewTripFlowStage.questions) {
            return NewTripQuestionShell(
              controller: _controller,
              onBack: _back,
              onEditOrigin: _editOrigin,
              onRetryOrigin: _resolveOrigin,
            );
          }
          return NewTripSharedFlow(
            controller: _controller,
            onBack: _back,
            onEditOrigin: _editOrigin,
            onFinish: _finish,
          );
        },
      ),
    );
  }
}

class _OriginEditorSheet extends StatefulWidget {
  const _OriginEditorSheet({required this.initialValue, required this.support});

  final String initialValue;
  final String support;

  @override
  State<_OriginEditorSheet> createState() => _OriginEditorSheetState();
}

class _OriginEditorSheetState extends State<_OriginEditorSheet> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _textController.text.trim();
    if (value.isNotEmpty) Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final compact =
        MediaQuery.sizeOf(context).width < 360 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.25;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + keyboard),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Da dove vuoi partire?',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 7),
          Text(
            widget.support,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const ValueKey('new-trip-origin-field'),
            controller: _textController,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Città, aeroporto o stazione',
              hintText: 'Es. Firenze o Firenze S. M. Novella',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 160),
            child: _textController.text.trim().isEmpty
                ? Container(
                    key: const ValueKey('origin-help'),
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Puoi indicare anche una stazione o un aeroporto: non proponiamo città casuali.',
                    ),
                  )
                : Card(
                    key: const ValueKey('origin-result'),
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      minTileHeight: 68,
                      leading: const Icon(Icons.location_on_outlined),
                      title: Text('Usa “${_textController.text.trim()}”'),
                      subtitle: const Text(
                        'Partenza modificabile in ogni momento',
                      ),
                      trailing: compact
                          ? null
                          : const Icon(Icons.arrow_forward),
                      onTap: _submit,
                    ),
                  ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const ValueKey('new-trip-origin-confirm'),
              onPressed: _textController.text.trim().isEmpty ? null : _submit,
              icon: const Icon(Icons.check),
              label: const Text('Usa questa partenza'),
            ),
          ),
        ],
      ),
    );
  }
}
