// Scheda «Inizio»: chi sono, numeri del sito che contano da soli, app su Google Play, ultimo articolo, carosello
// «da leggere», i tre argomenti del blog, assaggio della vetrina, di mestiere, invito alle notifiche, caffè e social.
// Stesse sezioni della home del sito (pd-home.php).
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../dati/archivio.dart';
import '../dati/formati.dart';
import '../dati/modelli.dart';
import '../dati/notifiche.dart';
import '../tema.dart';
import 'articoli.dart';
import 'comuni.dart';
import 'home.dart';
import 'scheda.dart';

const social = [
  (Icons.facebook_rounded, 'Facebook', 'https://www.facebook.com/pietrodefilippis.pagina', Color(0xFF1877F2)),
  (Icons.camera_alt_rounded, 'Instagram', 'https://www.instagram.com/pietrodefilippis.it/', Color(0xFFE1306C)),
  (Icons.tiktok_rounded, 'TikTok', 'https://www.tiktok.com/@pietrodefilippis.it', Color(0xFF111111)),
  (Icons.telegram_rounded, 'Telegram', 'https://t.me/pietrodefilippisit', Color(0xFF229ED9)),
];

class SchedaInizio extends StatelessWidget {
  const SchedaInizio({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: archivio,
    builder: (context, _) {
      final r = archivio.recenti;
      final fondo = MediaQuery.of(context).padding.bottom + 16;
      return RefreshIndicator(
        onRefresh: archivio.aggiorna,
        color: accento,
        edgeOffset: MediaQuery.of(context).padding.top,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(child: _Testata()),
            if (archivio.erroreRete != null)
              SliverToBoxAdapter(
                child: AvvisoRete(
                  r.isEmpty ? archivio.erroreRete! : 'Senza connessione: stai vedendo l\'ultima copia.',
                  riprova: archivio.aggiorna,
                ),
              ),
            if (!archivio.invitoNotificheFatto) const SliverToBoxAdapter(child: _InvitoNotifiche()),
            if (archivio.catalogo != null && archivio.catalogo!.gruppo('app').any((s) => s.play.isNotEmpty))
              SliverToBoxAdapter(child: _Store(archivio.catalogo!.gruppo('app'))),
            if (r.isEmpty && archivio.aggiornando)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 22, 16, 0),
                  child: SizedBox(height: 300, child: Luccichio(raggio: 24)),
                ),
              ),
            if (r.isNotEmpty) ...[
              _titolo('Ultimo articolo', azione: 'Tutti', onTap: () => schedaAttiva.value = schedaArticoli),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: Entrata(
                    child: CardArticoloGrande(
                      r.first,
                      altezza: 340,
                      etichetta: DateTime.now().difference(r.first.data).inDays < 3 ? 'Nuovo' : null,
                    ),
                  ),
                ),
              ),
            ],
            if (r.length > 1) ...[
              _titolo('Da leggere'),
              SliverToBoxAdapter(child: _Carosello(r.skip(1).take(6).toList())),
            ],
            if (archivio.catalogo?.argomenti.isNotEmpty ?? false) ...[
              _titolo('Di cosa scrivo', azione: 'Tutti', onTap: () => schedaAttiva.value = schedaArticoli),
              SliverToBoxAdapter(child: _Argomenti(archivio.catalogo!.argomenti)),
            ],
            if (archivio.catalogo != null) ...[
              _titolo('Le mie app', azione: 'Vetrina', onTap: () => schedaAttiva.value = schedaVetrina),
              SliverToBoxAdapter(child: _StrisciaApp(archivio.catalogo!)),
            ],
            if (r.length > 7) ...[
              _titolo('Altri articoli'),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList.separated(
                  itemCount: math.min(5, r.length - 7),
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => Entrata(ritardo: i, child: RigaArticolo(r[7 + i])),
                ),
              ),
            ],
            const SliverToBoxAdapter(child: _Mestiere()),
            const SliverToBoxAdapter(child: _Sostieni()),
            const SliverToBoxAdapter(child: _Social()),
            SliverToBoxAdapter(child: SizedBox(height: fondo)),
          ],
        ),
      );
    },
  );

  Widget _titolo(String t, {String? azione, VoidCallback? onTap}) => SliverPadding(
    padding: const EdgeInsets.fromLTRB(20, 26, 12, 12),
    sliver: SliverToBoxAdapter(
      child: Row(
        children: [
          Expanded(child: Text(t, style: stileTitolo(23))),
          if (azione != null)
            TextButton(
              onPressed: onTap,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(azione, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const Icon(Icons.chevron_right_rounded, size: 20),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

/// Testata: griglia del sito, saluto, foto con alone, numeri che contano da soli.
class _Testata extends StatelessWidget {
  const _Testata();

  @override
  Widget build(BuildContext context) {
    final c = archivio.catalogo;
    final cima = MediaQuery.of(context).padding.top;
    return ClipRRect(
      borderRadius: BorderRadius.zero,
      child: FondoGriglia(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, cima + 12, 12, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const LogoTk(lato: 34),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'pietrodefilippis.it',
                      style: TextStyle(color: bianco, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: .2),
                    ),
                  ),
                  AzioneTk(Icons.info_rounded, 'Informazioni', () => apriInformazioniPietro(context)),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Entrata(
                          child: RichText(
                            text: TextSpan(
                              style: stileTitolo(34, colore: bianco, altezza: 1.05),
                              children: const [
                                TextSpan(text: 'Ciao,\nsono '),
                                TextSpan(
                                  text: 'Pietro',
                                  style: TextStyle(color: sole),
                                ),
                                TextSpan(text: '.'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Entrata(
                          ritardo: 2,
                          child: Text(
                            'Scrivo di autismo, tecnologia e del mio quartiere. '
                            'E costruisco plugin, app e programmi, gratis per tutti.',
                            style: TextStyle(color: grigio300, fontSize: 14, height: 1.45, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Entrata(ritardo: 1, child: _Ritratto()),
                ],
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Row(
                  children: [
                    _Numero(c?.numeri['articoli'] ?? archivio.recenti.length, 'articoli'),
                    _Numero(c?.numeri['plugin'] ?? 0, 'plugin'),
                    _Numero((c?.numeri['app'] ?? 0) + (c?.numeri['programmi'] ?? 0), 'app e programmi'),
                    _Numero(c?.installazioniTotali ?? 0, 'installazioni attive', vivo: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Foto di Pietro in una cornice arrotondata, con alone che respira e un bollino.
Widget _quadretto(double lato, Color colore) => Container(
  width: lato,
  height: lato,
  decoration: BoxDecoration(color: colore, borderRadius: BorderRadius.circular(lato * .2)),
);

class _Ritratto extends StatefulWidget {
  const _Ritratto();

  @override
  State<_Ritratto> createState() => _RitrattoState();
}

class _RitrattoState extends State<_Ritratto> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, figlio) => Transform.translate(
      offset: Offset(0, -4 * Curves.easeInOut.transform(_c.value)),
      child: Container(
        width: 118,
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: accento.withValues(alpha: .25 + .25 * _c.value),
              blurRadius: 30 + 10 * _c.value,
              spreadRadius: 1,
            ),
          ],
        ),
        child: figlio,
      ),
    ),
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        // cornice scura come sul sito
        Positioned.fill(
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: inchiostro3, borderRadius: BorderRadius.circular(22)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset('assets/img/pietro.jpg', fit: BoxFit.cover, alignment: const Alignment(0, -.55)),
            ),
          ),
        ),
        // quadretti del logo in alto a destra
        Positioned(
          top: -9,
          right: -9,
          child: SizedBox(
            width: 30,
            height: 30,
            child: Stack(
              children: [
                Positioned(right: 0, top: 0, child: _quadretto(16, accento)),
                Positioned(left: 0, top: 8, child: _quadretto(11, const Color(0xFF8CC6F7))),
                Positioned(right: 2, bottom: 0, child: _quadretto(8, bianco)),
              ],
            ),
          ),
        ),
        // targhetta «PDF · Webmaster · UX/UI · online dal 2017»
        Positioned(
          left: -10,
          bottom: -16,
          child: Container(
            padding: const EdgeInsets.fromLTRB(9, 6, 10, 6),
            decoration: BoxDecoration(
              color: bianco,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [BoxShadow(color: Color(0x660B1424), blurRadius: 14, offset: Offset(0, 6))],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'PDF',
                  style: TextStyle(color: accento, fontSize: 8.5, fontWeight: FontWeight.w800, letterSpacing: 1),
                ),
                Text(
                  'Webmaster · UX/UI',
                  style: TextStyle(color: inchiostro, fontSize: 10.5, fontWeight: FontWeight.w800, height: 1.2),
                ),
                Text('online dal 2017', style: TextStyle(color: testoMuto, fontSize: 9, height: 1.2)),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

/// Numero che conta da zero al valore vero.
class _Numero extends StatelessWidget {
  const _Numero(this.valore, this.etichetta, {this.vivo = false});

  final int valore;
  final String etichetta;
  final bool vivo;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: valore.toDouble()),
                duration: const Duration(milliseconds: 1400),
                curve: Curves.easeOutCubic,
                builder: (_, v, _) => FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(numero(v.round()), style: stileTitolo(24, colore: bianco)),
                ),
              ),
            ),
            if (vivo && valore > 0) const PuntinoVivo(lato: 6),
          ],
        ),
        Text(
          etichetta,
          maxLines: 2,
          style: const TextStyle(color: grigio400, fontSize: 10.5, fontWeight: FontWeight.w700, height: 1.15),
        ),
      ],
    ),
  );
}

/// Card «attiva le notifiche» (Android 13+ chiede il permesso).
class _InvitoNotifiche extends StatelessWidget {
  const _InvitoNotifiche();

  @override
  Widget build(BuildContext context) => Entrata(
    child: Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFFF4D6), Color(0xFFFFE7A8)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: sole, borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.notifications_active_rounded, color: inchiostro),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Non perderti un articolo',
                  style: TextStyle(color: inchiostro, fontWeight: FontWeight.w800, fontSize: 14.5),
                ),
                SizedBox(height: 2),
                Text(
                  'Ti avviso quando ne esce uno nuovo, o quando arriva una nuova app.',
                  style: TextStyle(color: Color(0xFF6B5310), fontSize: 12.5, height: 1.3),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Premibile(
                onTap: () async {
                  final ok = await chiediPermessoNotifiche();
                  archivio.notifiche = ok;
                  archivio.invitoNotificheFatto = true;
                  if (context.mounted) {
                    avviso(
                      context,
                      ok
                          ? 'Fatto: ti avviso io quando c\'è qualcosa di nuovo'
                          : 'Notifiche non permesse: puoi attivarle dalle impostazioni di Android',
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(color: inchiostro, borderRadius: BorderRadius.circular(12)),
                  child: const Text(
                    'Attiva',
                    style: TextStyle(color: bianco, fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => archivio.invitoNotificheFatto = true,
                child: const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    'Non ora',
                    style: TextStyle(color: Color(0xFF6B5310), fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

/// Carosello di articoli: la card al centro è più grande, quelle ai lati si rimpiccioliscono.
class _Carosello extends StatefulWidget {
  const _Carosello(this.articoli);

  final List<Articolo> articoli;

  @override
  State<_Carosello> createState() => _CaroselloState();
}

class _CaroselloState extends State<_Carosello> {
  final _pagine = PageController(viewportFraction: .8);
  double _pagina = 0;

  @override
  void initState() {
    super.initState();
    _pagine.addListener(() => setState(() => _pagina = _pagine.page ?? 0));
  }

  @override
  void dispose() {
    _pagine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        height: 270,
        child: PageView.builder(
          controller: _pagine,
          padEnds: false,
          itemCount: widget.articoli.length,
          itemBuilder: (_, i) {
            final d = (i - _pagina).abs().clamp(0.0, 1.0);
            return Padding(
              padding: EdgeInsets.only(left: i == 0 ? 16 : 6, right: 6, top: 8 + 14 * d, bottom: 8 + 14 * d),
              child: Opacity(opacity: 1 - d * .25, child: CardArticoloGrande(widget.articoli[i], altezza: 254)),
            );
          },
        ),
      ),
      const SizedBox(height: 4),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < widget.articoli.length; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: (_pagina.round() == i) ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _pagina.round() == i ? accento : grigio300,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
        ],
      ),
    ],
  );
}

/// App per telefono e programmi in tessere colorate che scorrono.
class _StrisciaApp extends StatelessWidget {
  const _StrisciaApp(this.c);

  final Catalogo c;

  @override
  Widget build(BuildContext context) {
    final voci = [...c.gruppo('app'), ...c.gruppo('giochi'), ...c.gruppo('software')];
    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: voci.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final s = voci[i];
          final (c1, c2) = coloriScena(s.gruppo);
          return Entrata(
            ritardo: i,
            child: Premibile(
              onTap: () => apriSchedaProgramma(context, s),
              child: Container(
                width: 132,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [c1, c2]),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [BoxShadow(color: c2.withValues(alpha: .35), blurRadius: 14, offset: const Offset(0, 6))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: bianco.withValues(alpha: .22),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(s.emoji, style: const TextStyle(fontSize: 24)),
                    ),
                    const Spacer(),
                    Text(
                      s.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: bianco, fontWeight: FontWeight.w800, fontSize: 14.5),
                    ),
                    Text(
                      s.gruppo == 'software' ? s.disponibili.join(' · ') : etichettaTipo(s.gruppo),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: bianco.withValues(alpha: .8),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Etichetta «// minuscolo» coi quadretti del logo, come sul sito.
class _Etichetta extends StatelessWidget {
  const _Etichetta(this.testo);

  final String testo;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      _quadretto(6, accento),
      const SizedBox(width: 2),
      _quadretto(6, accento),
      const SizedBox(width: 2),
      Transform.translate(offset: const Offset(0, -3), child: _quadretto(6, const Color(0xFF8CC6F7))),
      const SizedBox(width: 8),
      Text(
        testo,
        style: const TextStyle(color: Color(0xFF8CC6F7), fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: .3),
      ),
    ],
  );
}

/// Pagina sviluppatore su Google Play: tutte le app pubblicate.
const paginaPlay = 'https://play.google.com/store/apps/dev?id=7693415642899552584';

/// Logo di Google Play in quattro spicchi (disegnato qui, come sul sito).
class _LogoPlay extends StatelessWidget {
  const _LogoPlay();

  @override
  Widget build(BuildContext context) => CustomPaint(size: const Size.square(26), painter: _PittorePlay());
}

class _PittorePlay extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final k = s.width / 24;
    void spicchio(List<Offset> p, Color c) =>
        canvas.drawPath(Path()..addPolygon([for (final o in p) o * k], true), Paint()..color = c);
    const centro = Offset(12.3, 12);
    spicchio(const [Offset(3.4, 2.4), Offset(3.4, 21.6), centro], accento);
    spicchio(const [Offset(3.4, 2.4), Offset(15.4, 8.9), centro], const Color(0xFF22C55E));
    spicchio(const [Offset(3.4, 21.6), Offset(15.4, 15.1), centro], const Color(0xFFEF4444));
    spicchio(const [Offset(15.4, 8.9), Offset(20.6, 12), Offset(15.4, 15.1), centro], sole);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// «Le mie app sono su Google Play» (come la scena «store» del sito): tessere delle app, verdi quelle già su Play.
class _Store extends StatelessWidget {
  const _Store(this.app);

  final List<Programma> app;

  @override
  Widget build(BuildContext context) {
    final su = app.where((s) => s.play.isNotEmpty).length;
    return Entrata(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 22, 16, 0),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          color: inchiostro,
          boxShadow: const [BoxShadow(color: Color(0x400B1424), blurRadius: 24, offset: Offset(0, 10))],
        ),
        child: Stack(
          children: [
            // aloni verde e blu come sul sito
            Positioned(right: -80, top: -90, child: _alone(260, const Color(0xFF22C55E))),
            Positioned(left: -90, bottom: -110, child: _alone(280, accento)),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Etichetta('novità · app ufficiali'),
                  const SizedBox(height: 8),
                  Text('Le mie app sono', style: stileTitolo(27, colore: bianco, altezza: 1.1)),
                  ShaderMask(
                    shaderCallback: (r) =>
                        const LinearGradient(colors: [Color(0xFF4ADE80), Color(0xFF8CC6F7), sole]).createShader(r),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        'su Google Play.',
                        style: stileTitolo(27, colore: bianco, altezza: 1.15).copyWith(fontStyle: FontStyle.italic),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Controllate da Google, si installano con un tocco e si aggiornano da sole. '
                    'E presto arrivano anche su iPhone, dall\'App Store.',
                    style: TextStyle(color: grigio300, fontSize: 13.5, height: 1.45, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 18),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 8,
                    childAspectRatio: .92,
                    padding: EdgeInsets.zero,
                    children: [
                      for (final (i, s) in [
                        ...app.where((s) => s.play.isNotEmpty),
                        ...app.where((s) => s.play.isEmpty),
                      ].indexed)
                        Entrata(ritardo: i, child: _TesseraStore(s)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _Bollo(
                          logo: const _LogoPlay(),
                          sopra: 'Disponibili su',
                          nome: 'Google Play',
                          onTap: () => apriLink(context, paginaPlay),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: _Bollo(
                          logo: Icon(Icons.apple, color: bianco, size: 28),
                          sopra: 'Prossimamente su',
                          nome: 'App Store',
                          presto: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '$su app già su Google Play · ${app.length - su} in arrivo · tutte gratis, senza pubblicità',
                    style: const TextStyle(color: grigio300, fontSize: 12, height: 1.4, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _alone(double lato, Color c) => Container(
    width: lato,
    height: lato,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [c.withValues(alpha: .35), c.withValues(alpha: 0)]),
    ),
  );
}

class _TesseraStore extends StatelessWidget {
  const _TesseraStore(this.s);

  final Programma s;

  @override
  Widget build(BuildContext context) {
    final su = s.play.isNotEmpty;
    return Premibile(
      onTap: () => su ? apriLink(context, s.play) : apriSchedaProgramma(context, s),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: su ? bianco : bianco.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: su ? const Color(0xFF22C55E) : bianco.withValues(alpha: .14),
                width: su ? 2.5 : 1,
              ),
              boxShadow: su ? const [BoxShadow(color: Color(0x8022C55E), blurRadius: 16, offset: Offset(0, 6))] : null,
            ),
            child: Opacity(
              opacity: su ? 1 : .7,
              child: Text(s.emoji, style: const TextStyle(fontSize: 27)),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            s.nome,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: bianco, fontSize: 11.5, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (su) ...[const PuntinoVivo(lato: 5), const SizedBox(width: 4)],
              Flexible(
                child: Text(
                  su ? 'su Google Play' : 'in arrivo',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: su ? const Color(0xFF86EFAC) : grigio400,
                    fontSize: 9.5,
                    fontWeight: su ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Bottone nero «Disponibili su Google Play» / «Prossimamente su App Store» (spento, col bollino PRESTO).
class _Bollo extends StatelessWidget {
  const _Bollo({required this.logo, required this.sopra, required this.nome, this.onTap, this.presto = false});

  final Widget logo;
  final String sopra, nome;
  final VoidCallback? onTap;
  final bool presto;

  @override
  Widget build(BuildContext context) {
    final bollo = Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: presto ? bianco.withValues(alpha: .16) : const Color(0xFF4ADE80),
          width: presto ? 1 : 1.4,
        ),
      ),
      child: Row(
        children: [
          logo,
          const SizedBox(width: 9),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    sopra,
                    style: const TextStyle(color: grigio300, fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    nome,
                    style: const TextStyle(color: bianco, fontSize: 18, fontWeight: FontWeight.w800, height: 1.1),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    if (!presto) return Premibile(onTap: onTap ?? () {}, child: bollo);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Opacity(opacity: .6, child: bollo),
        Positioned(
          top: -9,
          right: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(color: sole, borderRadius: BorderRadius.circular(7)),
            child: const Text(
              'PRESTO',
              style: TextStyle(color: inchiostro, fontSize: 9.5, fontWeight: FontWeight.w900, letterSpacing: .8),
            ),
          ),
        ),
      ],
    );
  }
}

/// I tre argomenti del blog, con la foto dell'ultimo articolo: toccandoli si aprono gli articoli di quella categoria.
class _Argomenti extends StatelessWidget {
  const _Argomenti(this.argomenti);

  final List<Argomento> argomenti;

  static const _icone = {
    'autismo': Icons.extension_rounded,
    'tecnologia': Icons.memory_rounded,
    'politica': Icons.location_city_rounded,
  };

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(
      children: [
        for (final (i, a) in argomenti.indexed)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 12),
            child: Entrata(
              ritardo: i,
              child: Premibile(
                onTap: () {
                  categoriaRichiesta.value = a.categoria;
                  schedaAttiva.value = schedaArticoli;
                },
                child: Container(
                  height: i == 0 ? 230 : 196,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: inchiostro2,
                    boxShadow: const [BoxShadow(color: Color(0x330B1424), blurRadius: 18, offset: Offset(0, 8))],
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (a.ultimaImmagine.isNotEmpty) ImmagineRete(a.ultimaImmagine),
                      // scuro dal basso: il testo resta sempre leggibile
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x660B1424), Color(0xF20B1424)],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(color: accento, borderRadius: BorderRadius.circular(12)),
                                  child: Icon(_icone[a.chiave] ?? Icons.article_rounded, color: bianco, size: 21),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: bianco.withValues(alpha: .16),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${a.totale} articoli',
                                    style: const TextStyle(color: bianco, fontSize: 12, fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text(a.titolo, style: stileTitolo(23, colore: bianco)),
                            const SizedBox(height: 4),
                            Text(
                              a.descrizione,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: grigio300, fontSize: 12.5, height: 1.35),
                            ),
                            if (a.ultimoTitolo.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text.rich(
                                TextSpan(
                                  children: [
                                    const TextSpan(
                                      text: 'L\'ultimo · ',
                                      style: TextStyle(color: sole, fontWeight: FontWeight.w800),
                                    ),
                                    TextSpan(text: a.ultimoTitolo),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: bianco, fontSize: 12.5, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

/// «Di mestiere» (come sul sito): i quattro servizi e il tasto per scrivermi.
class _Mestiere extends StatelessWidget {
  const _Mestiere();

  static const _servizi = [
    (Icons.code_rounded, 'Webmaster', 'Siti professionali, plugin su misura, temi e prestazioni.'),
    (Icons.brush_rounded, 'Web e UX/UI design', 'Grafica ed esperienza visiva, foto e video.'),
    (Icons.smartphone_rounded, 'App Android e iOS', 'App per telefono e programmi per Windows, Mac e Linux.'),
    (Icons.storefront_rounded, 'eCommerce', 'Negozi online e vendita sui marketplace.'),
  ];

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 30, 16, 0),
    child: Entrata(
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(26), color: inchiostro),
        child: FondoGriglia(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Etichetta('di mestiere'),
                const SizedBox(height: 8),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: 'Faccio siti, app e '),
                      TextSpan(
                        text: 'negozi online',
                        style: stileTitolo(26, colore: const Color(0xFF8CC6F7)).copyWith(fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                  style: stileTitolo(26, colore: bianco, altezza: 1.1),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Il web è da sempre la mia più grande passione e oggi è il mio lavoro a tempo pieno.',
                  style: TextStyle(color: grigio300, fontSize: 13.5, height: 1.45, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: .98,
                  padding: EdgeInsets.zero,
                  children: [
                    for (final (i, s) in _servizi.indexed)
                      Entrata(
                        ritardo: i,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: bianco.withValues(alpha: .06),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: bianco.withValues(alpha: .1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [accento, accentoScuro]),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(s.$1, color: bianco, size: 20),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                s.$2,
                                style: const TextStyle(
                                  color: bianco,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  height: 1.15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Expanded(
                                child: Text(
                                  s.$3,
                                  overflow: TextOverflow.fade,
                                  style: const TextStyle(color: grigio300, fontSize: 12, height: 1.35),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Premibile(
                  onTap: () => schedaAttiva.value = schedaScrivimi,
                  child: Container(
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: sole, borderRadius: BorderRadius.circular(14)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Scrivimi',
                          style: TextStyle(color: inchiostro, fontWeight: FontWeight.w900, fontSize: 15.5),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.send_rounded, color: inchiostro, size: 19),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Card gialla del caffè.
class _Sostieni extends StatelessWidget {
  const _Sostieni();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 30, 16, 0),
    child: Premibile(
      onTap: () => apriLink(context, archivio.catalogo?.dona ?? 'https://pietrodefilippis.it/donazione/'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFD36B), Color(0xFFF59E0B)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [BoxShadow(color: Color(0x40F59E0B), blurRadius: 20, offset: Offset(0, 8))],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Offrimi un caffè', style: stileTitolo(22)),
                  const SizedBox(height: 6),
                  const Text(
                    'Blog, plugin e app sono gratis e senza pubblicità. Se ti sono utili, un caffè mi aiuta a continuare.',
                    style: TextStyle(color: Color(0xFF5A3B00), fontSize: 13, height: 1.4, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(color: inchiostro, shape: BoxShape.circle),
              child: const Icon(Icons.coffee_rounded, color: sole, size: 28),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Social extends StatelessWidget {
  const _Social();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 26, 16, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text('Seguimi', style: stileTitolo(23)),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (final s in social)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Premibile(
                    onTap: () => apriLink(context, s.$3),
                    child: Container(
                      height: 78,
                      decoration: BoxDecoration(
                        color: bianco,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [BoxShadow(color: Color(0x0F0B1424), blurRadius: 12, offset: Offset(0, 4))],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(s.$1, color: s.$4, size: 28),
                          const SizedBox(height: 6),
                          Text(
                            s.$2,
                            style: const TextStyle(color: testoPieno, fontSize: 11.5, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Center(
          child: TextButton.icon(
            onPressed: () => apriLink(context, 'https://pietrodefilippis.it'),
            icon: const Icon(Icons.language_rounded, size: 18),
            label: const Text('pietrodefilippis.it', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ),
      ],
    ),
  );
}
