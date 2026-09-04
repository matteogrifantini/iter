import 'package:flutter/material.dart';
import '../../stays/stay_models.dart';
import '../../ai/gemini_models.dart';

class StayPickerSheet extends StatefulWidget {
  const StayPickerSheet({
    super.key,
    required this.destination,
    required this.stays,
    required this.neighborhoods,
    required this.selectedStay,
    required this.onStayBooked,
    this.onSkip,
    this.onCustomQuery,
  });

  final String destination;
  final List<StayOffer> stays;
  final List<NeighborhoodAdvice> neighborhoods;
  final StayOffer? selectedStay;
  final ValueChanged<StayOffer> onStayBooked;
  final VoidCallback? onSkip;
  final ValueChanged<String>? onCustomQuery;

  static Future<void> show(
    BuildContext context, {
    required String destination,
    required List<StayOffer> stays,
    required List<NeighborhoodAdvice> neighborhoods,
    required StayOffer? selectedStay,
    required ValueChanged<StayOffer> onStayBooked,
    VoidCallback? onSkip,
    ValueChanged<String>? onCustomQuery,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StayPickerSheet(
        destination: destination,
        stays: stays,
        neighborhoods: neighborhoods,
        selectedStay: selectedStay,
        onStayBooked: onStayBooked,
        onSkip: onSkip,
        onCustomQuery: onCustomQuery,
      ),
    );
  }

  @override
  State<StayPickerSheet> createState() => _StayPickerSheetState();
}

class _StayPickerSheetState extends State<StayPickerSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedZone;
  StayOffer? _activeSelectedStay;
  final TextEditingController _customQueryController = TextEditingController();
  String _activeFilter = 'all'; // all, budget, pool, sea, center
  late List<StayOffer> _currentStays;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _activeSelectedStay = widget.selectedStay;
    _currentStays = List.of(widget.stays);
    if (widget.neighborhoods.isNotEmpty) {
      _selectedZone = widget.neighborhoods.first.name;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _customQueryController.dispose();
    super.dispose();
  }

  void _regenerateStays() {
    setState(() {
      _currentStays = List.of(_currentStays)..shuffle();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Alloggi rinnovati con nuove combinazioni'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _askInChat() {
    Navigator.of(context).pop();
    widget.onCustomQuery?.call('Mostrami altre opzioni di alloggio o quartieri consigliati a ${widget.destination}');
  }

  void _handleCustomQuery(String query) {
    if (query.trim().isEmpty) return;
    final q = query.toLowerCase();
    setState(() {
      if (q.contains('econom') || q.contains('budget') || q.contains('prezzo')) {
        _activeFilter = 'budget';
      } else if (q.contains('piscina') || q.contains('pool') || q.contains('relax')) {
        _activeFilter = 'pool';
      } else if (q.contains('mare') || q.contains('spiaggia') || q.contains('beach') || q.contains('costa')) {
        _activeFilter = 'sea';
      } else if (q.contains('centro') || q.contains('piedi')) {
        _activeFilter = 'center';
      } else {
        _activeFilter = 'all';
      }
    });
    widget.onCustomQuery?.call(query);
    _customQueryController.clear();
    FocusScope.of(context).unfocus();
  }

  List<StayOffer> _getFilteredStays(List<StayOffer> raw) {
    var list = raw;
    if (_activeFilter == 'budget') {
      list = [...raw]..sort((a, b) => a.pricePerNightEur.compareTo(b.pricePerNightEur));
    } else if (_activeFilter == 'pool') {
      final pool = raw.where((s) => s.amenities.any((a) => a.toLowerCase().contains('piscin') || a.toLowerCase().contains('spa'))).toList();
      if (pool.isNotEmpty) list = pool;
    } else if (_activeFilter == 'sea') {
      final sea = raw.where((s) => s.neighborhood.toLowerCase().contains('costa') || s.neighborhood.toLowerCase().contains('playa') || s.amenities.any((a) => a.toLowerCase().contains('mare') || a.toLowerCase().contains('oceano') || a.toLowerCase().contains('spiaggia'))).toList();
      if (sea.isNotEmpty) list = sea;
    } else if (_activeFilter == 'center') {
      final center = raw.where((s) => s.walkingMinutesToCenter <= 10 || s.neighborhood.toLowerCase().contains('centro')).toList();
      if (center.isNotEmpty) list = center;
    }
    return list;
  }

  List<String> _getContextualTags(StayOffer stay) {
    final dest = widget.destination.toLowerCase();
    final neigh = stay.neighborhood.toLowerCase();
    final name = stay.name.toLowerCase();

    if (dest.contains('tenerife') || dest.contains('canarie')) {
      if (neigh.contains('isora') || name.contains('abama')) {
        return ['📍 Vicino al Parco del Teide (Giorno 1)', '🌅 Miglior tramonto sull\'oceano'];
      }
      if (neigh.contains('adeje') || neigh.contains('paraiso') || name.contains('hard rock')) {
        return ['🌊 Fronte mare a Costa Adeje', '🍹 Strategico per vita serale & relax'];
      }
      if (neigh.contains('puerto de la cruz') || name.contains('botánico')) {
        return ['🏛️ Comodo per La Laguna & Parco di Anaga', '🌺 Giardini subtropicali & Spa'];
      }
      if (neigh.contains('laguna')) {
        return ['🚶 Nel centro storico UNESCO • Tutto a piedi', '🍽️ A 2 min dai tipici guachinches'];
      }
    }

    // Default context tags
    if (stay.walkingMinutesToCenter <= 5) {
      return ['🚶 A soli ${stay.walkingMinutesToCenter} min a piedi dal centro', '🏛️ Posizione ottima per i monumenti'];
    } else if (stay.pricePerNightEur < 110) {
      return ['💡 Prezzo imbattibile per la qualità', '🚇 Comodo per raggiungere le tappe'];
    } else {
      return ['📍 Posizione strategica per l\'itinerario', '⭐ Alta valutazione dagli ospiti'];
    }
  }

  void _simulateBookingDialog(StayOffer stay) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified_rounded, color: Colors.blue, size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Conferma Alloggio', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stay.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                stay.neighborhood,
                style: TextStyle(color: Theme.of(ctx).colorScheme.onSurfaceVariant, fontSize: 13),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tariffa a notte', style: TextStyle(fontSize: 13)),
                        Text('${stay.pricePerNightEur.toInt()} €', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Cancellazione', style: TextStyle(fontSize: 13)),
                        Text('Gratuita', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                setState(() => _activeSelectedStay = stay);
                widget.onStayBooked(stay);
                Navigator.of(context).pop();
              },
              child: const Text('Conferma questo hotel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveStays = _getFilteredStays(
      _currentStays.isNotEmpty
          ? _currentStays
          : [
              StayOffer(
                id: 'default-stay-1',
                name: 'Hotel Boutique Central',
                type: StayType.boutiqueHotel,
                neighborhood: 'Centro Storico',
                ratingScore: 9.1,
                ratingCount: 1200,
                ratingLabel: 'Eccellente',
                pricePerNightEur: 110,
                walkingMinutesToCenter: 4,
                amenities: ['Wi-Fi veloce', 'Colazione inclusa', 'Cancellazione gratuita'],
                imageUrl: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',
                badgeLabel: 'Miglior Rapporto Qualità-Prezzo',
                bookingUrl: 'https://www.google.com/travel/hotels',
              ),
            ],
    );

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.90,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 38,
              height: 5,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          // Header essenziale e pulito con opzione SALTA ben visibile
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 16, 6),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dove Alloggiare a ${widget.destination}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Hotel selezionati in base al tuo itinerario',
                        style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                // Tasto Salta / Ho già un alloggio
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onSkip?.call();
                  },
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: colorScheme.primary,
                  ),
                  child: const Text(
                    'Salta alloggio',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 22),
                  tooltip: 'Chiudi',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Tab Bar
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Hotel Consigliati'),
              Tab(text: 'Zone & Quartieri'),
            ],
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: Hotel Scremati da Iter con Chat / Refinement Bar
                Column(
                  children: [
                    // Barra Chat / Raffina Opzioni rapida
                    Container(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                      color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Chip filtri rapidi
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _FilterPill(
                                  label: 'Tutti',
                                  icon: Icons.all_inclusive_rounded,
                                  isSelected: _activeFilter == 'all',
                                  onTap: () => setState(() => _activeFilter = 'all'),
                                ),
                                const SizedBox(width: 8),
                                _FilterPill(
                                  label: 'Più economici',
                                  icon: Icons.savings_outlined,
                                  isSelected: _activeFilter == 'budget',
                                  onTap: () => setState(() => _activeFilter = 'budget'),
                                ),
                                const SizedBox(width: 8),
                                _FilterPill(
                                  label: 'Con piscina/spa',
                                  icon: Icons.pool_rounded,
                                  isSelected: _activeFilter == 'pool',
                                  onTap: () => setState(() => _activeFilter = 'pool'),
                                ),
                                const SizedBox(width: 8),
                                _FilterPill(
                                  label: 'Fronte mare',
                                  icon: Icons.waves_rounded,
                                  isSelected: _activeFilter == 'sea',
                                  onTap: () => setState(() => _activeFilter = 'sea'),
                                ),
                                const SizedBox(width: 8),
                                _FilterPill(
                                  label: 'In centro storico',
                                  icon: Icons.location_city_rounded,
                                  isSelected: _activeFilter == 'center',
                                  onTap: () => setState(() => _activeFilter = 'center'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Mini input chat: "Chiedi altri alloggi a Iter"
                          Container(
                            height: 38,
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 10),
                                Icon(Icons.auto_awesome, size: 16, color: colorScheme.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _customQueryController,
                                    style: const TextStyle(fontSize: 12),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      hintText: 'Non ti piacciono? Chiedi a Iter (es. con terrazza)...',
                                      hintStyle: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                    ),
                                    onSubmitted: _handleCustomQuery,
                                  ),
                                ),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  icon: Icon(Icons.arrow_upward_rounded, size: 18, color: colorScheme.primary),
                                  onPressed: () => _handleCustomQuery(_customQueryController.text),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Lista Hotel
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        itemCount: effectiveStays.length + 1,
                        itemBuilder: (context, idx) {
                          if (idx == effectiveStays.length) {
                            return Container(
                              margin: const EdgeInsets.only(top: 8, bottom: 20),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.35)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.tune_rounded, size: 20, color: colorScheme.primary),
                                      const SizedBox(width: 8),
                                      const Expanded(
                                        child: Text(
                                          'Non hai trovato l\'alloggio ideale?',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Puoi rimescolare le opzioni o chiedere direttamente a Iter in chat indicando le tue preferenze (es. quartiere specifico, hotel con vista mare o spa).',
                                    style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant, height: 1.3),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: _regenerateStays,
                                          icon: const Icon(Icons.refresh_rounded, size: 16),
                                          label: const Text('Rinnova alloggi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: FilledButton.icon(
                                          onPressed: _askInChat,
                                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                                          label: const Text('Chiedi in chat', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }
                          final stay = effectiveStays[idx];
                          final isBooked = _activeSelectedStay?.id == stay.id;
                          final contextTags = _getContextualTags(stay);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isBooked ? Colors.green : colorScheme.outlineVariant.withValues(alpha: 0.3),
                                width: isBooked ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Cover Image con Badge
                                Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                      child: SizedBox(
                                        height: 155,
                                        width: double.infinity,
                                        child: Image.network(
                                          stay.imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) => Container(
                                            color: colorScheme.primaryContainer,
                                            child: Icon(Icons.hotel_rounded, size: 40, color: colorScheme.primary),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 12,
                                      left: 12,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE7FF67),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          stay.badgeLabel,
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (isBooked)
                                      Positioned(
                                        top: 12,
                                        right: 12,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.check_circle, color: Colors.white, size: 14),
                                              SizedBox(width: 4),
                                              Text(
                                                'SELEZIONATO',
                                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),

                                Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Nome e Rating
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              stay.name,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: Colors.amber.withValues(alpha: 0.18),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.star_rounded, size: 15, color: Colors.amber),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${stay.ratingScore}',
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        stay.neighborhood,
                                        style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                                      ),

                                      // TAG CONTESTUALI ALL'ITINERARIO
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: contextTags.map((t) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              t,
                                              style: TextStyle(
                                                color: colorScheme.primary,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),

                                      const SizedBox(height: 12),
                                      const Divider(height: 1),
                                      const SizedBox(height: 10),

                                      // Prezzo e Bottone Seleziona
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${stay.pricePerNightEur.toInt()} €',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 20,
                                                  color: colorScheme.primary,
                                                ),
                                              ),
                                              Text(
                                                '/ notte • tasse incluse',
                                                style: TextStyle(fontSize: 11, color: colorScheme.outline),
                                              ),
                                            ],
                                          ),
                                          FilledButton.icon(
                                            onPressed: () => _simulateBookingDialog(stay),
                                            style: FilledButton.styleFrom(
                                              backgroundColor: isBooked ? Colors.green : colorScheme.primary,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                            ),
                                            icon: Icon(isBooked ? Icons.check : Icons.done_rounded, size: 16),
                                            label: Text(
                                              isBooked ? 'Confermato' : 'Seleziona questo alloggio',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                // TAB 2: Zone & Quartieri (Senza testi ridondanti o patronizing)
                ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                  children: [
                    if (widget.neighborhoods.isEmpty) ...[
                      _NeighborhoodCard(
                        name: 'Costa Adeje & Playa Paraíso (Sud Mare)',
                        why: 'Spiagge dorate, clima caldo tutto l\'anno, resort sul mare e ottimi collegamenti.',
                        priceLabel: '~140€ / notte',
                        isSelected: _selectedZone?.contains('Costa') == true,
                        onSelect: () {
                          setState(() {
                            _selectedZone = 'Costa';
                            _activeFilter = 'sea';
                          });
                          _tabController.animateTo(0);
                        },
                      ),
                      _NeighborhoodCard(
                        name: 'San Cristóbal de La Laguna (Centro Storico)',
                        why: 'Città universitaria patrimonio UNESCO, architettura coloniale, vicina all\'aeroporto Nord.',
                        priceLabel: '~90€ / notte',
                        isSelected: _selectedZone?.contains('Laguna') == true,
                        onSelect: () {
                          setState(() {
                            _selectedZone = 'Laguna';
                            _activeFilter = 'center';
                          });
                          _tabController.animateTo(0);
                        },
                      ),
                      _NeighborhoodCard(
                        name: 'Puerto de la Cruz (Nord Verde)',
                        why: 'Atmosfera autentica canaria, giardini botanici, piscine naturali di San Telmo.',
                        priceLabel: '~115€ / notte',
                        isSelected: _selectedZone?.contains('Puerto') == true,
                        onSelect: () {
                          setState(() {
                            _selectedZone = 'Puerto';
                            _activeFilter = 'all';
                          });
                          _tabController.animateTo(0);
                        },
                      ),
                    ] else ...[
                      ...widget.neighborhoods.map((n) {
                        final isSel = _selectedZone == n.name;
                        return _NeighborhoodCard(
                          name: n.name,
                          why: n.why,
                          priceLabel: '~120€ / notte',
                          isSelected: isSel,
                          onSelect: () {
                            setState(() {
                              _selectedZone = n.name;
                              _activeFilter = 'all';
                            });
                            _tabController.animateTo(0);
                          },
                        );
                      }),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NeighborhoodCard extends StatelessWidget {
  const _NeighborhoodCard({
    required this.name,
    required this.why,
    required this.priceLabel,
    required this.isSelected,
    required this.onSelect,
  });

  final String name;
  final String why;
  final String priceLabel;
  final bool isSelected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? colorScheme.primary : colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onSelect,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      priceLabel,
                      style: TextStyle(fontSize: 11, color: colorScheme.primary, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                why,
                style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13, height: 1.3),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Mostra hotel in questa zona',
                    style: TextStyle(color: colorScheme.primary, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 14, color: colorScheme.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
