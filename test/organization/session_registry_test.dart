import 'package:flutter_test/flutter_test.dart';
import 'package:iter/features/organization/adapters/mock_travel_search_provider.dart';
import 'package:iter/features/organization/adapters/unavailable_stay_search_provider.dart';
import 'package:iter/features/organization/engine/session_registry.dart';
import 'package:iter/features/organization/providers/organization_ai_gateway.dart';

class _DummyAiGateway implements OrganizationAiGateway {
  @override
  Future<AiOrganizationResponse> decideNextStep(
    OrganizationAiContext context,
  ) async {
    return AiOrganizationResponse();
  }
}

void main() {
  group('SessionRegistry Tests', () {
    late SessionRegistry registry;

    setUp(() {
      registry = SessionRegistry(
        aiGateway: _DummyAiGateway(),
        travelProvider: MockTravelSearchProvider(delay: Duration.zero),
        stayProvider: const UnavailableStaySearchProvider(delay: Duration.zero),
      );
    });

    tearDown(() {
      registry.disposeAll();
    });

    test('getOrCreate returns identical instance for same tripId', () {
      final session1 = registry.getOrCreate('trip-1');
      final session2 = registry.getOrCreate('trip-1');

      expect(identical(session1, session2), isTrue);
      expect(registry.hasSession('trip-1'), isTrue);
    });

    test('getOrCreate returns distinct instances for different tripIds', () {
      final session1 = registry.getOrCreate('trip-1');
      final session2 = registry.getOrCreate('trip-2');

      expect(identical(session1, session2), isFalse);
      expect(session1.tripId, 'trip-1');
      expect(session2.tripId, 'trip-2');
    });

    test('disposeSession terminates and unregisters session', () {
      final session = registry.getOrCreate('trip-1');
      expect(session.isDisposed, isFalse);

      registry.disposeSession('trip-1');
      expect(session.isDisposed, isTrue);
      expect(registry.hasSession('trip-1'), isFalse);
    });

    test('disposeAll terminates all active sessions', () {
      final s1 = registry.getOrCreate('trip-1');
      final s2 = registry.getOrCreate('trip-2');

      registry.disposeAll();
      expect(s1.isDisposed, isTrue);
      expect(s2.isDisposed, isTrue);
      expect(registry.hasSession('trip-1'), isFalse);
      expect(registry.hasSession('trip-2'), isFalse);
    });
  });
}
