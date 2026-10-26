// Colori e pezzi propri di tk-pietro (quelli del sito pietrodefilippis.it); testata, card, dialoghi, Informazioni e
// splash sono nel kit comune.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'kit_tk.dart';

export 'kit_tk.dart';

const accento = Color(0xFF2093EC); // --pd-blue del sito
const accentoScuro = Color(0xFF1272C2); // --pd-blue-d
const sole = Color(0xFFFFC23D); // --pd-sun
const inchiostro = Color(0xFF0B1424); // --pd-ink
const inchiostro2 = Color(0xFF13213B);
const inchiostro3 = Color(0xFF1D2F50);
const carta = Color(0xFFF4F7FB); // --pd-paper
const cielo = Color(0xFFE7F2FD); // --pd-sky
const testoPieno = Color(0xFF1C2433);
const testoMuto = Color(0xFF5B6577);

/// Carattere dei titoli del sito.
const titoli = 'Fraunces';

TextStyle stileTitolo(double misura, {Color colore = inchiostro, FontWeight peso = FontWeight.w800, double? altezza}) =>
    TextStyle(
      fontFamily: titoli,
      fontSize: misura,
      fontWeight: peso,
      color: colore,
      height: altezza ?? 1.12,
      letterSpacing: -.4,
    );

/// Simbolo di tk-pietro: la «P» del sito in Fraunces col puntino giallo del sole.
Widget simboloPietro(double lato) => SizedBox(
  width: lato,
  height: lato,
  child: Stack(
    alignment: Alignment.center,
    children: [
      Text('P', style: stileTitolo(lato * .62, colore: bianco, altezza: 1)),
      Positioned(
        right: lato * .2,
        top: lato * .2,
        child: Container(
          width: lato * .13,
          height: lato * .13,
          decoration: const BoxDecoration(color: sole, shape: BoxShape.circle),
        ),
      ),
    ],
  ),
);

/// Il logo di Pietro (quello del sito): testata, avvio e Informazioni lo mostrano al posto del simbolo.
Widget logoPietro(double lato) =>
    Image.asset('assets/img/logo.png', width: lato, height: lato, filterQuality: FilterQuality.medium);

const configPietro = ConfigTk(
  nome: 'pietrodefilippis.it',
  repo: 'tk-pietro-app',
  motto: 'Il mio mondo in tasca',
  descrizione: 'Articoli, plugin, app e programmi di Pietro De Filippis',
  accento: accento,
  accentoScuro: accentoScuro,
  simbolo: simboloPietro,
  logoOriginale: logoPietro,
  avvioColorato: false,
  manifestUrl: 'https://dl.dropboxusercontent.com/scl/fi/fwpblmzfvuc3nnt12ihtm/pietro-version.json?rlkey=x1qcujw1p5oxva4v7z6vnp1us',
);

// ───────────────────────── colori della vetrina ─────────────────────────

/// Due colori della «scena» in alto nelle card, come sul sito: verde Free, blu Free + Pro, viola Solo Pro,
/// verde acqua i programmi, arancio le app, rosa i giochi, indaco i temi.
(Color, Color) coloriScena(String tipo) => switch (tipo) {
  'gratuito' => (const Color(0xFF22C55E), const Color(0xFF15803D)),
  'free-pro' => (accento, accentoScuro),
  'solo-pro' => (const Color(0xFF8B5CF6), const Color(0xFF5B21B6)),
  'software' => (const Color(0xFF14B8A6), const Color(0xFF0F766E)),
  'app' => (const Color(0xFFF97316), const Color(0xFFC2410C)),
  'giochi' => (const Color(0xFFEC4899), const Color(0xFFBE185D)),
  'tema' => (const Color(0xFF6366F1), const Color(0xFF3730A3)),
  _ => (navy3, navy),
};

String etichettaTipo(String tipo) => switch (tipo) {
  'gratuito' => 'Free',
  'free-pro' => 'Free + Pro',
  'solo-pro' => 'Solo Pro',
  'software' => 'Programma',
  'app' => 'App',
  'giochi' => 'Gioco',
  'tema' => 'Tema',
  _ => tipo,
};

// ───────────────────────── pezzi grafici ─────────────────────────

/// Fondo «inchiostro» del sito con la griglia sottile e due aloni di luce (testate wouuu).
class FondoGriglia extends StatelessWidget {
  const FondoGriglia({super.key, required this.child, this.colore = inchiostro, this.alone = accento});

  final Widget child;
  final Color colore, alone;

  @override
  Widget build(BuildContext context) => Container(
    color: colore,
    child: CustomPaint(painter: _PittoreGriglia(alone), child: child),
  );
}

class _PittoreGriglia extends CustomPainter {
  _PittoreGriglia(this.alone);

  final Color alone;

  @override
  void paint(Canvas canvas, Size size) {
    final linea = Paint()
      ..color = bianco.withValues(alpha: .045)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 34) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linea);
    }
    for (double y = 0; y < size.height; y += 34) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linea);
    }
    void luce(Offset c, double r, Color col) => canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(colors: [col.withValues(alpha: .38), col.withValues(alpha: 0)])
            .createShader(Rect.fromCircle(center: c, radius: r)),
    );
    luce(Offset(size.width * .9, size.height * .1), size.width * .7, alone);
    luce(Offset(size.width * .05, size.height * .95), size.width * .55, sole.withValues(alpha: .5));
  }

  @override
  bool shouldRepaint(covariant _PittoreGriglia old) => old.alone != alone;
}

/// Entra in scena scivolando dal basso, con un ritardo (liste che si compongono una card alla volta).
class Entrata extends StatelessWidget {
  const Entrata({super.key, required this.child, this.ritardo = 0, this.spostamento = 24});

  final Widget child;
  final int ritardo; // in passi da 60 ms
  final double spostamento;

  @override
  Widget build(BuildContext context) {
    final durata = 420 + math.min(ritardo, 8) * 60;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: durata),
      curve: Interval((durata - 420) / durata, 1, curve: Curves.easeOutCubic),
      builder: (_, v, c) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, (1 - v) * spostamento), child: c),
      ),
      child: child,
    );
  }
}

/// Si abbassa un poco sotto il dito.
class Premibile extends StatefulWidget {
  const Premibile({super.key, required this.child, required this.onTap, this.onLongPress});

  final Widget child;
  final VoidCallback? onTap, onLongPress;

  @override
  State<Premibile> createState() => _PremibileState();
}

class _PremibileState extends State<Premibile> {
  bool _giu = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTapDown: (_) => setState(() => _giu = true),
    onTapUp: (_) => setState(() => _giu = false),
    onTapCancel: () => setState(() => _giu = false),
    onTap: widget.onTap,
    onLongPress: widget.onLongPress,
    child: AnimatedScale(
      scale: _giu ? .965 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: widget.child,
    ),
  );
}

/// Puntino verde che pulsa (installazioni attive, «in diretta»).
class PuntinoVivo extends StatefulWidget {
  const PuntinoVivo({super.key, this.colore = const Color(0xFF22C55E), this.lato = 8});

  final Color colore;
  final double lato;

  @override
  State<PuntinoVivo> createState() => _PuntinoVivoState();
}

class _PuntinoVivoState extends State<PuntinoVivo> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: widget.lato * 2.4,
    height: widget.lato * 2.4,
    child: AnimatedBuilder(
      animation: _c,
      builder: (_, _) => Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: widget.lato * (1 + _c.value * 1.4),
            height: widget.lato * (1 + _c.value * 1.4),
            decoration: BoxDecoration(
              color: widget.colore.withValues(alpha: (1 - _c.value) * .45),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: widget.lato,
            height: widget.lato,
            decoration: BoxDecoration(color: widget.colore, shape: BoxShape.circle),
          ),
        ],
      ),
    ),
  );
}

/// Pillola chiara con icona (categorie, minuti di lettura, letture).
class Gettone extends StatelessWidget {
  const Gettone(this.testo, {super.key, this.icona, this.colore = testoMuto, this.fondo = grigio100});

  final String testo;
  final IconData? icona;
  final Color colore, fondo;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(20)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icona != null) ...[Icon(icona, size: 13, color: colore), const SizedBox(width: 4)],
        Text(
          testo,
          style: TextStyle(color: colore, fontSize: 11.5, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

/// Riquadro «niente da mostrare» con icona.
class StatoVuoto extends StatelessWidget {
  const StatoVuoto(this.icona, this.titolo, this.sottotitolo, {super.key, this.azione});

  final IconData icona;
  final String titolo, sottotitolo;
  final Widget? azione;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(color: cielo, borderRadius: BorderRadius.circular(22)),
          child: Icon(icona, color: accentoScuro, size: 34),
        ),
        const SizedBox(height: 14),
        Text(titolo, textAlign: TextAlign.center, style: stileTitolo(20)),
        const SizedBox(height: 6),
        Text(
          sottotitolo,
          textAlign: TextAlign.center,
          style: const TextStyle(color: testoMuto, fontSize: 14, fontWeight: FontWeight.w500, height: 1.4),
        ),
        if (azione != null) ...[const SizedBox(height: 16), azione!],
      ],
    ),
  );
}
