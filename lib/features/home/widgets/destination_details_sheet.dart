import 'package:flutter/material.dart';
import '../../places/visual_media_service.dart';

class DestinationDetailsSheet extends StatefulWidget {
  const DestinationDetailsSheet({
    super.key,
    required this.destination,
    required this.onStartPlanning,
    this.visualData,
  });

  final String destination;
  final ValueChanged<String> onStartPlanning;
  final DestinationVisualData? visualData;

  static Future<void> show(
    BuildContext context, {
    required String destination,
    required ValueChanged<String> onStartPlanning,
    DestinationVisualData? visualData,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DestinationDetailsSheet(
        destination: destination,
        onStartPlanning: onStartPlanning,
        visualData: visualData,
      ),
    );
  }

  @override
  State<DestinationDetailsSheet> createState() => _DestinationDetailsSheetState();
}

class _DestinationDetailsSheetState extends State<DestinationDetailsSheet> {
  DestinationVisualData? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.visualData != null) {
      _data = widget.visualData;
      _loading = false;
    } else {
      _loadData();
    }
  }


  Future<void> _loadData() async {
    try {
      final data = await VisualMediaService().getVisualData(widget.destination);
      if (mounted) {
        setState(() {
          _data = data;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.sizeOf(context);

    return Container(
      height: size.height * 0.85,
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

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.destination,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
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

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator.adaptive())
                : _data == null
                    ? Center(
                        child: Text(
                          'Informazioni non disponibili al momento.',
                          style: TextStyle(color: colorScheme.outline),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        children: [
                          // Gallery foto
                          if (_data!.images.isNotEmpty) ...[
                            SizedBox(
                              height: 220,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: PageView.builder(
                                  itemCount: _data!.images.length,
                                  itemBuilder: (context, idx) {
                                    return Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image.network(
                                          _data!.images[idx],
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) => Container(
                                            color: colorScheme.primaryContainer,
                                            child: Icon(Icons.image_outlined, color: colorScheme.primary, size: 40),
                                          ),
                                        ),
                                        if (_data!.images.length > 1)
                                          Positioned(
                                            bottom: 12,
                                            right: 12,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withValues(alpha: 0.65),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                '${idx + 1} / ${_data!.images.length}',
                                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Tagline
                          Text(
                            _data!.tagline,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 15,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Pill informative
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _InfoBadge(
                                icon: Icons.wb_sunny_outlined,
                                label: _data!.bestPeriod,
                                colorScheme: colorScheme,
                              ),
                              _InfoBadge(
                                icon: Icons.euro_symbol_rounded,
                                label: _data!.averageDailyCost,
                                colorScheme: colorScheme,
                              ),
                              if (_data!.climatePill.isNotEmpty)
                                _InfoBadge(
                                  icon: Icons.thermostat_rounded,
                                  label: _data!.climatePill,
                                  colorScheme: colorScheme,
                                ),
                            ],
                          ),
                          const SizedBox(height: 22),

                          // Highlights / Attrazioni principali
                          if (_data!.highlights.isNotEmpty) ...[
                            Text(
                              'Da non perdere',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _data!.highlights.map((h) {
                                return Chip(
                                  label: Text(h, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                                  avatar: const Icon(Icons.place_rounded, size: 16, color: Colors.redAccent),
                                  backgroundColor: colorScheme.surfaceContainerHigh,
                                  side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 22),
                          ],

                          // Consigli pratici da insider
                          if (_data!.insiderTips.isNotEmpty) ...[
                            Text(
                              'Consigli Iter Insider',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            ..._data!.insiderTips.map((tip) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('💡', style: TextStyle(fontSize: 14)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        tip,
                                        style: TextStyle(
                                          fontSize: 13,
                                          height: 1.35,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ],
                      ),
          ),

          // Bottom Fixed Action Button
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(top: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3))),
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onStartPlanning(widget.destination);
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.auto_awesome_rounded, size: 20),
                  label: Text(
                    'Pianifica viaggio a ${widget.destination}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({
    required this.icon,
    required this.label,
    required this.colorScheme,
  });

  final IconData icon;
  final String label;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
