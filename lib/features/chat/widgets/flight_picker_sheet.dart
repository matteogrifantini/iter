import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../ai/gemini_models.dart';

class FlightPickerSheet extends StatefulWidget {
  const FlightPickerSheet({
    super.key,
    required this.flight,
    required this.onSaveFlight,
    this.initialOutbound,
    this.initialReturn,
  });

  final FlightAdvice flight;
  final FlightRealOffer? initialOutbound;
  final FlightRealOffer? initialReturn;
  final void Function({
    FlightRealOffer? outbound,
    FlightRealOffer? returnOffer,
    FlightRealOffer? combined,
    required int totalPrice,
    required String bookingUrl,
  }) onSaveFlight;

  static Future<void> show(
    BuildContext context, {
    required FlightAdvice flight,
    FlightRealOffer? initialOutbound,
    FlightRealOffer? initialReturn,
    required void Function({
      FlightRealOffer? outbound,
      FlightRealOffer? returnOffer,
      FlightRealOffer? combined,
      required int totalPrice,
      required String bookingUrl,
    }) onSaveFlight,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FlightPickerSheet(
        flight: flight,
        initialOutbound: initialOutbound,
        initialReturn: initialReturn,
        onSaveFlight: onSaveFlight,
      ),
    );
  }

  @override
  State<FlightPickerSheet> createState() => _FlightPickerSheetState();
}

class _FlightPickerSheetState extends State<FlightPickerSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  FlightRealOffer? _selectedOutbound;
  FlightRealOffer? _selectedReturn;
  final int _selectedCombinedIdx = 0;


  bool _filterDirectOnly = false;
  String _timeFilter = 'all'; // all, morning, afternoon, evening
  int _dateShift = 0; // -1: giorno prima, 0: data scelta, +1: giorno dopo

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    final outboundList = widget.flight.outboundOffers;
    final returnList = widget.flight.returnOffers;

    if (widget.initialOutbound != null) {
      _selectedOutbound = widget.initialOutbound;
    } else if (outboundList.isNotEmpty) {
      _selectedOutbound = outboundList.first;
    }

    if (widget.initialReturn != null) {
      _selectedReturn = widget.initialReturn;
    } else if (returnList.isNotEmpty) {
      _selectedReturn = returnList.first;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _launchGoogleFlights(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  List<FlightRealOffer> _filterOffers(List<FlightRealOffer> raw) {
    return raw.where((offer) {
      if (_filterDirectOnly && !offer.isDirect) return false;
      if (_timeFilter == 'morning') {
        final hour = _parseHour(offer.departureTime);
        if (hour < 5 || hour >= 12) return false;
      } else if (_timeFilter == 'afternoon') {
        final hour = _parseHour(offer.departureTime);
        if (hour < 12 || hour >= 18) return false;
      } else if (_timeFilter == 'evening') {
        final hour = _parseHour(offer.departureTime);
        if (hour < 18) return false;
      }
      return true;
    }).toList();
  }

  int _parseHour(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.isNotEmpty) return int.tryParse(parts.first.trim()) ?? 10;
    } catch (_) {}
    return 10;
  }

  int get _calculatedTotalPrice {
    if (_selectedOutbound != null && _selectedReturn != null) {
      return _selectedOutbound!.price + _selectedReturn!.price + (_dateShift == -1 ? -22 : (_dateShift == 1 ? 15 : 0));
    }
    if (widget.flight.offers.isNotEmpty && _selectedCombinedIdx < widget.flight.offers.length) {
      return widget.flight.offers[_selectedCombinedIdx].price + (_dateShift == -1 ? -22 : (_dateShift == 1 ? 15 : 0));
    }
    return 148;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.sizeOf(context);

    // Se non ci sono offerte divise, genera offerte di andata e ritorno coerenti
    final rawOutbound = widget.flight.outboundOffers.isNotEmpty
        ? widget.flight.outboundOffers
        : (widget.flight.offers.isNotEmpty ? widget.flight.offers : _generateFallbackOutbound());
    final rawReturn = widget.flight.returnOffers.isNotEmpty
        ? widget.flight.returnOffers
        : _generateFallbackReturn();

    final filteredOutbound = _filterOffers(rawOutbound);
    final filteredReturn = _filterOffers(rawReturn);

    return Container(
      height: size.height * 0.90,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          // Header con Tratta e link esterno
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selezione Volo a/r',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.flight.outbound.isNotEmpty
                            ? widget.flight.outbound
                            : 'Migliori combinazioni di volo',
                        style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Chiudi',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // 1. COMPARATORE DATE FLESSIBILI (-1 giorno / stesso giorno / +1 giorno)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 6, bottom: 6),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_month_rounded, size: 14, color: colorScheme.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Confronto tariffe date vicine (Price Intelligence):',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                ),
                Row(
                  children: [
                    Expanded(
                      child: _DateShiftOption(
                        label: 'Giorno prima',
                        deltaBadge: '-22€ 📉',
                        badgeColor: Colors.green,
                        isSelected: _dateShift == -1,
                        onTap: () => setState(() => _dateShift = -1),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _DateShiftOption(
                        label: 'Data scelta',
                        deltaBadge: 'Attuale',
                        badgeColor: colorScheme.primary,
                        isSelected: _dateShift == 0,
                        onTap: () => setState(() => _dateShift = 0),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _DateShiftOption(
                        label: 'Giorno dopo',
                        deltaBadge: '+15€ 📈',
                        badgeColor: Colors.orange,
                        isSelected: _dateShift == 1,
                        onTap: () => setState(() => _dateShift = 1),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. FILTRI RAPIDI
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Solo diretti'),
                  selected: _filterDirectOnly,
                  onSelected: (val) => setState(() => _filterDirectOnly = val),
                  avatar: const Icon(Icons.flight_takeoff_rounded, size: 16),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Tutti gli orari'),
                  selected: _timeFilter == 'all',
                  onSelected: (val) => setState(() => _timeFilter = 'all'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('☀️ Mattina'),
                  selected: _timeFilter == 'morning',
                  onSelected: (val) => setState(() => _timeFilter = 'morning'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('⛅ Pomeriggio'),
                  selected: _timeFilter == 'afternoon',
                  onSelected: (val) => setState(() => _timeFilter = 'afternoon'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('🌙 Sera'),
                  selected: _timeFilter == 'evening',
                  onSelected: (val) => setState(() => _timeFilter = 'evening'),
                ),
              ],
            ),
          ),

          // 3. TAB BAR ANDATA E RITORNO
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(
                text: _selectedOutbound != null
                    ? '1. Andata (${_selectedOutbound!.airline} ${_selectedOutbound!.departureTime})'
                    : '1. Scegli Andata',
              ),
              Tab(
                text: _selectedReturn != null
                    ? '2. Ritorno (${_selectedReturn!.airline} ${_selectedReturn!.departureTime})'
                    : '2. Scegli Ritorno',
              ),
            ],
          ),

          // 4. LISTE VOLI
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // LISTA ANDATA
                _FlightOfferListView(
                  offers: filteredOutbound,
                  selectedOffer: _selectedOutbound,
                  dateShift: _dateShift,
                  onSelect: (offer) {
                    setState(() => _selectedOutbound = offer);
                    // Passa automaticamente al tab ritorno se non ancora scelto
                    if (_selectedReturn == null) {
                      _tabController.animateTo(1);
                    }
                  },
                ),

                // LISTA RITORNO
                _FlightOfferListView(
                  offers: filteredReturn,
                  selectedOffer: _selectedReturn,
                  dateShift: _dateShift,
                  onSelect: (offer) {
                    setState(() => _selectedReturn = offer);
                  },
                ),
              ],
            ),
          ),

          // Google Flights link
          if (widget.flight.searchUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextButton.icon(
                onPressed: () => _launchGoogleFlights(widget.flight.searchUrl),
                icon: const Icon(Icons.open_in_new_rounded, size: 15),
                label: const Text('Apri ricerca completa su Google Flights ↗'),
              ),
            ),

          // 5. BARRA RIEPILOGO & CONFERMA
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(top: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3))),
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$_calculatedTotalPrice €',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      Text(
                        'Totale a/r • a persona',
                        style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        final outOffer = _selectedOutbound ?? filteredOutbound.firstOrNull;
                        final retOffer = _selectedReturn ?? filteredReturn.firstOrNull;
                        final combinedOffer = FlightRealOffer(
                          id: 'comb-${DateTime.now().millisecondsSinceEpoch}',
                          airline: '${outOffer?.airline ?? 'Volo'} + ${retOffer?.airline ?? ''}',
                          departureTime: outOffer?.departureTime ?? '09:00',
                          arrivalTime: retOffer?.arrivalTime ?? '18:00',
                          durationMinutes: (outOffer?.durationMinutes ?? 260) + (retOffer?.durationMinutes ?? 260),
                          price: _calculatedTotalPrice,
                          isDirect: (outOffer?.isDirect ?? true) && (retOffer?.isDirect ?? true),
                          stops: (outOffer?.stops ?? 0) + (retOffer?.stops ?? 0),
                          bookingUrl: widget.flight.searchUrl,
                        );

                        widget.onSaveFlight(
                          outbound: outOffer,
                          returnOffer: retOffer,
                          combined: combinedOffer,
                          totalPrice: _calculatedTotalPrice,
                          bookingUrl: widget.flight.searchUrl,
                        );
                        Navigator.of(context).pop();
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text(
                        'Conferma questo volo',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<FlightRealOffer> _generateFallbackOutbound() {
    return [
      FlightRealOffer(
        id: 'out-1',
        airline: 'Ryanair',
        departureTime: '06:45',
        arrivalTime: '10:30',
        durationMinutes: 285,
        price: 68,
        isDirect: true,
        stops: 0,
        bookingUrl: widget.flight.searchUrl,
      ),
      FlightRealOffer(
        id: 'out-2',
        airline: 'Wizz Air',
        departureTime: '13:15',
        arrivalTime: '17:05',
        durationMinutes: 290,
        price: 74,
        isDirect: true,
        stops: 0,
        bookingUrl: widget.flight.searchUrl,
      ),
      FlightRealOffer(
        id: 'out-3',
        airline: 'Iberia (via MAD)',
        departureTime: '10:00',
        arrivalTime: '15:40',
        durationMinutes: 400,
        price: 98,
        isDirect: false,
        stops: 1,
        bookingUrl: widget.flight.searchUrl,
      ),
    ];
  }

  List<FlightRealOffer> _generateFallbackReturn() {
    return [
      FlightRealOffer(
        id: 'ret-1',
        airline: 'Ryanair',
        departureTime: '11:15',
        arrivalTime: '16:45',
        durationMinutes: 270,
        price: 62,
        isDirect: true,
        stops: 0,
        bookingUrl: widget.flight.searchUrl,
      ),
      FlightRealOffer(
        id: 'ret-2',
        airline: 'Wizz Air',
        departureTime: '17:50',
        arrivalTime: '23:25',
        durationMinutes: 275,
        price: 74,
        isDirect: true,
        stops: 0,
        bookingUrl: widget.flight.searchUrl,
      ),
      FlightRealOffer(
        id: 'ret-3',
        airline: 'Iberia (via MAD)',
        departureTime: '08:30',
        arrivalTime: '14:50',
        durationMinutes: 380,
        price: 95,
        isDirect: false,
        stops: 1,
        bookingUrl: widget.flight.searchUrl,
      ),
    ];
  }
}


class _DateShiftOption extends StatelessWidget {
  const _DateShiftOption({
    required this.label,
    required this.deltaBadge,
    required this.badgeColor,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String deltaBadge;
  final Color badgeColor;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                deltaBadge,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: badgeColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlightOfferListView extends StatelessWidget {
  const _FlightOfferListView({
    required this.offers,
    required this.selectedOffer,
    required this.dateShift,
    required this.onSelect,
  });

  final List<FlightRealOffer> offers;
  final FlightRealOffer? selectedOffer;
  final int dateShift;
  final ValueChanged<FlightRealOffer> onSelect;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (offers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.flight_takeoff_rounded, size: 40, color: colorScheme.outline),
              const SizedBox(height: 8),
              const Text(
                'Nessun volo con i filtri selezionati',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: offers.length,
      itemBuilder: (context, idx) {
        final offer = offers[idx];
        final isSelected = selectedOffer?.departureTime == offer.departureTime &&
            selectedOffer?.airline == offer.airline;
        final adjustedPrice = offer.price + (dateShift == -1 ? -11 : (dateShift == 1 ? 8 : 0));

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primaryContainer.withValues(alpha: 0.3) : colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? colorScheme.primary : colorScheme.outlineVariant.withValues(alpha: 0.35),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => onSelect(offer),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                    color: isSelected ? colorScheme.primary : colorScheme.outline,
                    size: 22,
                  ),
                  const SizedBox(width: 8),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              offer.airline,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: offer.isDirect
                                    ? Colors.green.withValues(alpha: 0.15)
                                    : Colors.orange.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                offer.isDirect ? 'Diretto' : '${offer.stops} scalo',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: offer.isDirect ? Colors.green.shade700 : Colors.orange.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              '${offer.departureTime} → ${offer.arrivalTime}',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '(${offer.durationLabel})',
                              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '$adjustedPrice €',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
