# TikTok Scene Studio

Simulatore Flutter locale per allestire scene di marketing su iPhone. L'obiettivo è riprodurre con fedeltà l'aspetto, la navigazione e le animazioni di TikTok, usando contenuti e metriche simulati configurabili sul dispositivo.

Il setup permette di personalizzare profilo, video, miniature, contatori, commenti e analitiche. La registrazione avviene con gli strumenti esterni o la registrazione schermo dell'iPhone. L'app funziona offline e conserva i dati localmente.

## Uso

1. Su Windows aprire `Avvia Scene Studio.cmd` e scegliere il tema nel setup.
2. Configurare il profilo e i post, importare video MP4/MOV e miniature, quindi impostare commenti, analitiche e contatori.
3. Aprire **Anteprima** per ripetere la sequenza di avvio dalla Home. Tenere premuto **Profile** in basso per riaprire il setup. Dal profilo, il menu in alto a destra apre **TikTok Studio**. Lo swipe verso il basso aggiorna la griglia.
4. In **Sequenza Home**, selezionare e trascinare i video nell’ordine di riproduzione. **Analitiche e schermate TikTok Studio** modifica il riepilogo e i dati separati per intervallo. **Badge e notifiche Inbox** controlla il numero e il fumetto.
5. Nel singolo video, imposta le visualizzazioni da mostrare. La griglia usa numeri interi sotto 10.000 e abbrevia i valori maggiori troncando al primo decimale.

La scena di riferimento inclusa contiene il profilo animalchaos281, nove copertine locali e i dati simulati di Studio. Nel setup puoi caricare la scena di riferimento o importare i tuoi filmati.

Il riferimento principale è iPhone 8 a 375 × 667 pt. Su iPhone la barra di stato e l’indicatore di registrazione appartengono a iOS. I media importati sono copiati nei documenti dell'app e le schermate Studio usano dati simulati.

In **Modalità all’avvio** puoi riaprire l’ultima modalità usata oppure partire sempre in Viewer o in Setup.

## Sviluppo

- `flutter pub get`, `flutter analyze` e `flutter test` per preparare e verificare il progetto.
- `flutter build windows --profile` per aggiornare la build avviata dal collegamento Windows.
- Per compilare, firmare e confrontare le transizioni su iPhone 8 e X con iOS 16.7, seguire la [guida iOS](ios/INSTALLAZIONE.md).
- Sinapsi è inizializzato nella cartella del progetto. I comandi `sinapsi start-task` e `sinapsi end-task` sono disponibili anche quando il server MCP della sessione punta a un'altra cartella.
