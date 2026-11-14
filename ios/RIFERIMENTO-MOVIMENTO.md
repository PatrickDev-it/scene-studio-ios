# Sequenza iPhone 8

Riferimento `RPReplay_Final1794604450.mp4`, 91,9 s a 750 × 1334 pixel. Il canvas dell’app è 375 × 667 pt. La barra di stato, l’avvio dalla Home e l’indicatore di registrazione sono gestiti da iOS.

| Passaggio | Tempo nel video o intervallo misurato |
| --- | --- |
| Apertura dall’icona e splash | Avvio a 4,98 s. La Home comincia a emergere a 6,78 s. |
| Notifica Inbox | Il fumetto emerge verso 11,05 s. Scompare verso 15,8 s. Il badge resta nella barra. |
| Profilo | Cambio schermata a 18,08 s. Miniature a 18,33 s. I contatori della scena sono statici e le visualizzazioni abbreviate sono troncate al primo decimale. |
| Menu del profilo | Scorrimento da destra da 24,98 s per circa 0,22 s. |
| TikTok Studio | Push intorno a 28,4 s. Prima un loader al centro, poi i loader nelle schede a 30,02 s. Dati a 30,38 s. |
| Analytics account | Push da 42,13 s. Scheletro fino a circa 43,90 s. I valori si completano nei fotogrammi successivi. |
| Analitiche e scorrimento | Overview e sorgenti di traffico, Inspiration, Content, Viewers, Followers. Cambio periodo in Viewers a circa 79,4 s, con attesa prima dei valori aggiornati. |

Il pull-to-refresh è simulato con un’attesa locale di 540 ms. La registrazione mostra soprattutto scorrimento e caricamento progressivo, quindi il refresh del profilo non ha un tempo direttamente misurabile dal riferimento. La velocità del lettore e dei gesti sul dispositivo va confermata con una build Release su iPhone.

## Riferimento visivo

Per profilo, griglia e Studio usare `RPReplay_Final1794612755.mp4`. Fotogrammi di controllo a 19,0 s (profilo), 26,0 s (Studio), 35,6 s (Overview) e 51,5 s (Viewers, Locations). Confrontare le catture a 375 × 667 pt escludendo la barra di registrazione gestita da iOS. Verificare anche il tema scuro.

Nel frame del profilo, la griglia inizia circa a y=302 pt e termina sopra la barra di navigazione a y=618 pt. Il badge Inbox è largo circa 24 pt con due cifre e si sovrappone all'angolo superiore destro dell'icona. Controllare anche il puntino sopra il selettore account, l'avatar anonimo e le due bolle di «Whisper, whisper».
