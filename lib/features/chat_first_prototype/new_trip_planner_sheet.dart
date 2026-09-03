import 'package:flutter/material.dart';

/// Modal bottom sheet guiding the traveler through planning a new trip step-by-step.
class NewTripPlannerSheet extends StatefulWidget {
  const NewTripPlannerSheet({
    super.key,
    required this.onPlanTrip,
    this.initialDestination,
  });

  final ValueChanged<String> onPlanTrip;
  final String? initialDestination;

  @override
  State<NewTripPlannerSheet> createState() => _NewTripPlannerSheetState();
}

class _NewTripPlannerSheetState extends State<NewTripPlannerSheet> {
  final _destinationController = TextEditingController();
  String _selectedDuration = '3 giorni (Weekend lungo)';
  String _selectedVibe = 'Cultura & Relax';
  String _selectedBudget = 'Equilibrato';

  final List<String> _popularDestinations = [
    'Budapest',
    'Porto',
    'Roma',
    'Lisbona',
    'Barcellona',
    'Parigi',
    'Praga',
    'Tokyo',
    'Berlino',
    'Vienna',
  ];

  final List<String> _durations = [
    '2 giorni (Weekend)',
    '3 giorni (Weekend lungo)',
    '4-5 giorni (Ponte)',
    '1 settimana',
    '10+ giorni (Itinerario completo)',
  ];

  final List<({String label, IconData icon, String desc})> _vibes = [
    (
      label: 'Cultura & Relax',
      icon: Icons.spa_rounded,
      desc: 'Monumenti, terme e ritmi rilassati',
    ),
    (
      label: 'Gourmet & Tradizioni',
      icon: Icons.restaurant_rounded,
      desc: 'Mercati tipici, degustazioni e bistrot',
    ),
    (
      label: 'Avventura & Esplorazione',
      icon: Icons.hiking_rounded,
      desc: 'Trekking, panorami e camminate',
    ),
    (
      label: 'Fuga Romantica',
      icon: Icons.favorite_rounded,
      desc: 'Tramonti, cene intime e scorci magici',
    ),
    (
      label: 'Weekend con Amici',
      icon: Icons.groups_rounded,
      desc: 'Vita serale, locali e divertimento',
    ),
  ];

  final List<String> _budgets = [
    'Smart / Low Cost',
    'Equilibrato',
    'Comfort & Charme',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialDestination != null) {
      _destinationController.text = widget.initialDestination!;
    }
  }

  @override
  void dispose() {
    _destinationController.dispose();
    super.dispose();
  }

  void _submit() {
    final dest = _destinationController.text.trim();
    if (dest.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci o seleziona una destinazione')),
      );
      return;
    }

    final prompt =
        'Organizza un viaggio a $dest di $_selectedDuration, con stile $_selectedVibe e budget $_selectedBudget.';
    widget.onPlanTrip(prompt);
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(100),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.explore_rounded,
                            color: theme.colorScheme.primary,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Organizza un Nuovo Viaggio',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Crea un itinerario su misura basato sui tuoi desideri',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Content Form
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // STEP 1: Destination
                Text(
                  '1. Dove vorresti andare?',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _destinationController,
                  decoration: InputDecoration(
                    hintText: 'Es. Budapest, Porto, Roma, Tokyo...',
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF1E232A)
                        : const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                Text(
                  'Destinazioni consigliate:',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _popularDestinations.map((d) {
                    final isSelected =
                        _destinationController.text.trim().toLowerCase() ==
                        d.toLowerCase();
                    return ChoiceChip(
                      label: Text(d, style: const TextStyle(fontSize: 12)),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _destinationController.text = d);
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // STEP 2: Duration
                Text(
                  '2. Per quanto tempo?',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _durations.map((dur) {
                    final isSelected = _selectedDuration == dur;
                    return ChoiceChip(
                      label: Text(dur),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedDuration = dur);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // STEP 3: Vibe
                Text(
                  '3. Che tipo di esperienza cerchi?',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Column(
                  children: _vibes.map((v) {
                    final isSelected = _selectedVibe == v.label;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () => setState(() => _selectedVibe = v.label),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primary.withAlpha(20)
                                : (isDark
                                      ? const Color(0xFF1E232A)
                                      : const Color(0xFFF8FAFC)),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : (isDark
                                        ? Colors.white12
                                        : Colors.black.withAlpha(15)),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                v.icon,
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      v.label,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      v.desc,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: theme.colorScheme.primary,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // STEP 4: Budget
                Text(
                  '4. Stile di Budget',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: _budgets
                      .map(
                        (b) => ButtonSegment(
                          value: b,
                          label: Text(b, style: const TextStyle(fontSize: 11)),
                        ),
                      )
                      .toList(),
                  selected: {_selectedBudget},
                  onSelectionChanged: (set) =>
                      setState(() => _selectedBudget = set.first),
                ),
                const SizedBox(height: 32),

                // Submit Button
                FilledButton.icon(
                  onPressed: _destinationController.text.trim().isEmpty
                      ? null
                      : _submit,
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: const Text(
                    'Genera Itinerario con l\'IA',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
