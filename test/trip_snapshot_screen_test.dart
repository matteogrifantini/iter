import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:iter/app/iter_theme.dart';
import 'package:iter/data/mock_data.dart';
import 'package:iter/features/chat_first_prototype/adaptive_home_model.dart';
import 'package:iter/features/chat_first_prototype/chat_first_app.dart';
import 'package:iter/features/chat_first_prototype/chat_first_controller.dart';
import 'package:iter/features/chat_first_prototype/chat_first_data.dart';
import 'package:iter/features/chat_first_prototype/chat_first_home_screen.dart';
import 'package:iter/features/chat_first_prototype/chat_first_models.dart';
import 'package:iter/features/chat_first_prototype/chat_first_thread_screen.dart';
import 'package:iter/features/chat_first_prototype/inspiration_importer.dart';
import 'package:iter/features/chat_first_prototype/place_reel_screen.dart';
import 'package:iter/features/chat_first_prototype/plan_cost_sheet.dart';
import 'package:iter/features/chat_first_prototype/plan_editor.dart';
import 'package:iter/features/chat_first_prototype/plan_external_launcher.dart';
import 'package:iter/features/chat_first_prototype/trip_snapshot_screen.dart';
import 'package:iter/models/trip_models.dart' show JourneyRoute;

const _conversationId = 'c-plan-ui';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Piano operativo', () {
    testWidgets(
      'reads the current conversation snapshot and shows narrative timeline without a map',
      (tester) async {
        final controller = _controllerFor(
          ChatFirstDemoData.operationalFixtureFor('porto').snapshot,
        );
        addTearDown(controller.dispose);

        await _pumpPlan(tester, controller: controller);

        expect(find.byKey(const Key('plan-map')), findsNothing);
        expect(find.byKey(const Key('plan-destination-hero')), findsOneWidget);
        expect(find.text('Giorno 1'), findsOneWidget);
        expect(find.text('Giorno 2'), findsOneWidget);
        expect(find.byKey(const Key('plan-timeline')), findsOneWidget);
        expect(find.text('Livraria Lello'), findsOneWidget);
        expect(find.byKey(const Key('plan-global-actions')), findsOneWidget);
        expect(
          tester.getSize(find.byKey(const Key('plan-global-actions'))).height,
          greaterThanOrEqualTo(48),
        );

        final updated = controller
            .conversationOf(_conversationId)
            .snapshot!
            .copyWith(destinationTitle: 'Porto aggiornato');
        controller.threadOf(_conversationId).summary = controller
            .conversationOf(_conversationId)
            .copyWith(title: 'Porto aggiornato', snapshot: updated);
        controller.notifyListeners();
        await tester.pump();

        expect(find.text('Porto aggiornato'), findsWidgets);
      },
    );

    testWidgets('il piano espone media della destinazione e il suo reel demo', (
      tester,
    ) async {
      final controller = _controllerFor(
        ChatFirstDemoData.operationalFixtureFor('porto').snapshot,
      );
      addTearDown(controller.dispose);

      await _pumpPlan(tester, controller: controller);

      expect(find.byKey(const Key('plan-destination-media')), findsOneWidget);
      expect(find.text('Porto · immagini e video'), findsOneWidget);
      await tester.tap(find.byKey(const Key('plan-destination-media')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('plan-destination-media-sheet')),
        findsOneWidget,
      );
      expect(find.text('Vedi video della destinazione'), findsOneWidget);
    });

    testWidgets('le ispirazioni salvate restano visibili nel piano', (
      tester,
    ) async {
      final controller = _controllerFor(
        ChatFirstDemoData.operationalFixtureFor('porto').snapshot,
      );
      addTearDown(controller.dispose);
      final draft = parseMockInspiration(
        'https://www.instagram.com/reel/iter-porto',
      ).draft!;
      controller.saveInspiration(conversationId: _conversationId, draft: draft);

      await _pumpPlan(tester, controller: controller);

      expect(find.text('Ispirazioni salvate'), findsOneWidget);
      expect(find.text('Una mattina lenta a Porto'), findsOneWidget);
      expect(find.text('Da integrare'), findsOneWidget);
    });

    testWidgets('imports a mock Reel, saves it, then proposes integration', (
      tester,
    ) async {
      final controller = _controllerFor(
        ChatFirstDemoData.operationalFixtureFor('porto').snapshot,
      );
      addTearDown(controller.dispose);
      final before = controller.conversationOf(_conversationId).snapshot!;

      await _pumpPlan(tester, controller: controller);
      await tester.tap(find.byTooltip('Altre azioni'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Importa ispirazione'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('inspiration-url-field')),
        'https://www.instagram.com/reel/iter-porto',
      );
      await tester.tap(find.text('Estrai ispirazione'));
      await tester.pumpAndSettle();
      expect(find.text('Livraria Lello'), findsOneWidget);
      expect(find.text('Salva ispirazione'), findsOneWidget);

      await tester.ensureVisible(find.text('Salva ispirazione'));
      await tester.tap(find.text('Salva ispirazione'));
      await tester.pumpAndSettle();
      expect(find.text('Ispirazione salvata'), findsOneWidget);
      expect(
        controller.conversationOf(_conversationId).snapshot!.toJson(),
        before.toJson(),
      );

      await tester.tap(find.text('Proponi integrazione'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Proposta inviata in chat'), findsOneWidget);
      expect(
        controller.threadOf(_conversationId).messages,
        contains(predicate<ChatMessage>((message) => message.proposal != null)),
      );
    });

    testWidgets('opens catalogue details from the seeded operational thread', (
      tester,
    ) async {
      final controller = ChatFirstPrototypeController();
      addTearDown(controller.dispose);

      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: TripSnapshotScreen(
            controller: controller,
            conversationId: 'c-roma-active',
          ),
        ),
      );
      final firstStop = find.byKey(const Key('plan-item-roma-day-1-item-1'));
      await tester.ensureVisible(firstStop);
      await tester.tap(firstStop);
      await tester.pumpAndSettle();

      expect(find.byType(DraggableScrollableSheet), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Il cuore archeologico della Roma antica.'),
        180,
        scrollable: _scrollableInside(const Key('place-sheet-scroll')),
      );
      expect(
        find.text('Il cuore archeologico della Roma antica.'),
        findsOneWidget,
      );
    });

    testWidgets('reserves the hero and shows Da sistemare for an empty plan', (
      tester,
    ) async {
      final controller = _controllerFor(_emptySnapshot());
      addTearDown(controller.dispose);

      await _pumpPlan(tester, controller: controller);

      expect(find.byKey(const Key('plan-destination-hero')), findsOneWidget);
      expect(
        tester.getSize(find.byKey(const Key('plan-destination-hero'))).height,
        greaterThan(120),
      );
      expect(find.text('Da sistemare'), findsOneWidget);
      expect(find.byKey(const Key('plan-global-actions')), findsOneWidget);
    });

    testWidgets(
      'scrolls timeline and sheet accessibly at 320, 360 and 390 in both themes with large text',
      (tester) async {
        final controller = _controllerFor(
          ChatFirstDemoData.operationalFixtureFor('porto').snapshot,
        );
        addTearDown(controller.dispose);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        for (final width in <double>[320, 360, 390]) {
          for (final brightness in <Brightness>[
            Brightness.light,
            Brightness.dark,
          ]) {
            final size = Size(width, 760);
            await tester.binding.setSurfaceSize(size);
            await tester.pumpWidget(
              MaterialApp(
                key: ValueKey<String>('$width-$brightness'),
                theme: ThemeData(brightness: brightness, useMaterial3: true),
                home: MediaQuery(
                  data: MediaQueryData(
                    size: size,
                    textScaler: const TextScaler.linear(1.5),
                    disableAnimations: true,
                  ),
                  child: TripSnapshotScreen(
                    controller: controller,
                    conversationId: _conversationId,
                  ),
                ),
              ),
            );
            await tester.pump();
            expect(tester.takeException(), isNull);
            expect(
              find.byKey(const Key('plan-global-actions')),
              findsOneWidget,
            );

            final lastStop = find.byKey(
              const Key('plan-item-porto-clerigos-stop'),
            );
            await tester.drag(
              _scrollableInside(const Key('plan-scroll')),
              const Offset(0, -360),
            );
            await tester.pump();
            expect(tester.takeException(), isNull);
            await tester.scrollUntilVisible(
              lastStop,
              260,
              scrollable: _scrollableInside(const Key('plan-scroll')),
            );
            expect(tester.takeException(), isNull);
            await tester.drag(
              _scrollableInside(const Key('plan-scroll')),
              const Offset(0, -180),
            );
            await tester.pump();
            expect(tester.takeException(), isNull);
            expect(tester.getCenter(lastStop).dy, lessThan(size.height - 80));
            await tester.tap(lastStop);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);

            final titleFocus = find.byKey(const Key('place-sheet-title-focus'));
            expect(
              FocusManager.instance.primaryFocus?.context,
              same(titleFocus.evaluate().single),
            );
            final semanticsHandle = tester.ensureSemantics();
            expect(
              tester.semantics.simulatedAccessibilityTraversal(),
              containsAllInOrder(<Matcher>[
                isSemantics(
                  label: 'Immagine non disponibile per Torre dos Clérigos',
                ),
                isSemantics(label: 'Torre dos Clérigos'),
                isSemantics(label: 'Panorama · Centro di Porto'),
                isSemantics(
                  label:
                      'Perché Iter te la consiglia\nSi inserisce nel ritmo “Libri e centro storico” senza spezzare la sequenza della giornata.',
                ),
              ]),
            );
            await tester.drag(
              _scrollableInside(const Key('place-sheet-scroll')),
              const Offset(0, -520),
            );
            await tester.pump();
            expect(tester.takeException(), isNull);
            await tester.scrollUntilVisible(
              find.text('Informazioni pratiche'),
              260,
              scrollable: _scrollableInside(const Key('place-sheet-scroll')),
            );
            expect(tester.takeException(), isNull);
            expect(find.text('Informazioni pratiche'), findsOneWidget);
            semanticsHandle.dispose();
            Navigator.of(
              tester.element(find.byType(DraggableScrollableSheet)),
            ).pop();
            await tester.pumpAndSettle();
          }
        }
      },
    );

    testWidgets(
      'opens an extended scrollable place sheet with one Iter note and practical order',
      (tester) async {
        final controller = _controllerFor(
          ChatFirstDemoData.operationalFixtureFor('porto').snapshot,
        );
        addTearDown(controller.dispose);

        await _pumpPlan(
          tester,
          controller: controller,
          textScaler: const TextScaler.linear(1.5),
        );
        final lelloStop = find.byKey(
          const Key('plan-item-porto-livraria-lello-stop'),
        );
        await tester.ensureVisible(lelloStop);
        await tester.pump();
        await tester.tap(lelloStop);
        await tester.pumpAndSettle();

        expect(find.byType(DraggableScrollableSheet), findsOneWidget);
        expect(
          find.byKey(const Key('place-sheet-title-focus')),
          findsOneWidget,
        );
        expect(find.text('Vedi reel'), findsOneWidget);
        expect(find.text('Foto: JaimeMSilva'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('Perché Iter te la consiglia'),
          180,
          scrollable: _scrollableInside(const Key('place-sheet-scroll')),
        );
        expect(find.text('Perché Iter te la consiglia'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('Scalone in legno e scaffali Liberty nel centro di Porto.'),
          180,
          scrollable: _scrollableInside(const Key('place-sheet-scroll')),
        );
        expect(
          find.text('Scalone in legno e scaffali Liberty nel centro di Porto.'),
          findsOneWidget,
        );
        expect(
          tester.getTopLeft(find.byType(DraggableScrollableSheet)).dy,
          lessThan(100),
        );

        await tester.scrollUntilVisible(
          find.textContaining('♿'),
          240,
          scrollable: _scrollableInside(const Key('place-sheet-scroll')),
        );
        expect(find.textContaining('📍'), findsOneWidget);
        expect(find.textContaining('🚶'), findsOneWidget);
        expect(find.textContaining('🎟'), findsOneWidget);
        expect(find.textContaining('♿'), findsOneWidget);
      },
    );

    testWidgets(
      'Chiedi a Iter returns to the same thread with removable context and no send',
      (tester) async {
        final controller = _controllerFor(
          ChatFirstDemoData.operationalFixtureFor('porto').snapshot,
        );
        addTearDown(controller.dispose);
        final messagesBefore = controller
            .threadOf(_conversationId)
            .messages
            .length;
        final snapshotBefore = controller
            .conversationOf(_conversationId)
            .snapshot;
        final navigatorKey = GlobalKey<NavigatorState>();

        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navigatorKey,
            home: const Scaffold(body: Text('Thread c-plan-ui')),
          ),
        );
        navigatorKey.currentState!.push(
          MaterialPageRoute<void>(
            builder: (_) => TripSnapshotScreen(
              controller: controller,
              conversationId: _conversationId,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final lelloStop = find.byKey(
          const Key('plan-item-porto-livraria-lello-stop'),
        );
        await tester.scrollUntilVisible(
          lelloStop,
          260,
          scrollable: _scrollableInside(const Key('plan-scroll')),
        );
        await tester.tap(lelloStop);
        await tester.pumpAndSettle();
        final askIter = find.text('Chiedi a Iter');
        await tester.scrollUntilVisible(
          askIter,
          180,
          scrollable: _scrollableInside(const Key('place-sheet-scroll')),
        );
        await tester.drag(
          _scrollableInside(const Key('place-sheet-scroll')),
          const Offset(0, -160),
        );
        await tester.pump();
        await tester.tap(askIter);
        await tester.pumpAndSettle();

        expect(find.text('Thread c-plan-ui'), findsOneWidget);
        expect(
          controller.placeComposerContext(_conversationId)?.title,
          'Livraria Lello',
        );
        expect(
          controller.threadOf(_conversationId).messages,
          hasLength(messagesBefore),
        );
        expect(
          controller.conversationOf(_conversationId).snapshot,
          same(snapshotBefore),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: ChatFirstThreadScreen(
              controller: controller,
              conversationId: _conversationId,
              onOpenSnapshot: (_) {},
            ),
          ),
        );
        await tester.pump();
        expect(find.text('Su Livraria Lello'), findsOneWidget);
        expect(find.byTooltip('Rimuovi contesto luogo'), findsOneWidget);
        await tester.tap(find.byTooltip('Rimuovi contesto luogo'));
        await tester.pump();
        expect(find.text('Su Livraria Lello'), findsNothing);
      },
    );

    testWidgets(
      'uses place media only for Lello and neutral fallbacks elsewhere',
      (tester) async {
        final controller = _controllerFor(
          ChatFirstDemoData.operationalFixtureFor('porto').snapshot,
        );
        addTearDown(controller.dispose);
        final semanticsHandle = tester.ensureSemantics();

        await _pumpPlan(tester, controller: controller);
        final lello = find.byKey(
          const Key('plan-item-porto-livraria-lello-stop'),
        );
        await tester.ensureVisible(lello);
        await tester.tap(lello);
        await tester.pumpAndSettle();
        expect(find.text('Vedi reel'), findsOneWidget);
        expect(find.text('Foto: JaimeMSilva'), findsOneWidget);
        Navigator.of(
          tester.element(find.byType(DraggableScrollableSheet)),
        ).pop();
        await tester.pumpAndSettle();

        final clerigos = find.byKey(const Key('plan-item-porto-clerigos-stop'));
        await tester.scrollUntilVisible(
          clerigos,
          220,
          scrollable: _scrollableInside(const Key('plan-scroll')),
        );
        await tester.tap(clerigos);
        await tester.pumpAndSettle();
        expect(find.text('Vedi reel'), findsNothing);
        expect(find.textContaining('JaimeMSilva'), findsNothing);
        expect(
          find.bySemanticsLabel(
            'Immagine non disponibile per Torre dos Clérigos',
          ),
          findsOneWidget,
        );
        semanticsHandle.dispose();
      },
    );

    testWidgets('keeps Roma place sheets neutral without approved media', (
      tester,
    ) async {
      final controller = ChatFirstPrototypeController();
      addTearDown(controller.dispose);
      final semanticsHandle = tester.ensureSemantics();

      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: TripSnapshotScreen(
            controller: controller,
            conversationId: 'c-roma-active',
          ),
        ),
      );
      final foro = find.byKey(const Key('plan-item-roma-day-1-item-1'));
      await tester.ensureVisible(foro);
      await tester.tap(foro);
      await tester.pumpAndSettle();

      expect(find.text('Vedi reel'), findsNothing);
      expect(find.textContaining('JaimeMSilva'), findsNothing);
      expect(
        find.bySemanticsLabel('Immagine non disponibile per Foro Romano'),
        findsOneWidget,
      );
      semanticsHandle.dispose();
    });

    testWidgets(
      'searches by category, previews without mutation, applies and undoes an added place',
      (tester) async {
        final controller = _controllerFor(
          ChatFirstDemoData.operationalFixtureFor('roma').snapshot,
        );
        addTearDown(controller.dispose);
        await _pumpPlan(tester, controller: controller);
        final before = controller.conversationOf(_conversationId).snapshot!;

        await tester.tap(find.text('Aggiungi luogo'));
        await tester.pumpAndSettle();
        expect(
          FocusManager.instance.primaryFocus?.context?.widget.key,
          const Key('place-picker-search'),
        );
        await tester.enterText(
          find.byKey(const Key('place-picker-search-field')),
          'Quartiere',
        );
        await tester.pump();
        expect(
          find.byKey(const Key('place-picker-result-roma-trastevere')),
          findsOneWidget,
        );
        await tester.tap(
          find.byKey(const Key('place-picker-result-roma-trastevere')),
        );
        await tester.pump();
        expect(find.text('Vicoli e tavole per la sera.'), findsOneWidget);
        await tester.tap(find.text('Scegli luogo'));
        await tester.pump();
        expect(find.text('Inizio di Giorno 1'), findsOneWidget);
        expect(find.text('Prima di Foro Romano'), findsOneWidget);
        expect(find.text('Dopo Foro Romano'), findsOneWidget);
        expect(find.text('Fine di Giorno 1'), findsOneWidget);
        expect(find.text('Da sistemare'), findsWidgets);
        await tester.tap(find.text('Prima di Foro Romano'));
        await tester.tap(find.text('Rivedi modifica'));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('plan-patch-sheet')), findsOneWidget);
        expect(
          find.textContaining('Trastevere entra in Giorno 1'),
          findsOneWidget,
        );
        expect(
          controller.conversationOf(_conversationId).snapshot!.days,
          before.days,
        );
        expect(
          controller.pendingPlanPatch(_conversationId)?.intent.targetIndex,
          0,
        );
        expect(
          find.byKey(const Key('plan-patch-strong-check')),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const Key('plan-patch-strong-check')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('plan-patch-apply')));
        await tester.pumpAndSettle();

        expect(find.text('Modifica applicata'), findsOneWidget);
        expect(
          controller
              .conversationOf(_conversationId)
              .snapshot!
              .days
              .first
              .items
              .map((item) => item.title),
          contains('Trastevere'),
        );
        await tester.tap(find.widgetWithText(TextButton, 'Annulla'));
        await tester.pump();
        expect(
          controller
              .conversationOf(_conversationId)
              .snapshot!
              .days
              .expand((day) => day.items)
              .map((item) => item.title),
          isNot(contains('Trastevere')),
        );
      },
    );

    testWidgets('aggiunge un luogo personalizzato dal picker', (tester) async {
      final controller = _controllerFor(
        ChatFirstDemoData.operationalFixtureFor('roma').snapshot,
      );
      addTearDown(controller.dispose);

      await _pumpPlan(tester, controller: controller);
      await tester.tap(find.text('Aggiungi luogo'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('place-picker-search-field')),
        'Mercato del Porto',
      );
      await tester.pump();

      expect(
        find.byKey(const Key('place-picker-manual-result')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('place-picker-manual-result')));
      await tester.pump();
      expect(find.text('Mercato del Porto'), findsOneWidget);
      expect(find.text('Luogo personalizzato'), findsOneWidget);
      await tester.tap(find.text('Aggiungi al piano'));
      await tester.pump();
      expect(find.text('Dove lo inseriamo?'), findsOneWidget);
    });

    testWidgets('adds a selected place to Da sistemare only after apply', (
      tester,
    ) async {
      final controller = _controllerFor(
        ChatFirstDemoData.operationalFixtureFor('roma').snapshot,
      );
      addTearDown(controller.dispose);
      await _pumpPlan(tester, controller: controller);

      await _openTrasteverePicker(tester);
      await tester.tap(find.text('Da sistemare').last);
      await tester.tap(find.text('Rivedi modifica'));
      await tester.pumpAndSettle();
      expect(
        controller.conversationOf(_conversationId).snapshot!.unplacedItems,
        isEmpty,
      );
      await tester.tap(find.byKey(const Key('plan-patch-apply')));
      await tester.pumpAndSettle();
      expect(
        controller
            .conversationOf(_conversationId)
            .snapshot!
            .unplacedItems
            .single
            .title,
        'Trastevere',
      );
    });

    testWidgets(
      'keeps an applied unplaced place visible, movable and removable',
      (tester) async {
        final controller = _controllerFor(
          ChatFirstDemoData.operationalFixtureFor('roma').snapshot,
        );
        addTearDown(controller.dispose);
        await _pumpPlan(tester, controller: controller);

        await _openTrasteverePicker(tester);
        await tester.tap(find.text('Da sistemare').last);
        await tester.tap(find.text('Rivedi modifica'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('plan-patch-apply')));
        await tester.pumpAndSettle();
        tester
            .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
            .removeCurrentSnackBar();
        await tester.pump();

        final unplaced = find.byKey(
          const Key('plan-unplaced-roma-trastevere-manual-stop'),
        );
        final unplacedMenu = find.byKey(
          const Key('plan-unplaced-menu-roma-trastevere-manual-stop'),
        );
        await tester.scrollUntilVisible(
          unplacedMenu,
          220,
          scrollable: _scrollableInside(const Key('plan-scroll')),
        );
        final planScroll = tester.state<ScrollableState>(
          _scrollableInside(const Key('plan-scroll')),
        );
        await planScroll.position.animateTo(
          planScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
        await tester.pumpAndSettle();
        expect(unplaced, findsOneWidget);
        expect(unplacedMenu.hitTestable(), findsOneWidget);
        await tester.tap(unplacedMenu);
        await tester.pumpAndSettle();
        expect(find.text('Sposta'), findsOneWidget);
        expect(find.text('Rimuovi'), findsOneWidget);
        await tester.tap(find.text('Sposta'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Fine di Giorno 2'));
        await tester.tap(find.text('Rivedi modifica'));
        await tester.pumpAndSettle();
        expect(
          controller.pendingPlanPatch(_conversationId)?.intent.targetDayId,
          'roma-day-2',
        );
        await tester.tap(find.byKey(const Key('plan-patch-apply')));
        await tester.pumpAndSettle();
        expect(
          controller.conversationOf(_conversationId).snapshot!.unplacedItems,
          isEmpty,
        );
        await tester.tap(find.widgetWithText(TextButton, 'Annulla'));
        await tester.pump();
        expect(
          controller
              .conversationOf(_conversationId)
              .snapshot!
              .unplacedItems
              .single
              .title,
          'Trastevere',
        );

        await tester.scrollUntilVisible(
          unplacedMenu,
          220,
          scrollable: _scrollableInside(const Key('plan-scroll')),
        );
        await planScroll.position.animateTo(
          planScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
        await tester.pumpAndSettle();
        await tester.tap(unplacedMenu);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Rimuovi'));
        await tester.pumpAndSettle();
        expect(find.textContaining('viene rimosso dal piano'), findsOneWidget);
        await tester.tap(find.byKey(const Key('plan-patch-apply')));
        await tester.pumpAndSettle();
        expect(
          controller.conversationOf(_conversationId).snapshot!.unplacedItems,
          isEmpty,
        );
        expect(unplaced, findsNothing);
      },
    );

    testWidgets(
      'keeps unplaced-only plans removable without offering an invalid move',
      (tester) async {
        final controller = _controllerFor(_unplacedOnlySnapshot());
        addTearDown(controller.dispose);
        await _pumpPlan(tester, controller: controller);

        final menu = find.byKey(const Key('plan-unplaced-menu-later-stop'));
        await tester.tap(menu);
        await tester.pumpAndSettle();

        expect(find.text('Sposta'), findsNothing);
        expect(find.text('Rimuovi'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Rimuovi'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('plan-patch-sheet')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'reserves normal final spacing and counts the gesture inset once',
      (tester) async {
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final controller = _controllerFor(_romaSnapshotWithUnplaced());
        addTearDown(controller.dispose);
        const size = Size(390, 844);
        await tester.binding.setSurfaceSize(size);

        Future<double> pumpWithInset(double bottomInset) async {
          await tester.pumpWidget(
            MaterialApp(
              key: ValueKey<double>(bottomInset),
              builder: (context, child) => MediaQuery(
                data: MediaQueryData(
                  size: size,
                  padding: EdgeInsets.only(bottom: bottomInset),
                  viewPadding: EdgeInsets.only(bottom: bottomInset),
                ),
                child: child!,
              ),
              home: TripSnapshotScreen(
                controller: controller,
                conversationId: _conversationId,
              ),
            ),
          );
          await tester.pump();
          final scroll = tester.state<ScrollableState>(
            _scrollableInside(const Key('plan-scroll')),
          );
          scroll.position.jumpTo(scroll.position.maxScrollExtent);
          await tester.pump();
          expect(
            find
                .byKey(const Key('plan-unplaced-menu-later-stop'))
                .hitTestable(),
            findsOneWidget,
          );
          final gap =
              tester
                  .getTopLeft(find.byKey(const Key('plan-global-actions')))
                  .dy -
              tester
                  .getBottomLeft(find.byKey(const Key('plan-unplaced-section')))
                  .dy;
          expect(gap, inInclusiveRange(24, 48));
          return scroll.position.maxScrollExtent;
        }

        final withoutInset = await pumpWithInset(0);
        final withInset = await pumpWithInset(34);
        expect(withInset - withoutInset, closeTo(26, 0.1));
      },
    );

    testWidgets('labels an empty selected day as Giornata vuota', (
      tester,
    ) async {
      final controller = _controllerFor(_snapshotWithEmptyDay());
      addTearDown(controller.dispose);
      await _pumpPlan(tester, controller: controller);

      await tester.tap(find.text('Giorno vuoto'));
      await tester.pump();

      expect(find.text('Giornata vuota'), findsOneWidget);
      expect(find.text('Da sistemare'), findsNothing);
    });

    testWidgets(
      'cancels previews and requires a fresh confirmation after rebase',
      (tester) async {
        final controller = _controllerFor(
          ChatFirstDemoData.operationalFixtureFor('roma').snapshot,
        );
        addTearDown(controller.dispose);
        await _pumpPlan(tester, controller: controller);

        await _openTrasteverePicker(tester);
        await tester.tap(find.text('Da sistemare').last);
        await tester.tap(find.text('Rivedi modifica'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('plan-patch-cancel')));
        await tester.pumpAndSettle();
        expect(controller.pendingPlanPatch(_conversationId), isNull);
        expect(
          controller.conversationOf(_conversationId).snapshot!.unplacedItems,
          isEmpty,
        );

        await _openTrasteverePicker(tester);
        await tester.tap(find.text('Da sistemare').last);
        await tester.tap(find.text('Rivedi modifica'));
        await tester.pumpAndSettle();
        final current = controller.conversationOf(_conversationId).snapshot!;
        controller.threadOf(_conversationId).summary = controller
            .conversationOf(_conversationId)
            .copyWith(
              snapshot: current.copyWith(revision: current.revision + 1),
            );
        controller.notifyListeners();
        await tester.tap(find.byKey(const Key('plan-patch-apply')));
        await tester.pump();
        expect(
          find.text('Piano aggiornato: ricontrolla la modifica.'),
          findsOneWidget,
        );
        expect(
          controller.conversationOf(_conversationId).snapshot!.unplacedItems,
          isEmpty,
        );
        await tester.tap(find.byKey(const Key('plan-patch-apply')));
        await tester.pumpAndSettle();
        expect(
          controller.conversationOf(_conversationId).snapshot!.unplacedItems,
          hasLength(1),
        );
      },
    );

    testWidgets(
      'context menu previews time, lock and confirmed removal with strong protection',
      (tester) async {
        final controller = _controllerFor(
          ChatFirstDemoData.operationalFixtureFor('roma').snapshot,
        );
        addTearDown(controller.dispose);
        await _pumpPlan(tester, controller: controller);
        await tester.tap(find.text('Giorno 2'));
        await tester.pump();

        await tester.tap(find.byKey(const Key('plan-menu-roma-borghese-stop')));
        await tester.pumpAndSettle();
        expect(find.text('Sposta'), findsOneWidget);
        expect(find.text('Cambia orario'), findsOneWidget);
        expect(find.text('Blocca'), findsOneWidget);
        expect(find.text('Rimuovi'), findsOneWidget);
        await tester.tap(find.text('Cambia orario'));
        await tester.pumpAndSettle();
        expect(find.byType(TimePickerDialog), findsOneWidget);
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        expect(
          controller.pendingPlanPatch(_conversationId)?.kind,
          PlanPatchKind.changeTime,
        );
        await tester.tap(find.byKey(const Key('plan-patch-cancel')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('plan-menu-roma-borghese-stop')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Blocca'));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('plan-patch-strong-check')),
          findsOneWidget,
        );
        expect(
          tester
              .widget<FilledButton>(find.byKey(const Key('plan-patch-apply')))
              .onPressed,
          isNull,
        );
        await tester.tap(find.byKey(const Key('plan-patch-strong-check')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('plan-patch-apply')));
        await tester.pumpAndSettle();
        expect(
          controller
              .conversationOf(_conversationId)
              .snapshot!
              .days
              .last
              .items
              .single
              .locked,
          isTrue,
        );

        await tester.tap(find.byKey(const Key('plan-menu-roma-borghese-stop')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Rimuovi'));
        await tester.pumpAndSettle();
        expect(find.textContaining('viene rimosso dal piano'), findsOneWidget);
        await tester.tap(find.byKey(const Key('plan-patch-cancel')));
        await tester.pumpAndSettle();
        expect(
          controller.conversationOf(_conversationId).snapshot!.days.last.items,
          hasLength(1),
        );
      },
    );

    testWidgets('drag and accessible move menu produce equivalent previews', (
      tester,
    ) async {
      final controller = _controllerFor(
        ChatFirstDemoData.operationalFixtureFor('porto').snapshot,
      );
      addTearDown(controller.dispose);
      await _pumpPlan(tester, controller: controller);
      final drag = find.byKey(const Key('plan-drag-porto-livraria-lello-stop'));
      await tester.ensureVisible(drag);
      await tester.pump();
      expect(tester.getCenter(drag).dy, inInclusiveRange(0, 844));
      final gesture = await tester.startGesture(tester.getCenter(drag));
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
      expect(
        find.byKey(const Key('plan-drag-feedback-porto-livraria-lello-stop')),
        findsOneWidget,
      );
      final target = find.byKey(const Key('plan-drag-target-porto-day-1-end'));
      expect(target, findsOneWidget);
      await gesture.moveBy(const Offset(0, 8));
      await tester.pump();
      await gesture.moveTo(tester.getCenter(target));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      final dragPreview = controller.pendingPlanPatch(_conversationId)!;
      expect(dragPreview.kind, PlanPatchKind.moveStop);
      await tester.tap(find.byKey(const Key('plan-patch-cancel')));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('plan-menu-porto-livraria-lello-stop')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sposta'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fine di Giorno 1'));
      await tester.tap(find.text('Rivedi modifica'));
      await tester.pumpAndSettle();
      final menuPreview = controller.pendingPlanPatch(_conversationId)!;

      expect(menuPreview.effects, dragPreview.effects);
      expect(menuPreview.intent.targetDayId, dragPreview.intent.targetDayId);
      expect(menuPreview.intent.targetIndex, dragPreview.intent.targetIndex);
    });

    testWidgets('drag and move menu both reach an empty day across days', (
      tester,
    ) async {
      final controller = _controllerFor(_snapshotWithEmptyDay());
      addTearDown(controller.dispose);
      await _pumpPlan(tester, controller: controller);
      final drag = find.byKey(const Key('plan-drag-source-stop'));
      await tester.ensureVisible(drag);
      await tester.pump();
      final gesture = await tester.startGesture(tester.getCenter(drag));
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
      final target = find.byKey(const Key('plan-drag-target-empty-day-empty'));
      expect(target, findsOneWidget);
      await gesture.moveTo(tester.getCenter(target));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      final dragPreview = controller.pendingPlanPatch(_conversationId)!;
      expect(dragPreview.intent.targetDayId, 'empty-day');
      expect(dragPreview.intent.targetIndex, 0);
      await tester.tap(find.byKey(const Key('plan-patch-cancel')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('plan-menu-source-stop')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sposta'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Giorno vuoto · giornata vuota'));
      await tester.tap(find.text('Rivedi modifica'));
      await tester.pumpAndSettle();
      final menuPreview = controller.pendingPlanPatch(_conversationId)!;

      expect(menuPreview.intent.targetDayId, dragPreview.intent.targetDayId);
      expect(menuPreview.intent.targetIndex, dragPreview.intent.targetIndex);
      expect(menuPreview.effects, dragPreview.effects);
    });

    testWidgets('requires strong confirmation for a purchased linked option', (
      tester,
    ) async {
      final controller = _controllerFor(_purchasedRomaSnapshot());
      addTearDown(controller.dispose);
      await _pumpPlan(tester, controller: controller);
      await tester.tap(find.text('Giorno 2'));
      await tester.pump();

      await tester.tap(find.byKey(const Key('plan-menu-roma-borghese-stop')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rimuovi'));
      await tester.pumpAndSettle();

      expect(
        find.text('Il piano include una scelta acquistata'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('plan-patch-strong-check')), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('plan-patch-apply')))
            .onPressed,
        isNull,
      );
      await tester.tap(find.byKey(const Key('plan-patch-cancel')));
      await tester.pumpAndSettle();
      expect(
        controller.conversationOf(_conversationId).snapshot!.days.last.items,
        hasLength(1),
      );
    });

    testWidgets(
      'keeps manual editing scrollable and semantic at 320, 360 and 390 with large text',
      (tester) async {
        addTearDown(() => tester.binding.setSurfaceSize(null));
        for (final width in <double>[320, 360, 390]) {
          for (final brightness in <Brightness>[
            Brightness.light,
            Brightness.dark,
          ]) {
            final controller = _controllerFor(
              ChatFirstDemoData.operationalFixtureFor('roma').snapshot,
            );
            final size = Size(width, 760);
            await tester.binding.setSurfaceSize(size);
            await tester.pumpWidget(
              MaterialApp(
                key: ValueKey<String>('edit-$width-$brightness'),
                theme: ThemeData(brightness: brightness, useMaterial3: true),
                builder: (context, child) => MediaQuery(
                  data: MediaQueryData(
                    size: size,
                    textScaler: const TextScaler.linear(1.5),
                    disableAnimations: true,
                  ),
                  child: child!,
                ),
                home: TripSnapshotScreen(
                  controller: controller,
                  conversationId: _conversationId,
                ),
              ),
            );
            await tester.pump();
            expect(tester.takeException(), isNull);

            await tester.tap(find.text('Aggiungi luogo'));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            expect(
              FocusManager.instance.primaryFocus?.context,
              same(
                find.byKey(const Key('place-picker-search')).evaluate().single,
              ),
            );
            await tester.enterText(
              find.byKey(const Key('place-picker-search-field')),
              'Quartiere',
            );
            await tester.pump();
            await tester.scrollUntilVisible(
              find.byKey(const Key('place-picker-result-roma-trastevere')),
              180,
              scrollable: _scrollableInside(const Key('place-picker-scroll')),
            );
            expect(tester.takeException(), isNull);
            await tester.tap(
              find.byKey(const Key('place-picker-result-roma-trastevere')),
            );
            await tester.pump();
            await tester.scrollUntilVisible(
              find.text('Scegli luogo'),
              180,
              scrollable: _scrollableInside(
                const Key('place-picker-detail-scroll'),
              ),
            );
            expect(tester.takeException(), isNull);
            await tester.tap(find.text('Scegli luogo'));
            await tester.pump();
            final reviewChange = find.text('Rivedi modifica');
            final placementScroll = _scrollableInside(
              const Key('place-picker-placement-scroll'),
            );
            await tester.scrollUntilVisible(
              reviewChange,
              180,
              scrollable: placementScroll,
            );
            await tester.drag(placementScroll, const Offset(0, -80));
            await tester.pump();
            expect(tester.takeException(), isNull);
            expect(tester.getCenter(reviewChange).dy, lessThan(size.height));
            expect(reviewChange.hitTestable(), findsOneWidget);
            await tester.tap(find.text('Da sistemare').last);
            await tester.pump();
            await tester.tap(reviewChange);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            expect(
              FocusManager.instance.primaryFocus?.context,
              same(
                find
                    .byKey(const Key('plan-patch-title-focus'))
                    .evaluate()
                    .single,
              ),
            );
            final semantics = tester.ensureSemantics();
            expect(
              tester.semantics.simulatedAccessibilityTraversal(),
              containsAllInOrder(<Matcher>[
                isSemantics(label: 'Rivedi modifica'),
                isSemantics(label: 'Trastevere va in Da sistemare'),
                isSemantics(label: 'Annulla'),
                isSemantics(label: 'Applica'),
              ]),
            );
            await tester.drag(
              _scrollableInside(const Key('plan-patch-scroll')),
              const Offset(0, -80),
            );
            await tester.pump();
            expect(tester.takeException(), isNull);
            semantics.dispose();
            await tester.tap(find.byKey(const Key('plan-patch-cancel')));
            await tester.pumpAndSettle();
            expect(controller.pendingPlanPatch(_conversationId), isNull);
            controller.dispose();
          }
        }
      },
    );
  });

  group('Reel luogo', () {
    testWidgets(
      'starts muted and exposes pause, audio, source and close controls',
      (tester) async {
        final playback = _FakePlanReelPlaybackController();
        await tester.pumpWidget(
          MaterialApp(
            home: PlaceReelScreen(
              placeTitle: 'Livraria Lello',
              media: _portoMedia(),
              controllerFactory: (_) => playback,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byTooltip('Chiudi reel'), findsOneWidget);
        expect(find.byTooltip('Pausa'), findsOneWidget);
        expect(find.byTooltip('Attiva audio'), findsOneWidget);
        expect(find.textContaining('JaimeMSilva'), findsOneWidget);

        await tester.tap(find.byTooltip('Pausa'));
        await tester.pump();
        expect(find.byTooltip('Riprendi'), findsOneWidget);
        await tester.tap(find.byTooltip('Attiva audio'));
        await tester.pump();
        expect(find.byTooltip('Disattiva audio'), findsOneWidget);
      },
    );

    testWidgets(
      'uses the photo fallback and keeps source visible on video error',
      (tester) async {
        final playback = _FakePlanReelPlaybackController(
          failInitialization: true,
        );
        await tester.pumpWidget(
          MaterialApp(
            home: PlaceReelScreen(
              placeTitle: 'Livraria Lello',
              media: _portoMedia(),
              controllerFactory: (_) => playback,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('place-reel-photo-fallback')),
          findsOneWidget,
        );
        expect(find.text('Video non disponibile'), findsOneWidget);
        expect(find.textContaining('JaimeMSilva'), findsOneWidget);
      },
    );

    testWidgets('reacts to asynchronous playback notifications without a tap', (
      tester,
    ) async {
      final playback = _FakePlanReelPlaybackController();
      await tester.pumpWidget(
        MaterialApp(
          home: PlaceReelScreen(
            placeTitle: 'Livraria Lello',
            media: _portoMedia(),
            controllerFactory: (_) => playback,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byTooltip('Pausa'), findsOneWidget);

      playback.emitPlaying(false);
      await tester.pump();
      expect(find.byTooltip('Riprendi'), findsOneWidget);

      playback.emitError();
      await tester.pump();
      expect(
        find.byKey(const Key('place-reel-photo-fallback')),
        findsOneWidget,
      );
      expect(find.text('Video non disponibile'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      expect(playback.removeListenerCalls, 1);
    });

    testWidgets('does not autoplay or loop when animations are disabled', (
      tester,
    ) async {
      final playback = _FakePlanReelPlaybackController();
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: PlaceReelScreen(
              placeTitle: 'Livraria Lello',
              media: _portoMedia(),
              controllerFactory: (_) => playback,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(playback.playCalls, 0);
      expect(playback.looping, isFalse);
      expect(find.byTooltip('Riprendi'), findsOneWidget);
    });

    testWidgets('supports explicit close and Android system Back', (
      tester,
    ) async {
      final playback = _FakePlanReelPlaybackController();
      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: const Scaffold(body: Text('Piano sotto il reel')),
        ),
      );
      navigatorKey.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => PlaceReelScreen(
            placeTitle: 'Livraria Lello',
            media: _portoMedia(),
            controllerFactory: (_) => playback,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Piano sotto il reel'), findsOneWidget);

      navigatorKey.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => PlaceReelScreen(
            placeTitle: 'Livraria Lello',
            media: _portoMedia(),
            controllerFactory: (_) => _FakePlanReelPlaybackController(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Chiudi reel'));
      await tester.pumpAndSettle();
      expect(find.text('Piano sotto il reel'), findsOneWidget);
    });
  });

  group('Google Maps directions URI', () {
    test('builds only the canonical HTTPS directions URI', () {
      final uri = GoogleMapsDirectionsUri.build(
        latitude: 41.146905,
        longitude: -8.614732,
      );

      expect(
        uri.toString(),
        'https://www.google.com/maps/dir/?api=1&destination=41.146905%2C-8.614732',
      );
    });

    test('rejects non-finite and out-of-range coordinates', () {
      expect(
        GoogleMapsDirectionsUri.build(latitude: double.nan, longitude: 0),
        isNull,
      );
      expect(GoogleMapsDirectionsUri.build(latitude: 91, longitude: 0), isNull);
      expect(
        GoogleMapsDirectionsUri.build(latitude: 0, longitude: -181),
        isNull,
      );
    });
  });

  group('PlanExternalLauncher', () {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=41%2C-8',
    );

    test('returns true when the external application opens', () async {
      final launcher = PlanExternalLauncher(
        launchExternal: (_) async => true,
        launchBrowser: (_) async => false,
      );

      expect(await launcher.open(uri), isTrue);
    });

    test(
      'falls back to the browser and reports false when both decline',
      () async {
        var browserCalls = 0;
        final launcher = PlanExternalLauncher(
          launchExternal: (_) async => false,
          launchBrowser: (_) async {
            browserCalls++;
            return false;
          },
        );

        expect(await launcher.open(uri), isFalse);
        expect(browserCalls, 1);
      },
    );

    test('contains launcher exceptions without crashing', () async {
      final launcher = PlanExternalLauncher(
        launchExternal: (_) => Future<bool>.error(StateError('external')),
        launchBrowser: (_) => Future<bool>.error(StateError('browser')),
      );

      expect(await launcher.open(uri), isFalse);
    });

    test('canOpen rifiuta URL non HTTPS o host non allowlisted', () {
      final launcher = PlanExternalLauncher(
        launchExternal: (_) async => true,
        launchBrowser: (_) async => false,
      );

      expect(launcher.canOpen(null), isFalse);
      expect(launcher.canOpen(Uri.parse('http://www.flytap.com/')), isFalse);
      expect(launcher.canOpen(Uri.parse('https://evil.example.com/')), isFalse);
      expect(launcher.canOpen(Uri.parse('https://www.flytap.com/')), isTrue);
      expect(launcher.canOpen(Uri.parse('https://www.booking.com/')), isTrue);
    });

    test(
      'open rifiuta URL non HTTPS o host non allowlisted senza launch',
      () async {
        var launched = 0;
        final launcher = PlanExternalLauncher(
          launchExternal: (_) async {
            launched++;
            return true;
          },
          launchBrowser: (_) async => false,
        );

        expect(
          await launcher.open(Uri.parse('https://evil.example.com/')),
          isFalse,
        );
        expect(
          await launcher.open(Uri.parse('http://www.flytap.com/')),
          isFalse,
        );
        expect(launched, 0);
      },
    );
  });

  group('PlanCostSheet', () {
    test(
      'buildPlanCostSheetData espone sezioni, stati e totale proiettato',
      () {
        final fixture = ChatFirstDemoData.operationalFixtureFor('porto');
        final snapshot = fixture.snapshot.copyWith(
          travelSelection: TravelPlanSelection(
            option: const TravelOption(
              id: 'porto-flight-tap-direct',
              label: 'TAP Air Portugal · FCO–OPO',
              priceCents: 18900,
              purchaseState: PurchaseState.selected,
            ),
          ),
          staySelection: StayPlanSelection(
            option: const StayOption(
              id: 'porto-hotel-torel-avantgarde',
              label: 'Torel Avantgarde',
              priceCents: 48200,
              purchaseState: PurchaseState.purchased,
            ),
          ),
        );
        final launcher = PlanExternalLauncher(
          launchExternal: (_) async => true,
          launchBrowser: (_) async => false,
        );

        final data = buildPlanCostSheetData(snapshot, launcher);
        expect(data.sections, hasLength(3));
        expect(data.sections[0].title, 'Da acquistare');
        final purchaseRows = data.sections[0].rows;
        expect(purchaseRows, hasLength(2));
        final travelRow = purchaseRows.first;
        expect(travelRow.label, 'TAP Air Portugal · FCO–OPO');
        expect(travelRow.priceCents, 18900);
        expect(travelRow.state, PurchaseState.selected);
        expect(travelRow.purchaseUri, Uri.parse('https://www.flytap.com/'));
        expect(travelRow.actionEnabled, isTrue);
        expect(travelRow.hasAction, isTrue);

        final stayRow = purchaseRows.last;
        expect(stayRow.state, PurchaseState.purchased);
        expect(stayRow.purchaseUri, Uri.parse('https://www.booking.com/'));
        expect(stayRow.hasAction, isTrue);

        expect(data.sections[1].title, 'Stime non acquistate');
        final estimateRows = data.sections[1].rows;
        expect(estimateRows, hasLength(3));
        expect(estimateRows.first.label, 'Ingressi');
        expect(estimateRows.first.subtitle, '2 × 18 €');
        expect(estimateRows.first.state, PurchaseState.estimate);
        expect(estimateRows.first.hasAction, isFalse);

        final totals = data.sections[2].rows;
        expect(data.sections[2].title, 'Totali');
        expect(totals, hasLength(3));
        expect(totals[0].label, 'Da acquistare fuori da Iter');
        expect(totals[0].priceCents, 67100);
        expect(totals[1].label, 'Stime sul posto');
        expect(totals[1].priceCents, 12600);
        expect(totals[2].label, 'Totale previsto');
        expect(totals[2].priceCents, 79700);
        expect(totals[2].emphasized, isTrue);
      },
    );

    test(
      'azioni esterne disabilitate per URL non HTTPS o host non allowlisted',
      () {
        final fixture = ChatFirstDemoData.operationalFixtureFor('porto');
        final snapshot = fixture.snapshot.copyWith(
          travelSelection: TravelPlanSelection(
            option: TravelOption(
              id: 'porto-flight-tap-direct',
              label: 'TAP Air Portugal · FCO–OPO',
              priceCents: 18900,
            ),
          ),
        );
        final launcher = PlanExternalLauncher(
          launchExternal: (_) async => true,
          launchBrowser: (_) async => false,
        );

        final data = buildPlanCostSheetData(snapshot, launcher);
        // Allowlisted HTTPS from the fixture stays enabled...
        expect(data.sections[0].rows.first.actionEnabled, isTrue);
        // ...while a hostile host or a plain-http link is refused.
        expect(
          launcher.canOpen(Uri.parse('https://not-a-provider.it/')),
          isFalse,
        );
        expect(launcher.canOpen(Uri.parse('http://www.flytap.com/')), isFalse);
      },
    );

    test('sheet non selezionato mostra stima senza azione esterna', () {
      final fixture = ChatFirstDemoData.operationalFixtureFor('porto');
      final launcher = PlanExternalLauncher(
        launchExternal: (_) async => true,
        launchBrowser: (_) async => false,
      );

      final data = buildPlanCostSheetData(fixture.snapshot, launcher);
      final travelRow = data.sections[0].rows.first;
      expect(travelRow.state, PurchaseState.estimate);
      expect(travelRow.purchaseUri, isNull);
      expect(travelRow.actionEnabled, isFalse);
      expect(travelRow.hasAction, isFalse);
    });

    testWidgets('apre Costi e mostra sezioni, prezzi, stati e totale', (
      tester,
    ) async {
      final controller = _controllerFor(
        ChatFirstDemoData.operationalFixtureFor('porto').snapshot,
      );
      addTearDown(controller.dispose);
      controller.selectTravelOption(
        conversationId: _conversationId,
        optionId: 'porto-flight-tap-direct',
      );
      controller.selectStayOption(
        conversationId: _conversationId,
        optionId: 'porto-hotel-torel-avantgarde',
      );
      await _pumpPlan(tester, controller: controller);

      await tester.tap(find.text('Costi'));
      await tester.pumpAndSettle();

      expect(find.text('Costi del piano'), findsOneWidget);
      expect(find.text('Da acquistare'), findsOneWidget);
      expect(find.text('Stime non acquistate'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Trasporto locale'),
        120,
        scrollable: _scrollableInside(const Key('plan-cost-sheet-scroll')),
      );
      expect(find.text('189 €'), findsWidgets);
      expect(find.text('482 €'), findsOneWidget);
      expect(find.text('selezionato'), findsNWidgets(2));
      expect(find.text('36 €'), findsOneWidget);
      expect(find.text('75 €'), findsOneWidget);
      expect(find.text('15 €'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Totale previsto'),
        120,
        scrollable: _scrollableInside(const Key('plan-cost-sheet-scroll')),
      );
      expect(find.text('Totali'), findsOneWidget);
      expect(find.text('Da acquistare fuori da Iter'), findsOneWidget);
      expect(find.text('Stime sul posto'), findsOneWidget);
      expect(find.text('126 €'), findsOneWidget);
      expect(find.text('Totale previsto'), findsOneWidget);
      expect(find.text('797 €'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text(
          'Dati demo · prezzi e disponibilità non sono in tempo reale.',
        ),
        120,
        scrollable: _scrollableInside(const Key('plan-cost-sheet-scroll')),
      );
      expect(
        find.text(
          'Dati demo · prezzi e disponibilità non sono in tempo reale.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('conferma acquisti demo richiede un passaggio esplicito', (
      tester,
    ) async {
      final controller = _controllerFor(
        ChatFirstDemoData.operationalFixtureFor('porto').snapshot,
      );
      addTearDown(controller.dispose);
      await _pumpPlan(tester, controller: controller);

      await tester.tap(find.text('Costi'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('plan-cost-confirm-demo')),
        160,
        scrollable: _scrollableInside(const Key('plan-cost-sheet-scroll')),
      );
      expect(find.text('Conferma acquisti demo'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Demo: nessun pagamento reale'),
        120,
        scrollable: _scrollableInside(const Key('plan-cost-sheet-scroll')),
      );
      expect(find.text('Demo: nessun pagamento reale'), findsOneWidget);

      await tester.tap(find.byKey(const Key('plan-cost-confirm-demo')));
      await tester.pumpAndSettle();
      expect(find.text('Conferma le scelte del piano?'), findsOneWidget);
      expect(find.text('Demo: nessun pagamento reale'), findsNWidgets(2));

      await tester.tap(find.byKey(const Key('plan-cost-confirm-dialog')));
      await tester.pumpAndSettle();
      expect(find.text('Scelte confermate'), findsOneWidget);
      expect(controller.mockPurchasesConfirmed(_conversationId), isTrue);
      expect(
        controller
            .conversationOf(_conversationId)
            .snapshot!
            .revisionMetadata!
            .label,
        'Conferma acquisti demo',
      );
    });

    testWidgets(
      'un piano senza volo o hotel non mostra una conferma inattiva',
      (tester) async {
        final controller = ChatFirstPrototypeController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: TripSnapshotScreen(
              controller: controller,
              conversationId: 'c-roma-active',
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Costi'));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('plan-cost-confirm-demo')), findsNothing);
        expect(find.text('Nessuna scelta demo da confermare'), findsOneWidget);
      },
    );

    testWidgets(
      'apre l acquirente dal foglio e marca acquisto aperto senza prompt',
      (tester) async {
        final controller = _controllerFor(
          ChatFirstDemoData.operationalFixtureFor('porto').snapshot,
        );
        addTearDown(controller.dispose);
        controller.selectTravelOption(
          conversationId: _conversationId,
          optionId: 'porto-flight-tap-direct',
        );
        controller.selectStayOption(
          conversationId: _conversationId,
          optionId: 'porto-hotel-torel-avantgarde',
        );
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.binding.setSurfaceSize(const Size(390, 844));
        final launcher = PlanExternalLauncher(
          launchExternal: (_) async => true,
          launchBrowser: (_) async => false,
        );
        await tester.pumpWidget(
          MaterialApp(
            home: TripSnapshotScreen(
              controller: controller,
              conversationId: _conversationId,
              externalLauncher: launcher,
            ),
          ),
        );
        await tester.pump();
        await tester.tap(find.text('Costi'));
        await tester.pumpAndSettle();

        // Both rows carry an enabled external action with announcement.
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Semantics &&
                widget.properties.label ==
                    'Si apre la pagina di TAP Air Portugal',
          ),
          findsOneWidget,
        );
        expect(find.text('Apri nel sito'), findsNWidgets(2));

        await tester.tap(find.text('Apri nel sito').first);
        await tester.pumpAndSettle();

        expect(
          controller
              .conversationOf(_conversationId)
              .snapshot!
              .travelSelection!
              .option
              .purchaseState,
          PurchaseState.purchaseOpened,
        );
        expect(find.text('acquisto aperto'), findsOneWidget);
        // No return prompt until the app actually resumes.
        expect(controller.pendingPurchasePrompts, isEmpty);
      },
    );

    testWidgets('righe con link rifiutato restano inerti', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlanCostSheet(
              sections: const <PlanCostSectionData>[
                PlanCostSectionData(
                  title: 'Da acquistare',
                  subtitle: 'Demo',
                  rows: <PlanCostRowData>[
                    PlanCostRowData(
                      kind: ExternalPurchaseKind.travel,
                      optionId: 'http-link',
                      label: 'Provider non sicuro',
                      priceCents: 100,
                      state: PurchaseState.selected,
                      purchaseUri: null,
                      actionEnabled: false,
                      hasAction: true,
                    ),
                    PlanCostRowData(
                      kind: ExternalPurchaseKind.travel,
                      optionId: 'host-link',
                      label: 'Host sconosciuto',
                      priceCents: 200,
                      state: PurchaseState.selected,
                      purchaseUri: null,
                      actionEnabled: false,
                      hasAction: true,
                    ),
                    PlanCostRowData(
                      kind: ExternalPurchaseKind.travel,
                      optionId: 'ok-link',
                      label: 'Provider demo',
                      priceCents: 300,
                      state: PurchaseState.selected,
                      purchaseUri: null,
                      actionEnabled: true,
                      hasAction: true,
                    ),
                  ],
                ),
                PlanCostSectionData(
                  title: 'Totali',
                  subtitle: '',
                  rows: <PlanCostRowData>[
                    PlanCostRowData(
                      label: 'Totale previsto',
                      priceCents: 600,
                      state: PurchaseState.estimate,
                      showState: false,
                      emphasized: true,
                    ),
                  ],
                ),
              ],
              onOpenPurchase: (_) async {},
            ),
          ),
        ),
      );
      await tester.pump();

      final disabledButtons = find.byWidgetPredicate(
        (widget) => widget is OutlinedButton && widget.onPressed == null,
      );
      expect(disabledButtons, findsNWidgets(2));
      final enabledButtons = find.byWidgetPredicate(
        (widget) => widget is FilledButton && widget.onPressed != null,
      );
      expect(enabledButtons, findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label ==
                  'Acquisto non disponibile per Provider non sicuro',
        ),
        findsOneWidget,
      );
      expect(find.text('Totale previsto'), findsOneWidget);
      expect(find.text('6 €'), findsOneWidget);
    });
  });

  group('Matrice e stress', () {
    testWidgets(
      'piano vuoto: nessun crash o divisione per zero, messaggio chiaro in tutta la matrice',
      (tester) async {
        addTearDown(() => tester.binding.setSurfaceSize(null));
        for (final width in <double>[320, 360, 390]) {
          for (final brightness in <Brightness>[
            Brightness.light,
            Brightness.dark,
          ]) {
            final controller = _controllerFor(_emptySnapshot());
            addTearDown(controller.dispose);
            final size = Size(width, 760);
            await tester.binding.setSurfaceSize(size);
            await tester.pumpWidget(
              _matrixApp(
                key: ValueKey<String>('empty-$width-${brightness.name}'),
                size: size,
                brightness: brightness,
                child: TripSnapshotScreen(
                  controller: controller,
                  conversationId: _conversationId,
                ),
              ),
            );
            await tester.pump();
            expect(tester.takeException(), isNull);
            expect(find.text('Da sistemare'), findsOneWidget);
            expect(
              find.text(
                'Qui compariranno le tappe ancora senza giorno o orario.',
              ),
              findsOneWidget,
            );

            // Foglio costi su piano senza scelte: stime coerenti, nessun crash.
            await tester.tap(find.text('Costi'));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            expect(find.text('Costi del piano'), findsOneWidget);
            expect(
              find.text('Da scegliere · TAP Air Portugal'),
              findsOneWidget,
            );
            // La terza sezione (Totali) è sotto la piega a 320/1.5: scorri
            // prima di assertare la riga totale.
            await tester.scrollUntilVisible(
              find.text('Totale previsto'),
              120,
              scrollable: _scrollableInside(
                const Key('plan-cost-sheet-scroll'),
              ),
            );
            expect(find.text('Totale previsto'), findsOneWidget);
            // Su un piano senza scelte le stime sul posto (126 €) coincidono
            // con il totale previsto (126 €): entrambe le righe lo mostrano.
            expect(find.text('126 €'), findsNWidgets(2));
            await tester.binding.handlePopRoute();
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            expect(find.byKey(const Key('plan-scroll')), findsOneWidget);

            // Picker su piano senza giorni: la scelta finisce in Da sistemare.
            await tester.tap(find.text('Aggiungi luogo'));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            expect(
              find.byKey(const Key('place-picker-search')),
              findsOneWidget,
            );
            await tester.tap(
              find.byKey(const Key('place-picker-result-porto-ribeira')),
            );
            await tester.pump();
            expect(tester.takeException(), isNull);
            await tester.scrollUntilVisible(
              find.text('Scegli luogo'),
              180,
              scrollable: _scrollableInside(
                const Key('place-picker-detail-scroll'),
              ),
            );
            await tester.tap(find.text('Scegli luogo'));
            await tester.pump();
            expect(tester.takeException(), isNull);
            final reviewChange = find.text('Rivedi modifica');
            await tester.scrollUntilVisible(
              reviewChange,
              180,
              scrollable: _scrollableInside(
                const Key('place-picker-placement-scroll'),
              ),
            );
            await tester.drag(
              _scrollableInside(const Key('place-picker-placement-scroll')),
              const Offset(0, -80),
            );
            await tester.pump();
            expect(tester.takeException(), isNull);
            expect(reviewChange.hitTestable(), findsOneWidget);
            await tester.tap(reviewChange);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            expect(find.byKey(const Key('plan-patch-sheet')), findsOneWidget);
            expect(find.textContaining('va in Da sistemare'), findsOneWidget);
            await tester.tap(find.byKey(const Key('plan-patch-cancel')));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
        }
      },
    );

    testWidgets(
      'matrice thread: moduli rich volo e hotel stabili a 320/360/390 in chiaro e scuro',
      (tester) async {
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final controller = ChatFirstPrototypeController();
        addTearDown(controller.dispose);
        final id = controller
            .startFromJourney(_guidedJourney('porto-guided-matrix'))
            .summary
            .id;

        Future<void> choose(String label) async {
          final current = controller.threadOf(id);
          final message = current.messages.lastWhere(
            (message) => message.choices.any((choice) => choice.label == label),
          );
          controller.choose(
            message.choices.firstWhere((choice) => choice.label == label),
            conversationId: id,
            messageId: message.id,
          );
        }

        for (final label in const <String>[
          '4–5 giorni, senza fretta',
          'Bilanciato: cultura e pause',
          'Centro, per spostarmi a piedi',
          'Treno o metro + passi',
          'Moderato: qualche tavola bella',
        ]) {
          await choose(label);
        }
        controller.acceptProposal(id, 'intake-proposal');
        for (final label in const <String>[
          'Salva',
          'Salva',
          'Irrinunciabile',
          'Passa',
          'Passa',
          'Passa',
        ]) {
          await choose(label);
        }
        await choose('Aereo diretto');

        final proposalsAfterFlow = controller
            .threadOf(id)
            .messages
            .where((message) => message.kind == ChatMessageKind.planProposal)
            .length;
        expect(proposalsAfterFlow, greaterThan(0));

        var cell = 0;
        for (final width in <double>[320, 360, 390]) {
          for (final brightness in <Brightness>[
            Brightness.light,
            Brightness.dark,
          ]) {
            cell += 1;
            final size = Size(width, 844);
            await tester.binding.setSurfaceSize(size);
            await tester.pumpWidget(
              _matrixApp(
                key: ValueKey<String>('thread-$width-${brightness.name}'),
                size: size,
                brightness: brightness,
                child: ChatFirstThreadScreen(
                  controller: controller,
                  conversationId: id,
                  onOpenSnapshot: (_) {},
                ),
              ),
            );
            await tester.pumpAndSettle();
            // La lista di chat si aggancia in fondo; la posizione dei moduli
            // rich varia col numero di proposte. Salto in cima e poi scendo,
            // così ogni cella esplora gli stessi moduli in modo deterministico.
            tester
                .state<ScrollableState>(find.byType(Scrollable).first)
                .position
                .jumpTo(0);
            await tester.pumpAndSettle();

            // Il pannello volo resta raggiungibile e senza overflow.
            await tester.scrollUntilVisible(
              find.text('TAP Air Portugal'),
              240,
              scrollable: find.byType(Scrollable).first,
              maxScrolls: 300,
            );
            expect(tester.takeException(), isNull);
            expect(find.text('Consigliato'), findsWidgets);

            await tester.scrollUntilVisible(
              find.text('Torel Avantgarde'),
              240,
              scrollable: find.byType(Scrollable).first,
              maxScrolls: 300,
            );
            expect(find.text('Torel Avantgarde'), findsOneWidget);
            expect(find.byTooltip('Aggiungi notti'), findsOneWidget);
            expect(find.byTooltip('Riduci notti'), findsOneWidget);

            // Lo stepper notti genera una proposta confermabile in ogni cella.
            final addNights = find.byTooltip('Aggiungi notti');
            await tester.scrollUntilVisible(
              addNights,
              240,
              scrollable: find.byType(Scrollable).first,
              maxScrolls: 300,
            );
            await tester.pumpAndSettle();
            await tester.tap(addNights, warnIfMissed: false);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            expect(
              controller
                  .threadOf(id)
                  .messages
                  .where(
                    (message) => message.kind == ChatMessageKind.planProposal,
                  )
                  .length,
              proposalsAfterFlow + cell,
            );
          }
        }
      },
    );

    testWidgets(
      'stress: 7 giorni e 10 tappe per giorno rendono e scrollano senza overflow',
      (tester) async {
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final cells = <(double, Brightness)>[
          (320, Brightness.dark),
          (360, Brightness.light),
          (390, Brightness.light),
        ];
        for (final (width, brightness) in cells) {
          final controller = _controllerFor(_stressSnapshot());
          addTearDown(controller.dispose);
          final size = Size(width, 760);
          await tester.binding.setSurfaceSize(size);
          final semantics = tester.ensureSemantics();
          await tester.pumpWidget(
            _matrixApp(
              key: ValueKey<double>(width),
              size: size,
              brightness: brightness,
              child: TripSnapshotScreen(
                controller: controller,
                conversationId: _conversationId,
              ),
            ),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
          expect(
            controller.conversationOf(_conversationId).snapshot!.days,
            hasLength(7),
          );
          expect(find.text('Giorno 1'), findsOneWidget);
          expect(
            find.bySemanticsLabel(
              'Giorno 1, Tema lungo della giornata 1 con molti spostamenti',
            ),
            findsOneWidget,
          );

          // Chips orizzontali: raggiungi e seleziona l'ultimo dei 7 giorni.
          await tester.scrollUntilVisible(
            find.text('Giorno 7'),
            150,
            scrollable: find
                .descendant(
                  of: find.byKey(const Key('plan-scroll')),
                  matching: find.byType(Scrollable),
                )
                .at(1),
          );
          // La chip può risultare costruita ma fuori dal clip visibile:
          // allineala prima del tap per renderla tappabile.
          final giorno7 = find.text('Giorno 7');
          await tester.ensureVisible(giorno7);
          await tester.pump();
          expect(tester.takeException(), isNull);
          await tester.tap(giorno7);
          await tester.pump();
          expect(
            find.bySemanticsLabel(
              'Giorno 7, Tema lungo della giornata 7 con molti spostamenti',
            ),
            findsOneWidget,
          );

          // Le 10 tappe del giorno 7 scorrono fino in fondo. Il giorno
          // selezionato costruisce eager le proprie tappe (Column), quindi la
          // verifica è lo scroll fino all'ultima tappa, non l'assenza.
          final lastStop = find.byKey(
            const Key('plan-item-stress-day-7-item-10'),
          );
          await tester.scrollUntilVisible(
            lastStop,
            300,
            scrollable: _scrollableInside(const Key('plan-scroll')),
          );
          expect(tester.takeException(), isNull);
          expect(lastStop, findsOneWidget);

          final scroll = tester.state<ScrollableState>(
            _scrollableInside(const Key('plan-scroll')),
          );
          scroll.position.jumpTo(scroll.position.maxScrollExtent);
          await tester.pump();
          expect(tester.takeException(), isNull);
          semantics.dispose();
        }
      },
    );

    testWidgets(
      'label italiane lunghe: nessun overflow nel piano, pannello e costi',
      (tester) async {
        addTearDown(() => tester.binding.setSurfaceSize(null));
        for (final width in <double>[320, 360, 390]) {
          for (final brightness in <Brightness>[
            Brightness.light,
            Brightness.dark,
          ]) {
            final controller = _controllerFor(_longLabelsSnapshot());
            addTearDown(controller.dispose);
            final size = Size(width, 760);
            await tester.binding.setSurfaceSize(size);
            await tester.pumpWidget(
              _matrixApp(
                key: ValueKey<String>('long-$width-${brightness.name}'),
                size: size,
                brightness: brightness,
                child: TripSnapshotScreen(
                  controller: controller,
                  conversationId: _conversationId,
                ),
              ),
            );
            await tester.pump();
            expect(tester.takeException(), isNull);
            expect(
              find.text(
                '2 notti in un appartamento con veranda sul quartiere storico',
              ),
              findsOneWidget,
            );
            // A 320/1.5 la timeline con i testi 'Douro' sta sotto la piega:
            // costruiscila scorrendo prima delle verifiche.
            await tester.scrollUntilVisible(
              find.byKey(const Key('plan-item-long-item-1')),
              240,
              scrollable: _scrollableInside(const Key('plan-scroll')),
            );
            expect(find.textContaining('Douro'), findsWidgets);

            // Titolo lungo nella timeline → pannello luogo esteso senza overflow.
            final firstStop = find.byKey(const Key('plan-item-long-item-1'));
            await tester.ensureVisible(firstStop);
            await tester.pump();
            await tester.tap(firstStop);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            expect(find.byType(DraggableScrollableSheet), findsOneWidget);
            await tester.scrollUntilVisible(
              find.textContaining('una sosta per la merenda'),
              160,
              scrollable: _scrollableInside(const Key('place-sheet-scroll')),
            );
            expect(tester.takeException(), isNull);
            Navigator.of(
              tester.element(find.byType(DraggableScrollableSheet)),
            ).pop();
            await tester.pumpAndSettle();

            // Costi con label lunga e stato acquistato leggibile.
            await tester.tap(find.text('Costi'));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            expect(
              find.textContaining(
                'appartamento con veranda sul quartiere storico',
              ),
              findsOneWidget,
            );
            expect(find.text('acquistato'), findsOneWidget);
            expect(find.text('189 €'), findsOneWidget);
            await tester.binding.handlePopRoute();
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
        }
      },
    );

    testWidgets(
      'semantica: timeline, azioni piano e foglio costi espongono label e stati',
      (tester) async {
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.binding.setSurfaceSize(const Size(390, 844));
        final controller = _controllerFor(
          ChatFirstDemoData.operationalFixtureFor('porto').snapshot,
        );
        addTearDown(controller.dispose);
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(
          MaterialApp(
            theme: IterTheme.light(),
            home: TripSnapshotScreen(
              controller: controller,
              conversationId: _conversationId,
            ),
          ),
        );
        await tester.pump();

        expect(find.bySemanticsLabel('Piano di Porto'), findsOneWidget);
        expect(
          find.bySemanticsLabel('Giorno 1, Libri e centro storico'),
          findsOneWidget,
        );
        expect(
          find.byTooltip('Altre azioni per Livraria Lello'),
          findsOneWidget,
        );
        expect(find.bySemanticsLabel('Aggiungi luogo'), findsOneWidget);
        expect(find.bySemanticsLabel('Chiedi'), findsOneWidget);
        expect(find.bySemanticsLabel('Costi'), findsOneWidget);
        expect(
          tester.semantics.simulatedAccessibilityTraversal(),
          containsAllInOrder(<Matcher>[
            isSemantics(label: 'Foto di Porto'),
            isSemantics(label: 'Giorno 1, Libri e centro storico'),
            isSemantics(label: 'Aggiungi luogo'),
          ]),
        );
        semantics.dispose();

        controller.selectTravelOption(
          conversationId: _conversationId,
          optionId: 'porto-flight-tap-direct',
        );
        controller.selectStayOption(
          conversationId: _conversationId,
          optionId: 'porto-hotel-torel-avantgarde',
        );
        await tester.tap(find.text('Costi'));
        await tester.pumpAndSettle();
        final costSemantics = tester.ensureSemantics();
        expect(find.bySemanticsLabel('Costi del piano'), findsOneWidget);
        expect(find.text('selezionato'), findsNWidgets(2));
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Semantics &&
                widget.properties.label ==
                    'Si apre la pagina di TAP Air Portugal',
          ),
          findsOneWidget,
        );
        costSemantics.dispose();
      },
    );

    testWidgets(
      'semantica home: card Prossima scelta e timeline di oggi con conteggio tappe',
      (tester) async {
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.binding.setSurfaceSize(const Size(390, 844));
        final controller = ChatFirstPrototypeController();
        addTearDown(controller.dispose);
        final planning = controller.threads.firstWhere(
          (thread) =>
              thread.summary.snapshot?.statusLabel == 'In pianificazione',
        );
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(
          MaterialApp(
            theme: IterTheme.light(),
            home: Scaffold(
              body: ChatFirstHomeScreen(
                model: AdaptiveHomeModel.planning(thread: planning),
                unread: 0,
                onSubmitIntent: (_) {},
                onVoiceIntent: () {},
                onPhotoIntent: (_) {},
                onOpenThread: (_) {},
                onOpenTrips: () {},
                onStartAnotherJourney: () async {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Prossima scelta'), findsOneWidget);
        expect(find.bySemanticsLabel('Continua il viaggio'), findsOneWidget);
        expect(
          find.bySemanticsLabel('Inizia un altro viaggio'),
          findsOneWidget,
        );
        semantics.dispose();

        final active = controller.threads.firstWhere(
          (thread) => thread.summary.snapshot?.statusLabel == 'In viaggio',
        );
        final activeSemantics = tester.ensureSemantics();
        await tester.pumpWidget(
          MaterialApp(
            theme: IterTheme.light(),
            home: Scaffold(
              body: ChatFirstHomeScreen(
                model: AdaptiveHomeModel.active(thread: active),
                unread: 0,
                onSubmitIntent: (_) {},
                onVoiceIntent: () {},
                onPhotoIntent: (_) {},
                onOpenThread: (_) {},
                onOpenTrips: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.bySemanticsLabel(
            'Timeline di oggi, '
            '${active.summary.snapshot!.days.first.items.length} tappe',
          ),
          findsOneWidget,
        );
        expect(find.bySemanticsLabel('Tappa flessibile'), findsWidgets);
        activeSemantics.dispose();
      },
    );

    testWidgets('semantica e back sul dialog del ritorno acquisto', (
      tester,
    ) async {
      final controller = ChatFirstPrototypeController();
      addTearDown(controller.dispose);
      final fixture = ChatFirstDemoData.operationalFixtureFor('porto');
      final launcher = PlanExternalLauncher(
        launchExternal: (_) async => true,
        launchBrowser: (_) async => false,
      );
      final id = controller.threads
          .firstWhere(
            (thread) =>
                thread.summary.snapshot?.statusLabel == 'In pianificazione',
          )
          .summary
          .id;
      controller.selectTravelOption(
        conversationId: id,
        optionId: fixture.flights.first.id,
      );
      expect(
        await controller.openExternalPurchase(
          conversationId: id,
          kind: ExternalPurchaseKind.travel,
          optionId: fixture.flights.first.id,
          uri: fixture.flights.first.providerUrl,
          launcher: launcher,
        ),
        isTrue,
      );

      await tester.pumpWidget(ChatFirstPrototypeApp(controller: controller));
      await tester.pumpAndSettle();
      expect(find.text('Sei tornato dal sito di prenotazione.'), findsNothing);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      final semantics = tester.ensureSemantics();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.bySemanticsLabel('Sei tornato dal sito di prenotazione.'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Sì, aggiorna'), findsOneWidget);
      expect(find.bySemanticsLabel('Non ancora'), findsOneWidget);
      semantics.dispose();

      // Back chiude il dialog e non l'app.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets(
      'riduzione movimento: timeline e anteprima restano interattive, usabile e senza eccezioni',
      (tester) async {
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.binding.setSurfaceSize(const Size(390, 844));
        final controller = _controllerFor(
          ChatFirstDemoData.operationalFixtureFor('porto').snapshot,
        );
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: child!,
            ),
            home: TripSnapshotScreen(
              controller: controller,
              conversationId: _conversationId,
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('plan-timeline')), findsOneWidget);

        final menu = find.byKey(
          const Key('plan-menu-porto-livraria-lello-stop'),
        );
        await tester.ensureVisible(menu);
        await tester.pump();
        await tester.tap(menu);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Rimuovi'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('plan-patch-sheet')), findsOneWidget);
        await tester.tap(find.byKey(const Key('plan-patch-cancel')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'back: chiude pannello luogo, anteprima modifica e foglio costi prima della route',
      (tester) async {
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.binding.setSurfaceSize(const Size(390, 844));
        final controller = _controllerFor(
          ChatFirstDemoData.operationalFixtureFor('porto').snapshot,
        );
        addTearDown(controller.dispose);
        final navigatorKey = GlobalKey<NavigatorState>();
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navigatorKey,
            theme: IterTheme.light(),
            home: const Scaffold(body: Text('Radice')),
          ),
        );
        Future<void> pushPlan() async {
          navigatorKey.currentState!.push(
            MaterialPageRoute<void>(
              builder: (_) => TripSnapshotScreen(
                controller: controller,
                conversationId: _conversationId,
              ),
            ),
          );
          await tester.pumpAndSettle();
        }

        await pushPlan();
        // Pannello luogo: back chiude il pannello, non la route del piano.
        final stop = find.byKey(
          const Key('plan-item-porto-livraria-lello-stop'),
        );
        await tester.ensureVisible(stop);
        await tester.pump();
        await tester.tap(stop);
        await tester.pumpAndSettle();
        expect(find.byType(DraggableScrollableSheet), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(DraggableScrollableSheet), findsNothing);
        expect(find.byKey(const Key('plan-scroll')), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Anteprima di modifica: back chiude la patch sheet, non la route.
        final menu = find.byKey(
          const Key('plan-menu-porto-livraria-lello-stop'),
        );
        await tester.scrollUntilVisible(
          menu,
          220,
          scrollable: _scrollableInside(const Key('plan-scroll')),
        );
        await tester.tap(menu);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Rimuovi'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('plan-patch-sheet')), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('plan-patch-sheet')), findsNothing);
        expect(find.byKey(const Key('plan-scroll')), findsOneWidget);

        // Foglio costi: back chiude il foglio.
        await tester.tap(find.text('Costi'));
        await tester.pumpAndSettle();
        expect(find.text('Costi del piano'), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text('Costi del piano'), findsNothing);
        expect(find.byKey(const Key('plan-scroll')), findsOneWidget);

        // Solo il back esplicito esce dalla route del piano.
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text('Radice'), findsOneWidget);
      },
    );
  });
}

Future<void> _pumpPlan(
  WidgetTester tester, {
  required ChatFirstPrototypeController controller,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQueryData(
          size: const Size(390, 844),
          textScaler: textScaler,
        ),
        child: child!,
      ),
      home: TripSnapshotScreen(
        controller: controller,
        conversationId: _conversationId,
      ),
    ),
  );
  await tester.pump();
}

Future<void> _openTrasteverePicker(WidgetTester tester) async {
  await tester.tap(find.text('Aggiungi luogo'));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const Key('place-picker-search-field')),
    'Trastevere',
  );
  await tester.pump();
  await tester.tap(
    find.byKey(const Key('place-picker-result-roma-trastevere')),
  );
  await tester.pump();
  await tester.tap(find.text('Scegli luogo'));
  await tester.pump();
}

ChatFirstPrototypeController _controllerFor(TripSnapshot snapshot) {
  final thread = ChatThread(
    summary: Conversation(
      id: _conversationId,
      title: snapshot.destinationTitle,
      subtitle: snapshot.statusLabel,
      avatar: const ChatAvatar(
        'assets/images/travel/porto_livraria_lello.jpg',
        label: 'Porto',
      ),
      timestamp: DateTime.utc(2026, 8, 11),
      lastPreview: 'Piano operativo',
      snapshot: snapshot,
    ),
    script: const <ScriptedBeat>[],
  );
  return ChatFirstPrototypeController(seed: <ChatThread>[thread]);
}

TripSnapshot _emptySnapshot() => TripSnapshot(
  destinationTitle: 'Porto',
  country: 'Portogallo',
  durationLabel: '2 giorni',
  statusLabel: 'In pianificazione',
  dates: '17–18 ottobre 2026',
  transport: 'Da scegliere',
  stay: 'Da scegliere',
  destinationMedia: const PlanMedia(),
);

TripSnapshot _snapshotWithEmptyDay() => TripSnapshot(
  destinationTitle: 'Roma',
  country: 'Italia',
  durationLabel: '2 giorni',
  statusLabel: 'In viaggio',
  dates: '14–15 ottobre 2026',
  transport: 'A piedi',
  stay: 'Centro',
  days: <TripDaySnapshot>[
    TripDaySnapshot(
      id: 'source-day',
      label: 'Giorno pieno',
      theme: 'Centro',
      items: const <TripItemSnapshot>[
        TripItemSnapshot(
          id: 'source-stop',
          title: 'Foro Romano',
          category: 'Archeologia',
          startTime: '10:00',
          durationMinutes: 60,
          locked: false,
        ),
      ],
    ),
    TripDaySnapshot(
      id: 'empty-day',
      label: 'Giorno vuoto',
      theme: 'Da costruire',
    ),
  ],
);

TripSnapshot _unplacedOnlySnapshot() => TripSnapshot(
  destinationTitle: 'Roma',
  country: 'Italia',
  durationLabel: '1 giorno',
  statusLabel: 'In viaggio',
  dates: '14 ottobre 2026',
  transport: 'A piedi',
  stay: 'Centro',
  unplacedItems: const <TripItemSnapshot>[
    TripItemSnapshot(
      id: 'later-stop',
      title: 'Da decidere',
      category: 'Passeggiata',
      durationMinutes: 45,
      locked: false,
    ),
  ],
);

TripSnapshot _romaSnapshotWithUnplaced() {
  final snapshot = ChatFirstDemoData.operationalFixtureFor('roma').snapshot;
  return snapshot.copyWith(
    unplacedItems: const <TripItemSnapshot>[
      TripItemSnapshot(
        id: 'later-stop',
        title: 'Da decidere',
        category: 'Passeggiata',
        durationMinutes: 45,
        locked: false,
      ),
    ],
  );
}

TripSnapshot _purchasedRomaSnapshot() {
  final snapshot = ChatFirstDemoData.operationalFixtureFor('roma').snapshot;
  final day = snapshot.days.last;
  final item = day.items.single;
  return snapshot.copyWith(
    days: <TripDaySnapshot>[
      snapshot.days.first,
      TripDaySnapshot(
        id: day.id,
        date: day.date,
        label: day.label,
        theme: day.theme,
        items: <TripItemSnapshot>[
          TripItemSnapshot.withPurchaseLinks(
            id: item.id,
            title: item.title,
            category: item.category,
            startTime: item.startTime,
            durationMinutes: item.durationMinutes,
            source: item.source,
            place: item.place,
            locked: item.locked,
            linkedPurchaseOptionIds: const <String>['roma-flight-purchased'],
          ),
        ],
      ),
    ],
    travelSelection: TravelPlanSelection(
      option: const TravelOption(
        id: 'roma-flight-purchased',
        label: 'Volo acquistato',
        purchaseState: PurchaseState.purchased,
      ),
    ),
  );
}

PlanMedia _portoMedia() =>
    ChatFirstDemoData.operationalFixtureFor('porto').media;

/// App di matrice: viewport [size], tema chiaro/scuro, testo 1.5 e
/// riduzione movimento attivi con gli stessi pattern dei test esistenti.
Widget _matrixApp({
  required Key key,
  required Size size,
  required Brightness brightness,
  TextScaler textScaler = const TextScaler.linear(1.5),
  bool disableAnimations = true,
  required Widget child,
}) => MaterialApp(
  key: key,
  theme: ThemeData(brightness: brightness, useMaterial3: true),
  builder: (context, child) => MediaQuery(
    data: MediaQueryData(
      size: size,
      textScaler: textScaler,
      disableAnimations: disableAnimations,
    ),
    child: child!,
  ),
  home: child,
);

/// Porto guidato con id unico: evita la collisione con il thread seed
/// 'porto-slow' e attraversa intake/F5 fino ai moduli rich (volo e hotel).
JourneyRoute _guidedJourney(String id) {
  final seeded = MockData.journeyById('porto-slow');
  return JourneyRoute(
    id: id,
    title: seeded.title,
    summary: seeded.summary,
    durationLabel: seeded.durationLabel,
    stops: const <String>['Porto'],
    destinationIds: const <String>['porto'],
    whyItFits: seeded.whyItFits,
    season: seeded.season,
    travelMode: seeded.travelMode,
    videoAssets: seeded.videoAssets,
    matchScore: seeded.matchScore,
  );
}

/// Fixture stress: 7 giorni × 10 tappe con id univoci e titoli lunghi.
TripSnapshot _stressSnapshot() => TripSnapshot(
  destinationTitle: 'Porto',
  country: 'Portogallo',
  durationLabel: '7 giorni',
  statusLabel: 'In pianificazione',
  dates: '17–23 ottobre 2026',
  transport: 'Volo da Roma',
  stay: 'Cedofeita',
  days: <TripDaySnapshot>[
    for (var day = 1; day <= 7; day++)
      TripDaySnapshot(
        id: 'stress-day-$day',
        label: 'Giorno $day',
        theme: 'Tema lungo della giornata $day con molti spostamenti',
        items: <TripItemSnapshot>[
          for (var item = 1; item <= 10; item++)
            TripItemSnapshot(
              id: 'stress-day-$day-item-$item',
              title:
                  'Tappa $day.$item — Passeggiata lunga con soste nel quartiere',
              category: 'Attività',
              startTime: '${(8 + item ~/ 2).toString().padLeft(2, '0')}:00',
              durationMinutes: 15 + item * 10,
              locked: item == 1,
            ),
        ],
      ),
  ],
);

/// Fixture con label italiane lunghe: titolo, categoria, date, trasporto,
/// soggiorno e opzione acquistata con testo esteso (Spec §10 testo lungo).
TripSnapshot _longLabelsSnapshot() => TripSnapshot(
  destinationTitle: 'Porto',
  country: 'Portogallo',
  durationLabel: '2 giorni con rientro in serata',
  statusLabel: 'In pianificazione',
  dates:
      '17–18 ottobre 2026 con rientro la sera del secondo giorno e cena libera',
  transport: 'Volo diretto con orario mattutino e bagaglio a mano incluso',
  stay: '2 notti in un appartamento con veranda sul quartiere storico',
  days: <TripDaySnapshot>[
    TripDaySnapshot(
      id: 'long-day-1',
      label: 'Giorno 1',
      theme:
          'Passeggiata pomeridiana lungo il fiume Douro con sosta della merenda a metà strada',
      items: <TripItemSnapshot>[
        TripItemSnapshot(
          id: 'long-item-1',
          title:
              'Passeggiata pomeridiana lungo il fiume Douro con sosta della merenda',
          category: 'Musei di arte contemporanea e fotografia sperimentale',
          startTime: '14:30',
          durationMinutes: 150,
          locked: false,
          place: PlanPlaceDetails(
            id: 'long-place-1',
            title:
                'Passeggiata pomeridiana lungo il fiume Douro con sosta della merenda',
            description:
                'Un giro lento che unisce le rive del fiume, le terrazze del lungomare e una sosta per la merenda prima di rientrare.',
          ),
        ),
        TripItemSnapshot(
          id: 'long-item-2',
          title: 'Torre dos Clérigos',
          category: 'Panorama',
          startTime: '18:00',
          durationMinutes: 45,
          locked: false,
        ),
      ],
    ),
  ],
  travelSelection: TravelPlanSelection(
    option: TravelOption(
      id: 'long-flight',
      label: '2 notti in un appartamento con veranda sul quartiere storico',
      priceCents: 18900,
      purchaseState: PurchaseState.purchased,
    ),
  ),
);

Finder _scrollableInside(Key key) => find
    .descendant(of: find.byKey(key), matching: find.byType(Scrollable))
    .first;

class _FakePlanReelPlaybackController extends PlanReelPlaybackController {
  _FakePlanReelPlaybackController({this.failInitialization = false});

  final bool failInitialization;
  bool _initialized = false;
  bool _playing = false;
  bool _muted = true;
  bool _hasError = false;
  bool looping = false;
  int playCalls = 0;
  int removeListenerCalls = 0;

  @override
  bool get hasError => failInitialization || _hasError;

  @override
  bool get isInitialized => _initialized;

  @override
  bool get isMuted => _muted;

  @override
  bool get isPlaying => _playing;

  @override
  Widget buildVideo(BuildContext context) =>
      const ColoredBox(key: Key('fake-reel-video'), color: Colors.black);

  @override
  Future<void> initialize() async {
    if (failInitialization) throw StateError('decode');
    _initialized = true;
    notifyListeners();
  }

  @override
  Future<void> pause() async {
    _playing = false;
    notifyListeners();
  }

  @override
  Future<void> play() async {
    playCalls++;
    _playing = true;
    notifyListeners();
  }

  @override
  Future<void> setLooping(bool value) async {
    looping = value;
  }

  @override
  Future<void> setMuted(bool value) async {
    _muted = value;
    notifyListeners();
  }

  void emitPlaying(bool value) {
    _playing = value;
    notifyListeners();
  }

  void emitError() {
    _hasError = true;
    notifyListeners();
  }

  @override
  void removeListener(VoidCallback listener) {
    removeListenerCalls++;
    super.removeListener(listener);
  }
}
