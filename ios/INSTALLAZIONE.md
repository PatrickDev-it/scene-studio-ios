# Installazione su iPhone

Il progetto ha un target minimo iOS **15.0**, compresa la serie iOS **16.7** di iPhone 8, 8 Plus e X. Su iPhone l’app si apre in verticale. Il nome visibile è **TikTok** e il bundle ID separato `com.scenestudio.tiktokpreview` permette di tenerla installata insieme all’originale.

## 1. Prepara il Mac

- Installa [Flutter 3.47.2 per macOS](https://docs.flutter.dev/install/archive), con Dart 3.13.2 e la variante Apple silicon o Intel adatta al Mac.
- Per installare e avviare direttamente su iOS 16.7 usa **Xcode 26.3** su macOS Sequoia 15.6 o successivo, oppure una versione 26.x che nella [tabella Apple](https://developer.apple.com/xcode/system-requirements/) indica *Device Support* da iOS 15. Xcode 27 indica iOS 17 per il collegamento ai dispositivi.
- Apri Xcode, completa l’installazione dei componenti iOS e aggiungi il tuo Apple Account da **Xcode → Settings → Accounts**. Se hai più versioni di Xcode, scegli quella compatibile anche in **Settings → Locations → Command Line Tools** e verifica con `xcodebuild -version`.

Dal Terminale, nella cartella con `pubspec.yaml`, esegui:

```sh
flutter doctor -v
flutter pub get --enforce-lockfile
flutter build ios --release --config-only --no-codesign
open ios/Runner.xcworkspace
```

La configurazione rigenera sul Mac i file Flutter e SwiftPM locali. Se hai copiato l’intera cartella di lavoro da Windows, esegui `flutter clean` prima di `flutter pub get`.

## 2. Firma e installa via USB

1. Collega l’iPhone sbloccato, conferma **Autorizza questo computer** e selezionalo come destinazione in Xcode. Abilita [Modalità sviluppatore](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device) in **Impostazioni → Privacy e sicurezza** dopo il primo abbinamento. Riavvia e conferma sul telefono.
2. In **Runner → TARGETS → Runner → Signing & Capabilities**, attiva **Automatically manage signing** e scegli il tuo **Team**. Se Xcode segnala che l’identificatore è già registrato, sostituiscilo con un identificatore univoco del tuo Team e riusalo per gli aggiornamenti.
3. In **Product → Scheme → Edit Scheme → Run → Info** seleziona **Release** e togli **Debug executable**. Premi **⌘R**. La firma resta di sviluppo e l’app usa codice ottimizzato per il confronto delle animazioni.
4. Dopo la prima installazione, avvia l’app dalla Home e scollega il cavo per il confronto. Con il [Personal Team](https://developer.apple.com/help/account/basics/about-your-developer-account) gratuito, il profilo di firma scade dopo sette giorni e puoi reinstallarlo da Xcode.

## 3. Confronta con TikTok

1. Tieni premuto **Profile** in basso per aprire il setup. Importa da **File → Su iPhone** un MP4 verticale H.264 con audio AAC e una miniatura JPG o PNG. Torna all’anteprima. Verifica che il contenuto resti disponibile dopo aver chiuso e riaperto l’app.
2. Registra lo schermo con iOS mentre provi apertura dalla griglia, passaggio verticale tra video, swipe dal bordo sinistro annullato e completato, commenti, tre puntini e ritorno dalle analitiche.
3. Ripeti su TikTok originale con lo stesso telefono, tema e impostazione **Riduci movimento**. Su iPhone 8 verifica lo spazio senza tacca e indicatore Home. Su iPhone X verifica la tacca e lo spazio sotto i controlli.
