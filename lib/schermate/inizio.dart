// Scheda «Inizio»: chi sono, numeri del sito che contano da soli, ultimo articolo, carosello «da leggere»,
// assaggio della vetrina, invito alle notifiche, caffè e social.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../dati/archivio.dart';
import '../dati/formati.dart';
import '../dati/modelli.dart';
import '../dati/notifiche.dart';
import '../tema.dart';
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
              const SizedBox(height: 22),
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
          borderRadius: BorderRadius.circular(28),
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
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: bianco.withValues(alpha: .7), width: 2.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: Image.asset('assets/img/pietro.jpg', fit: BoxFit.cover, alignment: const Alignment(0, -.55)),
            ),
          ),
        ),
        Positioned(
          right: -8,
          bottom: 14,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: sole,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Color(0x400B1424), blurRadius: 10, offset: Offset(0, 4))],
            ),
            child: const Text(
              'NAPOLI',
              style: TextStyle(color: inchiostro, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: .8),
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
