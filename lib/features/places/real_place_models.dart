/// Real place details fetched live from Wikipedia / OpenTripMap.
class RealPlaceDetail {
  const RealPlaceDetail({
    required this.title,
    required this.description,
    required this.extract,
    this.imageUrl,
    this.thumbnailUrl,
    this.latitude,
    this.longitude,
    this.wikipediaUrl,
  });

  final String title;
  final String description;
  final String extract;
  final String? imageUrl;
  final String? thumbnailUrl;
  final double? latitude;
  final double? longitude;
  final String? wikipediaUrl;
}
