# Apple Liquid Glass Contenuto-First Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Portare Iter allo stile Liquid Glass contenuto-first su tutta l'app senza rompere dati o flussi.

**Architecture:** Estendere `IterTheme` con token glass + creare `iter_glass_primitives.dart` sopra `IterMaterialSurface`, poi applicare a shell, home, chat, piano, costi, profilo con fallback opachi.

**Tech Stack:** Flutter Material 3, `BackdropFilter` / `ImageFilter.blur`, `flutter_test` widget tests, `flutter analyze`.

## Global Constraints

- Solo tab bar, composer, action bar piano e sheet usano blur. Mai vetro su vetro.
- Raggi: 24-28 card/sheet grandi, 20 pill controlli, 32 dock esistente invariato nella forma.
- `Rotta #2D63FF / #7EA0FF` solo azione primaria, `Segnale` solo decisioni, chrome in tinta neutra.
- Target 48dp, spacing 8dp, contrasto corpo 4.5:1, text scale 1.5, 320/360/390dp, dark/light, disableAnimations + reduceTransparency con fallback opaco.
- Motion 150-300ms ease-out, crossfade con moto ridotto, nessuna animazione infinita, nessun loading finto.
- Restano Bricolage Grotesque + Figtree, palette Rotta viva, navigazione Oggi/Viaggi/Tu, flussi preview→Applica→revisione→Annulla e `Demo: nessun pagamento reale`.
- Nessun cambio backend mock/Supabase, AI Gemini, prezzi live, GPS, Share Target, scraping.
- Verifica ogni task con `flutter analyze` e `flutter test`.

---

### Task 1: Token glass nel tema

**Files:**
- Modify: `lib/app/iter_theme.dart`
- Test: `test/glass_theme_test.dart`

**Interfaces:**
- Consumes: esistente `IterColorRoles` con canvas/raised/mutedInk/route/routeSignal/possibility/videoScrim.
- Produces: `IterGlassRoles` con `blurSigma double = 18.0`, `tintAlpha double = 0.84`, `borderAlpha double = 0.72`, `scrimAlpha double = 0.32`, `sheetRadius double = 28.0`, `cardRadius double = 24.0`, `pillRadius double = 20.0`; metodo `bool useBlur(BuildContext context)` che ritorna false con reduceTransparency.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iter/app/iter_theme.dart';

void main() {
  test('glass roles light e dark hanno blur e fallback', () {
    final light = IterTheme.light();
    final dark = IterTheme.dark();
    final lGlass = light.extension<IterGlassRoles>()!;
    final dGlass = dark.extension<IterGlassRoles>()!;
    expect(lGlass.blurSigma, 18.0);
    expect(dGlass.blurSigma, 18.0);
    expect(lGlass.sheetRadius, 28.0);
    expect(lGlass.cardRadius, 24.0);
    expect(lGlass.pillRadius, 20.0);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/glass_theme_test.dart`
Expected: FAIL with "Could not find IterGlassRoles" / extension null.

- [ ] **Step 3: Write minimal implementation**

```dart
@immutable
class IterGlassRoles extends ThemeExtension<IterGlassRoles> {
  const IterGlassRoles({
    this.blurSigma = 18.0,
    this.tintAlpha = 0.84,
    this.borderAlpha = 0.72,
    this.scrimAlpha = 0.32,
    this.sheetRadius = 28.0,
    this.cardRadius = 24.0,
    this.pillRadius = 20.0,
  });
  final double blurSigma;
  final double tintAlpha;
  final double borderAlpha;
  final double scrimAlpha;
  final double sheetRadius;
  final double cardRadius;
  final double pillRadius;

  static bool useBlur(BuildContext context) {
    return !MediaQuery.of(context).disableAnimations;
  }

  @override
  IterGlassRoles copyWith({double? blurSigma}) {
    return IterGlassRoles(blurSigma: blurSigma ?? this.blurSigma);
  }

  @override
  IterGlassRoles lerp(ThemeExtension<IterGlassRoles>? other, double t) {
    if (other is! IterGlassRoles) return this;
    return IterGlassRoles(
      blurSigma: blurSigma + (other.blurSigma - blurSigma) * t,
    );
  }
}
```

Aggiungere `IterGlassRoles(const IterGlassRoles())` in `extensions:` di `_build` in `lib/app/iter_theme.dart` sia light che dark.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/glass_theme_test.dart`
Expected: PASS. Poi `flutter analyze`.

- [ ] **Step 5: Commit**

```bash
git add lib/app/iter_theme.dart test/glass_theme_test.dart
git commit -m "feat(glass): add IterGlassRoles theme tokens"
```

### Task 2: Primitivi vetro condivisi

**Files:**
- Create: `lib/features/chat_first_prototype/iter_glass_primitives.dart`
- Modify: `lib/features/chat_first_prototype/iter_ui_primitives.dart:56-100`
- Test: `test/iter_glass_primitives_test.dart`

**Interfaces:**
- Consumes: `IterGlassRoles` da Task 1, `IterMaterialSurface(translucent, borderRadius, padding, child)`.
- Produces: `IterGlassBar({required child, padding})`, `IterGlassSheet({required child})`, `IterHeroScrim({required child})` — tutti `StatelessWidget` con `Key` opzionale, nessun colore raw.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iter/app/iter_theme.dart';
import 'package:iter/features/chat_first_prototype/iter_glass_primitives.dart';

void main() {
  testWidgets('IterGlassBar usa vetro con fallback opaco', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: IterTheme.light(),
        home: const Scaffold(body: IterGlassBar(child: Text('vetro'))),
      ),
    );
    expect(find.text('vetro'), findsOneWidget);
    expect(find.byKey(const Key('iter-glass-bar')), findsOneWidget);
  });

  testWidgets('IterGlassSheet ha raggio 28', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: IterTheme.light(),
        home: const Scaffold(body: IterGlassSheet(child: Text('sheet'))),
      ),
    );
    expect(find.byKey(const Key('iter-glass-sheet')), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/iter_glass_primitives_test.dart`
Expected: FAIL "Target of URI doesn't exist: iter_glass_primitives.dart".

- [ ] **Step 3: Write minimal implementation**

```dart
import 'package:flutter/material.dart';
import 'package:iter/app/iter_theme.dart';
import 'iter_ui_primitives.dart';

class IterGlassBar extends StatelessWidget {
  const IterGlassBar({super.key, required this.child, this.padding = const EdgeInsets.all(12)});
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final glass = Theme.of(context).extension<IterGlassRoles>()!;
    return IterMaterialSurface(
      key: const Key('iter-glass-bar'),
      padding: padding,
      borderRadius: BorderRadius.circular(glass.pillRadius),
      translucent: true,
      child: child,
    );
  }
}

class IterGlassSheet extends StatelessWidget {
  const IterGlassSheet({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final glass = Theme.of(context).extension<IterGlassRoles>()!;
    return IterMaterialSurface(
      key: const Key('iter-glass-sheet'),
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(glass.sheetRadius),
      translucent: true,
      child: child,
    );
  }
}

class IterHeroScrim extends StatelessWidget {
  const IterHeroScrim({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final glass = Theme.of(context).extension<IterGlassRoles>()!;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.0),
            Colors.black.withValues(alpha: glass.scrimAlpha),
          ],
        ),
      ),
      child: child,
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/iter_glass_primitives_test.dart`
Expected: PASS. Poi `flutter analyze`.

- [ ] **Step 5: Commit**

```bash
git add lib/features/chat_first_prototype/iter_glass_primitives.dart test/iter_glass_primitives_test.dart
git commit -m "feat(glass): add shared glass bar sheet scrim"
```

### Task 3: Shell tab pill in vetro con shrink su scroll

**Files:**
- Modify: `lib/features/chat_first_prototype/chat_first_shell.dart:214-300`
- Test: `test/chat_first_shell_glass_test.dart`

**Interfaces:**
- Consumes: `IterGlassBar` da Task 2, esistente `_ChatBottomNavigation(currentIndex, unread, onChanged)` e key `shell-floating-dock`.
- Produces: stessa key e semantics `Navigazione principale`, altezza dock 52 + padding 6 invariati, shrink animato 180ms ease-out disabilitato con `MediaQuery.disableAnimations`.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iter/app/iter_theme.dart';
import 'package:iter/features/chat_first_prototype/chat_first_controller.dart';
import 'package:iter/features/chat_first_prototype/chat_first_shell.dart';

void main() {
  testWidgets('dock resta flottante in vetro con 3 destinazioni', (tester) async {
    final controller = ChatFirstPrototypeController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: IterTheme.light(),
        home: ChatFirstShell(
          controller: controller,
          themeMode: ThemeMode.light,
          onThemeChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('shell-floating-dock')), findsOneWidget);
    expect(find.text('Oggi'), findsOneWidget);
    expect(find.text('Viaggi'), findsOneWidget);
    expect(find.text('Tu'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/chat_first_shell_glass_test.dart`
Expected: FAIL se controller richiede args o setup diverso — correggere setup leggendo `chat_first_controller.dart` costruttore reale, non inventare API.

- [ ] **Step 3: Write minimal implementation**

```dart
final reducedMotion = MediaQuery.disableAnimationsOf(context);
// In _ChatBottomNavigation.build, altezza dock animata:
child: AnimatedContainer(
  duration: reducedMotion ? Duration.zero : const Duration(milliseconds: 180),
  curve: Curves.easeOut,
  height: isScrolled ? 44.0 : 52.0,
  child: Row(/* 3 _FloatingDestination invariati */),
),
```

In `_ChatBottomNavigation.build`: wrappare `IterMaterialSurface` esistente con shrink via `ScrollNotification` depth 0 e offset > 80 come sopra. Non cambiare key `shell-floating-dock`, semantics, icone, badge. Verificare `translucent: true` resta.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/chat_first_shell_glass_test.dart test/chat_first_prototype_widget_test.dart`
Expected: PASS. Poi `flutter analyze`.

- [ ] **Step 5: Commit**

```bash
git add lib/features/chat_first_prototype/chat_first_shell.dart test/chat_first_shell_glass_test.dart
git commit -m "feat(glass): floating dock shrinks on scroll"
```

### Task 4: Home hero edge-to-edge + composer oggetto principale

**Files:**
- Modify: `lib/features/chat_first_prototype/chat_first_home_screen.dart`, `lib/features/chat_first_prototype/rotta_viva_home_sections.dart`
- Test: `test/home_glass_test.dart`

**Interfaces:**
- Consumes: `IterHeroScrim`, `IterGlassBar` da Task 2, `IterPageFrame(maxWidth: 760)` invariato.
- Produces: hero full-bleed sotto status bar con `Semantics(label: hero)`, riga operativa breve + `Vedi il piano completo`, timeline breve invariata nei dati.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iter/app/iter_theme.dart';
import 'package:iter/features/chat_first_prototype/iter_glass_primitives.dart';

void main() {
  testWidgets('hero scrim mantiene leggibilità', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: IterTheme.light(),
        home: const Scaffold(body: IterHeroScrim(child: Text('Porto'))),
      ),
    );
    expect(find.text('Porto'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/home_glass_test.dart`
Expected: PASS subito come smoke (primitivi già da Task 2) — allora estendere con pump di `chat_first_home_screen` reale e verificare `Vedi il piano completo` visibile una sola volta.

- [ ] **Step 3: Write minimal implementation**

Spostare hero `Image` a `Stack` full-bleed con `IterHeroScrim` + testi sopra, togliere box blu/card contenitore dal blocco principale, composer come `IterGlassBar` flottante in basso con safe area. Chip giorni con pillRadius 20. Nessun cambio copy o navigazione.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/home_glass_test.dart test/chat_first_prototype_widget_test.dart`
Expected: PASS. Poi `flutter analyze`. Verifica manuale 390dp light + 320dp dark.

- [ ] **Step 5: Commit**

```bash
git add lib/features/chat_first_prototype/chat_first_home_screen.dart lib/features/chat_first_prototype/rotta_viva_home_sections.dart test/home_glass_test.dart
git commit -m "feat(glass): home hero edge-to-edge"
```

### Task 5: Chat thread + composer in vetro

**Files:**
- Modify: `lib/features/chat_first_prototype/chat_first_thread_screen.dart`
- Test: `test/thread_glass_test.dart`

**Interfaces:**
- Consumes: `IterGlassBar` da Task 2.
- Produces: bolle raggio 20, card azionabili raggio 24 senza ombre pesanti (elevation 0-1), composer flottante allegato sx + campo min 2 righe + invio/mic dx, tooltip/semantics invariati.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iter/app/iter_theme.dart';

void main() {
  test('raggi chat rispettano token', () {
    final theme = IterTheme.light();
    final glass = theme.extension<IterGlassRoles>()!;
    expect(glass.pillRadius, 20.0);
    expect(glass.cardRadius, 24.0);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/thread_glass_test.dart`
Expected: PASS come contratto token — procedere a widget test del composer reale verificando allegato + invio presenti.

- [ ] **Step 3: Write minimal implementation**

Sostituire contenitore composer con `IterGlassBar`, bolle con `BorderRadius.circular(20)`, card thread con `BorderRadius.circular(24)` + `elevation: 0`, mantenere grammatica WhatsApp sx/dx e `MediaQuery.disableAnimations` per motion.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/thread_glass_test.dart test/chat_first_prototype_widget_test.dart`
Expected: PASS. Poi `flutter analyze`.

- [ ] **Step 5: Commit**

```bash
git add lib/features/chat_first_prototype/chat_first_thread_screen.dart test/thread_glass_test.dart
git commit -m "feat(glass): chat bubbles and composer"
```

### Task 6: Piano hero + action bar + chip giorni

**Files:**
- Modify: `lib/features/chat_first_prototype/trip_snapshot_screen.dart`, `lib/features/chat_first_prototype/plan_timeline.dart`
- Test: `test/snapshot_glass_test.dart`

**Interfaces:**
- Consumes: `IterGlassBar`, `IterHeroScrim` da Task 2.
- Produces: hero foto/video edge-to-edge, chip giorni pill in vetro, action bar Aggiungi luogo/Chiedi/Costi in vetro flottante, flusso preview→Applica→revisione→Annulla invariato.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:iter/app/iter_theme.dart';

void main() {
  test('sheet radius piano è 28', () {
    final glass = IterTheme.light().extension<IterGlassRoles>()!;
    expect(glass.sheetRadius, 28.0);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/snapshot_glass_test.dart`
Expected: PASS contratto — estendere verificando che `trip_snapshot_screen` pumpa senza eccezioni con controller mock esistente.

- [ ] **Step 3: Write minimal implementation**

Hero in `Stack` con scrim, chip giorni con pillRadius, action bar con `IterGlassBar` ancorata in basso + safe area, scheda tappa invariata nei dati con Indicazioni + Chiedi a Iter. Nessuna mappa sopra il piano.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/snapshot_glass_test.dart test/chat_first_prototype_widget_test.dart`
Expected: PASS. Poi `flutter analyze`.

- [ ] **Step 5: Commit**

```bash
git add lib/features/chat_first_prototype/trip_snapshot_screen.dart lib/features/chat_first_prototype/plan_timeline.dart test/snapshot_glass_test.dart
git commit -m "feat(glass): snapshot hero and action bar"
```

### Task 7: Costi dialog 28 + sheet vetro

**Files:**
- Modify: `lib/features/chat_first_prototype/plan_cost_sheet.dart`
- Test: `test/cost_glass_test.dart`

**Interfaces:**
- Consumes: `IterGlassSheet` da Task 2.
- Produces: foglio lineare 3 sezioni (Da acquistare / Stime / Totali), dialog conferma con totale + `Demo: nessun pagamento reale` sempre visibile, successo `Scelte confermate`.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iter/app/iter_theme.dart';
import 'package:iter/features/chat_first_prototype/iter_glass_primitives.dart';

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
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/cost_glass_test.dart`
Expected: PASS smoke — verificare poi copy `Demo: nessun pagamento reale` presente una sola volta nel pump reale di `plan_cost_sheet`.

- [ ] **Step 3: Write minimal implementation**

Wrappare `plan_cost_sheet` in `IterGlassSheet`, dialog con `shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))`, CTA demo invariato nel copy e nel flusso locale senza carta/PNR.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/cost_glass_test.dart`
Expected: PASS. Poi `flutter analyze`.

- [ ] **Step 5: Commit**

```bash
git add lib/features/chat_first_prototype/plan_cost_sheet.dart test/cost_glass_test.dart
git commit -m "feat(glass): cost sheet and confirm dialog"
```

### Task 8: Profilo hairline + verifica accessibilità/responsive

**Files:**
- Modify: `lib/features/chat_first_prototype/chat_first_profile_screen.dart`
- Test: `test/profile_glass_a11y_test.dart`

**Interfaces:**
- Consumes: tutti i primitivi precedenti, nessun nuovo blur.
- Produces: titoli con icona vettoriale + divider hairline, chip memoria, 3 statistiche, ListTile FAQ/Privacy, tema Chiaro/Scuro/Sistema invariato; test a 320dp, textScale 1.5, disableAnimations, reduceTransparency.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iter/app/iter_theme.dart';
import 'package:iter/features/chat_first_prototype/chat_first_profile_screen.dart';
import 'package:iter/features/chat_first_prototype/chat_first_controller.dart';

void main() {
  testWidgets('profilo leggibile a 320dp testo 1.5 senza overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final controller = ChatFirstPrototypeController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: IterTheme.light(),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: ChatFirstProfileScreen(controller: controller),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/profile_glass_a11y_test.dart`
Expected: FAIL se costruttore profilo diverso — leggere `chat_first_profile_screen.dart` e correggere args reali, non inventare.

- [ ] **Step 3: Write minimal implementation**

Rimuovere griglia card ripetute, usare `Divider(height: 1)`, `ListTile`, chip esistenti, statistiche compatte. Nessun blur aggiunto qui. Verificare `Semantics` immagini/azioni e contrasto 4.5:1 su light/dark.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/profile_glass_a11y_test.dart`
Expected: PASS. Poi `flutter analyze && flutter test` intera suite verde. Poi `flutter build web --release` e check 320/360/390dp chiaro/scuro.

- [ ] **Step 5: Commit**

```bash
git add lib/features/chat_first_prototype/chat_first_profile_screen.dart test/profile_glass_a11y_test.dart
git commit -m "feat(glass): profile cleanup and a11y check"
```
