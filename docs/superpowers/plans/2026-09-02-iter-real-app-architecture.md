# Piano di Implementazione — Architettura Reale Iter

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task in the current thread, respecting `AGENTS.md`. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Costruire l'applicazione reale Iter trasformandola in una vera app di viaggi: eliminare il box chat e i chip finti dalla Home, integrare l'IA reale (Google Gemini Free Tier via REST con chiave in `.env`/Impostazioni), offrire una chat a tutto schermo che genera blocchi concreti di itinerario, salvare i viaggi stabilmente in locale e collegare il piano a `TripSnapshotScreen`.

**Architecture:** Struttura a 3 tab pulite (**Oggi**, **Viaggi**, **Tu**). La Home mostra le tue pianificazioni, consigli personalizzati e mete da scoprire, con un pulsante primario *"Organizza un nuovo viaggio"* che apre la vera Chat a tutto schermo (`TripChatScreen`). Gemini risponde in italiano naturale e genera blocchi interattivi (voli, zone soggiorno, tappe giorno per giorno). Il piano si salva in locale con `TripRepository` e si visualizza in `TripSnapshotScreen`.

**Tech Stack:** Flutter (Dart), Google Generative AI REST API (`gemini-1.5-flash`), `shared_preferences`, `http`, `url_launcher`, OpenStreetMap / OSRM.

**Spec:** [`docs/superpowers/specs/2026-09-02-iter-real-app-architecture-design.md`](file:///Users/matteo/iter/docs/superpowers/specs/2026-09-02-iter-real-app-architecture-design.md)

## Global Constraints

- Zero campi di input o chat permanente sulla Home page.
- Nessuna risposta pre-confezionata o chip hardcoded forzati (Porto/Lisbona); Gemini deve comprendere qualsiasi destinazione reale al mondo.
- Nessuna dipendenza da database cloud per l'uso immediato: persistenza locale robusta tramite `SharedPreferences`.
- La sezione per l'inserimento della chiave Gemini è etichettata esplicitamente come strumento di collaudo/fase demo.
- `flutter analyze` deve rimanere a 0 errori e 0 warning.
- La suite dei test `flutter test` deve rimanere verde al 100%.

---

### Task 1: Servizio AI Google Gemini Reale (`GeminiTravelService`)

**Files:**
- Create: `lib/features/ai/gemini_models.dart`
- Create: `lib/features/ai/gemini_travel_service.dart`
- Test: `test/features/gemini_travel_service_test.dart`

**Interfaces:**
- Produces: `GeminiTravelService.generateTripAdvice({required String prompt, required String destination, ...})`
- Produces: `GeminiTripPlanDraft` (con `flightRecommendations`, `neighborhoods`, `dailyItinerary`)

- [ ] **Step 1: Scrivere il test per `GeminiTravelService`**

```dart
// test/features/gemini_travel_service_test.dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:iter/features/ai/gemini_travel_service.dart';

void main() {
  test('GeminiTravelService invia richiesta e mappa risposta strutturata', () async {
    final mockClient = MockClient((request) async {
      expect(request.url.queryParameters['key'], 'test-api-key');
      final fakeResponse = {
        'candidates': [
          {
            'content': {
              'parts': [
                {
                  'text': jsonEncode({
                    'message': 'Ecco una proposta per Madrid!',
                    'destination': 'Madrid',
                    'flight': {
                      'outbound': 'Milano MXP - Madrid MAD',
                      'priceEstimate': '65€',
                      'searchUrl': 'https://www.skyscanner.it'
                    },
                    'neighborhoods': [
                      {'name': 'Malasaña', 'why': 'Ideale per giovani e cibo tipico'}
                    ],
                    'days': [
                      {
                        'dayNumber': 1,
                        'theme': 'Centro storico e tapas',
                        'stops': ['Plaza Mayor', 'Mercado de San Miguel']
                      }
                    ]
                  })
                }
              ]
            }
          }
        ]
      };
      return http.Response(jsonEncode(fakeResponse), 200);
    });

    final service = GeminiTravelService(apiKey: 'test-api-key', client: mockClient);
    final result = await service.generateTripAdvice('Vorrei 3 giorni a Madrid');
    expect(result.destination, 'Madrid');
    expect(result.neighborhoods.first.name, 'Malasaña');
    expect(result.days.first.stops.length, 2);
  });
}
```

- [ ] **Step 2: Eseguire il test per verificare che fallisce**

```bash
flutter test test/features/gemini_travel_service_test.dart
```

- [ ] **Step 3: Implementare `gemini_models.dart` e `gemini_travel_service.dart`**

Definire i modelli immutabili per il parsing JSON e il client HTTP REST che chiama l'endpoint `gemini-1.5-flash:generateContent`.

- [ ] **Step 4: Eseguire il test per verificare che passa**

```bash
flutter test test/features/gemini_travel_service_test.dart
```

- [ ] **Step 5: Verificare analisi statica**

```bash
flutter analyze lib/features/ai test/features/gemini_travel_service_test.dart
```

---

### Task 2: Archivio Viaggi e Persistenza Locale (`TripRepository`)

**Files:**
- Create: `lib/features/trips/trip_entity.dart`
- Create: `lib/features/trips/trip_repository.dart`
- Test: `test/features/trip_repository_test.dart`

**Interfaces:**
- Produces: `TripRepository.getAllTrips()` -> `Future<List<TripEntity>>`
- Produces: `TripRepository.saveTrip(TripEntity trip)` -> `Future<void>`
- Produces: `TripRepository.deleteTrip(String id)` -> `Future<void>`

- [ ] **Step 1: Scrivere il test per `TripRepository`**

```dart
// test/features/trip_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iter/features/trips/trip_entity.dart';
import 'package:iter/features/trips/trip_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('TripRepository salva, recupera ed elimina viaggi in SharedPreferences', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = TripRepository();
    
    final trip = TripEntity(
      id: 'trip-1',
      destination: 'Siviglia',
      durationDays: 4,
      status: TripStatus.planning,
      coverImageUrl: 'https://images.unsplash.com/photo-siviglia',
      createdAt: DateTime.now(),
      messages: [],
    );

    await repo.saveTrip(trip);
    var all = await repo.getAllTrips();
    expect(all.length, 1);
    expect(all.first.destination, 'Siviglia');

    await repo.deleteTrip('trip-1');
    all = await repo.getAllTrips();
    expect(all, isEmpty);
  });
}
```

- [ ] **Step 2: Eseguire il test per verificare il fallimento**

```bash
flutter test test/features/trip_repository_test.dart
```

- [ ] **Step 3: Implementare `trip_entity.dart` e `trip_repository.dart`**

Implementare la serializzazione JSON e il salvataggio atomico tramite chiave `iter_saved_trips_v1`.

- [ ] **Step 4: Eseguire il test per confermare il passaggio**

```bash
flutter test test/features/trip_repository_test.dart
```

---

### Task 3: Nuova Home Screen ("Oggi") — Vetrina Senza Chat Box

**Files:**
- Create: `lib/features/home/home_screen.dart`
- Create: `lib/features/home/widgets/home_hero_banner.dart`
- Create: `lib/features/home/widgets/home_trips_section.dart`
- Create: `lib/features/home/widgets/home_deals_section.dart`
- Create: `lib/features/home/widgets/home_discover_section.dart`
- Test: `test/features/home_screen_widget_test.dart`

**Interfaces:**
- Consumes: `TripRepository` (per le pianificazioni salvate)
- Consumes: `LocalPreferencesService` (per città di partenza e stile)
- Produces: `HomeScreen(onOpenNewTripChat: ..., onOpenTripDetails: ...)`

- [ ] **Step 1: Scrivere il test per `HomeScreen`**

```dart
// test/features/home_screen_widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iter/features/home/home_screen.dart';

void main() {
  testWidgets('HomeScreen NON contiene TextField chat ed espone banner e sezioni', (tester) async {
    SharedPreferences.setMockInitialValues({});
    var openedChat = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeScreen(
            onOpenNewTripChat: () => openedChat = true,
            onOpenTripDetails: (_) {},
            onOpenProfile: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verificare che NON ci sia nessun campo di testo o composer chat nella Home!
    expect(find.byType(TextField), findsNothing);

    // Verificare il banner primario e il pulsante
    expect(find.text('Organizza un nuovo viaggio'), findsOneWidget);
    await tester.tap(find.text('Organizza un nuovo viaggio'));
    expect(openedChat, isTrue);

    // Verificare la presenza delle sezioni
    expect(find.text('Le tue pianificazioni'), findsOneWidget);
    expect(find.text('Consigli & Offerte per te'), findsOneWidget);
    expect(find.text('Scopri nuovi posti'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Eseguire il test per verificare il fallimento**

```bash
flutter test test/features/home_screen_widget_test.dart
```

- [ ] **Step 3: Implementare `home_screen.dart` e i widget dedicati**

Creare il layout pulito con il banner hero, le schede dei viaggi, i consigli e le mete da scoprire, con zero elementi di chat.

- [ ] **Step 4: Eseguire il test per verificare che passa**

```bash
flutter test test/features/home_screen_widget_test.dart
```

---

### Task 4: Esperienza Chat Dedicata a Tutto Schermo (`TripChatScreen`)

**Files:**
- Create: `lib/features/chat/trip_chat_screen.dart`
- Create: `lib/features/chat/widgets/flight_preview_card.dart`
- Create: `lib/features/chat/widgets/stay_neighborhood_card.dart`
- Create: `lib/features/chat/widgets/daily_plan_card.dart`
- Test: `test/features/trip_chat_screen_widget_test.dart`

**Interfaces:**
- Consumes: `GeminiTravelService`
- Consumes: `TripRepository`
- Produces: `TripChatScreen(tripId: ..., onOpenSnapshot: ...)`

- [ ] **Step 1: Scrivere il test per `TripChatScreen`**

```dart
// test/features/trip_chat_screen_widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iter/features/chat/trip_chat_screen.dart';

void main() {
  testWidgets('TripChatScreen mostra composer inferiore e genera bolla con risposta', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TripChatScreen(
          initialPrompt: 'Vorrei andare a Berlino',
          onOpenSnapshot: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Invia'), findsWidgets);
  });
}
```

- [ ] **Step 2: Eseguire il test e verificare il fallimento**

```bash
flutter test test/features/trip_chat_screen_widget_test.dart
```

- [ ] **Step 3: Implementare `trip_chat_screen.dart` e i widget di card interattive**

Integrare la chiamata al `GeminiTravelService`, la gestione dei messaggi reattiva e il pulsante *"Salva e apri itinerario completo"*.

- [ ] **Step 4: Eseguire il test per confermare il passaggio**

```bash
flutter test test/features/trip_chat_screen_widget_test.dart
```

---

### Task 5: Tab "Viaggi" (Archivio Pianificazioni)

**Files:**
- Create: `lib/features/trips/trips_list_screen.dart`
- Test: `test/features/trips_list_screen_test.dart`

**Interfaces:**
- Consumes: `TripRepository`
- Produces: `TripsListScreen(onOpenTripChat: ..., onOpenTripSnapshot: ...)`

- [ ] **Step 1: Scrivere il test per `TripsListScreen`**
- [ ] **Step 2: Verificare il fallimento**
- [ ] **Step 3: Implementare `TripsListScreen` con pulsanti per visualizzare il piano, riprendere la chat o eliminare**
- [ ] **Step 4: Verificare il passaggio del test**

---

### Task 6: Tab "Tu" (Profilo & Gestione API Key Demo)

**Files:**
- Create: `lib/features/profile/profile_screen.dart`
- Test: `test/features/profile_screen_widget_test.dart`

**Interfaces:**
- Consumes: `LocalPreferencesService`
- Produces: `ProfileScreen()`

- [ ] **Step 1: Scrivere il test per `ProfileScreen` con campi preferenze e campo API Key Demo**
- [ ] **Step 2: Verificare il fallimento**
- [ ] **Step 3: Implementare `ProfileScreen` con salvataggio preferenze di viaggio e input per la chiave Google AI Studio con indicatore di stato**
- [ ] **Step 4: Verificare il passaggio del test**

---

### Task 7: Shell di Navigazione Principale & Verifica E2E

**Files:**
- Create: `lib/features/shell/iter_main_shell.dart`
- Modify: `lib/features/chat_first_prototype/chat_first_app.dart`
- Test: `test/features/real_app_e2e_test.dart`

**Interfaces:**
- Unifica le 3 sezioni nella barra di navigazione inferiore (**Oggi**, **Viaggi**, **Tu**).

- [ ] **Step 1: Scrivere il test E2E globale di navigazione**
- [ ] **Step 2: Collegare `IterMainShell` nell'entrypoint dell'app**
- [ ] **Step 3: Eseguire l'intera suite dei test `flutter test`**
- [ ] **Step 4: Eseguire `flutter analyze` e verificare 0 errori e 0 warning**
- [ ] **Step 5: Compilare e servire la versione web release per il collaudo utente**
