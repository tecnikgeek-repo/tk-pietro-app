// Scheda «Vetrina»: plugin, app, programmi e temi, con le card «wouuu» del sito (scena del colore del piano,
// icona che fluttua, installazioni attive col puntino che pulsa). Tocco = scheda completa.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../dati/archivio.dart';
import '../dati/formati.dart';
import '../tema.dart';
import 'comuni.dart';
import 'scheda.dart';

class SchedaVetrina extends StatefulWidget {
  const SchedaVetrina({super.key});

  @override
  State<SchedaVetrina> createState() => _SchedaVetrinaState();
}

const _gruppi = ['Plugin', 'App', 'Programmi', 'Temi'];

class _SchedaVetrinaState extends State<SchedaVetrina> {
  int _gruppo = 0;
  String _tipo = ''; // '' tutti, gratuito, free-pro, solo-pro
  String _cerca = '';

  bool _corrisponde(String nome, String testo) {
    final q = _cerca.trim().toLowerCase();
    return q.isEmpty || nome.toLowerCase().contains(q) || testo.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: archivio,
    builder: (context, _) {
      final c = archivio.catalogo;
      final cima = MediaQuery.of(context).padding.top;
      final voci = <Widget>[];
      if (c != null) {
        if (_gruppo == 0 || _gruppo == 3) {
          final elenco = (_gruppo == 0 ? c.plugin : c.temi).where(
            (p) => (_tipo.isEmpty || p.tipo == _tipo) && _corrisponde(p.nome, '${p.corta} ${p.categoria}'),
          );
          for (final p in elenco) {
            voci.add(
              CardVetrina(
                emoji: p.emoji,
                nome: p.nome,
                testo: p.corta,
                scena: p.scena,
                pillola: etichettaTipo(p.tipo),
                installazioni: p.installazioni,
                piede: p.versione.isEmpty ? p.categoria : 'v${p.versione}',
                onTap: () => apriSchedaPlugin(context, p),
              ),
            );
          }
        } else {
          final g = _gruppo == 1 ? ['app', 'giochi'] : ['software'];
          for (final s in c.software.where((s) => g.contains(s.gruppo) && _corrisponde(s.nome, s.corta))) {
            voci.add(
              CardVetrina(
                emoji: s.emoji,
                nome: s.nome,
                testo: s.corta,
                scena: s.gruppo,
                pillola: 'Gratis',
                installazioni: s.installazioni,
                piede: s.versione.isNotEmpty ? 'v${s.versione}' : s.disponibili.join(' · '),
                onTap: () => apriSchedaProgramma(context, s),
              ),
            );
          }
        }
      }
      final conteggi = c == null
          ? const [0, 0, 0, 0]
          : [
              c.plugin.length,
              c.gruppo('app').length + c.gruppo('giochi').length,
              c.gruppo('software').length,
              c.temi.length,
            ];
      return RefreshIndicator(
        onRefresh: archivio.aggiorna,
        color: accento,
        edgeOffset: cima + 170,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: ClipRRect(
                borderRadius: BorderRadius.zero,
                child: FondoGriglia(
                  alone: const Color(0xFF8B5CF6),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, cima + 16, 20, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Vetrina', style: stileTitolo(32, colore: bianco)),
                        const SizedBox(height: 4),
                        Text(
                          c == null
                              ? 'Plugin, app e programmi fatti da me.'
                              : '${c.plugin.length} plugin, ${conteggi[1] + conteggi[2]} app e programmi, '
                                    '${numero(c.installazioniTotali)} installazioni attive.',
                          style: const TextStyle(color: grigio300, fontSize: 13.5),
                        ),
                        const SizedBox(height: 14),
                        _Segmenti(
                          voci: [for (var i = 0; i < _gruppi.length; i++) (_gruppi[i], conteggi[i])],
                          scelto: _gruppo,
                          onScelto: (i) => setState(() {
                            _gruppo = i;
                            _tipo = '';
                          }),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          onChanged: (v) => setState(() => _cerca = v),
                          style: const TextStyle(color: bianco, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            hintText: 'Cerca per nome o funzione',
                            hintStyle: const TextStyle(color: grigio400),
                            prefixIcon: const Icon(Icons.search_rounded, color: grigio300),
                            fillColor: bianco.withValues(alpha: .08),
                            isDense: true,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: bianco.withValues(alpha: .1)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: accento, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (_gruppo == 0)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 54,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    children: [
                      for (final t in const [
                        ('', 'Tutti'),
                        ('gratuito', 'Free'),
                        ('free-pro', 'Free + Pro'),
                        ('solo-pro', 'Solo Pro'),
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(t.$2),
                            selected: _tipo == t.$1,
                            onSelected: (_) => setState(() => _tipo = t.$1),
                            showCheckmark: false,
                            selectedColor: inchiostro,
                            backgroundColor: bianco,
                            labelStyle: TextStyle(
                              color: _tipo == t.$1 ? bianco : testoPieno,
                              fontWeight: FontWeight.w700,
                            ),
                            side: BorderSide(color: _tipo == t.$1 ? inchiostro : grigio200),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            if (c == null && archivio.aggiornando)
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: .66,
                  children: List.generate(4, (_) => const Luccichio(raggio: 22)),
                ),
              )
            else if (c == null)
              SliverToBoxAdapter(
                child: StatoVuoto(
                  Icons.wifi_off_rounded,
                  'Vetrina non ancora scaricata',
                  archivio.erroreRete ?? 'Collegati a internet e tira giù per aggiornare.',
                  azione: BottoneTk(testo: 'Riprova', icona: Icons.refresh_rounded, onTap: archivio.aggiorna),
                ),
              )
            else if (voci.isEmpty)
              const SliverToBoxAdapter(
                child: StatoVuoto(Icons.search_off_rounded, 'Niente con questo nome', 'Prova con un\'altra parola.'),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 240,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    mainAxisExtent: 270,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => Entrata(ritardo: i % 8, child: voci[i]),
                    childCount: voci.length,
                  ),
                ),
              ),
            SliverToBoxAdapter(child: SizedBox(height: MediaQuery.of(context).padding.bottom + 16)),
          ],
        ),
      );
    },
  );
}

/// Quattro segmenti con il numero: quello scelto ha la pillola bianca che scivola.
class _Segmenti extends StatelessWidget {
  const _Segmenti({required this.voci, required this.scelto, required this.onScelto});

  final List<(String, int)> voci;
  final int scelto;
  final ValueChanged<int> onScelto;

  @override
  Widget build(BuildContext context) => Container(
    height: 46,
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(color: bianco.withValues(alpha: .08), borderRadius: BorderRadius.circular(16)),
    child: LayoutBuilder(
      builder: (_, vincoli) {
        final w = vincoli.maxWidth / voci.length;
        return Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              left: w * scelto,
              top: 0,
              bottom: 0,
              width: w,
              child: Container(
                decoration: BoxDecoration(color: bianco, borderRadius: BorderRadius.circular(12)),
              ),
            ),
            Row(
              children: [
                for (var i = 0; i < voci.length; i++)
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onScelto(i),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text.rich(
                            TextSpan(
                              style: TextStyle(
                                color: i == scelto ? inchiostro : bianco,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                              children: [
                                TextSpan(text: voci[i].$1),
                                TextSpan(
                                  text: ' ${voci[i].$2}',
                                  style: TextStyle(
                                    color: i == scelto ? accentoScuro : grigio400,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    ),
  );
}

/// Card della vetrina: scena colorata con puntini e riflesso che passa, icona a cavallo che fluttua, nome, testo,
/// installazioni attive e versione.
class CardVetrina extends StatelessWidget {
  const CardVetrina({
    super.key,
    required this.emoji,
    required this.nome,
    required this.testo,
    required this.scena,
    required this.pillola,
    required this.installazioni,
    required this.piede,
    required this.onTap,
  });

  final String emoji, nome, testo, scena, pillola, piede;
  final int installazioni;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (c1, c2) = coloriScena(scena);
    return Premibile(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bianco,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [BoxShadow(color: Color(0x140B1424), blurRadius: 16, offset: Offset(0, 6))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 96,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(child: ScenaAnimata(c1, c2)),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: bianco.withValues(alpha: .92),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        pillola.toUpperCase(),
                        style: TextStyle(color: c2, fontSize: 9.5, fontWeight: FontWeight.w900, letterSpacing: .5),
                      ),
                    ),
                  ),
                  Positioned(left: 14, bottom: -26, child: IconaFluttuante(emoji, lato: 58, colore: c2)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 34, 14, 0),
              child: Text(
                nome,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: inchiostro, fontSize: 14.5, fontWeight: FontWeight.w800, height: 1.15),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 5, 14, 0),
                child: Text(
                  testo,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: testoMuto, fontSize: 12, height: 1.35),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(10, 8, 12, 10),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: grigio100)),
              ),
              child: Row(
                children: [
                  if (installazioni > 0) ...[
                    const PuntinoVivo(lato: 6),
                    Text(
                      numero(installazioni),
                      style: const TextStyle(color: inchiostro, fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(width: 8),
                  ] else
                    const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      piede,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: const TextStyle(color: grigio500, fontSize: 11.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Scena del colore del piano: puntini bianchi e un riflesso di luce che attraversa ogni tanto.
class ScenaAnimata extends StatefulWidget {
  const ScenaAnimata(this.c1, this.c2, {super.key});

  final Color c1, c2;

  @override
  State<ScenaAnimata> createState() => _ScenaAnimataState();
}

class _ScenaAnimataState extends State<ScenaAnimata> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 4200))
    ..repeat(period: Duration(milliseconds: 4200 + math.Random().nextInt(1800)));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: AnimatedBuilder(
      animation: _c,
      builder: (_, _) => CustomPaint(painter: _PittoreScena(widget.c1, widget.c2, _c.value)),
    ),
  );
}

class _PittoreScena extends CustomPainter {
  _PittoreScena(this.c1, this.c2, this.t);

  final Color c1, c2;
  final double t;

  @override
  void paint(Canvas canvas, Size s) {
    final r = Offset.zero & s;
    canvas.drawRect(
      r,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c1, c2],
        ).createShader(r),
    );
    final punto = Paint()..color = bianco.withValues(alpha: .16);
    for (double y = 8; y < s.height; y += 14) {
      for (double x = (y ~/ 14).isOdd ? 15 : 8; x < s.width; x += 14) {
        canvas.drawCircle(Offset(x, y), 1.3, punto);
      }
    }
    // riflesso: una fascia chiara inclinata che passa nel primo terzo del giro, poi pausa
    final p = (t * 3).clamp(0.0, 1.0);
    if (p > 0 && p < 1) {
      final x = -s.width * .6 + p * s.width * 2.2;
      canvas.save();
      canvas.clipRect(r);
      canvas.translate(x, 0);
      canvas.skew(-.5, 0);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, s.width * .25, s.height),
        Paint()
          ..shader = LinearGradient(
            colors: [bianco.withValues(alpha: 0), bianco.withValues(alpha: .28), bianco.withValues(alpha: 0)],
          ).createShader(Rect.fromLTWH(0, 0, s.width * .25, s.height)),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _PittoreScena old) => old.t != t || old.c1 != c1;
}

/// Icona (emoji) in un quadrato bianco con ombra, che sale e scende piano.
class IconaFluttuante extends StatefulWidget {
  const IconaFluttuante(this.emoji, {super.key, this.lato = 58, this.colore = accento});

  final String emoji;
  final double lato;
  final Color colore;

  @override
  State<IconaFluttuante> createState() => _IconaFluttuanteState();
}

class _IconaFluttuanteState extends State<IconaFluttuante> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 2600 + math.Random().nextInt(900)),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, figlio) =>
        Transform.translate(offset: Offset(0, -3 * Curves.easeInOut.transform(_c.value)), child: figlio),
    child: Container(
      width: widget.lato,
      height: widget.lato,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bianco,
        borderRadius: BorderRadius.circular(widget.lato * .3),
        boxShadow: [BoxShadow(color: widget.colore.withValues(alpha: .35), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Text(widget.emoji, style: TextStyle(fontSize: widget.lato * .5)),
    ),
  );
}
