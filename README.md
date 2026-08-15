# Iter

Iter è un'app Flutter mobile per costruire un viaggio insieme alla persona.
Questa versione del repository contiene una sola esperienza chat-first: la
chat aiuta, ma il piano resta sempre visibile e modificabile.

## Cosa puoi provare

- Home **Oggi**, archivio **Viaggi** e profilo **Tu** con navigazione flottante;
- chat mock con destinazioni, luoghi, voli, hotel, foto, video e vocali;
- piano operativo senza mappa in cima, con immagini, timeline, schede luogo,
  indicazioni, aggiunta, riordino, orario, blocco e rimozione;
- costi in tre sezioni e conferma locale **Conferma acquisti demo**;
- disponibilità/turni e statistiche leggere nel profilo;
- importazione mock di link Instagram/TikTok, salvataggio e proposta in chat.

Tutto è dichiarato come demo. Non vengono effettuati pagamenti o prenotazioni.

## Requisiti

- Flutter stable;
- Dart incluso nell'SDK Flutter;
- nessun provider esterno necessario per il percorso mock.

## Avvio

```bash
flutter pub get
./tool/run_web.sh
```

Lo script costruisce il Web release e lo serve su
`http://127.0.0.1:7357`. Apri l'indirizzo nel Browser integrato o in un browser
locale e interrompi il server con `Ctrl-C`.

Per avviare Android quando serve una verifica nativa:

```bash
./tool/run_android.sh
```

Non esistono define per scegliere la vecchia o la nuova app: il root è già
quello nuovo.

## Verifica

```bash
dart format lib test
git diff --check
flutter analyze
flutter test
flutter build web --release
```

Per la UI controllare anche larghezze 320/360/390 dp, testo 1.5, tema scuro e
riduzione del movimento. Il gate Android (`flutter build apk --debug`) è
necessario solo per modifiche native, inset, gesture, lifecycle o release.

## Documentazione

- [PRODUCT.md](PRODUCT.md) — perimetro e comportamento;
- [DESIGN.md](DESIGN.md) — sistema visuale e accessibilità;
- [HANDOFF.md](HANDOFF.md) — architettura, flussi e QA;
- [spec approvata](docs/superpowers/specs/2026-08-14-iter-new-only-design.md);
- [piano esecutivo](docs/superpowers/plans/2026-08-14-iter-new-only-implementation.md).

Le spec precedenti e `NEW_TRIP_MASTER_PLAN.md` sono materiale storico: non sono
istruzioni per riattivare codice o feature flag rimossi.

## Backend opzionale

Il mock è il default. Il seam Supabase può essere configurato con valori
pubblici:

```bash
flutter run \
  --dart-define=ITER_BACKEND=supabase \
  --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<publishable-key>
```

Non inserire mai chiavi Gemini, routing o service-role nel client.
