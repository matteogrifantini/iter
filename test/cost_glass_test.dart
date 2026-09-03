import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iter/app/iter_theme.dart';
import 'package:iter/features/chat_first_prototype/chat_first_data.dart';
import 'package:iter/features/chat_first_prototype/iter_glass_primitives.dart';
import 'package:iter/features/chat_first_prototype/plan_cost_sheet.dart';
import 'package:iter/features/chat_first_prototype/plan_external_launcher.dart';

void main() {
  testWidgets('cost sheet in vetro', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: IterTheme.light(),
        home: const Scaffold(body: IterGlassSheet(child: Text('Totali'))),
      ),
    );
    expect(find.text('Totali'), findsOneWidget);
  });

  testWidgets('real cost sheet gate: sezioni, dialog, disclaimer, successo', (
    tester,
  ) async {
    final launcher = PlanExternalLauncher(
      launchExternal: (_) async => true,
      launchBrowser: (_) async => false,
    );
    final data = buildPlanCostSheetData(
      ChatFirstDemoData.operationalFixtureFor('porto').snapshot,
      launcher,
    );
    expect(
      data.sections.map((section) => section.title),
      <String>['Da acquistare', 'Stime non acquistate', 'Totali'],
    );

    var confirmed = false;
    Finder sheetScrollable() => find
        .descendant(
          of: find.byKey(const Key('plan-cost-sheet-scroll')),
          matching: find.byType(Scrollable),
        )
        .first;
    Future<void> pumpSheet({required bool success}) {
      return tester.pumpWidget(
        MaterialApp(
          theme: IterTheme.light(),
          home: Scaffold(
            body: PlanCostSheet(
              sections: data.sections,
              onOpenPurchase: (_) async {},
              mockPurchasesConfirmed: success,
              onConfirmMockPurchases: () => confirmed = true,
            ),
          ),
        ),
      );
    }

    await pumpSheet(success: false);
    expect(find.byType(IterGlassSheet), findsOneWidget);
    expect(find.text('Da acquistare'), findsOneWidget);
    expect(find.text('Stime non acquistate'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Totale previsto'),
      120,
      scrollable: sheetScrollable(),
    );
    expect(find.text('Totali'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Demo: nessun pagamento reale'),
      120,
      scrollable: sheetScrollable(),
    );
    expect(find.text('Demo: nessun pagamento reale'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('plan-cost-confirm-demo')),
      160,
      scrollable: sheetScrollable(),
    );
    await tester.tap(find.byKey(const Key('plan-cost-confirm-demo')));
    await tester.pumpAndSettle();
    expect(find.text('Conferma le scelte del piano?'), findsOneWidget);
    final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
    expect(
      (dialog.shape! as RoundedRectangleBorder).borderRadius,
      BorderRadius.circular(28),
    );
    expect(find.textContaining('Totale previsto ·'), findsOneWidget);
    expect(find.text('Demo: nessun pagamento reale'), findsNWidgets(2));

    await tester.tap(find.byKey(const Key('plan-cost-confirm-dialog')));
    await tester.pumpAndSettle();
    expect(confirmed, isTrue);

    await pumpSheet(success: true);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Scelte confermate'),
      120,
      scrollable: sheetScrollable(),
    );
    expect(find.text('Scelte confermate'), findsOneWidget);
  });
}
