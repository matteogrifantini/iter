import 'package:flutter/material.dart';

import 'profile_models.dart';

class ProfileAvailabilitySheet extends StatefulWidget {
  const ProfileAvailabilitySheet({super.key});

  @override
  State<ProfileAvailabilitySheet> createState() =>
      _ProfileAvailabilitySheetState();
}

class _ProfileAvailabilitySheetState extends State<ProfileAvailabilitySheet> {
  late DateTime _date;
  var _kind = AvailabilityKind.free;
  late final TextEditingController _timeController;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _date = DateTime(now.year, now.month, now.day);
    _timeController = TextEditingController(text: 'Tutto il giorno');
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _timeController.dispose();
    _noteController.dispose();
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
            const SizedBox(height: 20),
            Text(
              'Nuova disponibilità',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Un piccolo segnale per aiutare Iter a proporti il momento giusto.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: const Text('Giorno'),
              subtitle: Text(_formatSheetDate(_date)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickDate,
            ),
            const SizedBox(height: 8),
            SegmentedButton<AvailabilityKind>(
              segments: const <ButtonSegment<AvailabilityKind>>[
                ButtonSegment<AvailabilityKind>(
                  value: AvailabilityKind.free,
                  label: Text('Libero'),
                  icon: Icon(Icons.wb_sunny_outlined),
                ),
                ButtonSegment<AvailabilityKind>(
                  value: AvailabilityKind.work,
                  label: Text('Turno'),
                  icon: Icon(Icons.work_outline),
                ),
              ],
              selected: <AvailabilityKind>{_kind},
              onSelectionChanged: (selection) {
                setState(() => _kind = selection.first);
              },
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(minimumSize: const Size(0, 48)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _timeController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Orario o fascia',
                hintText: 'es. Dopo le 18:00',
                prefixIcon: Icon(Icons.schedule_outlined),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              textInputAction: TextInputAction.done,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Nota (facoltativa)',
                hintText: 'es. Fine turno, posso partire da Roma',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _timeController.text.trim().isEmpty
                    ? null
                    : () => Navigator.of(context).pop(
                        AvailabilityEntry(
                          id: 'draft-${_date.millisecondsSinceEpoch}',
                          date: _date,
                          kind: _kind,
                          timeRange: _timeController.text.trim(),
                          note: _noteController.text.trim(),
                        ),
                      ),
                icon: const Icon(Icons.check),
                label: const Text('Salva disponibilità'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2026),
      lastDate: DateTime(2030),
      helpText: 'Scegli un giorno',
      cancelText: 'Annulla',
      confirmText: 'Conferma',
    );
    if (picked != null) setState(() => _date = picked);
  }
}

String _formatSheetDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
