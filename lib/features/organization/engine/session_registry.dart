import '../adapters/mock_travel_search_provider.dart';
import '../adapters/unavailable_stay_search_provider.dart';
import '../providers/organization_ai_gateway.dart';
import '../providers/stay_search_provider.dart';
import '../providers/supabase_organization_gateway.dart';
import '../providers/travel_search_provider.dart';
import 'organization_session.dart';

/// Registro con ciclo di vita controllato delle sessioni di organizzazione attive.
class SessionRegistry {
  SessionRegistry({
    required this.aiGateway,
    required this.travelProvider,
    required this.stayProvider,
  });

  /// Costruttore standard che usa gateway e provider di default sicuri e trasparenti.
  factory SessionRegistry.standard({
    OrganizationAiGateway? aiGateway,
    TravelSearchProvider? travelProvider,
    StaySearchProvider? stayProvider,
  }) {
    return SessionRegistry(
      aiGateway: aiGateway ?? SupabaseOrganizationGateway(),
      travelProvider: travelProvider ?? MockTravelSearchProvider(),
      stayProvider: stayProvider ?? const UnavailableStaySearchProvider(),
    );
  }

  final OrganizationAiGateway aiGateway;
  final TravelSearchProvider travelProvider;
  final StaySearchProvider stayProvider;

  final Map<String, OrganizationSession> _sessions =
      <String, OrganizationSession>{};

  /// Restituisce la sessione per il [tripId], creandola su richiesta se assente.
  OrganizationSession getOrCreate(String tripId) {
    return _sessions.putIfAbsent(
      tripId,
      () => OrganizationSession(
        tripId: tripId,
        aiGateway: aiGateway,
        travelProvider: travelProvider,
        stayProvider: stayProvider,
      ),
    );
  }

  /// Verifica se una sessione è già attiva.
  bool hasSession(String tripId) => _sessions.containsKey(tripId);

  /// Rilascia e rimuove la sessione per un dato [tripId].
  void disposeSession(String tripId) {
    final session = _sessions.remove(tripId);
    session?.dispose();
  }

  /// Rilascia tutte le sessioni attive.
  void disposeAll() {
    for (final session in _sessions.values) {
      session.dispose();
    }
    _sessions.clear();
  }
}
