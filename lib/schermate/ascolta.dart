// «Ascolta questo articolo», come il lettore vocale del sito: la voce italiana del telefono legge titolo e testo
// a pezzi di qualche frase (Android non accetta testi lunghi in una volta), con barra, pausa e velocità.
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../tema.dart';

/// Testo da leggere: titolo e articolo senza HTML, a pezzi di al massimo [max] caratteri tagliati sulle frasi.
List<String> pezziDaLeggere(String titolo, String html, {int max = 400}) {
  final testo = html
      .replaceAll(RegExp(r'<(script|style|figure|figcaption|iframe)[^>]*>.*?</\1>', dotAll: true), ' ')
      .replaceAll(RegExp(r'</(p|h\d|li|blockquote)>'), '. ')
      .replaceAll(RegExp(r'<[^>]+>'), ' ')
      .replaceAll(RegExp(r'&nbsp;|&#160;'), ' ')
      .replaceAll(RegExp(r'&#8217;|&rsquo;'), '’')
      .replaceAll(RegExp(r'&#8220;|&#8221;|&ldquo;|&rdquo;|&quot;'), '"')
      .replaceAll('&amp;', '&')
      .replaceAll(RegExp(r'&[#a-z0-9]+;'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'(\.\s*){2,}'), '. ');
  final frasi = RegExp(r'[^.!?…]+[.!?…]*')
      .allMatches('$titolo. $testo')
      .map((m) => m[0]!.trim())
      .where((f) => f.length > 1);
  final pezzi = <String>[];
  var cur = '';
  for (final f in frasi) {
    if (cur.isNotEmpty && cur.length + f.length + 1 > max) {
      pezzi.add(cur);
      cur = '';
    }
    cur = cur.isEmpty ? f : '$cur $f';
  }
  if (cur.isNotEmpty) pezzi.add(cur);
  return pezzi;
}

class Ascolta extends StatefulWidget {
  const Ascolta({super.key, required this.titolo, required this.html, this.scuro = false});

  final String titolo, html;
  final bool scuro;

  @override
  State<Ascolta> createState() => _AscoltaState();
}

const _velocita = [1.0, 1.25, 1.5, .75];

class _AscoltaState extends State<Ascolta> {
  final _tts = FlutterTts();
  late final List<String> _pezzi = pezziDaLeggere(widget.titolo, widget.html);
  late final int _totale = _pezzi.fold(0, (a, p) => a + p.length);
  int _i = 0, _fatti = 0, _nelPezzo = 0;
  int _vel = 0;
  bool _parla = false, _pronto = false;
  String? _errore;

  @override
  void initState() {
    super.initState();
    _prepara();
  }

  Future<void> _prepara() async {
    try {
      await _tts.setLanguage('it-IT');
      await _tts.awaitSpeakCompletion(true);
      _tts.setProgressHandler((_, inizio, _, _) {
        if (mounted) setState(() => _nelPezzo = inizio);
      });
      _tts.setErrorHandler((m) {
        if (mounted) setState(() => _errore = 'La voce del telefono non risponde');
      });
      _pronto = true;
    } catch (_) {
      _errore = 'Su questo telefono manca la voce italiana';
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _parla = false;
    _tts.stop().catchError((_) => null);
    super.dispose();
  }

  /// Velocità: Android parla «normale» a 0.5.
  double get _rate => .5 * _velocita[_vel];

  Future<void> _leggi() async {
    if (!_pronto || _pezzi.isEmpty) return;
    if (_i >= _pezzi.length) {
      _i = 0;
      _fatti = 0;
    }
    setState(() => _parla = true);
    await _tts.setSpeechRate(_rate);
    while (_parla && _i < _pezzi.length) {
      _nelPezzo = 0;
      await _tts.speak(_pezzi[_i]);
      if (!_parla || !mounted) return;
      _fatti += _pezzi[_i].length;
      _i++;
    }
    if (mounted) setState(() => _parla = false);
  }

  Future<void> _ferma() async {
    setState(() => _parla = false);
    await _tts.stop(); // si riprende dall'inizio del pezzo (qualche frase): niente parole perse
  }

  Future<void> _cambiaVelocita() async {
    setState(() => _vel = (_vel + 1) % _velocita.length);
    if (_parla) {
      await _tts.stop();
      _parla = false;
      _leggi();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scuro = widget.scuro;
    final minuti = (_totale / 6 / 150 / _velocita[_vel]).ceil().clamp(1, 99);
    final avanzamento = _totale == 0 ? 0.0 : ((_fatti + _nelPezzo) / _totale).clamp(0.0, 1.0);
    final v = _velocita[_vel];
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: scuro ? inchiostro2 : bianco,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scuro ? inchiostro3 : grigio200),
        boxShadow: scuro ? null : const [BoxShadow(color: Color(0x0F0B1424), blurRadius: 16, offset: Offset(0, 6))],
      ),
      child: Row(
        children: [
          Premibile(
            onTap: _errore != null ? null : (_parla ? _ferma : _leggi),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [accento, accentoScuro]),
                boxShadow: [
                  BoxShadow(
                    color: accento.withValues(alpha: _parla ? .55 : .3),
                    blurRadius: _parla ? 18 : 10,
                  ),
                ],
              ),
              child: Icon(
                _parla ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: bianco,
                size: 28,
                semanticLabel: _parla ? 'Pausa' : 'Ascolta',
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _errore ?? 'Ascolta questo articolo',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _errore != null ? grigio500 : (scuro ? bianco : inchiostro),
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                        ),
                      ),
                    ),
                    Text(
                      '$minuti min',
                      style: const TextStyle(color: grigio500, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: avanzamento,
                    minHeight: 5,
                    color: accento,
                    backgroundColor: scuro ? inchiostro3 : grigio200,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Premibile(
            onTap: _cambiaVelocita,
            child: Container(
              width: 50,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scuro ? inchiostro3 : grigio100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${v == v.roundToDouble() ? v.toInt() : v.toString().replaceAll('.', ',')}×',
                style: TextStyle(color: scuro ? bianco : inchiostro, fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
