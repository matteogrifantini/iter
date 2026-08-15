import 'package:flutter_test/flutter_test.dart';
import 'package:iter/features/chat_first_prototype/chat_first_controller.dart';
import 'package:iter/app/app_entry.dart';

void main() {
  testWidgets('root app is always the new three-destination shell', (
    tester,
  ) async {
    final controller = ChatFirstPrototypeController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(buildIterApp(controller: controller));

    expect(find.text('Oggi'), findsOneWidget);
    expect(find.text('Viaggi'), findsOneWidget);
    expect(find.text('Tu'), findsOneWidget);
    expect(find.text('Scopri'), findsNothing);
  });
}
