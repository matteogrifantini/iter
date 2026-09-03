import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'real_place_models.dart';
import 'real_place_service.dart';

/// Bottom sheet displaying live real photos and historical insights fetched from Wikipedia.
class RealPlaceSheet extends StatefulWidget {
  const RealPlaceSheet({super.key, required this.placeTitle, this.destination});

  final String placeTitle;
  final String? destination;

  @override
  State<RealPlaceSheet> createState() => _RealPlaceSheetState();
}

class _RealPlaceSheetState extends State<RealPlaceSheet> {
  final _service = RealPlaceService();
  RealPlaceDetail? _detail;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final detail = await _service.fetchPlaceDetails(
      widget.placeTitle,
      destination: widget.destination,
    );
    if (mounted) {
      setState(() {
        _detail = detail;
        _loading = false;
      });
    }
  }

  Future<void> _openWikipedia() async {
    if (_detail?.wikipediaUrl == null) return;
    final uri = Uri.parse(_detail!.wikipediaUrl!);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_detail == null)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.explore_off_rounded,
                        size: 48,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.placeTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Nessuna scheda enciclopedica trovata per questo luogo.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Photo Hero
                  if (_detail!.imageUrl != null)
                    Container(
                      height: 240,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E232A)
                            : const Color(0xFFE2E8F0),
                      ),
                      child: Image.network(
                        _detail!.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Center(
                          child: Icon(
                            Icons.photo_outlined,
                            size: 48,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _detail!.title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_detail!.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            _detail!.description,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 16),
                        Text(
                          'Storia e Informazioni',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _detail!.extract,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (_detail!.wikipediaUrl != null)
                          OutlinedButton.icon(
                            onPressed: _openWikipedia,
                            icon: const Icon(
                              Icons.open_in_new_rounded,
                              size: 16,
                            ),
                            label: const Text(
                              'Leggi l\'articolo completo su Wikipedia',
                            ),
                          ),
                      ],
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
