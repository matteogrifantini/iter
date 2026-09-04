import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'real_place_service.dart';

@immutable
class DestinationVisualData {
  const DestinationVisualData({
    required this.destination,
    required this.tagline,
    required this.images,
    required this.climatePill,
    required this.transportPill,
    required this.flightAdvicePill,
    this.videoUrl,
    this.bestPeriod = 'Maggio - Giugno & Settembre - Ottobre',
    this.averageDailyCost = '~110€ / giorno (alloggio, pasti, visite)',
    this.insiderTips = const [
      'Prenota online i monumenti iconici per evitare ore di coda',
      'Esplora a piedi i vicoli dei quartieri storici per scovare locali autentici',
      'Assaggia la cucina tipica nei mercati rionali',
    ],
    this.highlights = const [],
  });

  final String destination;
  final String tagline;
  final List<String> images;
  final String climatePill;
  final String transportPill;
  final String flightAdvicePill;
  final String? videoUrl;
  final String bestPeriod;
  final String averageDailyCost;
  final List<String> insiderTips;
  final List<String> highlights;
}

class VisualMediaService {
  VisualMediaService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  static String getPhotoForDestination(String destination) {
    final key = destination.trim().toLowerCase();
    for (final entry in _curatedCatalog.entries) {
      if (key.contains(entry.key) && entry.value.images.isNotEmpty) {
        return entry.value.images.first;
      }
    }
    return 'https://images.unsplash.com/photo-1488646953014-85cb44e25828?w=800&q=80';
  }

  static String getPhotoForStop(String destination, String stopText) {
    final s = stopText.toLowerCase();
    final d = destination.toLowerCase();

    if (d.contains('tenerife') || d.contains('canarie')) {
      if (s.contains('teide')) return 'https://images.unsplash.com/photo-1588668214407-6ea9a6d8c272?w=400&q=80';
      if (s.contains('masca') || s.contains('gigantes')) return 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=400&q=80';
      if (s.contains('laguna')) return 'https://images.unsplash.com/photo-1518684079-3c830dcef090?w=400&q=80';
      if (s.contains('anaga') || s.contains('teresitas')) return 'https://images.unsplash.com/photo-1544644181-1484b3fdfc62?w=400&q=80';
      if (s.contains('costa adeje') || s.contains('playa')) return 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=400&q=80';
    }

    if (s.contains('chiesa') || s.contains('duomo') || s.contains('cattedrale') || s.contains('basilica') || s.contains('cathedral')) {
      return 'https://images.unsplash.com/photo-1548625361-197e411b32d2?w=400&q=80';
    }
    if (s.contains('museo') || s.contains('galleria') || s.contains('museum') || s.contains('galerie')) {
      return 'https://images.unsplash.com/photo-1565008447742-97f6f38c985c?w=400&q=80';
    }
    if (s.contains('parco') || s.contains('giardino') || s.contains('park') || s.contains('garden')) {
      return 'https://images.unsplash.com/photo-1519331379826-f10be5486c6f?w=400&q=80';
    }
    if (s.contains('castello') || s.contains('torre') || s.contains('castle') || s.contains('palazzo') || s.contains('schloss')) {
      return 'https://images.unsplash.com/photo-1524397030793-a4c3300a3597?w=400&q=80';
    }
    if (s.contains('piazza') || s.contains('square') || s.contains('platz')) {
      return 'https://images.unsplash.com/photo-1513584684374-8bab748fbf90?w=400&q=80';
    }

    return getPhotoForDestination(destination);
  }


  static const Map<String, DestinationVisualData> _curatedCatalog = {
    'tenerife': DestinationVisualData(
      destination: 'Tenerife',
      tagline: 'L\'isola dell\'eterna primavera: il maestoso vulcano Teide, borghi coloniali, scogliere mozzafiato e spiagge oceaniche.',
      images: [
        'https://images.unsplash.com/photo-1588668214407-6ea9a6d8c272?w=1200&q=85',
        'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=1200&q=85',
        'https://images.unsplash.com/photo-1544644181-1484b3fdfc62?w=1200&q=85',
        'https://images.unsplash.com/photo-1518684079-3c830dcef090?w=1200&q=85',
      ],
      climatePill: 'Clima mite 20-25°C tutto l\'anno • Sole perenne al sud, verde al nord',
      transportPill: 'Auto a noleggio consigliatissima per esplorare l\'isola • Bus TITSA capillari',
      flightAdvicePill: 'Voli diretti frequenti low cost da tutta Italia su TFS (Sud) e TFN (Nord)',
      bestPeriod: 'Tutto l\'anno (eccezionale in autunno, inverno e primavera)',
      averageDailyCost: '~90€ / giorno (alloggio, auto, ristoranti tipici)',
      insiderTips: [
        'Prenota in anticipo l\'accesso alla cima del Teide e la funivia sul sito ufficiale',
        'Fai sosta nei "Guachinches" del nord per mangiare piatti tipici canari a prezzi bassissimi',
        'Attraversa la strada panoramica di Masca fino alle scogliere dei Giganti',
      ],
      highlights: ['Parco Nazionale del Teide', 'Masca & Los Gigantes', 'San Cristóbal de La Laguna', 'Spiaggia Las Teresitas', 'Anaga Rural Park'],
    ),

    'new york': DestinationVisualData(

      destination: 'New York',
      tagline: 'L\'energia pulsante di Manhattan, lo skyline leggendario, i parchi e la magia delle luci di Broadway.',
      images: [
        'https://images.unsplash.com/photo-1496442226666-8d4d0e62e6e9?w=1200&q=85',
        'https://images.unsplash.com/photo-1534430480872-3498386e7856?w=1200&q=85',
        'https://images.unsplash.com/photo-1538688525198-9b88f6f53126?w=1200&q=85',
        'https://images.unsplash.com/photo-1541336032412-2048a678540d?w=1200&q=85',
      ],
      climatePill: 'Inverno freddo e suggestivo con luminarie • Primavera e autunno miti',
      transportPill: 'Metro 24h efficientissima • Si cammina molto tra i quartieri',
      flightAdvicePill: 'Voli diretti frequenti da Roma e Milano verso JFK ed EWR',
      bestPeriod: 'Maggio - Giugno & Settembre - Dicembre (Natale magico)',
      averageDailyCost: '~180€ / giorno (hotel, pasti, attrazioni)',
      insiderTips: [
        'Usa la MetroCard unlimited 7 giorni per muoverti ovunque senza pensieri',
        'Visita The High Line al mattino presto per goderti la passeggiata senza folla',
        'Attraversa a piedi il ponte di Brooklyn verso il tramonto partendo da Manhattan',
      ],
      highlights: ['Statua della Libertà', 'Central Park', 'Empire State', 'The Met', 'Ponte di Brooklyn', 'High Line'],
    ),

    'palermo': DestinationVisualData(

      destination: 'Palermo',
      tagline: 'Mosaici arabo-normanni, street food leggendario nei mercati e luce dorata sul golfo.',
      images: [
        'https://upload.wikimedia.org/wikipedia/commons/thumb/4/45/Palermo_Cathedral_Facade.jpg/1280px-Palermo_Cathedral_Facade.jpg',
        'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a9/16._Mai_1897_An_diesem_Tag_wurde_die_Oper_von_Palermo_er%C3%B6ffnet._02.jpg/1280px-16._Mai_1897_An_diesem_Tag_wurde_die_Oper_von_Palermo_er%C3%B6ffnet._02.jpg',
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/5/52/Il_golfo_di_Mondello.jpg/1280px-Il_golfo_di_Mondello.jpg',
      ],
      climatePill: '22-26°C soleggiato e piacevole',
      transportPill: 'Centro storico a piedi e bus per Mondello',
      flightAdvicePill: 'Voli diretti FCO - PMO 55 min da 35€',
      bestPeriod: 'Aprile - Giugno & Settembre - Novembre (clima caldo spettacolare, evita il caldo record di Luglio-Agosto)',
      averageDailyCost: '~75€ / giorno (straordinario rapporto qualità/prezzo)',
      insiderTips: [
        'Assaggia le panelle e lo sfincione al mercato storico di Ballarò o al Capo.',
        'Entra nella Cappella Palatina al mattino presto per ammirare i mosaici dorati bizantini senza folla.',
        'Prendi il bus 806 dal centro per raggiungere la spiaggia di sabbia bianca e acqua cristallina di Mondello.',
        'La sera fai base tra piazza Marina e il quartiere Kalsa per locali all\'aperto e atmosfera autentica.',
      ],
      highlights: ['Cattedrale di Palermo', 'Cappella Palatina & Palazzo Reale', 'Mercato di Ballarò', 'Teatro Massimo', 'Mondello'],
    ),
    'messina': DestinationVisualData(
      destination: 'Messina',
      tagline: 'Porta della Sicilia, panorami mozzafiato sullo Stretto e granite leggendarie.',
      images: [
        'https://upload.wikimedia.org/wikipedia/commons/c/cc/Duomo_di_Messina.jpg',
        'https://upload.wikimedia.org/wikipedia/commons/1/17/MessinaStrait.jpg',
        'https://images.unsplash.com/photo-1533105079780-92b9be482077?w=800&q=80',
      ],
      climatePill: '21-25°C brezza dello Stretto',
      transportPill: 'Centro a piedi, tram costiero e aliscafi',
      flightAdvicePill: 'Voli FCO - CTA (Catania) 55 min da 24€',
      bestPeriod: 'Maggio - Giugno & Settembre - Ottobre (clima mite e vista limpida sulla costa calabra)',
      averageDailyCost: '~70€ / giorno (ottimo rapporto qualità/prezzo)',
      insiderTips: [
        'A mezzogiorno fermati a Piazza Duomo: il campanile attiva lo spettacolare orologio astronomico semovente.',
        'Fai colazione da Irrera o De Pasquale con mezza granita al caffè con panna e brioche col tuppo appena sfornata.',
        'Sali al Belvedere di Cristo Re al tramonto per la vista a 360 gradi sulla falce del porto e sullo Stretto.',
        'Assaggia la focaccia tradizionale messinese da Tommasino: tuma locale, scarola riccia e acciughe salate.',
      ],
      highlights: [
        'Duomo di Messina & Campanile Astronomico',
        'Fontana di Orione del Montorsoli',
        'Chiesa Santissima Annunziata dei Catalani',
        'Sacrario di Cristo Re & Belvedere Panoramico',
        'Riserva Naturale dei Laghi di Ganzirri',
      ],
    ),
    'berlino': DestinationVisualData(
      destination: 'Berlino',
      tagline: 'Storia viva, arte d\'avanguardia, clubbing leggendario e quartieri creativi.',
      images: [
        'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a6/Brandenburger_Tor_abends.jpg/1280px-Brandenburger_Tor_abends.jpg',
        'https://upload.wikimedia.org/wikipedia/commons/thumb/8/84/141227_Berliner_Dom.jpg/1280px-141227_Berliner_Dom.jpg',
        'https://images.unsplash.com/photo-1560969184-10fe8719e047?w=800&q=80',
      ],
      climatePill: '18-22°C estivo e fresco',
      transportPill: 'U-Bahn, S-Bahn e bici ovunque',
      flightAdvicePill: 'Voli diretti FCO - BER da 39€',
      bestPeriod: 'Maggio - Settembre (giornate lunghissime all\'aperto e parchi vivi)',
      averageDailyCost: '~85€ / giorno (molto accessibile per una capitale europea)',
      insiderTips: [
        'Noleggia una bici per attraversare l\'ex aeroporto di Tempelhof, ora parco pubblico immenso.',
        'Visita l\'East Side Gallery al mattino presto per ammirare i murales del Muro con calma.',
        'Fai una pausa currywurst da Curry 36 o un döner kebab autentico da Mustafa a Kreuzberg.',
        'Sali sulla cupola di vetro del Reichstag al tramonto (prenotazione online gratuita obbligatoria).',
      ],
      highlights: [
        'Porta di Brandeburgo',
        'Isola dei Musei (Museumsinsel)',
        'East Side Gallery (Muro di Berlino)',
        'Reichstag & Cupola di Norman Foster',
        'Quartiere Kreuzberg & Canale Paul-Lincke-Ufer',
      ],
    ),
    'monaco': DestinationVisualData(
      destination: 'Monaco di Baviera',
      tagline: 'Eleganza bavarese, birrerie storiche, giardini incantevoli e surf urbano sull\'Eisbach.',
      images: [
        'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c9/Neues_Rathaus_M%C3%BCnchen_2018.jpg/1280px-Neues_Rathaus_M%C3%BCnchen_2018.jpg',
        'https://upload.wikimedia.org/wikipedia/commons/thumb/d/da/Frauenkirche_Munich_-_View_from_Peterskirche_Tower2.jpg/1280px-Frauenkirche_Munich_-_View_from_Peterskirche_Tower2.jpg',
        'https://images.unsplash.com/photo-1595867818082-083862f3d630?w=800&q=80',
      ],
      climatePill: '17-23°C mite e piacevole',
      transportPill: 'S-Bahn, U-Bahn e centro tutto a piedi',
      flightAdvicePill: 'Voli diretti FCO - MUC da 49€ (~1h 35m)',
      bestPeriod: 'Maggio - Settembre & periodo mercatini di Natale a Dicembre',
      averageDailyCost: '~110€ / giorno (birrerie tipiche e musei accessibili)',
      insiderTips: [
        'Guarda i surfisti sfidare l\'onda artificiale sull\'Eisbach all\'ingresso dell\'Englischer Garten.',
        'Assaggia i Weißwurst tradizionali al Viktualienmarkt prima delle 12:00 accompagnati da un brezel caldo.',
        'Sali sulla torre della Chiesa di San Pietro (Alter Peter) per la vista più iconica su Marienplatz e sulle Alpi.',
        'Bevi una boccale di birra fresca all\'aperto al Biergarten della Chinesischer Turm.',
      ],
      highlights: [
        'Marienplatz & Carillon del Neues Rathaus',
        'Frauenkirche (Cattedrale di Nostra Signora)',
        'Englischer Garten & Eisbachwelle',
        'Viktualienmarkt (Mercato gastronomico storico)',
        'Residenz di Monaco (Palazzo reale dei Wittelsbach)',
      ],
    ),
    'stoccarda': DestinationVisualData(
      destination: 'Stoccarda',
      tagline: 'Culla dell\'automobile, vigneti urbani, architettura modernista e bagni termali.',
      images: [
        'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b3/StuttgartSchlossPlatz.JPG/1280px-StuttgartSchlossPlatz.JPG',
        'https://upload.wikimedia.org/wikipedia/commons/thumb/2/26/Mercedes-Benz_Museum_201312_08_blue_hour.jpg/1280px-Mercedes-Benz_Museum_201312_08_blue_hour.jpg',
        'https://images.unsplash.com/photo-1542282088-72c9c27ed0cd?w=800&q=80',
      ],
      climatePill: '17-22°C piacevole tra le colline',
      transportPill: 'S-Bahn, Stadtbahn e funicolare panoramica',
      flightAdvicePill: 'Voli diretti FCO - STR da 45€ (~1h 40m)',
      bestPeriod: 'Maggio - Ottobre (feste del vino tra le vigne del Neckar)',
      averageDailyCost: '~95€ / giorno (ottimi musei e trasporti integrati)',
      insiderTips: [
        'Visita il Mercedes-Benz Museum: una spirale architettonica a doppia elica straordinaria su 9 piani.',
        'Sali sulla collina del Birkenkopf (Monte delle Macerie) per un panorama a 360° sulla conca di Stoccarda.',
        'Assaggia i Maultaschen tradizionali (i celebri ravioli svevi) con insalata di patate tiepida in una Weinstube tipica.',
        'Passeggia lungo Schlossplatz e rilassati nei giardini del Neues Schloss.',
      ],
      highlights: [
        'Schlossplatz & Neues Schloss (Piazza centrale e residenza barocca)',
        'Museo Mercedes-Benz & Museo Porsche',
        'Staatsgalerie Stuttgart (Capolavori da Rembrandt a Picasso)',
        'Stadtbibliothek Stuttgart (La biblioteca cubo modernista)',
        'Wilhelma (Storico giardino zoologico e botanico moresco)',
      ],
    ),
    'barcellona': DestinationVisualData(



      destination: 'Barcellona',
      tagline: 'Capolavori di Gaudí, brezza del Mediterraneo e tapas bar vibranti tra il Born e il Barrio Gotico.',
      images: [
        'https://images.unsplash.com/photo-1583422409516-2895a77efded?w=800&q=80',
        'https://images.unsplash.com/photo-1539037116277-4db20889f2d4?w=800&q=80',
        'https://images.unsplash.com/photo-1511527661048-7fe73d85e9a4?w=800&q=80',
      ],
      climatePill: '21-25°C soleggiato e ventilato',
      transportPill: 'Metro capillare e lungomare a piedi',
      flightAdvicePill: 'Voli diretti da Roma FCO ~45-65€',
      bestPeriod: 'Maggio - Giugno & Settembre - Ottobre (clima caldo perfetto, evita l\'afa e la folla di Agosto)',
      averageDailyCost: '~115€ / giorno (hotel centrale, tapas e monumenti)',
      insiderTips: [
        'Prenota la Sagrada Família con almeno 2-3 settimane di anticipo: i biglietti sul posto sono quasi sempre esauriti!',
        'Evita i ristoranti turistici sulla Rambla: per tapas autentiche vai a El Born o nel quartiere Gràcia.',
        'Sali al tramonto ai Bunkers del Carmel per la vista a 360° più spettacolare e gratuita della città.',
        'Attento ai borseggiatori nelle stazioni metro della Rambla e a Plaça Catalunya.',
      ],
      highlights: ['Sagrada Família', 'Park Güell', 'Casa Batlló', 'Barrio Gotico & El Born', 'Barceloneta'],
    ),
    'lisbona': DestinationVisualData(
      destination: 'Lisbona',
      tagline: 'Luce dorata sull\'Atlantico, miradouros e tram storici tra i vicoli di Alfama.',
      images: [
        'https://images.unsplash.com/photo-1509840841025-9088ba78a826?w=800&q=80',
        'https://images.unsplash.com/photo-1513581166391-887a96ddeafd?w=800&q=80',
        'https://images.unsplash.com/photo-1524396309943-e03f5249f002?w=800&q=80',
      ],
      climatePill: '18-23°C in Autunno · Clima ideale',
      transportPill: 'Tram 28 e metro ovunque',
      flightAdvicePill: 'Voli diretti da Roma FCO ~70€',
      bestPeriod: 'Aprile - Giugno & Settembre - Novembre (temperature miti e luce spettacolare)',
      averageDailyCost: '~95€ / giorno (ottimo rapporto qualità/prezzo)',
      insiderTips: [
        'Prendi il tram 28 al mattino presto (prima delle 08:30) per evitare la fila di turisti.',
        'I Pastéis de Belém originali si mangiano caldi con cannella nell\'antica pasticceria vicino al monastero.',
        'Goditi il tramonto a Miradouro de Santa Luzia con musica fado dal vivo.',
      ],
      highlights: ['Torre de Belém', 'Mosteiro dos Jerónimos', 'Alfama & Miradouros', 'Tram 28', 'Praça do Comércio'],
    ),
    'porto': DestinationVisualData(
      destination: 'Porto',
      tagline: 'Vicoli in salita, azulejos, cantine storiche sul Douro e tramonti dorati sul Ponte Dom Luís I.',
      images: [
        'https://images.unsplash.com/photo-1555881400-74d7acaacd8b?w=800&q=80',
        'https://images.unsplash.com/photo-1513581166391-887a96ddeafd?w=800&q=80',
      ],
      climatePill: '18-24°C da maggio a ottobre • Clima atlantico mite',
      transportPill: 'Metro veloce linea E dall\'aeroporto OPO al centro (25 min)',
      flightAdvicePill: 'Voli diretti frequenti da Milano, Roma, Bologna e Napoli',
      bestPeriod: 'Maggio - Ottobre per giornate soleggiate e la Festa di São João a giugno',
      averageDailyCost: '~85€ / giorno (eccellente rapporto qualità/prezzo)',
      insiderTips: [
        'Attraversa a piedi il livello superiore del Ponte Dom Luís I al tramonto per la vista più iconica sulla Ribeira.',
        'Fai una degustazione guidata di vino Porto nelle cantine storiche di Vila Nova de Gaia.',
        'Prendi il tram storico linea 1 lungo il fiume fino all\'oceano a Foz do Douro.',
      ],
      highlights: ['Ponte Dom Luís I', 'Ribeira', 'Livraria Lello', 'Torre dos Clérigos', 'Cantine di Gaia'],
    ),
    'budapest': DestinationVisualData(
      destination: 'Budapest',
      tagline: 'Fascino asburgico sul Danubio, terme calde all\'aperto e ruin bar segreti.',
      images: [
        'https://images.unsplash.com/photo-1549877452-9c387954fbc2?w=800&q=80',
        'https://images.unsplash.com/photo-1517737812598-1a43d0ef2a60?w=800&q=80',
        'https://images.unsplash.com/photo-1505872245034-5c5ab9888941?w=800&q=80',
      ],
      climatePill: '14-19°C · Perfetta per le terme',
      transportPill: 'Tram 2 panoramico sul fiume',
      flightAdvicePill: 'Voli diretti low-cost da 50€',
      bestPeriod: 'Ottobre per il foliage dorato o Dicembre per mercatini e terme con il vapore nell\'aria fredda',
      averageDailyCost: '~80€ / giorno (una delle capitali europee più convenienti)',
      insiderTips: [
        'Porta costume, ciabatte e cuffia alle Terme Széchenyi per evitare di noleggiarli a caro prezzo.',
        'La vista più iconica del Parlamento illuminato si gode di notte dal Bastione dei Pescatori o dal battello.',
        'Visita Szimpla Kert, il primo e più famoso ruin bar, anche di giorno la domenica mattina per il mercatino locale.',
      ],
      highlights: ['Parlamento di Budapest', 'Bastione dei Pescatori', 'Terme Széchenyi', 'Ponte delle Catene', 'Ruin Bar'],
    ),
    'milano': DestinationVisualData(
      destination: 'Milano',
      tagline: 'Guglie gotiche, mostre di livello mondiale e la vivacità serale di Brera e Navigli.',
      images: [
        'https://images.unsplash.com/photo-1513584684374-8bab748fbf90?w=800&q=80',
        'https://images.unsplash.com/photo-1543429776-2782fc8e1acd?w=800&q=80',
        'https://images.unsplash.com/photo-1579783902614-a3fb3927b675?w=800&q=80',
      ],
      climatePill: 'Autunno fresco & mostre d\'arte',
      transportPill: 'Frecciarossa 2h59m da Roma Termini',
      flightAdvicePill: 'In treno AV centro-centro',
      bestPeriod: 'Settembre - Novembre & Marzo - Maggio per design, mostre ed eventi',
      averageDailyCost: '~140€ / giorno',
      insiderTips: [
        'Da Roma prendi assolutamente il Frecciarossa AV (3 ore centro-centro, zero stress da aeroporto).',
        'Sali sulle terrazze del Duomo a piedi al tramonto per vedere le Alpi e le guglie illuminate.',
        'Il Cenacolo Vinciano richiede prenotazione obbligatoria con mesi di anticipo.',
      ],
      highlights: ['Duomo & Terrazze', 'Castello Sforzesco', 'Pinacoteca di Brera', 'Navigli & Darsena', 'Galleria'],
    ),
    'madrid': DestinationVisualData(
      destination: 'Madrid',
      tagline: 'Energia infinita, musei del Triangolo d\'Oro e tapas bar aperti fino a tardi.',
      images: [
        'https://images.unsplash.com/photo-1539037116277-4db20889f2d4?w=800&q=80',
        'https://images.unsplash.com/photo-1543783207-ec64e4d95325?w=800&q=80',
        'https://images.unsplash.com/photo-1509356843151-3e7d96241e11?w=800&q=80',
      ],
      climatePill: '20-24°C soleggiato e piacevole',
      transportPill: 'Città perfetta a piedi e metro',
      flightAdvicePill: 'Voli frequenti da 60€',
      bestPeriod: 'Maggio - Giugno & Ottobre (in estate il caldo supera spesso i 38°C)',
      averageDailyCost: '~105€ / giorno',
      insiderTips: [
        'Il Museo del Prado è gratuito dal lunedì al sabato dalle 18:00 alle 20:00.',
        'Assaggia il bocadillo de calamares in Plaza Mayor nel bar storico La Campana.',
        'Noleggia una barchetta al laghetto del Parco del Retiro prima di visitare il Palacio de Cristal.',
      ],
      highlights: ['Museo del Prado', 'Palacio Real', 'Parco del Retiro', 'Plaza Mayor', 'Gran Vía'],
    ),
  };

  /// Restituisce i contenuti multimediali curati o dinamici per la meta richiesta.
  Future<DestinationVisualData> getVisualData(String destination) async {
    final key = destination.trim().toLowerCase();
    for (final entry in _curatedCatalog.entries) {
      if (key.contains(entry.key)) {
        return entry.value;
      }
    }

    // Dynamic fallback tramite Wikipedia API
    try {
      final realService = RealPlaceService(httpClient: _client);
      final details = await realService.fetchPlaceDetails(destination).timeout(const Duration(seconds: 2));
      final primaryImage = details?.imageUrl ?? 'https://images.unsplash.com/photo-1488646953014-85cb44e25828?w=800&q=80';
      return DestinationVisualData(
        destination: destination,
        tagline: details?.description.isNotEmpty == true 
            ? details!.description 
            : 'Una meta affascinante tutta da scoprire con Iter.',
        images: [primaryImage],
        climatePill: 'Consigliata da Iter',
        transportPill: 'Collegamenti verificati',
        flightAdvicePill: 'Pianificazione attiva',
        bestPeriod: 'Primavera e primo Autunno (clima ideale per esplorare)',
        averageDailyCost: '~100-120€ / giorno complessivo',
        insiderTips: const [
          'Pianifica le attrazioni principali al mattino per evitare folla',
          'Scegli un alloggio in posizione baricentrica per muoverti a piedi',
        ],
      );
    } catch (_) {
      return DestinationVisualData(
        destination: destination,
        tagline: 'Una destinazione imperdibile selezionata per te.',
        images: const ['https://images.unsplash.com/photo-1488646953014-85cb44e25828?w=800&q=80'],
        climatePill: 'Stagione favorevole',
        transportPill: 'A misura di viaggiatore',
        flightAdvicePill: 'Opzioni disponibili',
        bestPeriod: 'Primavera e Autunno',
        averageDailyCost: '~100€ / giorno',
        insiderTips: const [
          'Pianifica le visite con anticipo',
          'Muoviti a piedi nel centro storico',
        ],
      );
    }
  }
}
