// Splash di pietrodefilippis.it: come quello del kit (logo che respira, nome, motto, firma e versione), ma col logo
// tondo di Pietro e l'alone tondo, sul fondo inchiostro a griglia del sito. Il kit ha l'ombra quadrata delle icone TK.
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../tema.dart';

/// Mostra lo splash per almeno [durata], poi passa a [child] con una dissolvenza.
class ConAvvioPietro extends StatefulWidget {
  const ConAvvioPietro({super.key, required this.child, this.durata = const Duration(milliseconds: 1800)});

  final Widget child;
  final Duration durata;

  @override
  State<ConAvvioPietro> createState() => _ConAvvioPietroState();
}

class _ConAvvioPietroState extends State<ConAvvioPietro> {
  bool _pronto = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.durata, () {
      if (mounted) setState(() => _pronto = true);
    });
  }

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 400),
    child: _pronto ? widget.child : const AvvioPietro(),
  );
}

class AvvioPietro extends StatefulWidget {
  const AvvioPietro({super.key});

  @override
  State<AvvioPietro> createState() => _AvvioPietroState();
}

class _AvvioPietroState extends State<AvvioPietro> with SingleTickerProviderStateMixin {
  late final _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
    ..repeat(reverse: true);
  String _versione = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform()
        .then((i) {
          if (mounted) setState(() => _versione = i.version);
        })
        .catchError((_) {});
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: inchiostro,
    body: FondoGriglia(
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _anim,
                  builder: (_, _) {
                    final t = Curves.easeInOut.transform(_anim.value);
                    final scala = .94 + .12 * t;
                    return SizedBox(
                      width: 190,
                      height: 190,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Transform.scale(
                            scale: scala,
                            child: Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: accento.withValues(alpha: .10 + .12 * t),
                              ),
                            ),
                          ),
                          Transform.scale(
                            scale: scala,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: accento.withValues(alpha: .35 + .25 * t),
                                    blurRadius: 30,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: logoPietro(128),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 26),
                Text(configTk.nome, style: stileTitolo(34, colore: bianco)),
                const SizedBox(height: 8),
                Text(
                  configTk.motto.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: sole, fontSize: 13, letterSpacing: 4, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 36 + MediaQuery.of(context).padding.bottom,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Text(
                  'TecnikGeek',
                  style: TextStyle(color: grigio300, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1),
                ),
                const SizedBox(height: 2),
                Text(_versione.isEmpty ? '' : 'v$_versione', style: const TextStyle(color: grigio500, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
