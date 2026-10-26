// Lettura di un articolo: copertina in parallasse, barra dell'avanzamento, testo regolabile e modalità scura,
// salva per leggerlo senza rete, condividi, «leggi anche» in fondo.
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:fwfh_cached_network_image/fwfh_cached_network_image.dart';
import 'package:share_plus/share_plus.dart';

import '../dati/archivio.dart';
import '../dati/formati.dart';
import '../dati/modelli.dart';
import '../tema.dart';
import 'comuni.dart';

class _Fabbrica extends WidgetFactory with CachedNetworkImageFactory {}

/// I sottotitoli del sito sono paragrafi tutti in grassetto (<p><strong>MAIUSCOLO</strong></p>): diventano titoletti.
String preparaHtml(String html) => html
    .replaceAllMapped(RegExp(r'<p>\s*<strong>([^<]{2,160})</strong>\s*</p>'), (m) => '<h3 class="pd-sub">${m[1]}</h3>')
    .replaceAll(RegExp(r'<p>\s*(&nbsp;)?\s*</p>'), '');

class SchermataLettore extends StatefulWidget {
  const SchermataLettore({super.key, required this.articolo});

  final Articolo articolo;

  @override
  State<SchermataLettore> createState() => _SchermataLettoreState();
}

class _SchermataLettoreState extends State<SchermataLettore> {
  final _scorri = ScrollController();
  final _avanzamento = ValueNotifier<double>(0);
  late Articolo _a = widget.articolo;
  String? _errore;
  bool _carico = true;

  @override
  void initState() {
    super.initState();
    _scorri.addListener(() {
      final p = _scorri.position;
      if (p.maxScrollExtent > 0) _avanzamento.value = (p.pixels / p.maxScrollExtent).clamp(0, 1);
    });
    _carica();
  }

  @override
  void dispose() {
    _scorri.dispose();
    _avanzamento.dispose();
    super.dispose();
  }

  Future<void> _carica() async {
    setState(() {
      _carico = true;
      _errore = null;
    });
    try {
      final a = await archivio.articolo(widget.articolo);
      if (!mounted) return;
      setState(() => _a = a);
      archivio.segnaLetto(a.id);
    } catch (e) {
      if (mounted) setState(() => _errore = '$e');
    } finally {
      if (mounted) setState(() => _carico = false);
    }
  }

  void _condividi() => SharePlus.instance.share(ShareParams(text: '${_a.titolo}\n${_a.link}', subject: _a.titolo));

  void _regolaTesto() => showModalBottomSheet<void>(
    context: context,
    backgroundColor: bianco,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => ListenableBuilder(
      listenable: archivio,
      builder: (context, _) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Lettura', style: stileTitolo(20)),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Text(
                    'A',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: testoMuto),
                  ),
                  Expanded(
                    child: Slider(
                      value: archivio.dimensioneTesto,
                      min: .85,
                      max: 1.5,
                      divisions: 13,
                      onChanged: (v) => archivio.dimensioneTesto = v,
                    ),
                  ),
                  const Text(
                    'A',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: testoMuto),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: archivio.letturaScura,
                onChanged: (v) => archivio.letturaScura = v,
                title: const Text('Lettura al buio', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Fondo scuro, riposa gli occhi la sera'),
                secondary: const Icon(Icons.dark_mode_rounded),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: archivio,
    builder: (context, _) {
      final scuro = archivio.letturaScura;
      final fondo = scuro ? inchiostro : bianco;
      final testo = scuro ? const Color(0xFFD5DCE6) : testoPieno;
      final titolo = scuro ? bianco : inchiostro;
      final cima = MediaQuery.of(context).padding.top;
      return Scaffold(
        backgroundColor: fondo,
        body: Stack(
          children: [
            CustomScrollView(
              controller: _scorri,
              slivers: [
                SliverAppBar(
                  expandedHeight: 330,
                  pinned: true,
                  stretch: true,
                  backgroundColor: inchiostro,
                  surfaceTintColor: Colors.transparent,
                  leading: _TondoVetro(Icons.arrow_back_rounded, 'Indietro', () => Navigator.of(context).pop()),
                  actions: [
                    _TondoVetro(Icons.text_fields_rounded, 'Testo e lettura al buio', _regolaTesto),
                    _TondoVetro(Icons.ios_share_rounded, 'Condividi', _condividi),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _Vetro(child: TastoSalva(_a, chiaro: true)),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.parallax,
                    stretchModes: const [StretchMode.zoomBackground],
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        ImmagineRete(_a.copertina.isNotEmpty ? _a.copertina : _a.immagine),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: [0, .3, .7, 1],
                              colors: [Color(0x990B1424), Color(0x000B1424), Color(0x000B1424), Color(0x660B1424)],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    color: fondo,
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final c in _a.categorie)
                              Gettone(c.nome.toUpperCase(), colore: accentoScuro, fondo: scuro ? inchiostro3 : cielo),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _a.titolo,
                          style: stileTitolo(27 * archivio.dimensioneTesto.clamp(.9, 1.2), colore: titolo),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: const BoxDecoration(shape: BoxShape.circle),
                              clipBehavior: Clip.antiAlias,
                              child: Image.asset(
                                'assets/img/pietro.jpg',
                                fit: BoxFit.cover,
                                alignment: const Alignment(0, -.6),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pietro De Filippis',
                                    style: TextStyle(color: titolo, fontSize: 13.5, fontWeight: FontWeight.w800),
                                  ),
                                  Text(
                                    '${dataLunga(_a.data)}  ·  ${_a.minuti} min di lettura'
                                    '${_a.letture > 0 ? '  ·  ${letture(_a.letture)}' : ''}',
                                    style: const TextStyle(color: grigio500, fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Container(
                          height: 3,
                          width: 46,
                          decoration: BoxDecoration(color: sole, borderRadius: BorderRadius.circular(3)),
                        ),
                        const SizedBox(height: 6),
                      ],
                    ),
                  ),
                ),
                if (_a.contenuto != null)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                    sliver: HtmlWidget(
                      preparaHtml(_a.contenuto!),
                      renderMode: RenderMode.sliverList,
                      factoryBuilder: () => _Fabbrica(),
                      textStyle: TextStyle(fontSize: 17.5 * archivio.dimensioneTesto, height: 1.68, color: testo),
                      onTapUrl: (url) {
                        apriLink(context, url);
                        return true;
                      },
                      customStylesBuilder: (e) => switch (e.localName) {
                        'h3' when e.classes.contains('pd-sub') => {
                          'font-family': titoli,
                          'font-weight': '800',
                          'font-size': '1.12em',
                          'line-height': '1.3',
                          'color': scuro ? '#9CC9F5' : '#1272C2',
                          'margin': '1.1em 0 .3em 0',
                          'text-transform': 'none',
                        },
                        'h2' || 'h3' || 'h4' => {'font-family': titoli, 'color': scuro ? '#FFFFFF' : '#0B1424'},
                        'a' => {
                          'color': scuro ? '#7DBBF3' : '#1272C2',
                          'text-decoration': 'none',
                          'font-weight': '600',
                        },
                        'blockquote' => {
                          'border-left': '4px solid #FFC23D',
                          'padding': '2px 0 2px 14px',
                          'margin': '1em 0',
                          'font-style': 'italic',
                        },
                        'img' => {'border-radius': '14px'},
                        _ => null,
                      },
                      customWidgetBuilder: (e) {
                        if (e.localName != 'iframe') return null;
                        final src = e.attributes['src'] ?? '';
                        if (src.isEmpty) return const SizedBox.shrink();
                        return _CardVideo(src);
                      },
                    ),
                  )
                else if (_carico)
                  const SliverToBoxAdapter(child: _TestoInArrivo())
                else
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        AvvisoRete(_errore ?? 'Articolo non disponibile', riprova: _carica),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: BottoneTk(
                            testo: 'Leggilo sul sito',
                            icona: Icons.open_in_new_rounded,
                            chiaro: true,
                            onTap: () => apriLink(context, _a.link),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_a.contenuto != null)
                  SliverToBoxAdapter(
                    child: _Fine(articolo: _a, scuro: scuro, condividi: _condividi),
                  ),
                SliverToBoxAdapter(child: SizedBox(height: 30 + MediaQuery.of(context).padding.bottom)),
              ],
            ),
            // avanzamento della lettura, sotto la barra di stato
            Positioned(
              top: cima,
              left: 0,
              right: 0,
              child: ValueListenableBuilder<double>(
                valueListenable: _avanzamento,
                builder: (_, v, _) => Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: v,
                    child: Container(
                      height: 3,
                      decoration: const BoxDecoration(gradient: LinearGradient(colors: [accento, sole])),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _Vetro extends StatelessWidget {
  const _Vetro({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
    decoration: BoxDecoration(color: const Color(0x660B1424), borderRadius: BorderRadius.circular(40)),
    padding: const EdgeInsets.all(4),
    child: child,
  );
}

class _TondoVetro extends StatelessWidget {
  const _TondoVetro(this.icona, this.descrizione, this.onTap);

  final IconData icona;
  final String descrizione;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: descrizione,
    child: GestureDetector(
      onTap: onTap,
      child: _Vetro(child: Icon(icona, color: bianco, size: 20)),
    ),
  );
}

/// Righe grigie che scorrono mentre arriva il testo.
class _TestoInArrivo extends StatelessWidget {
  const _TestoInArrivo();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
    child: Column(
      children: [
        for (final l in [1.0, .95, .98, .7, 0.0, 1.0, .92, .6])
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: l == 0
                ? const SizedBox(height: 10)
                : FractionallySizedBox(
                    widthFactor: l,
                    alignment: Alignment.centerLeft,
                    child: const SizedBox(height: 14, child: Luccichio(raggio: 7)),
                  ),
          ),
      ],
    ),
  );
}

/// Video incorporato (YouTube, Facebook…): una card che lo apre nella sua app.
class _CardVideo extends StatelessWidget {
  const _CardVideo(this.src);

  final String src;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Premibile(
      onTap: () => apriLink(context, src.startsWith('//') ? 'https:$src' : src),
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [inchiostro2, inchiostro3]),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_circle_fill_rounded, color: bianco, size: 54),
            SizedBox(height: 6),
            Text(
              'Guarda il video',
              style: TextStyle(color: bianco, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Fine articolo: condividi, salva, scrivimi e altri articoli della stessa categoria.
class _Fine extends StatelessWidget {
  const _Fine({required this.articolo, required this.scuro, required this.condividi});

  final Articolo articolo;
  final bool scuro;
  final VoidCallback condividi;

  @override
  Widget build(BuildContext context) {
    final cat = articolo.categorie.map((c) => c.id).toSet();
    final altri = archivio.recenti.where((a) => a.id != articolo.id).toList()
      ..sort((a, b) {
        final pa = a.categorie.any((c) => cat.contains(c.id)) ? 0 : 1;
        final pb = b.categorie.any((c) => cat.contains(c.id)) ? 0 : 1;
        return pa != pb ? pa - pb : b.data.compareTo(a.data);
      });
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: FondoGriglia(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ti è stato utile?', style: stileTitolo(22, colore: bianco)),
                    const SizedBox(height: 6),
                    const Text(
                      'Fallo leggere a chi può servire: è il modo migliore per sostenere il blog.',
                      style: TextStyle(color: grigio300, fontSize: 14, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: BottoneTk(testo: 'Condividi', icona: Icons.ios_share_rounded, onTap: condividi),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ListenableBuilder(
                            listenable: archivio,
                            builder: (context, _) => BottoneTk(
                              testo: archivio.eSalvato(articolo.id) ? 'Salvato' : 'Salva',
                              icona: archivio.eSalvato(articolo.id)
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_border_rounded,
                              chiaro: true,
                              scuro: true,
                              onTap: () => archivio.alterna(articolo),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (altri.isNotEmpty) ...[
            const SizedBox(height: 26),
            Text('Leggi anche', style: stileTitolo(22, colore: scuro ? bianco : inchiostro)),
            const SizedBox(height: 12),
            for (final a in altri.take(3)) Padding(padding: const EdgeInsets.only(bottom: 12), child: RigaArticolo(a)),
          ],
        ],
      ),
    );
  }
}
