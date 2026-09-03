import 'package:flutter/material.dart';
import '../ai/gemini_travel_service.dart';
import '../chat_first_prototype/local_preferences_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final LocalPreferencesService _prefs = const LocalPreferencesService();
  late final TextEditingController _apiKeyController;

  String _departureCity = 'Milano';
  String _travelStyle = 'Cultura & Gastronomia';
  String _budget = 'Medio';
  bool _obscureKey = true;
  String? _statusMessage;
  bool _testingConnection = false;
  bool? _connectionValid;

  final List<String> _cities = [
    'Milano',
    'Roma',
    'Napoli',
    'Bologna',
    'Venezia',
    'Torino',
    'Palermo',
    'Bari',
    'Firenze',
  ];

  final List<String> _styles = [
    'Cultura & Gastronomia',
    'Natura & Relax',
    'Avventura & Trekking',
    'Vita Notturna & Città',
    'Spiagge & Mare',
  ];

  final List<String> _budgets = [
    'Economico',
    'Medio',
    'Senza limiti',
  ];

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController(text: _prefs.geminiApiKey ?? '');
    _departureCity = _prefs.departureCity;
    _travelStyle = _prefs.travelStyle;
    _budget = _prefs.budget;
    _loadAsync();
  }

  Future<void> _loadAsync() async {
    await _prefs.initPreferences();
    if (mounted) {
      setState(() {
        _departureCity = _prefs.departureCity;
        _travelStyle = _prefs.travelStyle;
        _budget = _prefs.budget;
        _apiKeyController.text = _prefs.geminiApiKey ?? '';
      });
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _savePreferences() async {
    await _prefs.saveDepartureCity(_departureCity);
    await _prefs.saveTravelStyle(_travelStyle);
    await _prefs.saveBudget(_budget);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preferenze aggiornate')),
      );
    }
  }

  Future<void> _saveApiKey() async {
    final key = _apiKeyController.text.trim();
    await _prefs.saveGeminiApiKey(key);
    setState(() {
      _statusMessage = 'Chiave salvata con successo';
      _connectionValid = null;
    });
  }

  Future<void> _testConnection() async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) {
      setState(() {
        _statusMessage = 'Inserisci prima una chiave API';
        _connectionValid = false;
      });
      return;
    }

    setState(() {
      _testingConnection = true;
      _statusMessage = null;
    });

    final service = GeminiTravelService(apiKey: key);
    final result = await service.testConnection();

    if (mounted) {
      setState(() {
        _testingConnection = false;
        _connectionValid = result.success;
        _statusMessage = result.success
            ? 'Connessione riuscita! Modello ${result.model ?? "Gemini"} attivo.'
            : (result.error != null
                ? 'Errore: ${result.error}'
                : 'Errore di connessione. Verifica che la chiave sia valida.');

      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Il tuo profilo',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
        children: [
          // Sezione: Preferenze di Viaggio
          Text(
            'Preferenze di Viaggio',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 6),
          Text(
            'Queste impostazioni aiutano Iter e Gemini a suggerirti mete e voli su misura.',
            style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.outline),
          ),
          const SizedBox(height: 16),

          // Città di partenza
          Text(
            'Città di partenza predefinita',
            style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _cities.contains(_departureCity) ? _departureCity : _cities.first,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: _cities
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => _departureCity = val);
                _savePreferences();
              }
            },
          ),
          const SizedBox(height: 18),

          // Stile di viaggio
          Text(
            'Stile di viaggio preferito',
            style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _styles.contains(_travelStyle) ? _travelStyle : _styles.first,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: _styles
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => _travelStyle = val);
                _savePreferences();
              }
            },
          ),
          const SizedBox(height: 18),

          // Budget
          Text(
            'Budget tipico',
            style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _budgets.contains(_budget) ? _budget : _budgets[1],
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: _budgets
                .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                .toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => _budget = val);
                _savePreferences();
              }
            },
          ),


          const SizedBox(height: 32),

          // Sezione: Configurazione IA (Fase Demo)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Strumento di Collaudo',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_connectionValid == true)
                      const Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Connesso',
                            style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Configurazione IA (Fase Demo)',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Inserisci la tua chiave API Google AI Studio gratuita per testare Gemini Pro/Flash liberamente. Nella versione di produzione commerciale l\'accesso sarà erogato automaticamente via backend.',
                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant, height: 1.4),
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('gemini_api_key_input'),
                  controller: _apiKeyController,
                  obscureText: _obscureKey,
                  decoration: InputDecoration(
                    labelText: 'Google Gemini API Key',
                    hintText: 'AIzaSy...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureKey ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscureKey = !_obscureKey),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed: _saveApiKey,
                      child: const Text('Salva chiave'),
                    ),
                    OutlinedButton(
                      onPressed: _testingConnection ? null : _testConnection,
                      child: _testingConnection
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Testa connessione'),
                    ),
                  ],
                ),
                if (_statusMessage != null) ...[

                  const SizedBox(height: 12),
                  Text(
                    _statusMessage!,
                    style: TextStyle(
                      fontSize: 13,
                      color: _connectionValid == true
                          ? Colors.green.shade700
                          : _connectionValid == false
                              ? Colors.red.shade700
                              : colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
