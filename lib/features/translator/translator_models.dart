/// A travel phrase categorized for quick offline and audio use.
class TravelPhrase {
  const TravelPhrase({
    required this.italian,
    required this.translated,
    required this.pronunciation,
    required this.category,
  });

  final String italian;
  final String translated;
  final String pronunciation;
  final String
  category; // 'Base & Saluti', 'Ristorante', 'Direzioni', 'Emergenze', 'Shopping & Pagamenti'
}

/// Supported destination language profile.
class LanguageProfile {
  const LanguageProfile({
    required this.code,
    required this.name,
    required this.flagEmoji,
    required this.phrases,
  });

  final String code; // 'hu', 'pt', 'es', 'fr', 'de', 'ja'
  final String name;
  final String flagEmoji;
  final List<TravelPhrase> phrases;
}
