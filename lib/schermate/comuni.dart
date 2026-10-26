// Pezzi usati da più schermate: immagini dal sito (in cache, leggibili senza rete), card degli articoli, link.
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../dati/archivio.dart';
import '../dati/formati.dart';
import '../dati/modelli.dart';
import '../tema.dart';
import 'lettore.dart';

/// Apre un indirizzo nel browser (o nell'app giusta: PayPal, Instagram…).
Future<void> apriLink(BuildContext context, String url) async {
  final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication).catchError((_) => false);
  if (!ok && context.mounted) avviso(context, 'Non riesco ad aprire il link');
}

void apriArticolo(BuildContext context, Articolo a) => Navigator.of(context).push(
  PageRouteBuilder<void>(
    transitionDuration: const Duration(milliseconds: 420),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (_, _, _) => SchermataLettore(articolo: a),
    transitionsBuilder: (_, anim, _, figlio) {
      final c = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: c,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, .06), end: Offset.zero).animate(c),
          child: figlio,
        ),
      );
    },
  ),
);

/// Solo per le foto delle schermate nei test: immagini da file locali invece che dalla rete.
@visibleForTesting
ImageProvider? Function(String url)? immaginiDiProva;

/// Immagine dal sito con un riflesso che scorre mentre arriva; senza rete e senza copia, un fondo col logo.
class ImmagineRete extends StatelessWidget {
  const ImmagineRete(this.url, {super.key, this.fit = BoxFit.cover, this.alt});

  final String url;
  final BoxFit fit;
  final String? alt;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return const _Segnaposto();
    final prova = immaginiDiProva?.call(url);
    if (prova != null) return Image(image: prova, fit: fit);
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 280),
      placeholder: (_, _) => const Luccichio(),
      errorWidget: (_, _, _) => const _Segnaposto(),
    );
  }
}

class _Segnaposto extends StatelessWidget {
  const _Segnaposto();

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(gradient: LinearGradient(colors: [inchiostro2, inchiostro3])),
    alignment: Alignment.center,
    child: Opacity(opacity: .5, child: logoPietro(52)),
  );
}

/// Riflesso grigio che scorre (attesa di immagini e card).
class Luccichio extends StatefulWidget {
  const Luccichio({super.key, this.raggio = 0});

  final double raggio;

  @override
  State<Luccichio> createState() => _LuccichioState();
}

class _LuccichioState extends State<Luccichio> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, _) => Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.raggio),
        gradient: LinearGradient(
          begin: Alignment(-1.5 + _c.value * 3, -.3),
          end: Alignment(-.5 + _c.value * 3, .3),
          colors: const [grigio200, grigio100, grigio200],
        ),
      ),
    ),
  );
}

/// Card grande: copertina a tutta larghezza con il titolo sopra, sfumato (primo articolo, carosello).
class CardArticoloGrande extends StatelessWidget {
  const CardArticoloGrande(this.a, {super.key, this.altezza = 300, this.etichetta});

  final Articolo a;
  final double altezza;
  final String? etichetta;

  @override
  Widget build(BuildContext context) => Premibile(
    onTap: () => apriArticolo(context, a),
    child: Container(
      height: altezza,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x2A0B1424), blurRadius: 24, offset: Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ImmagineRete(a.copertina.isNotEmpty ? a.copertina : a.immagine),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [.25, 1],
                  colors: [Color(0x000B1424), Color(0xF00B1424)],
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (etichetta != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(color: sole, borderRadius: BorderRadius.circular(20)),
                          child: Text(
                            etichetta!.toUpperCase(),
                            style: const TextStyle(
                              color: inchiostro,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (a.categorie.isNotEmpty)
                        Text(
                          a.categorie.first.nome.toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF9CC9F5),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    a.titolo,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: stileTitolo(22, colore: bianco, altezza: 1.15),
                  ),
                  const SizedBox(height: 10),
                  _Dettagli(a, chiaro: true),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Riga compatta: miniatura a sinistra, titolo e dettagli a destra.
class RigaArticolo extends StatelessWidget {
  const RigaArticolo(this.a, {super.key, this.azione});

  final Articolo a;
  final Widget? azione;

  @override
  Widget build(BuildContext context) {
    final letto = archivio.letti.contains(a.id);
    return Premibile(
      onTap: () => apriArticolo(context, a),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bianco,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Color(0x0F0B1424), blurRadius: 14, offset: Offset(0, 4))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(width: 104, height: 104, child: ImmagineRete(a.immagine)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 104,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (a.categorie.isNotEmpty)
                          Flexible(
                            child: Text(
                              a.categorie.first.nome.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: accentoScuro,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: .8,
                              ),
                            ),
                          ),
                        if (letto) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.check_circle_rounded, size: 13, color: grigio400),
                        ],
                        const Spacer(),
                        ?azione,
                      ],
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        a.titolo,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: stileTitolo(
                          15.5,
                          peso: FontWeight.w600,
                          colore: letto ? testoMuto : inchiostro,
                          altezza: 1.2,
                        ),
                      ),
                    ),
                    _Dettagli(a),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dettagli extends StatelessWidget {
  const _Dettagli(this.a, {this.chiaro = false});

  final Articolo a;
  final bool chiaro;

  @override
  Widget build(BuildContext context) {
    final c = chiaro ? grigio300 : grigio500;
    final s = TextStyle(color: c, fontSize: 11.5, fontWeight: FontWeight.w600);
    return Row(
      children: [
        Flexible(
          child: Text(
            tempoFa(a.data, breve: !chiaro),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: s,
          ),
        ),
        Text('  ·  ', style: s),
        Icon(Icons.schedule_rounded, size: 12.5, color: c),
        Text(' ${a.minuti} min', style: s),
        if (a.letture > 0) ...[
          Text('  ·  ', style: s),
          Icon(Icons.visibility_outlined, size: 12.5, color: c),
          Text(' ${numero(a.letture)}', style: s),
        ],
      ],
    );
  }
}

/// Pulsante «salva» col segnalibro che si riempie.
class TastoSalva extends StatelessWidget {
  const TastoSalva(this.a, {super.key, this.chiaro = false});

  final Articolo a;
  final bool chiaro;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: archivio,
    builder: (context, _) {
      final salvato = archivio.eSalvato(a.id);
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () async {
          try {
            await archivio.alterna(a);
            if (context.mounted) {
              avviso(context, salvato ? 'Tolto dai salvati' : 'Salvato: lo leggi anche senza internet');
            }
          } catch (e) {
            if (context.mounted) avviso(context, '$e');
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (c, an) => ScaleTransition(scale: an, child: c),
            child: Icon(
              salvato ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              key: ValueKey(salvato),
              size: 20,
              color: salvato ? sole : (chiaro ? bianco : grigio400),
            ),
          ),
        ),
      );
    },
  );
}

/// Barra d'errore discreta: «senza rete, stai vedendo la copia sul telefono».
class AvvisoRete extends StatelessWidget {
  const AvvisoRete(this.testo, {super.key, this.riprova});

  final String testo;
  final VoidCallback? riprova;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
    decoration: BoxDecoration(color: const Color(0xFFFFF7E6), borderRadius: BorderRadius.circular(14)),
    child: Row(
      children: [
        const Icon(Icons.cloud_off_rounded, color: Color(0xFFB7791F), size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            testo,
            style: const TextStyle(color: Color(0xFF7A4F0C), fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
        ),
        if (riprova != null) TextButton(onPressed: riprova, child: const Text('Riprova')),
      ],
    ),
  );
}
