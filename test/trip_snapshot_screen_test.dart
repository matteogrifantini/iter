import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:iter/features/chat_first_prototype/chat_first_controller.dart';
import 'package:iter/features/chat_first_prototype/chat_first_data.dart';
import 'package:iter/features/chat_first_prototype/chat_first_models.dart';
import 'package:iter/features/chat_first_prototype/chat_first_thread_screen.dart';
import 'package:iter/features/chat_first_prototype/place_reel_screen.dart';
import 'package:iter/features/chat_first_prototype/plan_editor.dart';
import 'package:iter/features/chat_first_prototype/plan_external_launcher.dart';
import 'package:iter/features/chat_first_prototype/trip_snapshot_screen.dart';

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
      'legacy snapshot adapter replaces and disposes owned controllers',
      (tester) async {
        final created = <_TrackingLegacyController>[];
        ChatFirstPrototypeController createController(TripSnapshot snapshot) {
          final controller = _TrackingLegacyController(snapshot);
          created.add(controller);
          return controller;
        }

        await tester.pumpWidget(
          MaterialApp(
            home: TripSnapshotScreen(
              key: const ValueKey<String>('legacy-plan'),
              snapshot: ChatFirstDemoData.operationalFixtureFor(
                'porto',
              ).snapshot,
              legacyControllerFactory: createController,
            ),
          ),
        );
        expect(created, hasLength(1));

        await tester.pumpWidget(
          MaterialApp(
            home: TripSnapshotScreen(
              key: const ValueKey<String>('legacy-plan'),
              snapshot: ChatFirstDemoData.operationalFixtureFor(
                'roma',
              ).snapshot,
              legacyControllerFactory: createController,
            ),
          ),
        );
        expect(created, hasLength(2));
        expect(created.first.disposeCalls, 1);
        expect(find.text('Roma'), findsWidgets);

        await tester.pumpWidget(const SizedBox.shrink());
        expect(created.last.disposeCalls, 1);
      },
    );

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

class _TrackingLegacyController extends ChatFirstPrototypeController {
  _TrackingLegacyController(TripSnapshot snapshot)
    : super(
        seed: <ChatThread>[
          ChatThread(
            summary: Conversation(
              id: 'legacy-plan-preview',
              title: snapshot.destinationTitle,
              subtitle: snapshot.statusLabel,
              avatar: const ChatAvatar('', label: 'Piano'),
              timestamp: DateTime.fromMillisecondsSinceEpoch(0),
              lastPreview: 'Anteprima Piano',
              snapshot: snapshot,
            ),
            script: const <ScriptedBeat>[],
          ),
        ],
      );

  int disposeCalls = 0;

  @override
  void dispose() {
    disposeCalls++;
    super.dispose();
  }
}
