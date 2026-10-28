// Foto delle schermate (caratteri veri) in build/anteprime/, per guardarle senza telefono.
// Con articoli e copertine veri in build/prova/ (articoli.json + img/) se ci sono, altrimenti le copie di test/dati.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tkpietro/dati/api.dart';
import 'package:tkpietro/dati/archivio.dart';
import 'package:tkpietro/schermate/avvio.dart';
import 'package:tkpietro/schermate/comuni.dart';
import 'package:tkpietro/schermate/home.dart';
import 'package:tkpietro/schermate/lettore.dart';
import 'package:tkpietro/schermate/scheda.dart';
import 'package:tkpietro/tema.dart';

import 'caratteri.dart';
import 'dati_test.dart' show sitoFinto;

Future<void> _scatta(WidgetTester t, Widget w, String nome, {Future<void> Function()? prima}) async {
  final k = GlobalKey();

  await t.pumpWidget(
    RepaintBoundary(
      key: k,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: temaKit().copyWith(scaffoldBackgroundColor: carta),
        locale: const Locale('it'),
        supportedLocales: const [Locale('it')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: w,
      ),
    ),
  );
  await t.pump(const Duration(milliseconds: 300));

  await prima?.call();

  // le immagini da file si decodificano solo fuori dal tempo finto
  for (var i = 0; i < 4; i++) {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 400)));
    await t.pump(const Duration(milliseconds: 500));
  }

  await t.runAsync(() async {
    final img = await (k.currentContext!.findRenderObject()! as RenderRepaintBoundary).toImage(pixelRatio: 2);
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    Directory('build/anteprime').createSync(recursive: true);
    File('build/anteprime/$nome.png').writeAsBytesSync(png!.buffer.asUint8List());
  });
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 1));
}

Future<void> _carattere(String famiglia, List<String> file) async {
  final l = FontLoader(famiglia);
  for (final f in file) {
    l.addFont(Future.value(ByteData.view(Uint8List.fromList(File(f).readAsBytesSync()).buffer)));
  }
  await l.load();
}

void main() {
  late Directory cartella;

  setUpAll(() async {
    await caricaCaratteri();
    await _carattere('Fraunces', ['assets/font/Fraunces-SemiBold.ttf', 'assets/font/Fraunces-ExtraBold.ttf']);
    configTk = configPietro;
    SharedPreferences.setMockInitialValues({'invito_notifiche': false});
    PackageInfo.setMockInitialValues(
      appName: 'tk-pietro',
      packageName: 'it.pietrodefilippis.tkpietro',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
    cartella = Directory.systemTemp.createTempSync('tkpietro-foto');
    final veri = File('build/prova/articoli.json');
    archivio = Archivio(
      cartella: cartella,
      prefs: await SharedPreferences.getInstance(),
      api: Api(
        client: sitoFinto(articoli: veri.existsSync() ? veri.readAsStringSync() : null),
        versione: '1.0.0',
      ),
      precarica: (_) async {},
    )..apri();

    await archivio.aggiorna();

    immaginiDiProva = (url) {
      final f = File('build/prova/img/${url.split('/').last}');
      return f.existsSync() ? FileImage(f) : const AssetImage('assets/img/pietro.jpg');
    };
  });

  tearDownAll(() => cartella.deleteSync(recursive: true));

  testWidgets('anteprime', (t) async {
    t.view.physicalSize = const Size(824, 1830);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);

    for (final (i, nome) in [(0, 'inizio'), (1, 'articoli'), (2, 'vetrina'), (3, 'salvati-vuoto'), (4, 'scrivimi')]) {
      schedaAttiva.value = i;
      await _scatta(t, const SchermataHome(), nome);
    }
    // Inizio più in basso: app su Google Play, argomenti, di mestiere
    for (final giu in [700, 1500, 2300, 3100, 3900]) {
      schedaAttiva.value = 0;
      await _scatta(
        t,
        const SchermataHome(),
        'inizio-$giu',
        prima: () async {
          await t.drag(find.byType(CustomScrollView).first, Offset(0, -giu.toDouble()));
          await t.pump(const Duration(milliseconds: 600));
        },
      );
    }
    await t.runAsync(() => archivio.salva(archivio.recenti[1]));
    await t.runAsync(() => archivio.salva(archivio.recenti[3]));
    schedaAttiva.value = 3;
    await _scatta(t, const SchermataHome(), 'salvati');

    await _scatta(t, SchermataLettore(articolo: archivio.recenti.first), 'lettore');
    await _scatta(
      t,
      SchermataLettore(articolo: archivio.recenti.first),
      'lettore-giu',
      prima: () async {
        await t.drag(find.byType(CustomScrollView), const Offset(0, -900));
      },
    );

    final c = archivio.catalogo!;
    final fp = c.plugin.firstWhere((p) => p.tipo == 'free-pro' && p.pro.isNotEmpty);
    await _scatta(
      t,
      Builder(
        builder: (context) {
          WidgetsBinding.instance.addPostFrameCallback((_) => apriSchedaPlugin(context, fp));
          return const Scaffold();
        },
      ),
      'scheda-plugin',
      prima: () => t.pump(const Duration(seconds: 1)),
    );
    await _scatta(
      t,
      Builder(
        builder: (context) {
          WidgetsBinding.instance.addPostFrameCallback((_) => apriSchedaProgramma(context, c.gruppo('app').first));
          return const Scaffold();
        },
      ),
      'scheda-app',
      prima: () => t.pump(const Duration(seconds: 1)),
    );
    await _scatta(
      t,
      Builder(
        builder: (context) {
          WidgetsBinding.instance.addPostFrameCallback((_) => apriInformazioniPietro(context));
          return const Scaffold();
        },
      ),
      'informazioni',
      prima: () => t.pump(const Duration(seconds: 1)),
    );
    await _scatta(t, const AvvioPietro(), 'avvio');
  });
}
