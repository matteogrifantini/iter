# Iter — Working agreement

Questo file contiene solo le regole utili a lavorare velocemente nel repository.
Il lavoro si svolge nel thread corrente con un solo agente: nessun orchestratore,
specialista, worker o sistema di escalation è richiesto.

## Prima di modificare

1. Leggere `HANDOFF.md`.
2. Leggere `NEW_TRIP_MASTER_PLAN.md` se il lavoro riguarda Nuovo viaggio.
3. Leggere `PRODUCT.md` e `DESIGN.md` per decisioni prodotto o UI.
4. Controllare `git status` e preservare le modifiche già presenti.
5. Definire in modo breve file interessati, risultato e verifica.

## Lavoro

- Modificare direttamente i file necessari nel thread corrente.
- Non introdurre ruoli, deleghe, task secondari o gate aggiuntivi.
- Non ampliare lo scope senza segnalarlo.
- Preferire dipendenze minime e codice semplice.
- Non inserire segreti nel client.
- Non trasformare Iter in un chatbot puro o in una dashboard SaaS.
- Conservare conferme esplicite per pagamenti, prenotazioni e modifiche importanti.
- Preservare l'isolamento del Nuovo viaggio Lab da `IterStore` e provider reali.

## Strumenti

Usare gli strumenti più diretti disponibili (`rg`, `sed`, `git`, `flutter` e
simili). `codegraph` è facoltativo e utile solo quando esiste e serve davvero.
`rtk` è facoltativo: non è un passaggio obbligatorio per ogni comando.
I report restano brevi: file cambiati, verifica, rischi o blocchi.

## Git e sicurezza

- Non usare reset distruttivi, force push o cancellazioni ampie.
- Non modificare file non pertinenti al task.
- Non committare o pushare senza richiesta esplicita dell'utente.
- Prima di un commit controllare diff, whitespace e stato del branch.

## Verifica

Per modifiche applicative, eseguire in proporzione allo scope:

```bash
flutter analyze
flutter test
```

Per modifiche UI, usare il Browser integrato e, quando serve, `flutter build web
--release`. Il build APK e il QA Android sono riservati a modifiche native,
inset, gesture, lifecycle, prestazioni o gate release.

Per sola configurazione/documentazione, validare il formato interessato e usare
`git diff --check`. Non servono build Flutter.
