import 'package:flutter/material.dart';

class TripProfilingCard extends StatefulWidget {
  const TripProfilingCard({
    super.key,
    required this.destination,
    required this.onProfileConfirmed,
  });

  final String destination;
  final ValueChanged<String> onProfileConfirmed;

  @override
  State<TripProfilingCard> createState() => _TripProfilingCardState();
}

class _TripProfilingCardState extends State<TripProfilingCard> {
  String _companions = 'In coppia 💑';
  String _vibe = 'Cultura & Scorci 🏛️';
  String _pace = 'Passo equilibrato 🚶';
  String _budget = 'Equilibrato 💶';

  final _companionOptions = ['In coppia 💑', 'Da solo 🎒', 'Con amici 🍻', 'In famiglia 👨‍👩‍👧'];
  final _vibeOptions = ['Cultura & Scorci 🏛️', 'Relax & Benessere 🧖', 'Vita notturna & Tapas 🍷', 'Avventura & Parchi 🌲'];
  final _paceOptions = ['Passo rilassato ☕', 'Passo equilibrato 🚶', 'Esploratore attivo 👟'];
  final _budgetOptions = ['Smart / Low cost 🏷️', 'Equilibrato 💶', 'Boutique & Comfort ✨'];

  void _confirm() {
    final prompt = 'Siamo $_companions, cerchiamo un viaggio all\'insegna di $_vibe, con $_pace e budget $_budget. Come possiamo organizzarlo al meglio?';
    widget.onProfileConfirmed(prompt);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
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
                child: const Text('🎯', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Che tipo di viaggio desideri?',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Personalizza in 3 tap il ritmo e l\'atmosfera a ${widget.destination}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Sezione 1: Chi siamo
          _SectionTitle(title: 'Con chi viaggi?'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _companionOptions.map((opt) {
              final isSel = _companions == opt;
              return ChoiceChip(
                label: Text(opt, style: const TextStyle(fontSize: 12)),
                selected: isSel,
                onSelected: (_) => setState(() => _companions = opt),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Sezione 2: Vibe
          _SectionTitle(title: 'Atmosfera desiderata'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _vibeOptions.map((opt) {
              final isSel = _vibe == opt;
              return ChoiceChip(
                label: Text(opt, style: const TextStyle(fontSize: 12)),
                selected: isSel,
                onSelected: (_) => setState(() => _vibe = opt),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Sezione 3: Ritmo a piedi
          _SectionTitle(title: 'Ritmo della giornata'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _paceOptions.map((opt) {
              final isSel = _pace == opt;
              return ChoiceChip(
                label: Text(opt, style: const TextStyle(fontSize: 12)),
                selected: isSel,
                onSelected: (_) => setState(() => _pace = opt),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Sezione 4: Budget
          _SectionTitle(title: 'Fascia di spesa'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _budgetOptions.map((opt) {
              final isSel = _budget == opt;
              return ChoiceChip(
                label: Text(opt, style: const TextStyle(fontSize: 12)),
                selected: isSel,
                onSelected: (_) => setState(() => _budget = opt),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Pulsante Conferma
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _confirm,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.auto_awesome_rounded, size: 18),
              label: Text(
                'Personalizza viaggio a ${widget.destination}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.2,
      ),
    );
  }
}
