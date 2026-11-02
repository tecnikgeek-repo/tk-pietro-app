// L'aspetto della chat scelto nel pannello del sito (puntini, logo, colori): arriva insieme al nonce,
// così l'app coincide col sito senza doverla aggiornare. Stessi disegni e tempi del foglio di stile del plugin.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AspettoAi {
  const AspettoAi({this.puntini = 'tondi', this.colore, this.logoSvg = '', this.logoVista = '', this.logoColore, this.logoTesto});

  factory AspettoAi.daJson(Map<dynamic, dynamic> j) => AspettoAi(
    puntini: j['puntini'] as String? ?? 'tondi',
    colore: _esa(j['colore']),
    logoSvg: j['logoSvg'] as String? ?? '',
    logoVista: j['logoVista'] as String? ?? '',
    logoColore: _esa(j['logoColore']),
    logoTesto: _esa(j['logoTesto']),
  );

  final String puntini;
  final Color? colore;
  final String logoSvg;
  final String logoVista;
  final Color? logoColore;
  final Color? logoTesto;

  static Color? _esa(Object? v) {
    final s = '$v'.replaceAll('#', '');
    final n = s.length == 6 ? int.tryParse(s, radix: 16) : null;
    return n == null ? null : Color(0xFF000000 | n);
  }
}

final aspettoAi = ValueNotifier<AspettoAi>(const AspettoAi());

/// Domanda arrivata da fuori dalla chat (home): vuota = apre la chat col campo pronto.
final domandaPerAi = ValueNotifier<String?>(null);

/// Il logo scelto nel pannello; se è quello di sempre resta il disegno dell'app.
class LogoAi extends StatelessWidget {
  const LogoAi({super.key, required this.predefinito});

  final Widget predefinito;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<AspettoAi>(
    valueListenable: aspettoAi,
    builder: (_, a, _) {
      if (a.logoSvg.isEmpty) return predefinito;
      final colore = a.logoTesto ?? Colors.white;
      final esa = colore.toARGB32().toRadixString(16).padLeft(8, '0').substring(2);
      return SvgPicture.string(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="${a.logoVista}">${a.logoSvg.replaceAll('currentColor', '#$esa')}</svg>',
      );
    },
  );
}

/// I tre puntini dell'attesa, nello stile scelto nel pannello.
class PuntiniAi extends StatefulWidget {
  const PuntiniAi({super.key});

  @override
  State<PuntiniAi> createState() => _PuntiniAiState();
}

class _PuntiniAiState extends State<PuntiniAi> with SingleTickerProviderStateMixin {
  static const _giro = 66; // secondi: multiplo di tutti i tempi, così il ritorno a capo non si vede
  late final _c = AnimationController(vsync: this, duration: const Duration(seconds: _giro))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// A che punto (0–1) è un puntino in un'animazione lunga [durata] secondi.
  double _fase(double durata, double ritardo) => (((_c.value * _giro - ritardo) / durata) % 1 + 1) % 1;

  double _onda(double p) => .5 - .5 * math.cos(p * 2 * math.pi);

  Widget _punto(double lato, double raggio, Color colore, {double alfa = 1, Border? bordo}) => Container(
    width: lato,
    height: lato,
    decoration: BoxDecoration(
      color: bordo == null ? colore.withValues(alpha: alfa) : null,
      border: bordo,
      borderRadius: BorderRadius.circular(raggio),
    ),
  );

  List<Widget> _stile(String s) {
    const bianco = Colors.white;
    final rit = [0.0, .2, .4];
    switch (s) {
      case 'quadretti':
        const colori = [Color(0xFF2093EC), Color(0xFF8CC6F7), Color(0xFFFFC23D)];
        return [
          for (var i = 0; i < 3; i++)
            Builder(
              builder: (_) {
                final v = _onda(_fase(1, i * .15));
                return Transform.translate(
                  offset: Offset(0, -5 * v),
                  child: _punto(8, 2, colori[i], alfa: .35 + .65 * v),
                );
              },
            ),
        ];
      case 'barre':
        return [
          for (var i = 0; i < 3; i++)
            Transform.scale(
              scaleY: .35 + .65 * _onda(_fase(1, rit[i])),
              child: Container(
                width: 4,
                height: 15,
                decoration: BoxDecoration(color: bianco.withValues(alpha: .85), borderRadius: BorderRadius.circular(2)),
              ),
            ),
        ];
      case 'respiro':
      case 'anelli':
        return [
          for (var i = 0; i < 3; i++)
            Builder(
              builder: (_) {
                final v = _onda(_fase(1.3, rit[i]));
                final alfa = .3 + .7 * v;
                return Transform.scale(
                  scale: .55 + .55 * v,
                  child: s == 'anelli'
                      ? _punto(9, 5, bianco, bordo: Border.all(color: bianco.withValues(alpha: alfa), width: 2))
                      : _punto(8, 4, bianco, alfa: alfa),
                );
              },
            ),
        ];
      case 'rombi':
        return [
          for (var i = 0; i < 3; i++)
            Builder(
              builder: (_) {
                final v = _onda(_fase(1.2, rit[i]));
                return Transform.rotate(
                  angle: math.pi / 4,
                  child: Transform.scale(scale: .6 + .5 * v, child: _punto(7, 1, bianco, alfa: .3 + .7 * v)),
                );
              },
            ),
        ];
      case 'scia':
        return [
          for (var i = 0; i < 3; i++)
            Builder(
              builder: (_) {
                final p = _fase(1.1, rit[i]);
                final v = p < .35 ? p / .35 : (1 - p) / .65;
                return _punto(7, 4, bianco, alfa: .15 + .85 * v);
              },
            ),
        ];
      default: // tondi
        return [
          for (var i = 0; i < 3; i++)
            Builder(
              builder: (_) {
                final p = _fase(1.2, rit[i]);
                final v = p < .6 ? math.sin(p / .6 * math.pi) : 0.0;
                return Transform.translate(
                  offset: Offset(0, -3 * v),
                  child: _punto(6, 3, bianco, alfa: .3 + .6 * v),
                );
              },
            ),
        ];
    }
  }

  Widget _orbita() => Transform.rotate(
    angle: _fase(1.1, 0) * 2 * math.pi,
    child: SizedBox(
      width: 18,
      height: 18,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (final (i, alfa) in const [1.0, .65, .35].indexed)
            Transform.rotate(
              angle: i * 2 * math.pi / 3,
              child: Transform.translate(offset: const Offset(0, -7), child: _punto(5, 3, Colors.white, alfa: alfa)),
            ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<AspettoAi>(
    valueListenable: aspettoAi,
    builder: (_, a, _) => AnimatedBuilder(
      animation: _c,
      builder: (_, _) {
        if (a.puntini == 'orbita') return _orbita();
        final spazio = a.puntini == 'quadretti' ? 5.0 : (a.puntini == 'rombi' ? 7.0 : 4.0);
        final pezzi = _stile(a.puntini);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (i, p) in pezzi.indexed) ...[if (i > 0) SizedBox(width: spazio), p],
          ],
        );
      },
    ),
  );
}
