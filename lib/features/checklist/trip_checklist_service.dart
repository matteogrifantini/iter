import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'trip_checklist_models.dart';

/// Service generating and persisting packing checklists for trips.
class TripChecklistService {
  const TripChecklistService();

  static const String _prefPrefix = 'iter_checklist_';

  /// Generates or loads the checklist for a given trip.
  Future<List<ChecklistItem>> loadChecklist(
    String tripId,
    String destination,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefPrefix$tripId');
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        return list
            .map((e) => ChecklistItem.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    final defaultList = generateDefaultChecklist(destination);
    await saveChecklist(tripId, defaultList);
    return defaultList;
  }

  /// Saves updated checklist to local storage.
  Future<void> saveChecklist(String tripId, List<ChecklistItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString('$_prefPrefix$tripId', raw);
  }

  /// Generates a tailored checklist based on destination specifics.
  List<ChecklistItem> generateDefaultChecklist(String destination) {
    final destLower = destination.toLowerCase();
    final isBudapest = destLower.contains('budapest');
    final isPortoOrLisbon =
        destLower.contains('porto') || destLower.contains('lisbona');

    final items = <ChecklistItem>[
      // Documenti
      ChecklistItem(
        id: 'doc-1',
        title: 'Carta d\'identità / Passaporto valido',
        category: 'Documenti',
        isEssential: true,
      ),
      ChecklistItem(
        id: 'doc-2',
        title: 'Tessera Sanitaria Europea (TEAM)',
        category: 'Documenti',
        isEssential: true,
      ),
      ChecklistItem(
        id: 'doc-3',
        title: 'Carte d\'imbarco salvate offline / su Wallet',
        category: 'Documenti',
        isEssential: true,
      ),
      ChecklistItem(
        id: 'doc-4',
        title: 'Carta di credito/debito abilitata all\'estero',
        category: 'Documenti',
        isEssential: true,
      ),

      // Abbigliamento
      ChecklistItem(
        id: 'abb-1',
        title: 'Scarpe da camminata comode e già rodate',
        category: 'Abbigliamento',
        isEssential: true,
      ),
      ChecklistItem(
        id: 'abb-2',
        title: 'Giacca antivento e antipioggia',
        category: 'Abbigliamento',
      ),
      ChecklistItem(
        id: 'abb-3',
        title: 'Cambi intimi e calzini per tutti i giorni',
        category: 'Abbigliamento',
      ),
      ChecklistItem(
        id: 'abb-4',
        title: 'Abbigliamento a strati (t-shirt + felpa/maglioncino)',
        category: 'Abbigliamento',
      ),

      // Elettronica
      ChecklistItem(
        id: 'ele-1',
        title: 'Powerbank da viaggio (massimo 10.000–20.000 mAh)',
        category: 'Elettronica',
        isEssential: true,
      ),
      ChecklistItem(
        id: 'ele-2',
        title: 'Caricatore smartphone e cavetti di riserva',
        category: 'Elettronica',
        isEssential: true,
      ),
      ChecklistItem(
        id: 'ele-3',
        title: 'Cuffie audio per passeggiate ed aereo',
        category: 'Elettronica',
      ),

      // Salute & Bagno
      ChecklistItem(
        id: 'sal-1',
        title: 'Kit medicinali base (antidolorifico, cerotti per vesciche)',
        category: 'Salute & Bagno',
      ),
      ChecklistItem(
        id: 'sal-2',
        title: 'Spazzolino, dentifricio e liquidi < 100ml in busta trasparente',
        category: 'Salute & Bagno',
      ),
      ChecklistItem(
        id: 'sal-3',
        title: 'Balsamo labbra e crema idratante',
        category: 'Salute & Bagno',
      ),
    ];

    // Destinazione specifica
    if (isBudapest) {
      items.addAll([
        ChecklistItem(
          id: 'spec-bud-1',
          title: 'Costume da bagno e ciabattine per le Terme Széchenyi',
          category: 'Specifici meta',
          isEssential: true,
        ),
        ChecklistItem(
          id: 'spec-bud-2',
          title: 'Telo microfibra e cuffia per piscina/terme',
          category: 'Specifici meta',
        ),
        ChecklistItem(
          id: 'spec-bud-3',
          title: 'Guanti termici e sciarpa per le sere sul Danubio',
          category: 'Specifici meta',
        ),
      ]);
    } else if (isPortoOrLisbon) {
      items.addAll([
        ChecklistItem(
          id: 'spec-pt-1',
          title:
              'Scarpe con suola antiscivolo per i ciottoli bagnati (calçada)',
          category: 'Specifici meta',
          isEssential: true,
        ),
        ChecklistItem(
          id: 'spec-pt-2',
          title: 'Occhiali da sole per la luce oceanica dei Miradouros',
          category: 'Specifici meta',
        ),
      ]);
    } else {
      items.add(
        ChecklistItem(
          id: 'spec-gen-1',
          title: 'Ombrello tascabile antivento',
          category: 'Specifici meta',
        ),
      );
    }

    return items;
  }
}
