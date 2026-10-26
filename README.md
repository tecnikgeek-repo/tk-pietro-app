# pietrodefilippis.it — app per Android e iPhone

Il mondo di [pietrodefilippis.it](https://pietrodefilippis.it) in tasca: gli articoli del blog (autismo, tecnologia,
scuola, sanità e territorio) da leggere anche senza internet, la vetrina di plugin WordPress, app e programmi con le
installazioni attive, le notifiche degli articoli nuovi e il modulo per scrivermi. Tutte le funzioni sono gratis,
per tutti.

- **Piattaforme:** Android (APK); iPhone in arrivo.
- **Licenza:** software libero sotto [GNU AGPL-3.0](COPYING), fornito così com'è, senza alcuna garanzia.
- **Privacy:** articoli salvati, letti e impostazioni restano sul telefono. Le notifiche nascono da un controllo
  del sito fatto dal telefono circa una volta all'ora: nessun servizio esterno, nessun account. Il modulo Contatti
  manda nome, email e messaggio solo a pietrodefilippis.it. Le statistiche anonime (una volta al giorno: nome,
  versione, sistema e un codice casuale) partono solo se dici sì nel benvenuto o in Informazioni.

## Compilare dal sorgente

Serve [Flutter](https://flutter.dev) (versione indicata in `.github/workflows/android.yml`):

```
flutter pub get
flutter test
flutter build apk --release
```

Senza la variabile `ANDROID_KEYSTORE` l'APK si firma con la chiave di debug di Flutter.

Il carattere Fraunces è sotto [SIL Open Font License](assets/font/OFL.txt). Il nome «pietrodefilippis.it», il logo e la foto
non sono coperti dalla licenza (AGPL sez. 7): una versione modificata deve avere un nome e un'immagine diversi.

© 2026 Pietro De Filippis (TecnikGeek) — [pietrodefilippis.it](https://pietrodefilippis.it)
