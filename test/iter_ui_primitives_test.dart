import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:iter/app/iter_theme.dart';
import 'package:iter/features/chat_first_prototype/iter_ui_primitives.dart';

void main() {
  testWidgets('page frame caps wide content without shrinking phone content', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: IterTheme.light(),
        home: SizedBox(
          width: 1200,
          height: 700,
          child: IterPageFrame(child: const Text('Route content')),
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(const Key('iter-page-frame'))).width,
      lessThanOrEqualTo(760),
    );
    expect(find.text('Route content'), findsOneWidget);
  });

  testWidgets('shared primitives expose the route hierarchy and semantics', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: IterTheme.light(),
        home: Scaffold(
          body: Column(
            children: <Widget>[
              const IterSectionHeading(
                eyebrow: 'Oggi',
                title: 'Roma',
                key: Key('home-heading'),
              ),
              IterMaterialSurface(
                key: const Key('floating-surface'),
                translucent: true,
                child: const Text('Composer'),
              ),
              const IterRouteDivider(active: true),
              const IterRouteDivider(active: false),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Oggi'), findsOneWidget);
    expect(find.text('Roma'), findsOneWidget);
    expect(find.text('Composer'), findsOneWidget);
    expect(find.byKey(const Key('iter-route-divider-active')), findsOneWidget);
    expect(find.byKey(const Key('iter-route-divider')), findsOneWidget);
    expect(find.bySemanticsLabel('Composer'), findsOneWidget);
  });
}
