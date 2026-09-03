import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../ai/gemini_models.dart';
import '../../flights/google_flights_url_builder.dart';

/// Interactive card allowing the user to select their outbound and return flights step-by-step,
/// see the combined configured total, and open Google Flights with the configured flight.
class FlightSelectorCard extends StatefulWidget {
  const FlightSelectorCard({
    super.key,
    required this.flight,
    this.initialDirectOnly = false,
    this.onDirectFilterChanged,
    this.onOptionSaved,
  });

  final FlightAdvice flight;
  final bool initialDirectOnly;
  final ValueChanged<bool>? onDirectFilterChanged;
  final void Function({
    FlightRealOffer? outbound,
    FlightRealOffer? returnOffer,
    FlightRealOffer? combined,
    required int totalPrice,
    required String bookingUrl,
  })? onOptionSaved;

  @override
  State<FlightSelectorCard> createState() => _FlightSelectorCardState();
}

class _FlightSelectorCardState extends State<FlightSelectorCard> {
  int _activeTabIndex = 0; // 0: Andata, 1: Ritorno, 2: Pacchetti
  FlightRealOffer? _selectedOutbound;
  FlightRealOffer? _selectedReturn;
  FlightRealOffer? _selectedCombined;
  late bool _directOnly;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _directOnly = widget.initialDirectOnly;
    _initSelections();
  }

  @override
  void didUpdateWidget(covariant FlightSelectorCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.flight != widget.flight) {
      _initSelections();
    }
  }

  void _initSelections() {
    final outs = _filteredList(widget.flight.outboundOffers);
    if (outs.isNotEmpty && _selectedOutbound == null) {
      _selectedOutbound = outs.first;
    }
    final rets = _filteredList(widget.flight.returnOffers);
    if (rets.isNotEmpty && _selectedReturn == null) {
      _selectedReturn = rets.first;
    }
    final combs = _filteredList(widget.flight.offers);
    if (combs.isNotEmpty && _selectedCombined == null) {
      _selectedCombined = combs.first;
    }
  }

  List<FlightRealOffer> _filteredList(List<FlightRealOffer> list) {
    if (!_directOnly) return list;
    return list.where((f) => f.isDirect).toList();
  }

  int get _totalPrice {
    if (_activeTabIndex == 2 && _selectedCombined != null) {
      return _selectedCombined!.price;
    }
    if (_selectedOutbound != null && _selectedReturn != null) {
      return _selectedOutbound!.price + _selectedReturn!.price;
    }
    if (_selectedCombined != null) {
      return _selectedCombined!.price;
    }
    return 0;
  }

  Future<void> _launchConfiguredGoogleFlights() async {
    final effectiveUrl = GoogleFlightsUrlBuilder.build(
      destination: widget.flight.outbound,
      rawUrl: widget.flight.searchUrl,
    );
    final uri = Uri.tryParse(effectiveUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _formatLegDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso);
      return GoogleFlightsUrlBuilder.formatShortDate(dt);
    } catch (_) {
      return '';
    }
  }

  Color _evalColor(String? eval) {
    if (eval == 'economico') return Colors.green;
    if (eval == 'alto') return Colors.orange;
    return const Color(0xFF1976D2);
  }

  IconData _evalIcon(String? eval) {
    if (eval == 'economico') return Icons.trending_down_rounded;
    if (eval == 'alto') return Icons.info_outline_rounded;
    return Icons.thumb_up_alt_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isSaved) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green.withValues(alpha: 0.45)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.green, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Opzione di volo salvata nel viaggio',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        'Totale stimato: $_totalPrice € a/r',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _isSaved = false),
                  child: const Text('Modifica'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_selectedOutbound != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '• Andata: ${_selectedOutbound!.airline} (${_selectedOutbound!.departureTime} ➔ ${_selectedOutbound!.arrivalTime})',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            if (_selectedReturn != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '• Ritorno: ${_selectedReturn!.airline} (${_selectedReturn!.departureTime} ➔ ${_selectedReturn!.arrivalTime})',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            if (_activeTabIndex == 2 && _selectedCombined != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '• Pacchetto: ${_selectedCombined!.airline} (${_selectedCombined!.departureTime} ➔ ${_selectedCombined!.arrivalTime})',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Acquisto disponibile nel riepilogo viaggio',
                  style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                ),
                TextButton.icon(
                  onPressed: _launchConfiguredGoogleFlights,
                  icon: const Icon(Icons.open_in_new_rounded, size: 13),
                  label: const Text('Vedi su Google Flights', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),

          ],
        ),
      );
    }

    final rawOut = _filteredList(widget.flight.outboundOffers);
    final rawRet = _filteredList(widget.flight.returnOffers);
    final rawComb = _filteredList(widget.flight.offers);

    // Limit to top 4 options so the user has the best choices without long scrolling
    final outboundList = rawOut.take(4).toList();
    final returnList = rawRet.take(4).toList();
    final combinedList = rawComb.take(4).toList();

    final hasSeparateLegs = outboundList.isNotEmpty || returnList.isNotEmpty;

    final depDateLabel = _formatLegDate(widget.flight.departureDateStr);
    final retDateLabel = _formatLegDate(widget.flight.returnDateStr);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con destinazione e date
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.flight_takeoff_rounded, color: colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Configura il tuo Volo',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (widget.flight.formattedDates != null && widget.flight.formattedDates!.isNotEmpty)
                      Text(
                        '🗓️ ${widget.flight.formattedDates!}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      )
                    else
                      Text(
                        widget.flight.outbound,
                        style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
              // Filter chip solo diretti
              FilterChip(
                selected: _directOnly,
                label: const Text('Solo diretti', style: TextStyle(fontSize: 11)),
                onSelected: (val) {
                  setState(() {
                    _directOnly = val;
                  });
                  widget.onDirectFilterChanged?.call(val);
                },
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
            ],
          ),

          // Banner con consiglio tariffario AI (se presente)
          if (widget.flight.priceAdvice != null && widget.flight.priceAdvice!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: _evalColor(widget.flight.priceEvaluation).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _evalColor(widget.flight.priceEvaluation).withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _evalIcon(widget.flight.priceEvaluation),
                    size: 16,
                    color: _evalColor(widget.flight.priceEvaluation),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.flight.priceAdvice!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),

          // Tabs per scegliere Andata, Ritorno o Pacchetti A/R
          if (hasSeparateLegs) ...[
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(3),
              child: Row(
                children: [
                  Expanded(
                    child: _TabButton(
                      label: depDateLabel.isNotEmpty ? '1. Andata ($depDateLabel)' : '1. Andata',
                      icon: Icons.flight_takeoff_rounded,
                      isActive: _activeTabIndex == 0,
                      badge: _selectedOutbound != null ? '${_selectedOutbound!.price}€' : null,
                      onTap: () => setState(() => _activeTabIndex = 0),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _TabButton(
                      label: retDateLabel.isNotEmpty ? '2. Ritorno ($retDateLabel)' : '2. Ritorno',
                      icon: Icons.flight_land_rounded,
                      isActive: _activeTabIndex == 1,
                      badge: _selectedReturn != null ? '${_selectedReturn!.price}€' : null,
                      onTap: () => setState(() => _activeTabIndex = 1),
                    ),
                  ),
                  if (combinedList.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Expanded(
                      child: _TabButton(
                        label: '3. A/R Insieme',
                        icon: Icons.sync_alt_rounded,
                        isActive: _activeTabIndex == 2,
                        badge: 'da ${combinedList.first.price}€',
                        onTap: () => setState(() => _activeTabIndex = 2),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Contenuto del tab attivo (max 4 opzioni selezionate e compatte)
            if (_activeTabIndex == 0) ...[
              if (outboundList.isEmpty)
                _emptyMessage('Nessun volo di andata diretto trovato.')
              else
                ...outboundList.map((offer) => _FlightOptionTile(
                      offer: offer,
                      isSelected: _selectedOutbound?.id == offer.id,
                      onSelect: () => setState(() => _selectedOutbound = offer),
                    )),
            ] else if (_activeTabIndex == 1) ...[
              if (returnList.isEmpty)
                _emptyMessage('Nessun volo di ritorno diretto trovato.')
              else
                ...returnList.map((offer) => _FlightOptionTile(
                      offer: offer,
                      isSelected: _selectedReturn?.id == offer.id,
                      onSelect: () => setState(() => _selectedReturn = offer),
                    )),
            ] else ...[
              if (combinedList.isEmpty)
                _emptyMessage('Nessun pacchetto a/r diretto trovato.')
              else
                ...combinedList.map((offer) => _FlightOptionTile(
                      offer: offer,
                      isSelected: _selectedCombined?.id == offer.id,
                      onSelect: () => setState(() => _selectedCombined = offer),
                    )),
            ],
          ] else ...[
            // Se non ci sono tratte separate, mostra le opzioni a/r combinate
            if (combinedList.isEmpty)
              _emptyMessage('Nessun volo diretto trovato.')
            else
              ...combinedList.map((offer) => _FlightOptionTile(
                    offer: offer,
                    isSelected: _selectedCombined?.id == offer.id,
                    onSelect: () => setState(() => _selectedCombined = offer),
                  )),
          ],

          const Divider(height: 20),

          // Riepilogo Configurazione e Salva e Prosegui
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Totale stimato a/r',
                      style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                    Text(
                      _totalPrice > 0 ? '$_totalPrice €' : widget.flight.priceEstimate,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () {
                  setState(() => _isSaved = true);
                  widget.onOptionSaved?.call(
                    outbound: _selectedOutbound,
                    returnOffer: _selectedReturn,
                    combined: _selectedCombined,
                    totalPrice: _totalPrice,
                    bookingUrl: widget.flight.searchUrl,
                  );
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: const Text('Salva opzione e prosegui', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _launchConfiguredGoogleFlights,
              icon: const Icon(Icons.open_in_new_rounded, size: 13),
              label: const Text('Vedi su Google Flights', style: TextStyle(fontSize: 11)),
            ),
          ),
        ],
      ),
    );
  }



  Widget _emptyMessage(String msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          msg,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.icon,
    required this.isActive,
    this.badge,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isActive;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: isActive ? colorScheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isActive
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isActive ? colorScheme.primaryContainer : colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge!,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isActive ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        ),

      ),
    );
  }
}

class _FlightOptionTile extends StatelessWidget {
  const _FlightOptionTile({
    required this.offer,
    required this.isSelected,
    required this.onSelect,
  });

  final FlightRealOffer offer;
  final bool isSelected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primaryContainer.withValues(alpha: 0.25) : colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outlineVariant.withValues(alpha: 0.35),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: isSelected ? colorScheme.primary : colorScheme.outline,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        offer.airline,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: offer.isDirect ? Colors.green.withValues(alpha: 0.12) : colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          offer.isDirect ? 'Diretto' : '${offer.stops} scalo',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: offer.isDirect ? Colors.green.shade800 : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      if (offer.badge != null && offer.badge!.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: offer.badge == 'Miglior prezzo'
                                ? Colors.green.withValues(alpha: 0.15)
                                : colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            offer.badge!,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: offer.badge == 'Miglior prezzo'
                                  ? Colors.green.shade800
                                  : colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),

                  Text(
                    '${offer.departureTime} – ${offer.arrivalTime} (${offer.durationLabel})',
                    style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Text(
              '${offer.price} €',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
