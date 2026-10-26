// Lettura dei dati veri del sito (copie in test/dati/), formati, archivio senza rete e notifiche.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tkpietro/dati/api.dart';
import 'package:tkpietro/dati/archivio.dart';
import 'package:tkpietro/dati/formati.dart';
import 'package:tkpietro/dati/modelli.dart';
import 'package:tkpietro/dati/notifiche.dart';
import 'package:tkpietro/schermate/ascolta.dart';
import 'package:tkpietro/schermate/lettore.dart' show preparaHtml;

String dato(String nome) => File('test/dati/$nome').readAsStringSync();

/// Sito finto: risponde con le copie vere; [articoli] sostituisce l'elenco.
MockClient sitoFinto({String? articoli, String? catalogo, void Function(http.Request)? vede}) => MockClient((r) async {
  vede?.call(r);
  final p = r.url.path;
  final h = {'content-type': 'application/json; charset=utf-8'};
  if (p.endsWith('/posts')) return http.Response.bytes(utf8.encode(articoli ?? dato('articoli.json')), 200, headers: h);
  if (p.contains('/posts/')) return http.Response.bytes(utf8.encode(dato('articolo.json')), 200, headers: h);
  if (p.endsWith('/categories')) {
    return http.Response.bytes(
      utf8.encode(
        '[{"id":12,"name":"Autismo","slug":"autismo","count":22},{"id":369,"name":"Blog","slug":"blog","count":1}]',
      ),
      200,
      headers: h,
    );
  }
  if (p.endsWith('/catalogo')) {
    return http.Response.bytes(utf8.encode(catalogo ?? dato('catalogo.json')), 200, headers: h);
  }
  if (p.endsWith('/contatto')) {
    final b = Uri.splitQueryString(r.body);
    if ((b['messaggio'] ?? '').length < 10) {
      return http.Response.bytes(utf8.encode('{"message":"Il messaggio è troppo corto."}'), 400, headers: h);
    }
    return http.Response('{"ok":true}', 200, headers: h);
  }
  return http.Response('{}', 200, headers: h);
});

void main() {
  test('catalogo vero', () {
    final c = Catalogo.daJson(jsonDecode(dato('catalogo.json')) as Map<String, dynamic>);
    expect(c.plugin.length, greaterThan(50));
    expect(c.gruppo('app'), isNotEmpty);
    expect(c.gruppo('software'), isNotEmpty);
    final fp = c.plugin.firstWhere((p) => p.tipo == 'free-pro');
    expect(fp.contributo, isNotNull);
    expect(fp.contributo!.$2, greaterThan(fp.contributo!.$1));
    expect(fp.scarica, startsWith('https://pietrodefilippis.it/scarica/'));
    final app = c.gruppo('app').first;
    expect(app.scarica['android'], contains('/scarica-app/'));
    expect(app.inArrivo, contains('iPhone'));
    expect(c.installazioniTotali, greaterThan(0));
  });

  test('articoli veri', () {
    final l = [for (final a in jsonDecode(dato('articoli.json')) as List) Articolo.daJson((a as Map).cast())];
    expect(l, hasLength(5));
    expect(l.first.titolo, isNot(contains('&#')));
    expect(l.first.miniatura, startsWith('https://'));
    final a = Articolo.daJson(jsonDecode(dato('articolo.json')) as Map<String, dynamic>);
    expect(a.contenuto, contains('<p>'));
    // salvato e riletto: uguale
    final b = Articolo.daJson(jsonDecode(jsonEncode(a.json())) as Map<String, dynamic>);
    expect([b.id, b.titolo, b.contenuto, b.categorie.length], [a.id, a.titolo, a.contenuto, a.categorie.length]);
  });

  test('testo e formati', () {
    expect(pulisciTesto('l&#8217;AI &amp; il 3&#x2F;4 &hellip;'), 'l’AI & il 3/4 …');
    expect(numero(1234567), '1.234.567');
    expect(numero(12), '12');
    final ora = DateTime(2026, 10, 26, 12);
    expect(tempoFa(DateTime(2026, 10, 26, 11, 58), ora: ora), '2 minuti fa');
    expect(tempoFa(DateTime(2026, 10, 26, 9), ora: ora), '3 ore fa');
    expect(tempoFa(DateTime(2026, 10, 25, 9), ora: ora), 'ieri');
    expect(tempoFa(DateTime(2026, 10, 22, 9), ora: ora), '4 giorni fa');
    expect(tempoFa(DateTime(2026, 9, 2), ora: ora), '2 settembre 2026');
    expect(
      preparaHtml('<p><strong>LA NULLITÀ ASSOLUTA</strong></p><p>testo <strong>forte</strong></p><p>&nbsp;</p>'),
      '<h3 class="pd-sub">LA NULLITÀ ASSOLUTA</h3><p>testo <strong>forte</strong></p>',
    );
    expect(immaginiNelTesto('<p><img class="x" src="https://a/b.jpg"> <img src=\'https://c/d.png\'></p>'), {
      'https://a/b.jpg',
      'https://c/d.png',
    });
  });

  group('archivio', () {
    late Directory cartella;
    setUp(() {
      cartella = Directory.systemTemp.createTempSync('tkpietro');
      SharedPreferences.setMockInitialValues({});
    });
    tearDown(() => cartella.deleteSync(recursive: true));

    Future<Archivio> nuovo(http.Client c, List<String> scaricate) async => Archivio(
      cartella: cartella,
      prefs: await SharedPreferences.getInstance(),
      api: Api(client: c, versione: 'prova'),
      precarica: (u) async => scaricate.add(u),
    )..apri();

    test('aggiorna, poi senza rete resta la copia', () async {
      final scaricate = <String>[];
      final a = await nuovo(sitoFinto(), scaricate);
      await a.aggiorna();
      expect(a.erroreRete, isNull);
      expect(a.recenti, hasLength(5));
      expect(a.categorie.map((c) => c.nome), ['Autismo']); // «Blog» escluso
      expect(a.catalogo, isNotNull);
      expect(scaricate, isNotEmpty); // copertine in cache

      final offline = await nuovo(MockClient((_) async => throw const SocketException('niente rete')), []);
      expect(offline.recenti, hasLength(5));
      expect(offline.catalogo!.plugin, isNotEmpty);
      await offline.aggiorna();
      expect(offline.erroreRete, contains('connessione'));
      expect(offline.recenti, hasLength(5));
    });

    test('salvati: testo e immagini per leggere senza rete', () async {
      final scaricate = <String>[];
      final a = await nuovo(sitoFinto(), scaricate);
      await a.aggiorna();
      await a.salva(a.recenti.first);
      expect(a.eSalvato(a.recenti.first.id), isTrue);
      expect(a.salvati.first.contenuto, isNotNull);
      expect(scaricate, contains(a.salvati.first.copertina));

      final offline = await nuovo(MockClient((_) async => throw const SocketException('niente rete')), []);
      final letto = await offline.articolo(offline.recenti.first);
      expect(letto.contenuto, contains('<p>'));
      await offline.togli(letto.id);
      expect(offline.salvati, isEmpty);
    });

    test('lettura contata una volta', () async {
      var colpi = 0;
      final a = await nuovo(sitoFinto(vede: (r) => r.url.path.endsWith('/hit') ? colpi++ : null), []);
      a.segnaLetto(5);
      a.segnaLetto(5);
      await Future<void>.delayed(Duration.zero);
      expect(colpi, 1);
      expect(a.letti, {5});
    });
  });

  test('messaggio: errore del sito mostrato così com\'è', () async {
    final api = Api(client: sitoFinto(), versione: 'prova');
    await api.inviaMessaggio(
      nome: 'Mario',
      email: 'm@x.it',
      argomento: 'Altro',
      messaggio: 'Un messaggio abbastanza lungo',
    );
    expect(
      () => api.inviaMessaggio(nome: 'Mario', email: 'm@x.it', argomento: 'Altro', messaggio: 'corto'),
      throwsA(isA<ErroreSito>().having((e) => e.messaggio, 'messaggio', 'Il messaggio è troppo corto.')),
    );
  });

  test('notifiche: niente arretrati la prima volta, poi solo le novità', () async {
    SharedPreferences.setMockInitialValues({});
    final p = await SharedPreferences.getInstance();
    expect(await cercaNovita(Api(client: sitoFinto()), p), isEmpty);

    final articoli = jsonDecode(dato('articoli.json')) as List;
    final nuovo = Map<String, dynamic>.from(articoli.first as Map)
      ..['id'] = 99999
      ..['title'] = {'rendered': 'Articolo appena uscito'};
    final catalogo = jsonDecode(dato('catalogo.json')) as Map<String, dynamic>;
    (catalogo['software'] as List).add({'slug': 'tk-nuova', 'nome': 'tk-nuova', 'gruppo': 'app'});
    final n = await cercaNovita(
      Api(
        client: sitoFinto(articoli: jsonEncode([nuovo, ...articoli]), catalogo: jsonEncode(catalogo)),
      ),
      p,
    );
    expect(n.map((x) => x.titolo), ['Nuovo articolo', 'Novità in vetrina']);
    expect(n.first.testo, 'Articolo appena uscito');
    expect(n.first.apri, 'articolo:99999');
    expect(n.last.testo, contains('tk-nuova'));
    // al giro dopo non le ripete
    expect(
      await cercaNovita(
        Api(
          client: sitoFinto(articoli: jsonEncode([nuovo, ...articoli]), catalogo: jsonEncode(catalogo)),
        ),
        p,
      ),
      isEmpty,
    );
  });

  test('ascolta: testo pulito a pezzi sulle frasi', () {
    final a = Articolo.daJson(jsonDecode(dato('articolo.json')) as Map<String, dynamic>);
    final p = pezziDaLeggere(a.titolo, a.contenuto!);
    expect(p.first, startsWith('35 milioni di euro'));
    expect(p.every((x) => x.length <= 400 || !x.contains('. ')), isTrue);
    expect(p.join(' '), isNot(contains('<')));
    expect(p.join(' '), isNot(contains('&#')));
    expect(p.join(' '), contains('l’AI Act'));
  });
}
