import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iter/app/app_config.dart';
import 'package:iter/app/iter_app.dart';

void main() {
  testWidgets('builds a journey progressively before suggesting destinations', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(375, 812));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const IterApp(
        config: AppConfig(
          backend: 'mock',
          supabaseUrl: '',
          supabaseAnonKey: '',
        ),
      ),
    );

    expect(find.text('Partiamo da come vuoi sentirti.'), findsOneWidget);
    expect(find.text('Inizia un viaggio'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('new-trip')));
    await tester.pumpAndSettle();

    expect(find.text('Come vuoi sentirti al ritorno?'), findsOneWidget);

    for (final answer in <String>[
      'Rigenerato',
      'Un weekend',
      'Spostarmi in treno',
      'In coppia',
      'Un equilibrio',
    ]) {
      await tester.tap(find.text(answer));
      await tester.pumpAndSettle();
    }

    expect(find.text('Tre viaggi, non tre città.'), findsOneWidget);
    expect(find.text('Atlantico in treno'), findsOneWidget);

    await tester.tap(find.text('Parti da questo viaggio').first);
    await tester.pumpAndSettle();

    expect(find.text('Segui il tuo istinto.'), findsOneWidget);

    for (var index = 0; index < 10; index++) {
      await tester.tap(find.text('Salva'));
      await tester.pumpAndSettle();
    }

    await tester.tap(find.text('Avanti'));
    await tester.pumpAndSettle();
    expect(find.text('Come comincia il viaggio?'), findsOneWidget);

    await tester.tap(find.text('Arriva con il giorno davanti'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continua'));
    await tester.pumpAndSettle();
    expect(find.text('Dove vuoi svegliarti?'), findsOneWidget);

    await tester.tap(find.text('Scegli base').first);
    await tester.pumpAndSettle();
    expect(find.text('Giorno per giorno'), findsOneWidget);
    expect(find.text('Chiedi a Iter di cambiare il piano'), findsOneWidget);
  });
}
