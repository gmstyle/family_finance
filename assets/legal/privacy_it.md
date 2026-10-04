# Informativa sulla privacy — Family Finance

**Ultimo aggiornamento:** 4 ottobre 2026

Questa informativa descrive come Family Finance (“l’app”) tratta i tuoi dati. Il libro mastro condiviso appartiene alla famiglia; le credenziali di accesso restano su Firebase Authentication.

## Titolare

Family Finance è un libro mastro familiare per movimenti confermati, budget e obiettivi virtuali. Contatto per richieste privacy: contattagmstyle@gmail.com.

## Dati trattati

- **Account:** email, nome visualizzato, identificativi di autenticazione (Firebase Auth).
- **Libro mastro famiglia:** conti, categorie, transazioni, trasferimenti, budget e speso del periodo, obiettivi e versamenti, rollup mensili.
- **Bozze di ingestione:** importo, data contabile, esercente, conto/categoria suggeriti da OCR scontrino o notifiche di pagamento — mai il testo grezzo della notifica né la foto dello scontrino.
- **Token dispositivo:** token FCM per alert di soglia budget (sotto il profilo utente).
- **Preferenze:** lingua UI memorizzata sul dispositivo (`shared_preferences`).

## Finalità

- Fornire il libro mastro condiviso e la membership.
- Calcolare saldi, periodi di budget e stats tramite Cloud Functions (solo server).
- Inviare notifiche di soglia budget (80% / 100%) se hai dispositivi registrati.
- Creare bozze di revisione da OCR on-device o cattura notifiche Android — **le transazioni nascono solo dopo conferma esplicita**.

## Trattamento sul dispositivo

- **OCR scontrini (Android):** riconoscimento testo on-device (ML Kit). Le foto non vengono caricate sui nostri server.
- **Listener notifiche (Android):** le notifiche di pagamento dei package in allowlist vengono interpretate on-device in campi bozza. Il corpo grezzo non viene persistito.

## Condivisione

Non vendiamo dati personali. L’infrastruttura usa Google Firebase (Auth, Firestore, Functions, Messaging, Remote Config). I membri invitati leggono e scrivono il libro mastro secondo le regole dell’app.

## Conservazione e cancellazione

- Puoi esportare un JSON dei dati famiglia leggibili da Impostazioni.
- Puoi eliminare l’account da Impostazioni. Se sei l’unico membro, la cancellazione rimuove anche in modo definitivo il libro mastro della famiglia dopo conferma esplicita. Se restano altri membri, devi trasferire la proprietà / promuovere un altro admin; i dati condivisi restano alla famiglia.

## Diritti

In base alla tua giurisdizione puoi chiedere accesso, rettifica o cancellazione. Usa export/eliminazione in-app dove disponibili, oppure contatta contattagmstyle@gmail.com.

## Minori

L’app non è destinata a minori di 13 anni (o all’età minima equivalente nel tuo Paese).

## Modifiche

Possiamo aggiornare questa informativa. La copia in-app, `docs/privacy-policy.md` e le pagine pubbliche sotto `hosting/public/` saranno allineate.
