import 'dart:convert';
import 'package:http/http.dart' as http;
import 'translator_models.dart';

/// Service delivering travel phrases and live translation for destination languages.
class TravelTranslatorService {
  TravelTranslatorService({http.Client? httpClient}) : _client = httpClient;

  final http.Client? _client;

  /// Translates free text from Italian to destination target language using free public API.
  Future<String> translateText(String text, String targetLangCode) async {
    final client = _client ?? http.Client();
    final encoded = Uri.encodeComponent(text);
    final url = Uri.parse(
      'https://api.mymemory.translated.net/get?q=$encoded&langpair=it|$targetLangCode',
    );

    try {
      final response = await client
          .get(url)
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final responseData = data['responseData'] as Map<String, dynamic>?;
        final translated = responseData?['translatedText'] as String?;
        if (translated != null && translated.isNotEmpty) {
          return translated;
        }
      }
    } catch (_) {}

    return text;
  }

  /// Returns complete phrasebook for a given destination.
  LanguageProfile getLanguageForDestination(String destination) {
    final destLower = destination.toLowerCase();

    if (destLower.contains('budapest')) {
      return const LanguageProfile(
        code: 'hu',
        name: 'Ungherese (Magyar)',
        flagEmoji: '🇭🇺',
        phrases: [
          TravelPhrase(
            italian: 'Buongiorno / Salve',
            translated: 'Jó napot kívánok',
            pronunciation: 'Yoo no-pot kee-vaa-nok',
            category: 'Base & Saluti',
          ),
          TravelPhrase(
            italian: 'Grazie mille',
            translated: 'Köszönöm szépen',
            pronunciation: 'Koe-soe-noem say-pen',
            category: 'Base & Saluti',
          ),
          TravelPhrase(
            italian: 'Per favore',
            translated: 'Kérem',
            pronunciation: 'Kay-rem',
            category: 'Base & Saluti',
          ),
          TravelPhrase(
            italian: 'Parla italiano o inglese?',
            translated: 'Beszél olaszul vagy angolul?',
            pronunciation: 'Bess-el o-lo-sul vodj on-go-lul?',
            category: 'Base & Saluti',
          ),
          TravelPhrase(
            italian: 'Il conto per favore',
            translated: 'A számlát kérem',
            pronunciation: 'O saam-laat kay-rem',
            category: 'Ristorante',
          ),
          TravelPhrase(
            italian: 'Un tavolo per due',
            translated: 'Egy asztalt két főre',
            pronunciation: 'Edj os-tolt kayt foo-reh',
            category: 'Ristorante',
          ),
          TravelPhrase(
            italian: 'Dov\'è la stazione / la fermata del tram?',
            translated: 'Hol van a villamosmegálló?',
            pronunciation: 'Hol von o vil-lo-mosh-meg-aall-oo?',
            category: 'Direzioni',
          ),
          TravelPhrase(
            italian: 'Quanto costa questo?',
            translated: 'Mennyibe kerül ez?',
            pronunciation: 'Men-nyee-beh keh-rool ez?',
            category: 'Shopping & Pagamenti',
          ),
          TravelPhrase(
            italian: 'Accettate la carta di credito?',
            translated: 'Lehet kártyával fizetni?',
            pronunciation: 'Leh-het kaarr-tyaa-vol fee-zet-nee?',
            category: 'Shopping & Pagamenti',
          ),
          TravelPhrase(
            italian: 'Ho bisogno di aiuto / Farmacia',
            translated: 'Segítségre van szükségem / Gyógyszertár',
            pronunciation: 'Sheh-geet-shayg-reh von sook-shay-gem',
            category: 'Emergenze',
          ),
        ],
      );
    }

    if (destLower.contains('porto') || destLower.contains('lisbona')) {
      return const LanguageProfile(
        code: 'pt',
        name: 'Portoghese',
        flagEmoji: '🇵🇹',
        phrases: [
          TravelPhrase(
            italian: 'Buongiorno / Ciao',
            translated: 'Bom dia / Olá',
            pronunciation: 'Bon dee-ah / Oh-laa',
            category: 'Base & Saluti',
          ),
          TravelPhrase(
            italian: 'Grazie',
            translated: 'Obrigado (uomini) / Obrigada (donne)',
            pronunciation: 'Oh-bree-gaa-doo / Oh-bree-gaa-dah',
            category: 'Base & Saluti',
          ),
          TravelPhrase(
            italian: 'Il conto per favore',
            translated: 'A conta, por favor',
            pronunciation: 'Ah con-tah poor fah-voor',
            category: 'Ristorante',
          ),
          TravelPhrase(
            italian: 'Dov\'è il bagno?',
            translated: 'Onde fica a casa de banho?',
            pronunciation: 'On-jee fee-kah ah kah-zah jee bahn-yoo?',
            category: 'Direzioni',
          ),
        ],
      );
    }

    // Default English profile
    return const LanguageProfile(
      code: 'en',
      name: 'Inglese Internazionale',
      flagEmoji: '🇬🇧',
      phrases: [
        TravelPhrase(
          italian: 'Buongiorno / Ciao',
          translated: 'Good morning / Hello',
          pronunciation: 'Gud mor-ning / Heh-lo',
          category: 'Base & Saluti',
        ),
        TravelPhrase(
          italian: 'Grazie mille',
          translated: 'Thank you very much',
          pronunciation: 'Thenk yu veh-ree much',
          category: 'Base & Saluti',
        ),
        TravelPhrase(
          italian: 'Il conto per favore',
          translated: 'The check / bill, please',
          pronunciation: 'Dheh bil, pleez',
          category: 'Ristorante',
        ),
      ],
    );
  }
}
