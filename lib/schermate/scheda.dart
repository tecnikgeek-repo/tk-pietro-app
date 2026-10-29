// Scheda completa di un plugin, tema, programma o app: entra girando come le card del sito. Cosa fa, cosa c'è gratis
// e cosa col Pro, contributo (nota già pronta da incollare su PayPal), download per ogni sistema, codice sorgente.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../dati/archivio.dart';
import '../dati/formati.dart';
import '../dati/modelli.dart';
import '../tema.dart';
import 'comuni.dart';
import 'contatti.dart';
import 'home.dart';
import 'vetrina.dart';

Route<void> _gira(Widget pagina) => PageRouteBuilder<void>(
  transitionDuration: const Duration(milliseconds: 560),
  reverseTransitionDuration: const Duration(milliseconds: 380),
  pageBuilder: (_, _, _) => pagina,
  transitionsBuilder: (_, anim, _, figlio) {
    final c = CurvedAnimation(parent: anim, curve: Curves.easeOutBack, reverseCurve: Curves.easeInCubic);
    return AnimatedBuilder(
      animation: c,
      builder: (_, f) => Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, .0012)
          ..rotateY((1 - c.value) * math.pi / 2.6),
        child: Opacity(opacity: anim.value.clamp(0, 1), child: f),
      ),
      child: figlio,
    );
  },
);

void apriSchedaPlugin(BuildContext context, Plugin p) => Navigator.of(context).push(_gira(_SchedaPlugin(p)));
void apriSchedaProgramma(BuildContext context, Programma s) => Navigator.of(context).push(_gira(_SchedaProgramma(s)));

/// Porta alla scheda «Scrivimi» con argomento e inizio del messaggio già scritti.
void scrivimiDi(BuildContext context, String argomento, String messaggio) {
  bozzaContatto.value = (argomento, messaggio);
  Navigator.of(context).popUntil((r) => r.isFirst);
  schedaAttiva.value = schedaScrivimi;
}

// ───────────────────────── struttura comune ─────────────────────────

class _Pagina extends StatelessWidget {
  const _Pagina({
    required this.emoji,
    required this.nome,
    required this.scena,
    required this.pillola,
    required this.dati,
    required this.corpo,
    this.azioni = const [],
  });

  final String emoji, nome, scena, pillola;
  final List<(String, String, bool)> dati; // valore, etichetta, vivo
  final List<Widget> corpo;
  final List<Widget> azioni;

  @override
  Widget build(BuildContext context) {
    final (c1, c2) = coloriScena(scena);
    final cima = MediaQuery.of(context).padding.top;
    final basso = MediaQuery.of(context).padding.bottom;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: carta,
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(
                height: cima + 200,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: ClipRRect(borderRadius: BorderRadius.zero, child: ScenaAnimata(c1, c2)),
                    ),
                    Positioned(
                      top: cima + 8,
                      left: 8,
                      child: AzioneTk(Icons.arrow_back_rounded, 'Indietro', () => Navigator.of(context).pop()),
                    ),
                    Positioned(
                      top: cima + 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                        decoration: BoxDecoration(color: bianco, borderRadius: BorderRadius.circular(20)),
                        child: Text(
                          pillola.toUpperCase(),
                          style: TextStyle(color: c2, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: .6),
                        ),
                      ),
                    ),
                    Positioned(left: 20, bottom: -44, child: IconaFluttuante(emoji, lato: 96, colore: c2)),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 58, 20, 24 + basso + (azioni.isEmpty ? 0 : 76)),
              sliver: SliverList.list(
                children: [
                  Text(nome, style: stileTitolo(30)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      for (var i = 0; i < dati.length; i++) ...[
                        if (i > 0) const SizedBox(width: 10),
                        Expanded(child: _Dato(dati[i].$1, dati[i].$2, vivo: dati[i].$3)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...corpo,
                ],
              ),
            ),
          ],
        ),
        bottomSheet: azioni.isEmpty
            ? null
            : Container(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + basso),
                decoration: const BoxDecoration(
                  color: bianco,
                  boxShadow: [BoxShadow(color: Color(0x1A0B1424), blurRadius: 20, offset: Offset(0, -4))],
                ),
                child: Row(
                  children: [
                    for (var i = 0; i < azioni.length; i++) ...[
                      if (i > 0) const SizedBox(width: 10),
                      Expanded(child: azioni[i]),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato(this.valore, this.etichetta, {this.vivo = false});

  final String valore, etichetta;
  final bool vivo;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
    decoration: BoxDecoration(
      color: bianco,
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [BoxShadow(color: Color(0x0C0B1424), blurRadius: 10, offset: Offset(0, 3))],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (vivo) const PuntinoVivo(lato: 6),
            Flexible(
              child: Text(
                valore,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: inchiostro, fontSize: 15.5, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          etichetta,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: grigio500, fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

Widget _sezione(String titolo) => Padding(
  padding: const EdgeInsets.only(top: 22, bottom: 10),
  child: Text(titolo, style: stileTitolo(21)),
);

Widget _paragrafo(String t) => Text(
  t,
  style: const TextStyle(color: testoPieno, fontSize: 15.5, height: 1.55, fontWeight: FontWeight.w400),
);

class _Elenco extends StatelessWidget {
  const _Elenco(this.voci, {required this.icona, required this.colore, this.titolo, this.fondo = bianco});

  final List<String> voci;
  final IconData icona;
  final Color colore, fondo;
  final String? titolo;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 12),
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
    decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(20)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (titolo != null) ...[TitoloSezione(titolo!, colore: colore), const SizedBox(height: 8)],
        for (final v in voci)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 1),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(color: colore.withValues(alpha: .14), shape: BoxShape.circle),
                  child: Icon(icona, size: 13, color: colore),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    v,
                    style: const TextStyle(color: testoPieno, fontSize: 14, height: 1.4, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

// ───────────────────────── plugin e temi ─────────────────────────

class _SchedaPlugin extends StatelessWidget {
  const _SchedaPlugin(this.p);

  final Plugin p;

  @override
  Widget build(BuildContext context) {
    final cosa = p.tema ? 'tema' : 'plugin';
    final soloPro = p.tipo == 'solo-pro';
    return _Pagina(
      emoji: p.emoji,
      nome: p.nome,
      scena: p.scena,
      pillola: etichettaTipo(p.tipo),
      dati: [
        if (p.installazioni > 0) (numero(p.installazioni), 'installazioni attive', true),
        if (p.versione.isNotEmpty) ('v${p.versione}', 'versione', false),
        if (p.categoria.isNotEmpty && !p.tema) (p.categoria, 'categoria', false),
        if (p.tema) ('WordPress', 'tema', false),
      ].take(3).toList(),
      corpo: [
        _sezione('Cosa fa'),
        _paragrafo(p.desc.isNotEmpty ? p.desc : p.corta),
        if (p.free.isNotEmpty)
          _Elenco(
            p.free,
            titolo: soloPro ? 'Cosa fa' : 'Gratis, per sempre',
            icona: Icons.check_rounded,
            colore: const Color(0xFF16A34A),
          ),
        if (p.pro.isNotEmpty)
          _Elenco(p.pro, titolo: 'Con il Pro', icona: Icons.star_rounded, colore: accentoScuro, fondo: cielo),
        if (p.sblocca.isNotEmpty) ...[const SizedBox(height: 12), _paragrafo(p.sblocca)],
        if (p.contributo != null && !soloPro) _Contributo(p),
        if (soloPro) ...[
          _sezione('Ti interessa?'),
          _paragrafo('Questo $cosa lo preparo su misura: scrivimi cosa ti serve e ti spiego come lavorarci insieme.'),
        ],
        _sezione('Come si installa'),
        _Passi([
          'Scarica lo ZIP qui sotto.',
          p.tema
              ? 'Nel tuo WordPress vai su Aspetto → Temi → Aggiungi nuovo → Carica tema.'
              : 'Nel tuo WordPress vai su Plugin → Aggiungi nuovo → Carica plugin.',
          'Scegli il file, installa e attiva: lo trovi nel menu a sinistra.',
        ]),
      ],
      azioni: [
        if (p.scarica.isNotEmpty)
          BottoneTk(testo: 'Scarica gratis', icona: Icons.download_rounded, onTap: () => apriLink(context, p.scarica))
        else
          BottoneTk(
            testo: 'Contattami',
            icona: Icons.mail_rounded,
            onTap: () =>
                scrivimiDi(context, 'Un plugin o il suo Pro', 'Ciao Pietro, mi interessa ${p.nome} per il mio sito: '),
          ),
        if (p.scheda.isNotEmpty)
          BottoneTk(
            testo: 'Sul sito',
            icona: Icons.open_in_new_rounded,
            chiaro: true,
            onTap: () => apriLink(context, p.scheda),
          ),
      ],
    );
  }
}

class _Passi extends StatelessWidget {
  const _Passi(this.passi);

  final List<String> passi;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var i = 0; i < passi.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: inchiostro, shape: BoxShape.circle),
                child: Text(
                  '${i + 1}',
                  style: const TextStyle(color: sole, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(passi[i], style: const TextStyle(color: testoPieno, fontSize: 14.5, height: 1.4)),
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

/// Contributo per il Pro: Annuale o Lifetime, poi la finestra con la nota da incollare su PayPal.
class _Contributo extends StatefulWidget {
  const _Contributo(this.p);

  final Plugin p;

  @override
  State<_Contributo> createState() => _ContributoState();
}

class _ContributoState extends State<_Contributo> {
  bool _lifetime = false;

  int get _importo => _lifetime ? widget.p.contributo!.$2 : widget.p.contributo!.$1;

  Future<void> _sblocca() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final sito = TextEditingController(text: prefs.getString('mio_sito') ?? '');
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: bianco,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (d) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.of(d).viewInsets.bottom + MediaQuery.of(d).padding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sblocca il Pro', style: stileTitolo(22)),
            const SizedBox(height: 6),
            Text(
              'Contributo suggerito: $_importo € (${_lifetime ? 'Lifetime' : 'Annuale'}). Copio io la nota da incollare '
              'su PayPal: appena arriva ti mando la chiave per email.',
              style: const TextStyle(color: testoMuto, height: 1.4),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: sito,
              keyboardType: TextInputType.url,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Il sito dove lo usi', hintText: 'miosito.it'),
            ),
            const SizedBox(height: 16),
            BottoneTk(
              testo: 'Copia la nota e apri PayPal',
              icona: Icons.content_copy_rounded,
              onTap: () => Navigator.pop(d, true),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    final dominio = sito.text.trim().replaceFirst(RegExp(r'^https?://'), '').replaceAll(RegExp(r'/+$'), '');
    await prefs.setString('mio_sito', dominio);
    final nota = '${widget.p.nome} · Pro ${_lifetime ? 'Lifetime' : 'Annuale'}${dominio.isEmpty ? '' : ' · $dominio'}';
    await Clipboard.setData(ClipboardData(text: '$nota — $_importo €'));
    if (!mounted) return;
    avviso(context, 'Nota copiata: incollala nel messaggio su PayPal');
    apriLink(context, archivio.catalogo?.dona ?? 'https://pietrodefilippis.it/donazione/');
  }

  @override
  Widget build(BuildContext context) {
    final (annuale, lifetime) = widget.p.contributo!;
    return Container(
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [inchiostro, inchiostro3],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Il Pro, con un contributo', style: stileTitolo(21, colore: bianco)),
          const SizedBox(height: 4),
          const Text('Per un sito, con aggiornamenti e assistenza.', style: TextStyle(color: grigio300, fontSize: 13)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _Opzione(
                  'Annuale',
                  '$annuale €',
                  'un anno',
                  !_lifetime,
                  () => setState(() => _lifetime = false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Opzione(
                  'Lifetime',
                  '$lifetime €',
                  'per sempre',
                  _lifetime,
                  () => setState(() => _lifetime = true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          BottoneTk(testo: 'Sblocca il Pro con un contributo', icona: Icons.favorite_rounded, onTap: _sblocca),
        ],
      ),
    );
  }
}

class _Opzione extends StatelessWidget {
  const _Opzione(this.titolo, this.prezzo, this.nota, this.scelta, this.onTap);

  final String titolo, prezzo, nota;
  final bool scelta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scelta ? bianco : bianco.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scelta ? sole : bianco.withValues(alpha: .12), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titolo.toUpperCase(),
            style: TextStyle(
              color: scelta ? accentoScuro : grigio300,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              letterSpacing: .6,
            ),
          ),
          const SizedBox(height: 2),
          Text(prezzo, style: stileTitolo(24, colore: scelta ? inchiostro : bianco)),
          Text(
            nota,
            style: TextStyle(color: scelta ? grigio500 : grigio400, fontSize: 11.5, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ),
  );
}

// ───────────────────────── programmi e app ─────────────────────────

class _SchedaProgramma extends StatelessWidget {
  const _SchedaProgramma(this.s);

  final Programma s;

  @override
  Widget build(BuildContext context) {
    final d = s.scarica;
    final azioni = <Widget>[
      if (d['android'] != null)
        BottoneTk(
          testo: 'Scarica per Android',
          icona: Icons.android_rounded,
          onTap: () => apriLink(context, d['android']!),
        ),
      if (d['windows'] != null)
        BottoneTk(testo: 'Windows', icona: Icons.window_rounded, onTap: () => apriLink(context, d['windows']!)),
      if (d['mac'] != null)
        BottoneTk(testo: 'Mac', icona: Icons.laptop_mac_rounded, onTap: () => apriLink(context, d['mac']!)),
      if (d['link'] != null)
        BottoneTk(testo: 'Scarica', icona: Icons.download_rounded, onTap: () => apriLink(context, d['link']!)),
      if (d.isEmpty)
        BottoneTk(
          testo: 'Contattami',
          icona: Icons.mail_rounded,
          onTap: () => scrivimiDi(context, 'Un’app', 'Ciao Pietro, mi interessa ${s.nome}: '),
        ),
    ];
    return _Pagina(
      emoji: s.emoji,
      nome: s.nome,
      scena: s.gruppo,
      pillola: s.codice.isNotEmpty ? 'Gratis · software libero' : etichettaTipo(s.gruppo),
      dati: [
        if (s.installazioni > 0) (numero(s.installazioni), 'installazioni attive', true),
        if (s.versione.isNotEmpty) ('v${s.versione}', 'versione', false),
        (s.disponibili.join(' · '), s.inArrivo.isEmpty ? 'funziona su' : '${s.inArrivo.join(', ')} presto', false),
      ].take(3).toList(),
      corpo: [
        _sezione('Cosa fa'),
        _paragrafo(s.cosa.isNotEmpty ? s.cosa : s.corta),
        if (s.punti.isNotEmpty)
          _Elenco(s.punti, titolo: 'In breve', icona: Icons.check_rounded, colore: coloriScena(s.gruppo).$2),
        if (d['macIntel'] != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: TextButton.icon(
              onPressed: () => apriLink(context, d['macIntel']!),
              icon: const Icon(Icons.memory_rounded, size: 18),
              label: const Text('Hai un Mac con processore Intel? Scarica questa versione'),
            ),
          ),
        if (d['linux'] != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: TextButton.icon(
              onPressed: () => apriLink(context, d['linux']!),
              icon: const Icon(Icons.terminal_rounded, size: 18),
              label: const Text('Usi Linux? Scarica la versione per Linux'),
            ),
          ),
        if (s.codice.isNotEmpty) ...[
          _sezione('Software libero'),
          _paragrafo(
            'Tutte le funzioni sono gratis, senza chiavi né pubblicità. Il codice è pubblico (licenza AGPL-3.0): '
            'chiunque può controllarlo.',
          ),
          const SizedBox(height: 10),
          BottoneTk(
            testo: 'Codice su GitHub',
            icona: Icons.code_rounded,
            chiaro: true,
            onTap: () => apriLink(context, s.codice),
          ),
        ],
      ],
      // al massimo due pulsanti in fondo: Windows e Mac, oppure Android
      azioni: azioni.take(2).toList(),
    );
  }
}
