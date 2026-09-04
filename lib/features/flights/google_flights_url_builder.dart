class GoogleFlightsUrlBuilder {
  static const Map<String, String> cityToIata = {
    'budapest': 'BUD',
    'porto': 'OPO',
    'roma': 'ROM',
    'fiumicino': 'FCO',
    'ciampino': 'CIA',
    'milano': 'MIL',
    'malpensa': 'MXP',
    'linate': 'LIN',
    'bergamo': 'BGY',
    'napoli': 'NAP',
    'bologna': 'BLQ',
    'venezia': 'VCE',
    'torino': 'TRN',
    'palermo': 'PMO',
    'catania': 'CTA',
    'messina': 'CTA',
    'taormina': 'CTA',
    'siracusa': 'CTA',
    'trapani': 'TPS',
    'bari': 'BRI',
    'brindisi': 'BDS',
    'cagliari': 'CAG',
    'olbia': 'OLB',
    'alghero': 'AHO',
    'firenze': 'FLR',
    'verona': 'VRN',
    'pisa': 'PSA',
    'genova': 'GOA',
    'lisbona': 'LIS',
    'barcellona': 'BCN',

    'madrid': 'MAD',
    'siviglia': 'SVQ',
    'valencia': 'VLC',
    'parigi': 'CDG',
    'berlino': 'BER',
    'monaco': 'MUC',
    'monaco di baviera': 'MUC',
    'munich': 'MUC',
    'stoccarda': 'STR',
    'stuttgart': 'STR',
    'amsterdam': 'AMS',


    'praga': 'PRG',
    'vienna': 'VIE',
    'londra': 'LHR',
    'edimburgo': 'EDI',
    'dublino': 'DUB',
    'bruxelles': 'BRU',
    'copenaghen': 'CPH',
    'stoccolma': 'ARN',
    'oslo': 'OSL',
    'tokyo': 'NRT',
    'new york': 'JFK',
    'tenerife': 'TFS',
    'tenerife sud': 'TFS',
    'tenerife nord': 'TFN',
    'canarie': 'TFS',
  };


  static const Map<String, int> italianMonths = {
    'gennaio': 1,
    'febbraio': 2,
    'marzo': 3,
    'aprile': 4,
    'maggio': 5,
    'giugno': 6,
    'luglio': 7,
    'agosto': 8,
    'settembre': 9,
    'ottobre': 10,
    'novembre': 11,
    'dicembre': 12,
  };

  /// Riconosce se l'utente menziona la città di partenza nel testo.
  static String? extractOriginCity(String text) {
    final lower = text.toLowerCase();
    const origins = [
      'roma', 'fiumicino', 'ciampino',
      'milano', 'malpensa', 'linate', 'bergamo',
      'napoli', 'bologna', 'venezia', 'torino',
      'firenze', 'bari', 'palermo', 'catania',
      'verona', 'pisa', 'genova',
    ];

    for (final city in origins) {
      if (RegExp('\\b(sono\\s+di|parto\\s+da|partendo\\s+da|volo\\s+da|da)\\s+$city\\b').hasMatch(lower) ||
          RegExp('\\bsono\\s+$city\\b').hasMatch(lower)) {
        return city[0].toUpperCase() + city.substring(1);
      }
    }
    return null;
  }

  /// Riconosce se l'utente richiede espressamente un volo diretto.
  static bool isDirectFlightRequested(String text) {
    final lower = text.toLowerCase();
    return lower.contains('diretto') ||
        lower.contains('diretti') ||
        lower.contains('senza scali') ||
        lower.contains('senza scalo');
  }

  /// Restituisce il codice IATA per la città o l'IATA stesso se già a 3 lettere.
  static String resolveIata(String cityOrIata, {String fallback = 'ROM'}) {
    final cleaned = cityOrIata.trim().toLowerCase();
    if (cleaned.length == 3 && cleaned == cleaned.toUpperCase()) {
      return cleaned.toUpperCase();
    }
    for (final entry in cityToIata.entries) {
      if (cleaned.contains(entry.key) || entry.key.contains(cleaned)) {
        return entry.value;
      }
    }
    return fallback;
  }


  /// Costruisce l'URL di Google Flights basato sulle specifiche di AWeirdDev/flights.
  static String build({
    required String destination,
    String originCity = 'Roma',
    String? rawUrl,
    String? textWithDates,
    DateTime? departureDate,
    DateTime? returnDate,
  }) {
    // Se è già un URL valido di Google Flights, lo arricchiamo con lingua e valuta se mancanti
    if (rawUrl != null && rawUrl.startsWith('https://www.google.com/travel/flights')) {
      final uri = Uri.tryParse(rawUrl);
      if (uri != null) {
        final queryParams = Map<String, String>.from(uri.queryParameters);
        queryParams.putIfAbsent('hl', () => 'it');
        queryParams.putIfAbsent('curr', () => 'EUR');
        return uri.replace(queryParameters: queryParams).toString();
      }
    }

    final destIata = resolveIata(destination, fallback: 'BUD');
    final originIata = resolveIata(originCity, fallback: 'ROM');


    DateTime? dep = departureDate;
    DateTime? ret = returnDate;

    if (dep == null && textWithDates != null) {
      final parsedDates = extractDatesFromText(textWithDates);
      dep = parsedDates.$1;
      ret = parsedDates.$2;
    }

    final buffer = StringBuffer('Flights to $destIata from $originIata');
    if (dep != null) {
      buffer.write(' on ${_formatIsoDate(dep)}');
      if (ret != null) {
        buffer.write(' through ${_formatIsoDate(ret)}');
      }
    }

    final encodedQuery = Uri.encodeComponent(buffer.toString());
    return 'https://www.google.com/travel/flights?q=$encodedQuery&hl=it&curr=EUR';
  }

  /// Cerca di estrarre date di partenza e ritorno da frasi in linguaggio naturale
  /// (es. "dal 5 al 10 dicembre", "dall'11 al 19", "prossimo weekend", "05/12 - 10/12").
  static (DateTime?, DateTime?) extractDatesFromText(
    String text, {
    int referenceYear = 2026,
    int? defaultMonth,
  }) {
    final lower = text.toLowerCase();

    // 1. Riconoscimento "prossimo weekend" o "questo weekend / fine settimana"
    final isNextWeekend = lower.contains('prossimo weekend') ||
        lower.contains('prossimo fine settimana') ||
        lower.contains('weekend prossimo');
    final isThisWeekend = lower.contains('questo weekend') ||
        lower.contains('questo fine settimana') ||
        lower.contains('il weekend') ||
        lower.contains('nel weekend') ||
        lower.contains('un weekend');

    if (isNextWeekend || isThisWeekend) {
      final now = DateTime.now();
      // weekday: 1 = Lunedì, ..., 5 = Venerdì, 6 = Sabato, 7 = Domenica
      int daysToThisFriday = (DateTime.friday - now.weekday) % 7;
      if (daysToThisFriday <= 0) {
        daysToThisFriday += 7;
      }
      final targetFriday = isNextWeekend
          ? now.add(Duration(days: daysToThisFriday + 7))
          : now.add(Duration(days: daysToThisFriday));
      final targetSunday = targetFriday.add(const Duration(days: 2));

      return (
        DateTime(targetFriday.year, targetFriday.month, targetFriday.day),
        DateTime(targetSunday.year, targetSunday.month, targetSunday.day),
      );
    }

    // 2. Pattern: "dal 5 al 10 dicembre" oppure "5-10 dicembre"
    final regexRange = RegExp(r"(?:dal\s+|dall['’]\s*)?(\d{1,2})\s*(?:al|-)\s*(\d{1,2})\s+([a-z]+)");
    final matchRange = regexRange.firstMatch(lower);
    if (matchRange != null) {
      final startDay = int.tryParse(matchRange.group(1) ?? '');
      final endDay = int.tryParse(matchRange.group(2) ?? '');
      final monthName = matchRange.group(3) ?? '';
      final month = italianMonths[monthName];

      if (startDay != null && endDay != null && month != null) {
        try {
          return (
            DateTime(referenceYear, month, startDay),
            DateTime(referenceYear, month, endDay),
          );
        } catch (_) {}
      }
    }

    // 2b. Pattern con solo giorni: "dall'11 al 19" o "11-19" con mese di contesto (es. dicembre)
    final regexJustDays = RegExp(r"(?:dal\s+|dall['’]\s*)(\d{1,2})\s*(?:al|-)\s*(\d{1,2})\b");
    final matchJustDays = regexJustDays.firstMatch(lower);
    if (matchJustDays != null && defaultMonth != null) {
      final startDay = int.tryParse(matchJustDays.group(1) ?? '');
      final endDay = int.tryParse(matchJustDays.group(2) ?? '');
      if (startDay != null && endDay != null) {
        try {
          return (
            DateTime(referenceYear, defaultMonth, startDay),
            DateTime(referenceYear, defaultMonth, endDay),
          );
        } catch (_) {}
      }
    }


    // 3. Pattern con slash: "05/12 - 10/12"
    final regexSlash = RegExp(r'(\d{1,2})/(\d{1,2})(?:/(\d{4}))?\s*(?:al|-)\s*(\d{1,2})/(\d{1,2})(?:/(\d{4}))?');
    final matchSlash = regexSlash.firstMatch(lower);
    if (matchSlash != null) {
      final d1 = int.tryParse(matchSlash.group(1) ?? '');
      final m1 = int.tryParse(matchSlash.group(2) ?? '');
      final y1 = int.tryParse(matchSlash.group(3) ?? '') ?? referenceYear;

      final d2 = int.tryParse(matchSlash.group(4) ?? '');
      final m2 = int.tryParse(matchSlash.group(5) ?? '');
      final y2 = int.tryParse(matchSlash.group(6) ?? '') ?? y1;

      if (d1 != null && m1 != null && d2 != null && m2 != null) {
        try {
          return (DateTime(y1, m1, d1), DateTime(y2, m2, d2));
        } catch (_) {}
      }
    }

    return (null, null);
  }

  static const List<String> italianDayNames = ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];
  static const List<String> italianMonthNames = [
    'Gen', 'Feb', 'Mar', 'Apr', 'Mag', 'Giu', 'Lug', 'Ago', 'Set', 'Ott', 'Nov', 'Dic'
  ];

  static String formatShortDate(DateTime date) {
    final dayName = italianDayNames[(date.weekday - 1) % 7];
    final monthName = italianMonthNames[(date.month - 1) % 12];
    return '$dayName ${date.day} $monthName';
  }

  static String formatDateRange(DateTime dep, DateTime ret) {
    final depStr = formatShortDate(dep);
    final retStr = formatShortDate(ret);
    return '$depStr – $retStr ${ret.year}';
  }

  static String _formatIsoDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

