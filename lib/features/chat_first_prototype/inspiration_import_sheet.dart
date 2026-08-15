import 'package:flutter/material.dart';

import 'chat_first_controller.dart';
import 'inspiration_importer.dart';
import 'inspiration_models.dart';

typedef InspirationSaveCallback =
    SavedInspiration? Function({
      required String conversationId,
      required InspirationDraft draft,
    });

typedef InspirationProposeCallback =
    bool Function(SavedInspiration inspiration);

@immutable
class InspirationTripOption {
  const InspirationTripOption({
    required this.conversationId,
    required this.destinationId,
    required this.title,
    required this.subtitle,
  });

  final String conversationId;
  final String destinationId;
  final String title;
  final String subtitle;
}

Future<bool?> showInspirationImportSheet({
  required BuildContext context,
  required ChatFirstPrototypeController controller,
  required String initialConversationId,
}) {
  final trips = controller.threads
      .where((thread) => thread.summary.snapshot != null)
      .map(
        (thread) => InspirationTripOption(
          conversationId: thread.summary.id,
          destinationId: thread.summary.title.trim().toLowerCase(),
          title: thread.summary.title,
          subtitle: thread.summary.subtitle,
        ),
      )
      .toList(growable: false);
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => InspirationImportSheet(
      trips: trips,
      initialConversationId: initialConversationId,
      onSave: controller.saveInspiration,
      onPropose: (inspiration) => controller.proposeInspiration(
        inspiration.conversationId,
        inspiration.id,
      ),
    ),
  );
}

class InspirationImportSheet extends StatefulWidget {
  const InspirationImportSheet({
    super.key,
    required this.trips,
    required this.initialConversationId,
    required this.onSave,
    required this.onPropose,
  });

  final List<InspirationTripOption> trips;
  final String initialConversationId;
  final InspirationSaveCallback onSave;
  final InspirationProposeCallback onPropose;

  @override
  State<InspirationImportSheet> createState() => _InspirationImportSheetState();
}

class _InspirationImportSheetState extends State<InspirationImportSheet> {
  late final TextEditingController _urlController;
  String? _selectedConversationId;
  InspirationDraft? _draft;
  SavedInspiration? _saved;
  String? _errorMessage;
  var _proposed = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController();
    _selectedConversationId =
        widget.trips.any(
          (trip) => trip.conversationId == widget.initialConversationId,
        )
        ? widget.initialConversationId
        : widget.trips.firstOrNull?.conversationId;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.outlineVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Importa un Reel o TikTok',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'In questa demo Iter legge solo link locali approvati: niente rete, '
              'niente pubblicazione automatica nel piano.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            if (_saved == null) ...<Widget>[
              TextField(
                key: const Key('inspiration-url-field'),
                controller: _urlController,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'Link del video',
                  hintText: 'https://www.instagram.com/reel/...',
                  prefixIcon: const Icon(Icons.link_outlined),
                  errorText: _errorMessage,
                ),
                onSubmitted: (_) => _extract(),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  ActionChip(
                    label: const Text('Demo Porto'),
                    onPressed: () =>
                        _useDemo('https://www.instagram.com/reel/iter-porto'),
                  ),
                  ActionChip(
                    label: const Text('Demo Roma'),
                    onPressed: () =>
                        _useDemo('https://www.tiktok.com/@iter/roma-foro'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _extract,
                  icon: const Icon(Icons.auto_awesome_outlined),
                  label: const Text('Estrai ispirazione'),
                ),
              ),
            ],
            if (_draft case final draft?) ...<Widget>[
              const SizedBox(height: 20),
              _DraftPreview(draft: draft),
              const SizedBox(height: 16),
              if (widget.trips.isEmpty)
                Text(
                  'Apri o crea un piano prima di salvare questa ispirazione.',
                  style: Theme.of(context).textTheme.bodyLarge,
                )
              else ...<Widget>[
                DropdownButtonFormField<String>(
                  initialValue: _selectedConversationId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'A quale viaggio la colleghiamo?',
                    prefixIcon: Icon(Icons.route_outlined),
                  ),
                  items: <DropdownMenuItem<String>>[
                    for (final trip in widget.trips)
                      DropdownMenuItem<String>(
                        value: trip.conversationId,
                        child: Text('${trip.title} · ${trip.subtitle}'),
                      ),
                  ],
                  onChanged: (value) =>
                      setState(() => _selectedConversationId = value),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _selectedConversationId == null ? null : _save,
                    icon: const Icon(Icons.bookmark_add_outlined),
                    label: const Text('Salva ispirazione'),
                  ),
                ),
              ],
            ],
            if (_saved case final saved?) ...<Widget>[
              const SizedBox(height: 20),
              _SavedPreview(saved: saved),
              const SizedBox(height: 16),
              if (_errorMessage case final error?) ...<Widget>[
                Text(
                  error,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 12),
              ],
              if (!_proposed)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _propose,
                    icon: const Icon(Icons.route_outlined),
                    label: const Text('Proponi integrazione'),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(Icons.check_circle_outline, color: colors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Proposta inviata in chat. Il piano cambia solo se '
                          'accetti la modifica.',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            if (_saved != null || _draft == null) ...<Widget>[
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(_proposed),
                  child: Text(_saved == null ? 'Annulla' : 'Chiudi'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _useDemo(String url) {
    _urlController.text = url;
    _extract();
  }

  void _extract() {
    final result = parseMockInspiration(_urlController.text);
    setState(() {
      _draft = result.draft;
      _errorMessage = result.errorMessage;
    });
  }

  void _save() {
    final draft = _draft;
    final conversationId = _selectedConversationId;
    if (draft == null || conversationId == null) return;
    final saved = widget.onSave(conversationId: conversationId, draft: draft);
    if (saved == null) {
      setState(
        () => _errorMessage = 'Non riesco a salvare questa ispirazione.',
      );
      return;
    }
    setState(() => _saved = saved);
  }

  void _propose() {
    final saved = _saved;
    if (saved == null) return;
    final proposed = widget.onPropose(saved);
    setState(() {
      _proposed = proposed;
      _errorMessage = proposed
          ? null
          : 'Collega l’ispirazione a un piano compatibile con la destinazione.';
    });
  }
}

class _DraftPreview extends StatelessWidget {
  const _DraftPreview({required this.draft});

  final InspirationDraft draft;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Image.asset(
            draft.mediaAsset,
            height: 150,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const SizedBox(height: 40),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  draft.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${draft.placeName} · ${draft.suggestedCategory} · ${draft.moment}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedPreview extends StatelessWidget {
  const _SavedPreview({required this.saved});

  final SavedInspiration saved;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            saved.mediaAsset,
            width: 78,
            height: 78,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => ColoredBox(
              color: colors.surfaceContainerHighest,
              child: const SizedBox(width: 78, height: 78),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Ispirazione salvata',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                saved.placeName,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Text(
                'Collegata a ${saved.destinationId}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
