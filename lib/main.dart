// tk-pietro per Android e iPhone — TecnikGeek (pietrodefilippis.it)
// Il mondo di pietrodefilippis.it in tasca: articoli del blog (anche senza rete), vetrina di plugin, app e programmi,
// notifiche delle novità, modulo per scrivermi e caffè.
// Copyright (C) 2026 Pietro De Filippis (TecnikGeek) — AGPL-3.0-or-later, vedi COPYING
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dati/api.dart';
import 'dati/archivio.dart';
import 'dati/notifiche.dart';
import 'schermate/home.dart';
import 'tema.dart';
import 'tk_licenza.dart';
import 'tk_pro.dart';

/// Errore non gestito dell'ultima volta (file «last_crash.txt», come nelle altre app TK).
String? crashPrecedente;
File? _fileCrash;

void _salvaCrash(Object errore, StackTrace? traccia) {
  try {
    _fileCrash?.writeAsStringSync('tk-pietro\n\n$errore\n\n${traccia ?? ''}');
  } catch (_) {}
}

Future<void> _inizializza(String versione) async {
  final supporto = await getApplicationSupportDirectory();
  try {
    _fileCrash = File('${supporto.path}/last_crash.txt');
    if (_fileCrash!.existsSync()) {
      final t = _fileCrash!.readAsStringSync();
      if (t.trim().isNotEmpty) crashPrecedente = t;
      _fileCrash!.deleteSync();
    }
  } catch (_) {}
  archivio = Archivio(
    cartella: Directory('${supporto.path}/archivio'),
    prefs: await SharedPreferences.getInstance(),
    api: Api(versione: versione),
  )..apri();
  await preparaNotifiche();
}

/// Benvenuto, statistiche (solo col consenso) e invito al caffè: tutte le funzioni sono per tutti.
Future<String> _avviaLicenza() async {
  try {
    final info = await PackageInfo.fromPlatform();
    final lic = Licenza(slug: 'tk-pietro', versione: info.version);
    await lic.carica();
    proTk = ProTk(lic);
    lic.avvia(); // segnale del giorno in sottofondo, SOLO se l'utente ha detto sì alle statistiche
    return info.version;
  } catch (_) {
    proTk = null; // senza memoria niente benvenuto né statistiche: l'app funziona lo stesso
    return '';
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configTk = configPietro;
  registraLicenzaAgpl();
  final versione = await _avviaLicenza();
  FlutterError.onError = (d) {
    FlutterError.presentError(d);
    _salvaCrash(d.exception, d.stack);
  };
  PlatformDispatcher.instance.onError = (e, s) {
    _salvaCrash(e, s);
    return false;
  };
  runApp(AppPietro(avvio: _inizializza(versione)));
}

class AppPietro extends StatelessWidget {
  const AppPietro({super.key, required this.avvio});

  final Future<void> avvio;

  @override
  Widget build(BuildContext context) {
    final base = temaKit();
    return MaterialApp(
      title: 'pietrodefilippis.it',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        scaffoldBackgroundColor: carta,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {TargetPlatform.android: FadeForwardsPageTransitionsBuilder()},
        ),
      ),
      locale: const Locale('it'),
      supportedLocales: const [Locale('it')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: ConAvvio(
        child: FutureBuilder<void>(
          future: avvio,
          builder: (_, s) {
            if (s.hasError) return _ErroreAvvio('${s.error}');
            if (s.connectionState != ConnectionState.done) return const SchermataAvvio();
            return SchermataHome(crash: crashPrecedente);
          },
        ),
      ),
    );
  }
}

class _ErroreAvvio extends StatelessWidget {
  const _ErroreAvvio(this.errore);

  final String errore;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: navy,
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: rosso, size: 56),
            const SizedBox(height: 14),
            const Text(
              'Non riesco ad aprire l\'app',
              style: TextStyle(color: bianco, fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              errore,
              textAlign: TextAlign.center,
              style: const TextStyle(color: grigio300),
            ),
            const SizedBox(height: 14),
            const Text(
              'Scrivi a TecnikGeek con questo messaggio.',
              textAlign: TextAlign.center,
              style: TextStyle(color: grigio400, fontSize: 13),
            ),
          ],
        ),
      ),
    ),
  );
}
