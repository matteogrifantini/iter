import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iter/app/iter_theme.dart';
import 'package:iter/features/chat_first_prototype/chat_first_profile_screen.dart';
import 'package:iter/features/chat_first_prototype/profile_models.dart';

Widget _pumpProfile({
  required ThemeData theme,
  TextScaler textScaler = const TextScaler.linear(1.5),
  bool highContrast = false,
  bool disableAnimations = false,
  List<String> memoryTags = const <String>['Ritmo lento', 'Tavola di quartiere'],
  List<AvailabilityEntry> availability = const <AvailabilityEntry>[],
  ThemeMode themeMode = ThemeMode.light,
  ValueChanged<String>? onRemoveAvailability,
}) {
  return MaterialApp(
    theme: theme,
    builder: (context, child) => MediaQuery(
      // copyWith: preserva size reale del view (320dp), cambia solo a11y.
      data: MediaQuery.of(context).copyWith(
        textScaler: textScaler,
        highContrast: highContrast,
        disableAnimations: disableAnimations,
      ),
      child: child!,
    ),
    home: Scaffold(
      body: ChatFirstProfileScreen(
        themeMode: themeMode,
        onThemeChanged: (_) {},
        onOpenChats: () {},
        memoryTags: memoryTags,
        availability: availability,
        onRemoveAvailability: onRemoveAvailability,
      ),
    ),
  );
}

Finder _profileScrollable() => find
    .descendant(
      of: find.byType(ChatFirstProfileScreen),
      matching: find.byType(Scrollable),
    )
    .first;

final _demoAvailability = <AvailabilityEntry>[
  AvailabilityEntry(
    id: 'availability-1',
    date: DateTime(2026, 10, 17),
    kind: AvailabilityKind.free,
    timeRange: 'Tutto il giorno',
    note: 'Weekend libero',
  ),
];

void main() {
  testWidgets('profilo leggibile a 320dp testo 1.5 senza overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _pumpProfile(theme: IterTheme.light(), availability: _demoAvailability),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    // Attraversa tutta la lista: nessun overflow/exception anche fuori fold.
    await tester.scrollUntilVisible(
      find.text('Le tue conversazioni', skipOffstage: false),
      200,
      scrollable: _profileScrollable(),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('profilo dark + highContrast + no animazioni senza exception', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _pumpProfile(
        theme: IterTheme.dark(),
        themeMode: ThemeMode.dark,
        highContrast: true,
        disableAnimations: true,
        availability: _demoAvailability,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    // SliverList costruisce i figli solo quando entrano nel viewport: per
    // verificare il contenuto sotto il fold bisogna scorrerci (a 1.5x il
    // SegmentedButton non è ancora costruito al primo frame). Dopo lo scroll
    // gli assert usano skipOffstage:false perché il figlio può essere
    // costruito nel cache extent ma appena fuori dal paint extent.
    // Tema Chiaro/Scuro/Sistema invariato.
    await tester.scrollUntilVisible(
      find.text('Sistema', skipOffstage: false),
      200,
      scrollable: _profileScrollable(),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Chiaro', skipOffstage: false), findsOneWidget);
    expect(find.text('Scuro', skipOffstage: false), findsOneWidget);
    expect(find.text('Sistema', skipOffstage: false), findsOneWidget);
  });

  testWidgets('profilo usa hairline Divider, ListTile, chip, stats, nessun blur',
      (tester) async {
    await tester.pumpWidget(
      _pumpProfile(theme: IterTheme.light(), availability: _demoAvailability),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    // Primo fold: 3 statistiche compatte + chip memoria + hairline divider.
    expect(find.text('viaggi'), findsOneWidget);
    expect(find.text('luoghi'), findsOneWidget);
    expect(find.text('km stimati'), findsOneWidget);
    expect(find.byType(Chip), findsWidgets);
    expect(find.byType(Divider), findsWidgets);
    for (final d in tester.widgetList<Divider>(find.byType(Divider))) {
      expect(d.height ?? 0, lessThanOrEqualTo(2));
    }
    // Tema Chiaro/Scuro/Sistema invariato.
    await tester.scrollUntilVisible(
      find.text('Sistema', skipOffstage: false),
      200,
      scrollable: _profileScrollable(),
    );
    expect(find.text('Chiaro', skipOffstage: false), findsOneWidget);
    expect(find.text('Scuro', skipOffstage: false), findsOneWidget);
    expect(find.text('Sistema', skipOffstage: false), findsOneWidget);
    // ListTile FAQ/Privacy/conversazioni.
    await tester.scrollUntilVisible(
      find.text('Domande frequenti', skipOffstage: false),
      200,
      scrollable: _profileScrollable(),
    );
    expect(find.byType(ListTile, skipOffstage: false), findsWidgets);
    expect(find.text('Domande frequenti', skipOffstage: false), findsOneWidget);
    expect(find.text('Privacy', skipOffstage: false), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Le tue conversazioni', skipOffstage: false),
      200,
      scrollable: _profileScrollable(),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    // Profilo resta opaco: nessun blur aggiunto qui.
    expect(find.byType(BackdropFilter, skipOffstage: false), findsNothing);
  });

  testWidgets('profilo target tocco 48dp', (tester) async {
    await tester.pumpWidget(
      _pumpProfile(
        theme: IterTheme.light(),
        availability: _demoAvailability,
        onRemoveAvailability: (_) {},
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.text('Sistema', skipOffstage: false),
      200,
      scrollable: _profileScrollable(),
    );
    final segmented = tester.getSize(
      find.byType(SegmentedButton<ThemeMode>, skipOffstage: false),
    );
    expect(segmented.height, greaterThanOrEqualTo(48));
    // Il bottone intero deve offrire un target da 48dp.
    await tester.scrollUntilVisible(
      find.text('Aggiungi disponibilità', skipOffstage: false),
      200,
      scrollable: _profileScrollable(),
    );
    final addButtonSize = tester.getSize(
      find.ancestor(
        of: find.text('Aggiungi disponibilità', skipOffstage: false),
        matching: find.byType(OutlinedButton, skipOffstage: false),
      ),
    );
    expect(addButtonSize.height, greaterThanOrEqualTo(48));
    await tester.scrollUntilVisible(
      find.byTooltip('Rimuovi disponibilità', skipOffstage: false),
      200,
      scrollable: _profileScrollable(),
    );
    final removeSize = tester.getSize(
      find.byTooltip('Rimuovi disponibilità', skipOffstage: false),
    );
    expect(removeSize.height, greaterThanOrEqualTo(48));
    expect(removeSize.width, greaterThanOrEqualTo(48));
  });

  testWidgets('profilo semantics conservate', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _pumpProfile(theme: IterTheme.light()),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final statsSemantics = tester.getSemantics(
      find.byKey(const Key('profile-stats')),
    );
    expect(statsSemantics.label, contains('Statistiche di viaggio'));
    await tester.scrollUntilVisible(
      find.text('Aspetto', skipOffstage: false),
      200,
      scrollable: _profileScrollable(),
    );
    expect(find.text('Aspetto', skipOffstage: false), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Disponibilità', skipOffstage: false),
      200,
      scrollable: _profileScrollable(),
    );
    expect(find.text('Disponibilità', skipOffstage: false), findsOneWidget);
    semantics.dispose();
  });
}
