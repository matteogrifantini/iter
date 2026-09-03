import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iter/features/profile/profile_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('ProfileScreen visualizza preferenze di viaggio e campo API Key Demo', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(

      const MaterialApp(
        home: Scaffold(
          body: ProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Il tuo profilo'), findsOneWidget);
    expect(find.text('Città di partenza predefinita'), findsOneWidget);
    expect(find.text('Stile di viaggio preferito'), findsOneWidget);

    // Verificare sezione API Key Demo
    expect(find.text('Configurazione IA (Fase Demo)'), findsOneWidget);
    expect(find.byType(TextField), findsWidgets);

    // Inserire una chiave e salvare
    await tester.enterText(find.byKey(const Key('gemini_api_key_input')), 'AIzaSyTestKey123');
    await tester.tap(find.text('Salva chiave'));
    await tester.pumpAndSettle();

    expect(find.text('Chiave salvata con successo'), findsOneWidget);
  });
}
