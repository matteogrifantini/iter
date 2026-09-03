import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iter/app/app_entry.dart';
import 'package:iter/features/chat_first_prototype/chat_first_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('E2E Trip Lifecycle & Traveler Journey', () {
    testWidgets(
      'Full end-to-end flow: Home pulita -> Viaggi -> Profilo Tu -> Apri Chat a tutto schermo',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final controller = ChatFirstPrototypeController();
        addTearDown(controller.dispose);

        // 1. App Startup su Home pulita senza chat box
        await tester.pumpWidget(buildIterApp(controller: controller));
        await tester.pumpAndSettle();

        expect(find.text('Oggi'), findsOneWidget);
        expect(find.text('Viaggi'), findsOneWidget);
        expect(find.text('Tu'), findsOneWidget);
        expect(find.text('iter'), findsOneWidget);
        expect(find.text('Organizza un nuovo viaggio'), findsOneWidget);
        expect(find.byType(TextField), findsNothing);

        // 2. Navigazione a Viaggi
        await tester.tap(find.text('Viaggi').last);
        await tester.pumpAndSettle();

        expect(find.text('I tuoi viaggi'), findsOneWidget);
        expect(find.text('Nuovo viaggio'), findsOneWidget);

        // 3. Navigazione a Profilo Tu
        await tester.tap(find.text('Tu').last);
        await tester.pumpAndSettle();

        expect(find.text('Il tuo profilo'), findsOneWidget);
        expect(find.text('Preferenze di Viaggio'), findsOneWidget);
        expect(find.text('Configurazione IA (Fase Demo)'), findsOneWidget);

        // 4. Ritorno a Oggi ed apertura chat dedicata
        await tester.tap(find.text('Oggi').last);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Organizza un nuovo viaggio'));
        await tester.pumpAndSettle();

        // Chat dedicata aperta
        expect(find.text('Organizzazione viaggio'), findsOneWidget);
        expect(find.byType(TextField), findsOneWidget);
      },
    );
  });
}
