import 'food_models.dart';

/// Service delivering authentic food guides, traditional dishes and culinary spots.
class FoodGuideService {
  const FoodGuideService();

  Future<DestinationFoodGuide> getFoodGuide(String destination) async {
    final key = destination.trim().toLowerCase();

    if (key.contains('budapest')) {
      return const DestinationFoodGuide(
        destination: 'Budapest',
        culinaryIdentity:
            'Cucina magiara ricca di sapori profondi, paprika nobile dolce, stufati cotti a fuoco lento e pasticceria imperiale austro-ungarica.',
        dishes: [
          LocalDish(
            name: 'Gulasch Tradizionale',
            localName: 'Gulyásleves',
            description:
                'Zuppa densa e profumata con teneri cubi di manzo, patate, carote, csipetke (gnocchetti di pasta) e paprika dolce di Szeged.',
            category: 'Piatto forte',
            dietaryTag: 'Carne',
            mustTryPlace: 'Gettó Gulyás (Quartiere Ebraico)',
          ),
          LocalDish(
            name: 'Lángos',
            localName: 'Lángos',
            description:
                'Focaccia fritta croccante fuori e morbida dentro, servita caldissima con aglio fresco strofinato, panna acida (tejföl) e formaggio grattugiato.',
            category: 'Street food',
            dietaryTag: 'Vegetariano',
            mustTryPlace: 'Primo piano del Mercato Centrale (Nagyvásárcsarnok)',
          ),
          LocalDish(
            name: 'Kürtőskalács',
            localName: 'Kürtőskalács',
            description:
                'Il celebre "dolce a camino", cotto alla brace rotante e caramellato con cannella, noci o vaniglia.',
            category: 'Dolce tipico',
            dietaryTag: 'Dolce',
            mustTryPlace: 'Molnár’s Kürtőskalács (Váci Utca)',
          ),
          LocalDish(
            name: 'Pollo alla Paprika',
            localName: 'Paprikás Csirke',
            description:
                'Cosce di pollo cotte in una salsa vellutata di panna acida e paprika, accompagnate da galuska (gnocchetti).',
            category: 'Piatto forte',
            dietaryTag: 'Carne',
            mustTryPlace: 'Menza Étterem és Kávézó (Liszt Ferenc tér)',
          ),
        ],
        venues: [
          RecommendedVenue(
            name: 'Mercato Centrale (Nagyvásárcsarnok)',
            type: 'Mercato coperto storico',
            specialty: 'Paprika, salami ungheresi, lángos espresso',
            priceTier: '€',
            address: 'Vámház krt. 1-3, Budapest',
            whyIterRecommends:
                'Il più grande mercato coperto d\'Europa in splendido stile liberty neogotico.',
            mapsQuery: 'Great Market Hall Budapest',
          ),
          RecommendedVenue(
            name: 'Gettó Gulyás',
            type: 'Trattoria tipica',
            specialty: 'Spezzatini e stufati tradizionali (Pörkölt)',
            priceTier: '€€',
            address: 'Wesselényi u. 18, Budapest',
            whyIterRecommends:
                'Autentica cucina casalinga nel cuore del quartiere ebraico, lontana dalle trappole per turisti.',
            mapsQuery: 'Getto Gulyas Budapest',
          ),
          RecommendedVenue(
            name: 'New York Café',
            type: 'Caffè storico imperiale',
            specialty: 'Cioccolata calda, torte Dobos ed Esterházy',
            priceTier: '€€€',
            address: 'Erzsébet krt. 9-11, Budapest',
            whyIterRecommends:
                'Definito il caffè più bello del mondo, con stucchi dorati e lampadari di cristallo.',
            mapsQuery: 'New York Cafe Budapest',
          ),
        ],
        orderingPhrases: {
          'Un tavolo per due per favore':
              'Egy asztalt két főre, kérem (Pronuncia: Egh astolt ket foore, keerem)',
          'Il conto per favore':
              'A számlát kérem (Pronuncia: O saamlaat keerem)',
          'È delizioso!': 'Nagyon finom! (Pronuncia: Noghyon finom)',
          'Un bicchiere d\'acqua naturale': 'Egy pohár mentes vizet kérem',
          'Senza glutine / Vegetariano': 'Gluténmentes / Vegetáriánus',
        },
      );
    }

    if (key.contains('porto')) {
      return const DestinationFoodGuide(
        destination: 'Porto',
        culinaryIdentity:
            'Cucina atlantica generosa e schietta: pesce freschissimo alla griglia, baccalà in mille ricette, porto DOC e dolci conventuali.',
        dishes: [
          LocalDish(
            name: 'Francesinha',
            localName: 'Francesinha',
            description:
                'Il sandwich iconico di Porto: pane tostato farcito con bistecca, salsiccia fresca e linguiça, coperto di formaggio fuso e affogato in salsa calda piccante alla birra.',
            category: 'Piatto forte',
            dietaryTag: 'Carne',
            mustTryPlace: 'Café Santiago o Brasão Cervejaria',
          ),
          LocalDish(
            name: 'Pastel de Nata caldo',
            localName: 'Pastel de Nata',
            description:
                'Tortina di sfoglia croccantissima ripiena di crema pasticcera bruciata alla cannella, servita appena sfornata.',
            category: 'Dolce tipico',
            dietaryTag: 'Dolce',
            mustTryPlace: 'Manteigaria (Rua dos Clérigos)',
          ),
          LocalDish(
            name: 'Bacalhau à Gomes de Sá',
            localName: 'Bacalhau à Gomes de Sá',
            description:
                'Baccalà dissodato al forno con patate, cipolle caramellate, uova sode, olive nere e olio d\'oliva del Douro.',
            category: 'Piatto forte',
            dietaryTag: 'Pesce',
            mustTryPlace: 'Adega São Nicolau (Ribeira)',
          ),
        ],
        venues: [
          RecommendedVenue(
            name: 'Mercado do Bolhão',
            type: 'Mercato storico rinnovato',
            specialty:
                'Ostriche fresche, formaggi Serra da Estrela, vino verde',
            priceTier: '€',
            address: 'Rua Formosa 322, Porto',
            whyIterRecommends:
                'L\'anima gastronomica di Porto: banchi vivaci e assaggi espressi di pesce e conserve.',
            mapsQuery: 'Mercado do Bolhao Porto',
          ),
          RecommendedVenue(
            name: 'Brasão Cervejaria Coliseu',
            type: 'Bistrot & birreria artigianale',
            specialty: 'Francesinha cotta nel forno a legna',
            priceTier: '€€',
            address: 'Rua de Passos Manuel 205, Porto',
            whyIterRecommends:
                'La versione più raffinata della Francesinha in un ambiente elegante in pietra e legno.',
            mapsQuery: 'Brasao Cervejaria Porto',
          ),
        ],
        orderingPhrases: {
          'Un tavolo per due per favore': 'Uma mesa para dois, por favor',
          'Il conto per favore': 'A conta, por favor',
          'È delizioso!': 'Está delicioso / Muito bom!',
          'Un caffè espresso': 'Um café / Uma bica, por favor',
        },
      );
    }

    // Generic realistic food guide
    return DestinationFoodGuide(
      destination: destination,
      culinaryIdentity:
          'Cucina locale autentica radicata negli ingredienti di stagione del territorio.',
      dishes: const [
        LocalDish(
          name: 'Specialità della Casa',
          localName: 'Piatto tipico regionale',
          description:
              'Piatto tradizionale cucinato secondo la ricetta storica della città.',
          category: 'Piatto forte',
          dietaryTag: 'Tipico',
          mustTryPlace: 'Trattoria del centro storico',
        ),
      ],
      venues: const [
        RecommendedVenue(
          name: 'Mercato Cittadino',
          type: 'Mercato coperto',
          specialty: 'Prodotti locali freschi e street food',
          priceTier: '€',
          address: 'Centro Storico',
          whyIterRecommends:
              'Il posto ideale per scoprire gli ingredienti genuini del luogo.',
          mapsQuery: 'Central Market',
        ),
      ],
      orderingPhrases: const {
        'Un tavolo per due per favore': 'A table for two, please',
        'Il conto per favore': 'The check, please',
        'Grazie mille': 'Thank you very much',
      },
    );
  }
}
