# Iter Apple Liquid Glass — Design Spec

Data: 2026-09-03
Branch: `feat/apple-liquid-glass-design` (da `feat/real-iter-app` @ `9007e49`)
Scope: tutta l'app — Home, Chat, Piano, Costi, Profilo
Direzione approvata: A. Liquid Glass contenuto-first, full Apple look con identità Rotta viva preservata nei token.

## 1. Principi

1. Contenuto prima, chrome in vetro. Solo tab bar, composer, action bar piano e sheet usano blur. Mai vetro su vetro.
2. Edge-to-edge. Hero foto/video sotto status bar e tab, con scrim leggera solo dove serve leggibilità.
3. Raggi concentrici stile hardware Apple: 24-28 card/sheet grandi, 20 pill controlli.
4. Colore parsimonioso nel chrome (tinta neutra), `Rotta #2D63FF / #7EA0FF` solo per azione primaria, `Segnale` solo per decisioni.
5. Nessuna modifica a contratti dati, AI, acquisti demo o navigazione Oggi/Viaggi/Tu.

## 2. Architettura

- `lib/app/iter_theme.dart`: aggiungere token glass (`glassBlurSigma`, `glassTintLight/Dark`, `glassBorderOpacity`, `scrimOpacity`) come `ThemeExtension`, con varianti light/dark e fallback opaco. Nessun colore raw nei widget.
- Nuovo `lib/features/chat_first_prototype/iter_glass_primitives.dart`: `IterGlassBar` (BackdropFilter + tinta + bordo hairline + fallback opaco per reduceTransparency), `IterGlassSheet` (raggio 28, inset half-sheet), `IterHeroScrim`.
- `chat_first_shell.dart`: tab pill flottante in vetro, si restringe allo scroll (come iOS 26), safe area nativa, larghezza max 760dp invariata.
- Home / thread / snapshot / cost sheet / profilo riusano i primitivi, non duplicano blur.

## 3. Componenti per schermata

**Home:** vuota = composer grande oggetto principale; con viaggio = hero full-bleed + riga operativa breve + Vedi piano completo + timeline breve + composer flottante.

**Chat:** bolle raggi 20, card azionabili raggi 24 senza ombre pesanti, composer multi-riga flottante in vetro con allegato sx e invio/mic dx, feedback pressed + semantics invariati.

**Piano:** hero foto/video edge-to-edge, fatti brevi, chip giorni pill in vetro, timeline continua, scheda tappa con Indicazioni + Chiedi a Iter, action bar flottante in vetro (Aggiungi luogo / Chiedi / Costi), overflow solo azioni rare. Preview → Applica → revisione → snackbar Annulla invariato.

**Costi:** documento lineare 3 sezioni, CTA demo apre dialog raggio 28 con totale + `Demo: nessun pagamento reale`, successo = Scelte confermate.

**Profilo:** titoli con icona vettoriale + hairline, chip memoria, 3 statistiche compatte, ListTile FAQ/Privacy, tema Chiaro/Scuro/Sistema invariato.

## 4. Motion e stati

- 150-300ms ease-out, nessuna animazione infinita. Con moto ridotto: stato immediato o crossfade, blur off.
- Con trasparenza ridotta: chrome diventa opaco (surface, non blur).
- Tutti i controlli mantengono normal/pressed/disabled/errore. Sheet scrollabili, nessun CTA nascosto. Nessun loading finto.

## 5. Accessibilità e responsive

- Target 48dp, spacing 8dp. Semantics per immagini, azioni, stato acquisto.
- Contrasto corpo 4.5:1 in entrambi i temi, verificato anche su foto con scrim.
- Test obbligatori 320/360/390dp, text scale 1.5, dark mode, disableAnimations. Piano sempre con rappresentazione testuale timeline.

## 6. Verifica

```bash
flutter analyze
flutter test
flutter build web --release
python3 -m http.server 7357 --directory build/web --bind 127.0.0.1
```

Browsing a 320/360/390dp, chiaro/scuro, testo 1.5, riduzione movimento + trasparenza.

## 7. Non-obiettivi

Nessun cambio a backend mock/Supabase, AI Gemini, prezzi live, GPS, Share Target, scraping social, checkout reale. Nessuna migrazione a Cupertino/SF: restano Bricolage Grotesque + Figtree e palette Rotta viva.
