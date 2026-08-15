import 'inspiration_models.dart';

InspirationImportResult parseMockInspiration(String rawUrl) {
  final value = rawUrl.trim();
  if (value.isEmpty) {
    return const InspirationImportResult.error('Incolla un link per iniziare.');
  }

  final uri = Uri.tryParse(value);
  if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
    return const InspirationImportResult.error(
      'Usa un link HTTPS di Instagram o TikTok.',
    );
  }

  final host = uri.host.toLowerCase();
  final path = uri.pathSegments.map((segment) => segment.toLowerCase());
  final segments = path.toList(growable: false);

  if ((host == 'www.instagram.com' || host == 'instagram.com') &&
      segments.length == 2 &&
      segments[0] == 'reel' &&
      segments[1] == 'iter-porto') {
    return InspirationImportResult.valid(
      InspirationDraft(
        platform: InspirationPlatform.instagram,
        url: value,
        title: 'Una mattina lenta a Porto',
        placeName: 'Livraria Lello',
        destinationId: 'porto',
        moment: 'Mattina',
        suggestedCategory: 'Cultura',
        mediaAsset: 'assets/images/travel/porto_livraria_lello.jpg',
      ),
    );
  }

  if ((host == 'www.tiktok.com' || host == 'tiktok.com') &&
      segments.length == 2 &&
      segments[0] == '@iter' &&
      segments[1] == 'roma-foro') {
    return InspirationImportResult.valid(
      InspirationDraft(
        platform: InspirationPlatform.tiktok,
        url: value,
        title: 'Roma al tramonto',
        placeName: 'Foro Romano',
        destinationId: 'roma',
        moment: 'Tramonto',
        suggestedCategory: 'Archeologia',
        mediaAsset: 'assets/images/travel/rome_city.jpg',
      ),
    );
  }

  return const InspirationImportResult.error(
    'Per ora puoi provare uno dei link demo di Iter.',
  );
}
