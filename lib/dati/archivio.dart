// Stato dell'app e copia sul telefono di quello che arriva dal sito: articoli recenti, vetrina, categorie, articoli
// aperti (gli ultimi 40) e salvati (con le immagini), così si legge anche senza rete.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart';
import 'modelli.dart';

late Archivio archivio;

/// Scarica un'immagine nella cache (per leggerla poi senza rete).
typedef Precarica = Future<void> Function(String url);

Future<void> _precaricaVera(String url) async {
  try {
    await DefaultCacheManager().downloadFile(url);
  } catch (_) {}
}

class Archivio extends ChangeNotifier {
  Archivio({required this.cartella, required this.prefs, required this.api, Precarica? precarica})
    : _precarica = precarica ?? _precaricaVera;

  final Directory cartella;
  final SharedPreferences prefs;
  final Api api;
  final Precarica _precarica;

  static const _maxAperti = 40;

  List<Articolo> recenti = const [];
  List<Categoria> categorie = const [];
  Catalogo? catalogo;
  List<Articolo> salvati = const [];
  Set<int> letti = {};

  /// Ultimo errore di rete (null = l'ultimo aggiornamento è andato bene).
  String? erroreRete;
  bool aggiornando = false;

  // ───── impostazioni ─────
  double get dimensioneTesto => prefs.getDouble('dimensione_testo') ?? 1.0;
  set dimensioneTesto(double v) {
    prefs.setDouble('dimensione_testo', v.clamp(.85, 1.5));
    notifyListeners();
  }

  bool get letturaScura => prefs.getBool('lettura_scura') ?? false;
  set letturaScura(bool v) {
    prefs.setBool('lettura_scura', v);
    notifyListeners();
  }

  bool get notifiche => prefs.getBool('notifiche') ?? true;
  set notifiche(bool v) {
    prefs.setBool('notifiche', v);
    notifyListeners();
  }

  /// La card «Attiva le notifiche» in home è già stata chiusa o usata?
  bool get invitoNotificheFatto => prefs.getBool('invito_notifiche') ?? false;
  set invitoNotificheFatto(bool v) {
    prefs.setBool('invito_notifiche', v);
    notifyListeners();
  }

  // ───── file ─────
  File _file(String nome) => File('${cartella.path}/$nome');

  dynamic _leggiJson(String nome) {
    try {
      final f = _file(nome);
      if (!f.existsSync()) return null;
      return jsonDecode(f.readAsStringSync());
    } catch (_) {
      return null;
    }
  }

  Future<void> _scriviJson(String nome, Object dati) async {
    try {
      if (!cartella.existsSync()) cartella.createSync(recursive: true);
      final tmp = _file('$nome.tmp');
      await tmp.writeAsString(jsonEncode(dati));
      await tmp.rename(_file(nome).path); // scrittura sicura: mai un file a metà
    } catch (_) {}
  }

  /// Carica la copia sul telefono (istantaneo, anche senza rete).
  void apri() {
    final r = _leggiJson('recenti.json');
    if (r is List) recenti = [for (final a in r) Articolo.daJson((a as Map).cast())];
    final c = _leggiJson('categorie.json');
    if (c is List) categorie = [for (final x in c) Categoria.daJson((x as Map).cast())];
    final v = _leggiJson('catalogo.json');
    if (v is Map) catalogo = Catalogo.daJson(v.cast());
    final s = _leggiJson('salvati.json');
    if (s is List) salvati = [for (final a in s) Articolo.daJson((a as Map).cast())];
    letti = (prefs.getStringList('letti') ?? const []).map(int.parse).toSet();
  }

  /// Aggiorna dal sito articoli recenti, categorie e vetrina. Senza rete resta la copia di prima.
  Future<void> aggiorna() async {
    if (aggiornando) return;
    aggiornando = true;
    notifyListeners();
    try {
      final risultati = await Future.wait([api.articoli(perPagina: 15), api.categorie(), api.catalogoGrezzo()]);
      recenti = risultati[0] as List<Articolo>;
      categorie = risultati[1] as List<Categoria>;
      final grezzo = risultati[2] as Map<String, dynamic>;
      catalogo = Catalogo.daJson(grezzo);
      erroreRete = null;
      await _scriviJson('recenti.json', [for (final a in recenti) a.json()]);
      await _scriviJson('categorie.json', [for (final c in categorie) c.json()]);
      await _scriviJson('catalogo.json', grezzo);
      // le copertine dei recenti in cache: la home resta bella anche senza rete
      for (final a in recenti.take(6)) {
        if (a.immagine.isNotEmpty) _precarica(a.immagine);
      }
    } on ErroreSito catch (e) {
      erroreRete = e.messaggio;
    } catch (e) {
      erroreRete = 'Aggiornamento non riuscito: $e';
    } finally {
      aggiornando = false;
      notifyListeners();
    }
  }

  // ───── articoli ─────

  /// L'articolo intero: dai salvati o dalla copia sul telefono se c'è (e prova ad aggiornarlo), altrimenti dal sito.
  Future<Articolo> articolo(Articolo base) async {
    final locale = salvato(base.id) ?? _articoloLocale(base.id);
    if (locale?.contenuto != null) {
      // aggiornato in sottofondo; intanto si legge quello che c'è
      api.articolo(base.id).then(_ricordaAperto).catchError((_) => base);
      return locale!;
    }
    final a = await api.articolo(base.id);
    await _ricordaAperto(a);
    return a;
  }

  Articolo? _articoloLocale(int id) {
    final j = _leggiJson('articolo-$id.json');
    return j is Map ? Articolo.daJson(j.cast()) : null;
  }

  Future<Articolo> _ricordaAperto(Articolo a) async {
    await _scriviJson('articolo-${a.id}.json', a.json());
    if (salvato(a.id) != null) {
      salvati = [for (final s in salvati) s.id == a.id ? a : s];
      await _scriviJson('salvati.json', [for (final s in salvati) s.json()]);
    }
    _potaAperti();
    return a;
  }

  /// Tiene solo gli ultimi [_maxAperti] articoli aperti (i salvati stanno a parte e non scadono).
  void _potaAperti() {
    try {
      final file =
          cartella.listSync().whereType<File>().where((f) => RegExp(r'articolo-\d+\.json$').hasMatch(f.path)).toList()
            ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      for (final f in file.skip(_maxAperti)) {
        f.deleteSync();
      }
    } catch (_) {}
  }

  void segnaLetto(int id) {
    if (!letti.add(id)) return;
    prefs.setStringList('letti', letti.map((e) => '$e').toList());
    // ogni lettura conta anche nelle statistiche del sito, una volta per articolo
    api.contaLettura(id);
    notifyListeners();
  }

  // ───── salvati ─────

  Articolo? salvato(int id) {
    for (final s in salvati) {
      if (s.id == id) return s;
    }
    return null;
  }

  bool eSalvato(int id) => salvato(id) != null;

  /// Salva l'articolo per leggerlo senza rete: testo, copertina e immagini dentro il testo.
  Future<void> salva(Articolo a) async {
    final intero = a.contenuto != null ? a : await articolo(a);
    salvati = [intero, ...salvati.where((s) => s.id != a.id)];
    notifyListeners();
    await _scriviJson('salvati.json', [for (final s in salvati) s.json()]);
    final immagini = {
      if (intero.copertina.isNotEmpty) intero.copertina,
      if (intero.miniatura.isNotEmpty) intero.miniatura,
      ...immaginiNelTesto(intero.contenuto ?? ''),
    };
    await Future.wait(immagini.map(_precarica));
  }

  Future<void> togli(int id) async {
    salvati = salvati.where((s) => s.id != id).toList();
    notifyListeners();
    await _scriviJson('salvati.json', [for (final s in salvati) s.json()]);
  }

  Future<void> alterna(Articolo a) => eSalvato(a.id) ? togli(a.id) : salva(a);
}

/// Indirizzi delle immagini dentro l'HTML di un articolo.
@visibleForTesting
Set<String> immaginiNelTesto(String html) =>
    RegExp(r'''<img[^>]+src=["']([^"']+)["']''').allMatches(html).map((m) => m.group(1)!).toSet();
