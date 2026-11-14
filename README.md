# TikTok Scene Studio

Simulatore Flutter locale per allestire scene di marketing su iPhone. L'obiettivo è riprodurre con fedeltà l'aspetto, la navigazione e le animazioni di TikTok, usando contenuti e metriche simulati configurabili sul dispositivo.

Il setup permette di personalizzare profilo, video, miniature, contatori, commenti e analitiche. La registrazione avviene con gli strumenti esterni o la registrazione schermo dell'iPhone. L'app funziona offline e conserva i dati localmente.

## Uso

1. Su Windows aprire `Avvia Scene Studio.cmd`. Il setup mostra il profilo con la stessa navigazione del Viewer.
2. Toccare nome, username, foto, bio e contatori per modificarli. Tenere premuta una miniatura per impostare video locale, copertina e metriche. Aprire TikTok Studio dal menu del profilo: i valori del riepilogo, i testi del banner, le schede Monetization e le metriche nelle pagine Analytics si modificano sul posto. Toccare una riga di località, età, genere o sorgente di traffico per cambiarne nome e percentuale; le altre righe restano intatte.
3. Il menu **Impostazioni scena** apre la sequenza Home, il badge Inbox, il tema, la scena di riferimento e **Tutte le impostazioni** per i campi avanzati, compresa la modalità all’avvio.
4. Premere **Viewer** per ripetere l’avvio dalla Home. Tenere premuto **Profile** in basso per tornare al setup. Lo swipe verso il basso aggiorna la griglia.
5. La griglia mostra numeri interi sotto 10.000 e abbrevia i valori maggiori troncando al primo decimale.

La scena di riferimento inclusa contiene il profilo animalchaos281, nove copertine locali e i dati simulati di Studio. Nel setup puoi caricare la scena di riferimento o importare i tuoi filmati.

Il riferimento principale è iPhone 8 a 375 × 667 pt. Su iPhone la barra di stato e l’indicatore di registrazione appartengono a iOS. I media importati sono copiati nei documenti dell'app e le schermate Studio usano dati simulati.

In **Modalità all’avvio** puoi riaprire l’ultima modalità usata oppure partire sempre in Viewer o in Setup.

## Sviluppo

- `flutter pub get`, `flutter analyze` e `flutter test` per preparare e verificare il progetto.
- `flutter build windows --profile` per aggiornare la build avviata dal collegamento Windows.
- Per compilare, firmare e confrontare le transizioni su iPhone 8 e X con iOS 16.7, seguire la [guida iOS](ios/INSTALLAZIONE.md).
