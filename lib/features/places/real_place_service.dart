import 'dart:convert';
import 'package:http/http.dart' as http;
import 'real_place_models.dart';

/// Service interfacing with live Wikipedia REST API to get real photos and details for any place.
class RealPlaceService {
  RealPlaceService({http.Client? httpClient})
    : _client = httpClient ?? http.Client();

  final http.Client _client;

  /// Fetches real photos, description and historical summary from Wikipedia.
  Future<RealPlaceDetail?> fetchPlaceDetails(
    String placeName, {
    String? destination,
  }) async {
    final cleanName = _cleanPlaceName(placeName);
    var detail = await _fetchWikipediaSummary('it', cleanName);
    detail ??= await _fetchWikipediaSummary('en', cleanName);

    if (detail == null && destination != null) {
      final combined = '$cleanName, $destination';
      detail = await _fetchWikipediaSummary('it', combined);
      detail ??= await _fetchWikipediaSummary('en', combined);
    }

    return detail;
  }

  Future<RealPlaceDetail?> _fetchWikipediaSummary(
    String lang,
    String title,
  ) async {
    final encoded = Uri.encodeComponent(title.replaceAll(' ', '_'));
    final url = Uri.parse(
      'https://$lang.wikipedia.org/api/rest_v1/page/summary/$encoded',
    );

    try {
      final response = await _client
          .get(
            url,
            headers: {
              'User-Agent': 'IterTravelApp/1.0 (contact@itertravel.app)',
            },
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final type = data['type'] as String?;
        if (type == 'disambiguation') return null;

        final displayTitle = data['title'] as String? ?? title;
        final description = data['description'] as String? ?? '';
        final extract = data['extract'] as String? ?? '';
        final originalImage =
            (data['originalimage'] as Map<String, dynamic>?)?['source']
                as String?;
        final thumbnail =
            (data['thumbnail'] as Map<String, dynamic>?)?['source'] as String?;

        final coordinates = data['coordinates'] as Map<String, dynamic>?;
        final lat = (coordinates?['lat'] as num?)?.toDouble();
        final lon = (coordinates?['lon'] as num?)?.toDouble();

        final contentUrls = data['content_urls'] as Map<String, dynamic>?;
        final desktop = contentUrls?['desktop'] as Map<String, dynamic>?;
        final pageUrl = desktop?['page'] as String?;

        return RealPlaceDetail(
          title: displayTitle,
          description: description,
          extract: extract,
          imageUrl: originalImage ?? thumbnail,
          thumbnailUrl: thumbnail,
          latitude: lat,
          longitude: lon,
          wikipediaUrl: pageUrl,
        );
      }
    } catch (_) {}
    return null;
  }

  String _cleanPlaceName(String name) {
    return name
        .replaceAll(
          RegExp(
            r'^(Passeggiata verso|Visita a|Sosta a|Arrivo a|Pranzo a|Cena a)\s+',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(RegExp(r'\(.*?\)$'), '')
        .trim();
  }
}
