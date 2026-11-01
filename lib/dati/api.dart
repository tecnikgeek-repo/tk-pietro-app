// Collegamento a pietrodefilippis.it: articoli (wp/v2 + campo pd_app), vetrina e messaggi (pd-app/v1, mu-plugin
// pd-app.php sul sito), letture (tk-post-views).
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../schermate/aspetto_ai.dart';
import 'modelli.dart';

const sito = 'https://pietrodefilippis.it';
const _campiLista = 'id,date,link,title,pd_app';

/// Errore da mostrare così com'è all'utente.
class ErroreSito implements Exception {
  const ErroreSito(this.messaggio);
  final String messaggio;
  @override
  String toString() => messaggio;
}

class Api {
  Api({http.Client? client, this.versione = ''}) : _c = client ?? http.Client();

  final http.Client _c;
  final String versione;

  Map<String, String> get _intestazioni => {
    'User-Agent': 'tk-pietro/$versione (android)',
    'Accept': 'application/json',
  };

  Future<dynamic> _leggi(String percorso, [Map<String, String>? parametri]) async {
    final u = Uri.parse('$sito$percorso').replace(queryParameters: parametri);
    final http.Response r;
    try {
      r = await _c.get(u, headers: _intestazioni).timeout(const Duration(seconds: 20));
    } catch (_) {
      throw const ErroreSito('Non riesco a raggiungere il sito: controlla la connessione.');
    }
    if (r.statusCode == 400 && percorso.contains('/posts')) return const []; // pagina oltre l'ultima
    if (r.statusCode != 200) throw ErroreSito('Il sito ha risposto ${r.statusCode}: riprova tra poco.');
    return jsonDecode(utf8.decode(r.bodyBytes));
  }

  /// Una pagina di articoli, i più recenti prima. [categoria] e [cerca] facoltativi.
  Future<List<Articolo>> articoli({int pagina = 1, int perPagina = 12, int? categoria, String? cerca}) async {
    final j = await _leggi('/wp-json/wp/v2/posts', {
      'per_page': '$perPagina',
      'page': '$pagina',
      '_fields': _campiLista,
      if (categoria != null) 'categories': '$categoria',
      if (cerca != null && cerca.trim().isNotEmpty) 'search': cerca.trim(),
    });
    return [for (final a in j as List) Articolo.daJson((a as Map).cast())];
  }

  /// Un articolo intero, col testo.
  Future<Articolo> articolo(int id) async {
    final j = await _leggi('/wp-json/wp/v2/posts/$id', {'_fields': '$_campiLista,content'});
    return Articolo.daJson((j as Map).cast());
  }

  Future<List<Categoria>> categorie() async {
    final j = await _leggi('/wp-json/wp/v2/categories', {
      'per_page': '50',
      'hide_empty': '1',
      '_fields': 'id,name,slug,count',
    });
    return [
      for (final c in j as List)
        if (!const {'blog', 'senza-categoria'}.contains((c as Map)['slug'])) Categoria.daJson(c.cast()),
    ]..sort((a, b) => b.conteggio.compareTo(a.conteggio));
  }

  /// Vetrina completa: plugin, temi, programmi e app.
  Future<Map<String, dynamic>> catalogoGrezzo() async =>
      ((await _leggi('/wp-json/pd-app/v1/catalogo')) as Map).cast<String, dynamic>();

  /// Conta la lettura nelle statistiche del sito (come una visita alla pagina). Gli errori non contano.
  Future<void> contaLettura(int id) async {
    try {
      await _c
          .post(
            Uri.parse('$sito/wp-json/tk-post-views/v1/hit'),
            headers: _intestazioni,
            body: {'id': '$id', 'ref': 'android-app://it.pietrodefilippis.tkpietro'},
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  // ───────────────────────── tk-ai: la chat con l'intelligenza artificiale del sito ─────────────────────────

  String? _nonceAi;

  /// Versione del motore che risponde, come la dà il sito insieme al nonce (vuota finché non si sa).
  String versioneAi = '';

  /// Le domande suggerite: le dà il sito insieme al nonce, e quante mostrarne.
  List<String> suggeriteAi = const [];
  int visteAi = 5;

  /// Nonce della chat (lo stesso che il sito dà alle sue pagine), chiesto una volta e rinnovato se scade.
  Future<String> _nonce({bool nuovo = false}) async {
    if (_nonceAi != null && !nuovo) return _nonceAi!;
    final j = await _leggi('/wp-json/tk-ai/v1/nonce');
    _nonceAi = (j as Map)['nonce'] as String? ?? '';
    versioneAi = j['versione'] as String? ?? '';
    if (j['suggerite'] is List) suggeriteAi = [for (final x in j['suggerite'] as List) '$x'];
    if (j['viste'] is int) visteAi = j['viste'] as int;
    if (j['aspetto'] is Map) aspettoAi.value = AspettoAi.daJson(j['aspetto'] as Map);
    return _nonceAi!;
  }

  /// La versione del motore per la testata della chat: se il sito non risponde, niente numero e nessun errore.
  Future<String> chiediVersioneAi() async {
    try {
      await _nonce();
    } catch (_) {}
    return versioneAi;
  }

  /// Segnala una risposta al sito; false se non è arrivata.
  Future<bool> segnalaAi(String domanda, String risposta, String motivo) async {
    final corpo = jsonEncode({'domanda': domanda, 'risposta': risposta, 'motivo': motivo});
    Future<http.Response> manda(String nonce) => _c
        .post(
          Uri.parse('$sito/wp-json/tk-ai/v1/segnala'),
          headers: {..._intestazioni, 'Content-Type': 'application/json', 'X-WP-Nonce': nonce},
          body: corpo,
        )
        .timeout(const Duration(seconds: 20));
    try {
      var r = await manda(await _nonce());
      if (r.statusCode == 403) r = await manda(await _nonce(nuovo: true));
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Una domanda a tk-ai: [messaggi] sono gli ultimi della conversazione ({ruolo: utente|ai, testo}); [foto] è un
  /// JPEG e [vocale] un WAV 16 kHz, in base64. Il sito cerca nelle sue pagine e chiede al motore tk-ai.
  /// [suPezzo] riceve le parole man mano (null = si ricomincia: il PC si è fermato e risponde il box), [suIntanto] i
  /// messaggi da mostrare se tarda. Se il sito risponde tutto insieme funziona lo stesso, solo senza parole man mano.
  Future<RispostaAi> chiediAi(
    List<Map<String, String>> messaggi, {
    String? foto,
    String? vocale,
    void Function(String?)? suPezzo,
    void Function(List<String>)? suIntanto,
  }) async {
    final corpo = jsonEncode({'messaggi': messaggi, 'foto': ?foto, 'vocale': ?vocale, 'flusso': true});
    Future<http.StreamedResponse> manda(String nonce) => _c
        .send(
          http.Request('POST', Uri.parse('$sito/wp-json/tk-ai/v1/chat'))
            ..headers.addAll({..._intestazioni, 'Content-Type': 'application/json', 'X-WP-Nonce': nonce})
            ..body = corpo,
        )
        .timeout(const Duration(seconds: 200));
    const persa = ErroreSito('Non riesco a raggiungere il sito: controlla la connessione.');
    http.StreamedResponse r;
    try {
      r = await manda(await _nonce());
      if (r.statusCode == 403) {
        await r.stream.drain<void>();
        r = await manda(await _nonce(nuovo: true)); // nonce scaduto: se ne chiede uno nuovo
      }
    } on ErroreSito {
      rethrow;
    } catch (_) {
      throw persa;
    }
    if ((r.headers['content-type'] ?? '').contains('ndjson')) {
      Map? finale;
      try {
        final righe = r.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .timeout(const Duration(seconds: 200));
        await for (final riga in righe) {
          if (riga.isEmpty) continue;
          final d = jsonDecode(riga);
          if (d is! Map) continue;
          if (d['pezzo'] is String) {
            suPezzo?.call(d['pezzo'] as String);
          } else if (d['azzera'] == true) {
            suPezzo?.call(null);
          } else if (d['intanto'] is List) {
            suIntanto?.call([for (final x in d['intanto'] as List) '$x']);
          } else if (d['fine'] == true && d['dati'] is Map) {
            finale = d['dati'] as Map;
          }
        }
      } catch (_) {
        throw persa;
      }
      if (finale == null) throw persa;
      return RispostaAi.daJson(finale.cast<String, dynamic>());
    }
    try {
      final tutta = await http.Response.fromStream(r);
      return RispostaAi.daJson((jsonDecode(utf8.decode(tutta.bodyBytes)) as Map).cast<String, dynamic>());
    } catch (_) {
      throw ErroreSito('Il sito ha risposto ${r.statusCode}: riprova tra poco.');
    }
  }

  /// Manda un messaggio dal modulo Contatti: finisce nei «Messaggi» del sito e arriva per email.
  Future<void> inviaMessaggio({
    required String nome,
    required String email,
    required String argomento,
    required String messaggio,
    String telefono = '',
  }) async {
    final http.Response r;
    try {
      r = await _c
          .post(
            Uri.parse('$sito/wp-json/pd-app/v1/contatto'),
            headers: _intestazioni,
            body: {
              'nome': nome,
              'email': email,
              'telefono': telefono,
              'argomento': argomento,
              'messaggio': messaggio,
              'versione': versione,
              'sito': '', // trappola per i robot: vuota
            },
          )
          .timeout(const Duration(seconds: 25));
    } catch (_) {
      throw const ErroreSito('Messaggio non inviato: controlla la connessione e riprova.');
    }
    if (r.statusCode == 200) return;
    String testo = 'Messaggio non inviato (errore ${r.statusCode}).';
    try {
      final j = jsonDecode(utf8.decode(r.bodyBytes));
      if (j is Map && j['message'] is String) testo = j['message'] as String;
    } catch (_) {}
    throw ErroreSito(testo);
  }
}
