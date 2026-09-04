import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iter/features/chat/trip_chat_screen.dart';
import 'package:iter/features/home/home_screen.dart';
import 'package:iter/features/profile/profile_screen.dart';
import 'package:iter/features/trips/trips_list_screen.dart';


void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('E2E: App si apre sulla Home pulita (senza chat box), permette navigazione tra le tab Oggi, Viaggi e Tu', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: _TestIterAppShell(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Tab Oggi: Home Screen pulita senza TextField chat
    expect(find.text('iter'), findsOneWidget);
    expect(find.text('Organizza un nuovo viaggio'), findsOneWidget);


    expect(find.text('Le tue pianificazioni'), findsNothing);
    expect(find.text('Consigli & Offerte per te'), findsOneWidget);

    expect(find.text('Scopri nuovi posti'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);

    // 2. Navigazione a Tab Viaggi
    await tester.tap(find.text('Viaggi'));
    await tester.pumpAndSettle();
    expect(find.text('I tuoi viaggi'), findsOneWidget);
    expect(find.text('Nuovo viaggio'), findsOneWidget);

    // 3. Navigazione a Tab Tu (Profilo)
    await tester.tap(find.text('Tu'));
    await tester.pumpAndSettle();
    expect(find.text('Il tuo profilo'), findsOneWidget);
    expect(find.text('Preferenze di Viaggio'), findsOneWidget);
    expect(find.text('Configurazione IA (Fase Demo)'), findsOneWidget);
    expect(find.byKey(const Key('gemini_api_key_input')), findsOneWidget);

    // 4. Ritorno alla Home ed apertura della Chat dedicata a tutto schermo
    await tester.tap(find.text('Oggi'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Organizza un nuovo viaggio'));
    await tester.pumpAndSettle();

    // Ora siamo nella TripChatScreen a schermo intero con composer dedicato
    expect(find.text('Organizzazione viaggio'), findsOneWidget);
    expect(find.text('Scrivi un messaggio a Iter...'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

  });
}

class _TestIterAppShell extends StatefulWidget {
  const _TestIterAppShell();

  @override
  State<_TestIterAppShell> createState() => _TestIterAppShellState();
}

class _TestIterAppShellState extends State<_TestIterAppShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          HomeScreen(
            onOpenNewTripChat: ({destination}) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TripChatScreen(
                    initialPrompt: destination != null ? 'Vorrei andare a $destination' : null,
                    onOpenSnapshot: (_) {},
                  ),
                ),
              );
            },
            onOpenTripDetails: (_) {},
            onOpenProfile: () => setState(() => _tab = 2),
          ),
          TripsListScreen(
            onOpenTripChat: (_) {},
            onOpenTripSnapshot: (_) {},
            onStartNewTrip: () {},
          ),

          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Oggi'),
          NavigationDestination(icon: Icon(Icons.flight), label: 'Viaggi'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Tu'),
        ],
      ),
    );
  }
}

