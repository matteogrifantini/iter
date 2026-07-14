import 'package:flutter/material.dart';

import '../widgets/iter_ui.dart';

class AvailabilityScreen extends StatelessWidget {
  const AvailabilityScreen({
    super.key,
    required this.selectedDates,
    required this.onToggleDate,
  });

  final List<DateTime> selectedDates;
  final ValueChanged<DateTime> onToggleDate;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final choices = List<DateTime>.generate(
      14,
      (index) => DateTime(today.year, today.month, today.day + index + 1),
    );
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Indietro',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 28),
          children: [
            const ScreenHeader(
              eyebrow: 'Quando puoi partire',
              title: 'Segna solo i giorni liberi.',
              subtitle:
                  'In futuro potrai collegare i turni. Per ora nulla viene importato o letto da altri calendari.',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SurfacePanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedDates.isEmpty
                          ? 'Nessuna data selezionata'
                          : '${selectedDates.length} ${selectedDates.length == 1 ? 'giorno libero' : 'giorni liberi'} segnati',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tocca le date che vorresti tenere aperte per una partenza.',
                    ),
                  ],
                ),
              ),
            ),
            const SectionTitle(title: 'Le prossime due settimane'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: choices.map((date) {
                  final isSelected = selectedDates.any(
                    (picked) => _sameDate(picked, date),
                  );
                  return FilterChip(
                    selected: isSelected,
                    onSelected: (_) => onToggleDate(date),
                    label: Text(_label(date)),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _sameDate(DateTime left, DateTime right) =>
      left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;

  String _label(DateTime date) {
    const weekdays = ['lun', 'mar', 'mer', 'gio', 'ven', 'sab', 'dom'];
    return '${weekdays[date.weekday - 1]} ${date.day}';
  }
}
