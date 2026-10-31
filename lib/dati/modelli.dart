// Dati dell'app: articoli del blog e voci della vetrina, letti dalle API del sito (wp/v2 e pd-app/v1).

String _s(Object? v) => v == null ? '' : '$v';
int _i(Object? v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
List<String> _l(Object? v) => v is List ? v.map((e) => '$e').toList() : const [];

/// Toglie le entità HTML che WordPress lascia nei titoli («l&#8217;AI» → «l’AI»).
String pulisciTesto(String t) {
  const nomi = {
    'amp': '&',
    'quot': '"',
    'apos': "'",
    'lt': '<',
    'gt': '>',
    'nbsp': ' ',
    'hellip': '…',
    'rsquo': '’',
    'lsquo': '‘',
    'ldquo': '“',
    'rdquo': '”',
    'ndash': '–',
    'mdash': '—',
    'laquo': '«',
    'raquo': '»',
    'euro': '€',
  };
  return t.replaceAllMapped(RegExp(r'&(#x[0-9a-fA-F]+|#\d+|[a-zA-Z]+);'), (m) {
    final e = m.group(1)!;
    if (e.startsWith('#x')) return String.fromCharCode(int.parse(e.substring(2), radix: 16));
    if (e.startsWith('#')) return String.fromCharCode(int.parse(e.substring(1)));
    return nomi[e] ?? m.group(0)!;
  });
}

class Categoria {
  const Categoria(this.id, this.nome, [this.conteggio = 0]);

  final int id;
  final String nome;
  final int conteggio;

  factory Categoria.daJson(Map<String, dynamic> j) =>
      Categoria(_i(j['id']), pulisciTesto(_s(j['nome'] ?? j['name'])), _i(j['count'] ?? j['conteggio']));

  Map<String, dynamic> json() => {'id': id, 'nome': nome, 'conteggio': conteggio};
}

class Articolo {
  const Articolo({
    required this.id,
    required this.titolo,
    required this.data,
    required this.link,
    this.letture = 0,
    this.minuti = 1,
    this.copertina = '',
    this.miniatura = '',
    this.categorie = const [],
    this.estratto = '',
    this.contenuto,
  });

  final int id;
  final String titolo;
  final DateTime data;
  final String link;
  final int letture, minuti;
  final String copertina, miniatura;
  final List<Categoria> categorie;
  final String estratto;

  /// HTML dell'articolo: c'è solo quando è stato aperto (o salvato).
  final String? contenuto;

  String get immagine => miniatura.isNotEmpty ? miniatura : copertina;

  /// Dal JSON di wp/v2/posts con il campo pd_app, oppure da quello salvato sul telefono.
  factory Articolo.daJson(Map<String, dynamic> j) {
    final pd = (j['pd_app'] as Map?)?.cast<String, dynamic>() ?? j;
    final titolo = j['title'] is Map ? _s((j['title'] as Map)['rendered']) : _s(j['titolo']);
    final contenuto = j['content'] is Map ? _s((j['content'] as Map)['rendered']) : j['contenuto'] as String?;
    return Articolo(
      id: _i(j['id']),
      titolo: pulisciTesto(titolo),
      data: DateTime.tryParse(_s(j['date'] ?? j['data'])) ?? DateTime(2026),
      link: _s(j['link']),
      letture: _i(pd['letture']),
      minuti: _i(pd['minuti']).clamp(1, 99),
      copertina: _s(pd['copertina']),
      miniatura: _s(pd['miniatura']),
      categorie: [for (final c in (pd['categorie'] as List? ?? const [])) Categoria.daJson((c as Map).cast())],
      estratto: pulisciTesto(_s(pd['estratto'])),
      contenuto: contenuto,
    );
  }

  Map<String, dynamic> json({bool conContenuto = true}) => {
    'id': id,
    'titolo': titolo,
    'data': data.toIso8601String(),
    'link': link,
    'letture': letture,
    'minuti': minuti,
    'copertina': copertina,
    'miniatura': miniatura,
    'categorie': [for (final c in categorie) c.json()],
    'estratto': estratto,
    if (conContenuto && contenuto != null) 'contenuto': contenuto,
  };

  Articolo conContenuto(String html) => Articolo(
    id: id,
    titolo: titolo,
    data: data,
    link: link,
    letture: letture,
    minuti: minuti,
    copertina: copertina,
    miniatura: miniatura,
    categorie: categorie,
    estratto: estratto,
    contenuto: html,
  );
}

/// Plugin o tema WordPress della vetrina.
class Plugin {
  const Plugin({
    required this.slug,
    required this.nome,
    required this.tipo,
    this.emoji = '📦',
    this.categoria = '',
    this.corta = '',
    this.desc = '',
    this.free = const [],
    this.pro = const [],
    this.sblocca = '',
    this.versione = '',
    this.installazioni = 0,
    this.scheda = '',
    this.scarica = '',
    this.contatta = '',
    this.contributo,
    this.tema = false,
  });

  final String slug, nome, tipo, emoji, categoria, corta, desc, sblocca, versione, scheda, scarica, contatta;
  final List<String> free, pro;
  final int installazioni;

  /// Contributo suggerito per il Pro su 1 sito: (annuale, lifetime) in euro.
  final (int, int)? contributo;
  final bool tema;

  /// Colore della scena: i temi hanno il loro.
  String get scena => tema ? 'tema' : tipo;

  factory Plugin.daJson(Map<String, dynamic> j, {bool tema = false}) {
    final c = j['contributo'] as Map?;
    return Plugin(
      slug: _s(j['slug']),
      nome: _s(j['nome']),
      tipo: _s(j['tipo']),
      emoji: _s(j['emoji']).isEmpty ? '📦' : _s(j['emoji']),
      categoria: _s(j['categoria']),
      corta: _s(j['corta']),
      desc: _s(j['desc']),
      free: _l(j['free']),
      pro: _l(j['pro']),
      sblocca: _s(j['sblocca']),
      versione: _s(j['versione']),
      installazioni: _i(j['installazioni']),
      scheda: _s(j['scheda']),
      scarica: _s(j['scarica']),
      contatta: _s(j['contatta']),
      contributo: c == null ? null : (_i(c['annuale']), _i(c['lifetime'])),
      tema: tema,
    );
  }
}

/// Programma per computer, app o gioco della vetrina (software libero).
class Programma {
  const Programma({
    required this.slug,
    required this.nome,
    required this.gruppo,
    this.emoji = '💻',
    this.corta = '',
    this.cosa = '',
    this.punti = const [],
    this.piattaforme = const [],
    this.versione = '',
    this.installazioni = 0,
    this.codice = '',
    this.scarica = const {},
    this.play = '',
    this.ios = '',
  });

  final String slug, nome, gruppo, emoji, corta, cosa, versione, codice;

  /// Link di Google Play (vuoto finché l'app non è pubblicata lì) e dell'App Store.
  final String play, ios;
  final List<String> punti, piattaforme;
  final int installazioni;

  /// windows, mac, macIntel, linux, android, link → indirizzo del sito che porta sempre all'ultima versione.
  final Map<String, String> scarica;

  /// Piattaforme già disponibili e quelle in arrivo («iPhone · prossimamente»).
  List<String> get disponibili => piattaforme.where((p) => !p.contains('prossimamente')).toList();
  List<String> get inArrivo =>
      piattaforme.where((p) => p.contains('prossimamente')).map((p) => p.split('·').first.trim()).toList();

  factory Programma.daJson(Map<String, dynamic> j) => Programma(
    slug: _s(j['slug']),
    nome: _s(j['nome']),
    gruppo: _s(j['gruppo']),
    emoji: _s(j['emoji']).isEmpty ? '💻' : _s(j['emoji']),
    corta: _s(j['corta']),
    cosa: _s(j['cosa']),
    punti: _l(j['punti']),
    piattaforme: _l(j['piattaforme']),
    versione: _s(j['versione']),
    installazioni: _i(j['installazioni']),
    codice: _s(j['codice']),
    scarica: (j['scarica'] is Map) ? (j['scarica'] as Map).map((k, v) => MapEntry('$k', '$v')) : const {},
    play: _s(j['play']),
    ios: _s(j['ios']),
  );
}

/// Uno dei tre argomenti del blog (come nella home del sito): quanti articoli e l'ultimo uscito.
class Argomento {
  const Argomento({
    required this.chiave,
    required this.titolo,
    this.descrizione = '',
    this.categoria = 0,
    this.totale = 0,
    this.ultimoTitolo = '',
    this.ultimaImmagine = '',
  });

  final String chiave, titolo, descrizione, ultimoTitolo, ultimaImmagine;
  final int categoria, totale;

  factory Argomento.daJson(Map<String, dynamic> j) {
    final u = (j['ultimo'] is Map) ? (j['ultimo'] as Map).cast<String, dynamic>() : const <String, dynamic>{};
    return Argomento(
      chiave: _s(j['chiave']),
      titolo: _s(j['titolo']),
      descrizione: _s(j['descrizione']),
      categoria: _i(j['categoria']),
      totale: _i(j['totale']),
      ultimoTitolo: _s(u['titolo']),
      ultimaImmagine: _s(u['immagine']),
    );
  }
}

class Catalogo {
  const Catalogo({
    required this.plugin,
    required this.temi,
    required this.software,
    this.dona = 'https://pietrodefilippis.it/donazione/',
    this.numeri = const {},
    this.aggiornato,
    this.argomenti = const [],
  });

  final List<Plugin> plugin, temi;
  final List<Programma> software;
  final List<Argomento> argomenti;
  final String dona;
  final Map<String, int> numeri;
  final DateTime? aggiornato;

  List<Programma> gruppo(String g) => software.where((s) => s.gruppo == g).toList();

  /// Installazioni attive in tutto (plugin, temi, programmi e app).
  int get installazioniTotali =>
      [...plugin, ...temi].fold(0, (a, p) => a + p.installazioni) + software.fold(0, (a, s) => a + s.installazioni);

  factory Catalogo.daJson(Map<String, dynamic> j) => Catalogo(
    plugin: [for (final p in (j['plugin'] as List? ?? const [])) Plugin.daJson((p as Map).cast())],
    temi: [for (final p in (j['temi'] as List? ?? const [])) Plugin.daJson((p as Map).cast(), tema: true)],
    software: [for (final s in (j['software'] as List? ?? const [])) Programma.daJson((s as Map).cast())],
    dona: _s(j['dona']).isEmpty ? 'https://pietrodefilippis.it/donazione/' : _s(j['dona']),
    numeri: (j['numeri'] as Map? ?? const {}).map((k, v) => MapEntry('$k', _i(v))),
    aggiornato: j['aggiornato'] == null ? null : DateTime.fromMillisecondsSinceEpoch(_i(j['aggiornato']) * 1000),
    argomenti: [for (final a in (j['argomenti'] as List? ?? const [])) Argomento.daJson((a as Map).cast())],
  );
}

// ───────────────────────── tk-ai ─────────────────────────

/// Una pagina del sito usata da tk-ai per rispondere (le schede «Dove l'ho letto»).
class FonteAi {
  const FonteAi({required this.titolo, required this.url, this.tipo = '', this.immagine = '', this.estratto = ''});

  final String titolo, url, tipo, immagine, estratto;

  factory FonteAi.daJson(Map<String, dynamic> j) => FonteAi(
    titolo: '${j['titolo'] ?? ''}',
    url: '${j['url'] ?? ''}',
    tipo: '${j['tipo'] ?? ''}',
    immagine: '${j['immagine'] ?? ''}',
    estratto: '${j['estratto'] ?? ''}',
  );
}

/// Risposta della chat: [ok] falso = risposta di cortesia (motore spento, limite…), con la pagina [contatti].
class RispostaAi {
  const RispostaAi({
    required this.ok,
    required this.testo,
    this.fonti = const [],
    this.contatti = '',
    this.trascrizione = '',
  });

  final bool ok;
  final String testo, contatti, trascrizione;
  final List<FonteAi> fonti;

  factory RispostaAi.daJson(Map<String, dynamic> j) => RispostaAi(
    ok: j['ok'] == true,
    testo: '${j['risposta'] ?? ''}',
    contatti: '${j['contatti'] ?? ''}',
    trascrizione: '${j['trascrizione'] ?? ''}',
    fonti: [
      for (final f in (j['fonti'] is List ? j['fonti'] as List : const []))
        if (f is Map && f['url'] != null) FonteAi.daJson(f.cast()),
    ],
  );
}
