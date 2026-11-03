// Scheda «AI»: la chat con tk-ai, l'intelligenza artificiale di Pietro, come la modalità AI del sito (notte,
// griglia e aloni). La domanda diventa un titolo, la risposta un piccolo articolo con i link, sotto le pagine del
// sito usate («Per saperne di più»). Si può mandare una foto o un vocale di 30 secondi. Risponde il sito
// (REST tk-ai/v1/chat), che cerca nelle sue pagine e chiede al motore tk-ai.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../dati/api.dart';
import '../dati/archivio.dart';
import '../dati/modelli.dart';
import '../tema.dart';
import 'aspetto_ai.dart';
import 'comuni.dart';
import 'home.dart';

const _suggerite = [
  'Che plugin hai per WordPress?',
  'Quali app hai fatto?',
  'Di cosa parla il blog?',
  'Fai anche siti per i negozi?',
];
const _pensando = [
  'Sto pensando',
  'Cerco per te',
  'Sto guardando',
  'Ci sono',
  'Un momento',
  'Mi informo',
  'Sto verificando',
  'Lo sto cercando',
  'Faccio un controllo',
  'Sto mettendo insieme tutto',
  'Vediamo un po\'',
  'Sto ragionando',
  'Ci sto pensando',
  'Do un\'occhiata',
  'Raccolgo le informazioni',
  'Sto scrivendo',
  'Un secondo soltanto',
  'Metto in ordine le idee',
  'Sto trovando le parole',
  'Ancora un istante',
  'Arrivo subito',
  'Ci penso un attimo',
  'Un attimo',
  'Fammi controllare',
  'Sto cercando',
  'Sto leggendo',
  'Cerco la risposta',
  'Controllo un attimo',
  'Preparo la risposta',
  'Verifico subito',
  'Ci guardo subito',
  'Dammi un secondo',
  'Sto controllando',
  'Guardo meglio',
  'Ci sto lavorando',
];
const _quasi = [
  'Ci sono quasi, ancora qualche secondo…',
  'Ci sto mettendo un po\', ma ci arrivo…',
  'È una ricerca lunga, abbi pazienza…',
  'Non mi sono dimenticato di te…',
  'Sto ancora cercando il meglio per te…',
  'Un altro po\' e ti rispondo…',
  'Sto controllando ancora una cosa…',
  'Grazie per la pazienza, quasi ci siamo…',
  'Ancora poco e finisco…',
  'Sto dando gli ultimi ritocchi…',
  'Eccomi quasi, resta con me…',
  'Quasi fatto, un altro momento…',
  'Manca poco, resta qui…',
  'Sto finendo, ancora un attimo…',
  'Ancora qualche secondo e ci siamo…',
];
const _titoliFonti = [
  'Per saperne di più',
  'Forse ti interessa',
  'Guarda anche',
  'Qualcosa in più',
  'Da vedere',
  'Vai più a fondo',
  'Trovi tutto qui',
  'Ecco dove guardare',
  'Ne parliamo anche qui',
  'Vuoi leggere di più?',
  'Altri dettagli',
  'Può tornarti utile',
  'Se ti incuriosisce',
  'Dai uno sguardo',
  'Tutti i dettagli',
  'Puoi vedere anche',
  'Ti lascio questi',
  'Un passo in più',
  'Da qui puoi continuare',
  'Le pagine giuste',
  'Per chi vuole di più',
  'Vuoi più info?',
  'Approfondisci qui',
  'Leggi anche',
  'Vuoi approfondire?',
  'Da leggere',
  'Ti può interessare',
  'Qui trovi di più',
  'Per approfondire',
  'Scopri di più',
  'Continua a leggere',
  'Altre informazioni',
  'Se vuoi saperne di più',
  'Dai un\'occhiata',
  'Può esserti utile',
];
final _caso = math.Random();
String _unaDi(List<String> v) => v[_caso.nextInt(v.length)];
/// Il colore della chat: quello scelto nel pannello del sito.
Color get _accentoAi => aspettoAi.value.colore ?? accento;
const _turchese = Color(0xFF22B8C9);
const _tenue = Color(0xFFA9B4CC);
const _maxStoria = 10;

/// Un turno della conversazione: la domanda (con foto o vocale) e la risposta, quando arriva.
class _Turno {
  _Turno({required this.domanda, this.foto, this.vocale = false});

  String domanda;
  final List<int>? foto;
  final bool vocale;
  RispostaAi? risposta;
  String scritto = ''; // le parole man mano, finché non arriva la risposta definitiva
  final intanto = <String>[]; // i messaggi mentre aspetta: dopo 5 secondi, poi 10, poi 5…
  final titoloFonti = _unaDi(_titoliFonti);
  final chiaveRisposta = GlobalKey(); // con i messaggi d'attesa il turno è lungo: si va alla risposta
  final chiave = GlobalKey(); // per portare la risposta in vista dall'inizio del turno
}

class SchedaAi extends StatefulWidget {
  const SchedaAi({super.key});

  @override
  State<SchedaAi> createState() => _SchedaAiState();
}

class _SchedaAiState extends State<SchedaAi> with WidgetsBindingObserver {
  bool _tastiera = false;
  final _turni = <_Turno>[];
  final _storia = <Map<String, String>>[];
  final _campo = TextEditingController();
  final _scorri = ScrollController();
  final _fuoco = FocusNode();
  List<int>? _fotoPronta;
  bool _occupato = false;

  // vocale
  // creato solo al primo vocale: costruirlo subito parla col telefono anche a chi non lo usa
  AudioRecorder? _rec;
  AudioRecorder get _registratore => _rec ??= AudioRecorder();
  bool _registra = false;
  DateTime? _inizioVoce;
  Timer? _timerVoce;
  StreamSubscription<Amplitude>? _ampiezza;
  final _onde = ValueNotifier<List<double>>(List.filled(24, .15));
  String _versione = '';
  List<String>? _idee; // le domande suggerite di questa apertura

  void _scegliIdee() {
    final tutte = [...archivio.api.suggeriteAi]..shuffle();
    _idee = tutte.isEmpty ? _suggerite : tutte.take(archivio.api.visteAi).toList();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    domandaPerAi.addListener(_daFuori);
    WidgetsBinding.instance.addPostFrameCallback((_) => _daFuori());
    // la versione del motore che risponde: la dà il sito, così cambia da sola senza aggiornare l'app
    archivio.api.chiediVersioneAi().then((v) {
      if (!mounted) return;
      setState(() {
        _versione = v;
        _scegliIdee();
      });
    });
  }

  // Il campo sale e scende con la tastiera: senza questo, chiudendola la barra delle schede ci finiva sopra
  @override
  void didChangeMetrics() {
    if (!mounted) return;
    final t = View.of(context).viewInsets.bottom > 0;
    if (t != _tastiera) setState(() => _tastiera = t);
  }

  void _daFuori() {
    final d = domandaPerAi.value;
    if (d == null || !mounted || _occupato) return;
    domandaPerAi.value = null;
    if (d.isEmpty) {
      _fuoco.requestFocus();
    } else {
      _manda(testo: d);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    domandaPerAi.removeListener(_daFuori);
    _campo.dispose();
    _scorri.dispose();
    _fuoco.dispose();
    _timerVoce?.cancel();
    _ampiezza?.cancel();
    _rec?.dispose();
    _onde.dispose();
    super.dispose();
  }

  void _inFondo() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_scorri.hasClients) {
      _scorri.animateTo(
        _scorri.position.maxScrollExtent,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    }
  });

  // ───────────── invio ─────────────

  Future<void> _manda({String? testo, String? vocaleB64, int secondi = 0}) async {
    final t = (testo ?? _campo.text).trim();
    final foto = _fotoPronta;
    if (_occupato || (t.isEmpty && foto == null && vocaleB64 == null)) return;
    HapticFeedback.lightImpact();
    final turno = _Turno(
      domanda: vocaleB64 != null ? 'Messaggio vocale · $secondi s' : (t.isNotEmpty ? t : 'Cosa c\'è in questa foto?'),
      foto: foto,
      vocale: vocaleB64 != null,
    );
    setState(() {
      _occupato = true;
      _fotoPronta = null;
      _campo.clear();
      _turni.add(turno);
    });
    if (vocaleB64 == null) _storia.add({'ruolo': 'utente', 'testo': turno.domanda});
    _inFondo();
    Timer? disegno;
    void suPezzo(String? t) {
      final prima = turno.scritto.isEmpty;
      turno.scritto = t == null ? '' : turno.scritto + t;
      if (!mounted || disegno != null) return;
      disegno = Timer(const Duration(milliseconds: 60), () {
        disegno = null;
        if (!mounted || turno.risposta != null) return;
        // se si sta guardando il fondo, il testo resta in vista mentre si scrive
        final segui = _scorri.hasClients && _scorri.position.maxScrollExtent - _scorri.offset < 160;
        setState(() {});
        if (prima) {
          _inFondo();
        } else if (segui) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scorri.hasClients) _scorri.jumpTo(_scorri.position.maxScrollExtent);
          });
        }
      });
    }

    // la chat non resta muta: dopo 5 secondi, poi altri 10, poi 5… finché arriva la prima parola
    Timer? catena;
    final partito = DateTime.now();
    void suIntanto(List<String> testi) {
      void prossimo(int i, int dopo) {
        if (i >= testi.length) return;
        catena = Timer(Duration(seconds: dopo), () {
          if (!mounted || turno.risposta != null || turno.scritto.isNotEmpty) return;
          setState(() => turno.intanto.add(testi[i]));
          _inFondo();
          prossimo(i + 1, i.isOdd ? 5 : 10);
        });
      }

      prossimo(0, math.max(0, 5 - DateTime.now().difference(partito).inSeconds));
    }

    RispostaAi r;
    try {
      r = await archivio.api.chiediAi(
        _storia.sublist(math.max(0, _storia.length - _maxStoria)),
        foto: foto != null ? base64Encode(foto) : null,
        vocale: vocaleB64,
        suPezzo: suPezzo,
        suIntanto: suIntanto,
      );
    } on ErroreSito catch (e) {
      r = RispostaAi(ok: false, testo: e.messaggio);
    } catch (_) {
      r = const RispostaAi(ok: false, testo: 'In questo momento non riesco a rispondere: riprova tra poco o scrivimi.');
    }
    disegno?.cancel();
    catena?.cancel();
    if (!mounted) return;
    setState(() {
      if (turno.vocale && r.trascrizione.isNotEmpty) {
        turno.domanda = r.trascrizione;
        _storia.add({'ruolo': 'utente', 'testo': r.trascrizione});
      }
      turno.risposta = r;
      if (r.ok) {
        _storia.add({'ruolo': 'ai', 'testo': r.testo});
      } else if (!turno.vocale && _storia.isNotEmpty) {
        _storia.removeLast(); // la risposta di cortesia non torna al motore come conversazione
      }
      _occupato = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = (turno.intanto.isNotEmpty ? turno.chiaveRisposta : turno.chiave).currentContext;
      if (c != null) {
        Scrollable.ensureVisible(c, duration: const Duration(milliseconds: 450), curve: Curves.easeOutCubic);
      }
    });
  }

  void _nuova() {
    if (_occupato) return;
    HapticFeedback.selectionClick();
    setState(() {
      _turni.clear();
      _storia.clear();
      _fotoPronta = null;
      _scegliIdee();
    });
  }

  // ───────────── foto ─────────────

  Future<void> _scegliFoto() async {
    if (_occupato || _registra) return;
    final da = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: inchiostro2,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: bianco.withValues(alpha: .25), borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 14),
              _VoceFoglio(
                icona: Icons.photo_camera_rounded,
                testo: 'Scatta una foto',
                onTap: () => Navigator.pop(c, ImageSource.camera),
              ),
              _VoceFoglio(
                icona: Icons.photo_library_rounded,
                testo: 'Scegli dalla galleria',
                onTap: () => Navigator.pop(c, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
    if (da == null) return;
    try {
      final f = await ImagePicker().pickImage(source: da, maxWidth: 1280, maxHeight: 1280, imageQuality: 82);
      if (f == null || !mounted) return;
      final b = await f.readAsBytes();
      setState(() => _fotoPronta = b);
      _fuoco.requestFocus();
    } catch (_) {
      if (mounted) avviso(context, 'Non riesco ad aprire la foto');
    }
  }

  // ───────────── vocale (WAV 16 kHz mono, al massimo 30 secondi) ─────────────

  Future<void> _iniziaVoce() async {
    if (_occupato) return;
    try {
      if (!await _registratore.hasPermission()) {
        if (mounted) avviso(context, 'Per mandare un vocale l\'app deve poter usare il microfono');
        return;
      }
      final dir = await getTemporaryDirectory();
      final percorso = '${dir.path}/tk-ai-vocale.wav';
      await _registratore.start(
        const RecordConfig(encoder: AudioEncoder.wav, sampleRate: 16000, numChannels: 1),
        path: percorso,
      );
    } catch (e) {
      if (mounted) avviso(context, 'Il microfono non parte: $e');
      return;
    }
    HapticFeedback.mediumImpact();
    _ampiezza = _registratore.onAmplitudeChanged(const Duration(milliseconds: 90)).listen((a) {
      final v = ((a.current + 50) / 50).clamp(.12, 1.0);
      _onde.value = [..._onde.value.skip(1), v];
    });
    setState(() {
      _registra = true;
      _inizioVoce = DateTime.now();
    });
    _timerVoce = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!mounted) return;
      setState(() {});
      if (DateTime.now().difference(_inizioVoce!).inSeconds >= 30) _fermaVoce(manda: true);
    });
  }

  Future<void> _fermaVoce({required bool manda}) async {
    if (!_registra) return;
    _timerVoce?.cancel();
    await _ampiezza?.cancel();
    final secondi = DateTime.now().difference(_inizioVoce!).inSeconds;
    final percorso = await _registratore.stop();
    setState(() {
      _registra = false;
      _onde.value = List.filled(24, .15);
    });
    if (!manda || percorso == null || secondi < 1) return;
    final byte = await File(percorso).readAsBytes();
    _manda(vocaleB64: base64Encode(byte), secondi: secondi);
  }

  // ───────────── schermata ─────────────

  @override
  Widget build(BuildContext context) {
    final sotto = MediaQuery.paddingOf(context).bottom;
    final tastiera = _tastiera;
    return FondoGriglia(
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _testata(),
            Expanded(
              child: ShaderMask(
                // le righe sfumano sotto la testata e sopra la barra
                shaderCallback: (r) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black, Colors.black, Colors.transparent],
                  stops: [0, .03, .95, 1],
                ).createShader(r),
                blendMode: BlendMode.dstIn,
                child: ListView(
                  controller: _scorri,
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                  children: [
                    if (_turni.isEmpty) _inizio(),
                    for (final t in _turni) _VistaTurno(turno: t, key: t.chiave),
                  ],
                ),
              ),
            ),
            Padding(
              // sopra la barra delle schede; con la tastiera aperta la barra è nascosta
              padding: EdgeInsets.fromLTRB(14, 4, 14, tastiera ? 10 : 64 + 10 + sotto + 12),
              child: _compositore(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _testata() => Padding(
    padding: const EdgeInsets.fromLTRB(18, 10, 12, 4),
    child: Row(
      children: [
        const _Avatar(lato: 40),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'tk-ai',
                style: TextStyle(color: bianco, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -.2),
              ),
              if (_versione.isNotEmpty)
                Text(
                  'Versione $_versione',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: _tenue.withValues(alpha: .95), fontSize: 11.5),
                ),
            ],
          ),
        ),
        if (_turni.isNotEmpty) _TastoTondo(icona: Icons.add_rounded, etichetta: 'Nuova conversazione', onTap: _nuova),
      ],
    ),
  );

  Widget _inizio() => Padding(
    padding: const EdgeInsets.only(top: 26),
    child: Column(
      children: [
        const Entrata(child: _LogoGalleggia()),
        const SizedBox(height: 22),
        Entrata(
          ritardo: 1,
          child: Text('Ciao!', style: stileTitolo(40, colore: bianco)),
        ),
        const SizedBox(height: 8),
        Entrata(
          ritardo: 2,
          child: Text(
            'Sono tk-ai, l\'intelligenza artificiale di Pietro. Chiedimi di plugin, app, articoli e lavori: rispondo dalle pagine del sito.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _tenue, fontSize: 15.5, height: 1.5),
          ),
        ),
        const SizedBox(height: 26),
        for (final (i, idea) in (_idee ?? _suggerite).indexed)
          Entrata(
            ritardo: 3 + i,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _Idea(
                testo: idea,
                onTap: () => _manda(testo: idea),
              ),
            ),
          ),
      ],
    ),
  );

  Widget _compositore() {
    final haTesto = _campo.text.trim().isNotEmpty || _fotoPronta != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_fotoPronta != null)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: inchiostro2,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: bianco.withValues(alpha: .1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(Uint8List.fromList(_fotoPronta!), width: 44, height: 44, fit: BoxFit.cover),
                ),
                const SizedBox(width: 10),
                Text('Foto pronta: scrivi la domanda', style: TextStyle(color: _tenue, fontSize: 13)),
                const SizedBox(width: 6),
                _TastoTondo(
                  icona: Icons.close_rounded,
                  etichetta: 'Togli la foto',
                  piccolo: true,
                  onTap: () => setState(() => _fotoPronta = null),
                ),
              ],
            ),
          ),
        _BordoAurora(
          veloce: _occupato,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: inchiostro2.withValues(alpha: .96),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (_registra) ...[
                  _TastoTondo(
                    icona: Icons.close_rounded,
                    etichetta: 'Annulla il vocale',
                    onTap: () => _fermaVoce(manda: false),
                  ),
                  Expanded(
                    child: _BarraVoce(
                      onde: _onde,
                      secondi: DateTime.now().difference(_inizioVoce!).inMilliseconds / 1000,
                    ),
                  ),
                ] else ...[
                  _TastoTondo(
                    icona: Icons.photo_camera_outlined,
                    etichetta: 'Manda una foto',
                    trasparente: true,
                    onTap: _scegliFoto,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _campo,
                      focusNode: _fuoco,
                      minLines: 1,
                      maxLines: 5,
                      maxLength: 800,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _manda(),
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(color: bianco, fontSize: 16, height: 1.4),
                      cursorColor: _turchese,
                      decoration: InputDecoration(
                        hintText: 'Chiedi qualsiasi cosa…',
                        hintStyle: TextStyle(color: bianco.withValues(alpha: .45)),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        fillColor: Colors.transparent,
                        counterText: '',
                        isDense: true,
                        contentPadding: const EdgeInsets.fromLTRB(6, 12, 6, 12),
                      ),
                    ),
                  ),
                  if (!haTesto)
                    _TastoTondo(
                      icona: Icons.mic_none_rounded,
                      etichetta: 'Manda un vocale (fino a 30 secondi)',
                      trasparente: true,
                      onTap: _iniziaVoce,
                    ),
                ],
                const SizedBox(width: 4),
                _TastoInvia(
                  attivo: (haTesto || _registra) && !_occupato,
                  rosso: _registra,
                  onTap: _registra ? () => _fermaVoce(manda: true) : () => _manda(),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 7, left: 4),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            children: [
              Text(
                'Risponde l\'intelligenza artificiale: può sbagliare.',
                style: TextStyle(color: _tenue.withValues(alpha: .7), fontSize: 11.5),
              ),
              GestureDetector(
                onTap: () => apriLink(context, 'https://pietrodefilippis.it/privacy-policy/#chat-ai'),
                child: Text(
                  'Privacy',
                  style: TextStyle(color: _tenue.withValues(alpha: .9), fontSize: 11.5, decoration: TextDecoration.underline),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ───────────────────────── un turno ─────────────────────────

/// Mentre si scrive: via i riferimenti [1] e la riga del blocco prodotti, che la risposta definitiva toglie comunque.
String _soloTesto(String s) => s
    .replaceAll(RegExp(r'\s*\[\d+(?:\s*,\s*\d+)*\]'), '')
    .replaceAll(RegExp(r'^.*PRODOTTI NEI NEGOZI.*$\n?', multiLine: true, caseSensitive: false), '');

class _VistaTurno extends StatelessWidget {
  const _VistaTurno({super.key, required this.turno});

  final _Turno turno;

  @override
  Widget build(BuildContext context) {
    final r = turno.risposta;
    return Entrata(
      child: Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (turno.foto != null)
              Center(
                child: _FotoScan(byte: turno.foto!, scansiona: r == null),
              ),
            if (turno.foto != null) const SizedBox(height: 14),
            // la domanda, a destra: una nuvoletta senza nome, come quelle del sito
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const SizedBox(width: 44),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [_accentoAi, _turchese]),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(6),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (turno.vocale) const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Icon(Icons.mic_rounded, color: bianco, size: 18),
                        ),
                        Flexible(
                          child: Text(
                            turno.domanda,
                            style: const TextStyle(color: bianco, fontSize: 16, height: 1.35, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final t in turno.intanto) ...[
              Entrata(child: _NuvolaAi(child: _Articolo(testo: t))),
              const SizedBox(height: 10),
            ],
            if (r != null)
              KeyedSubtree(key: turno.chiaveRisposta, child: _Risposta(domanda: turno.domanda, risposta: r, titoloFonti: turno.titoloFonti))
            else
              _NuvolaAi(child: turno.scritto.isNotEmpty ? _Articolo(testo: '${_soloTesto(turno.scritto)} ▍') : const _Attesa()),
          ],
        ),
      ),
    );
  }
}

/// La nuvoletta dell'AI, a sinistra e senza nome.
class _NuvolaAi extends StatelessWidget {
  const _NuvolaAi({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Flexible(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .1),
            border: Border.all(color: Colors.white.withValues(alpha: .12)),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(6),
              bottomRight: Radius.circular(18),
            ),
          ),
          child: child,
        ),
      ),
      const SizedBox(width: 24),
    ],
  );
}

/// Segnalare una risposta: si sceglie il motivo e arriva nella scheda Domande del pannello del sito.
Future<void> _segnala(BuildContext context, String domanda, String risposta) async {
  final motivo = await showDialog<String>(
    context: context,
    builder: (c) => SimpleDialog(
      title: const Text('Segnala questa risposta'),
      children: [
        for (final m in const ['Sbagliata', 'Offensiva', 'Altro'])
          SimpleDialogOption(onPressed: () => Navigator.pop(c, m), child: Text(m)),
      ],
    ),
  );
  if (motivo == null || !context.mounted) return;
  final ok = await archivio.api.segnalaAi(domanda, risposta.replaceAll('**', ''), motivo);
  if (context.mounted) avviso(context, ok ? 'Grazie: la controlliamo.' : 'Non riesco a inviare la segnalazione: riprova.');
}

class _Risposta extends StatelessWidget {
  const _Risposta({required this.domanda, required this.risposta, required this.titoloFonti});

  final String domanda;
  final RispostaAi risposta;
  final String titoloFonti;

  @override
  Widget build(BuildContext context) {
    final r = risposta;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _NuvolaAi(child: _Articolo(testo: r.testo)),
        if (r.fonti.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            titoloFonti.toUpperCase(),
            style: TextStyle(color: _tenue, fontSize: 11.5, fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < r.fonti.length; i++)
            Entrata(
              ritardo: 2 + i,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: _Fonte(fonte: r.fonti[i]),
              ),
            ),
        ],
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (!r.ok)
              _Pillola(
                icona: Icons.mail_rounded,
                testo: 'Scrivimi',
                pieno: true,
                onTap: () => schedaAttiva.value = schedaScrivimi,
              )
            else ...[
              _Pillola(
                icona: Icons.copy_rounded,
                testo: 'Copia',
                onTap: () {
                  Clipboard.setData(ClipboardData(text: r.testo.replaceAll('**', '')));
                  avviso(context, 'Risposta copiata');
                },
              ),
              _Pillola(
                icona: Icons.flag_rounded,
                testo: 'Segnala',
                onTap: () => _segnala(context, domanda, r.testo),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// La risposta come un piccolo articolo: paragrafi, elenchi, **grassetto**, link cliccabili (anche senza https://).
class _Articolo extends StatelessWidget {
  const _Articolo({required this.testo});

  final String testo;

  static final _reLink = RegExp(
    r'\[([^\]]+)\]\((https?://[^)\s]+)\)|(https?://[^\s<>")]+[^\s<>").,;:!?])|([\w.+-]+@[\w-]+(?:\.[\w-]+)*\.[a-z]{2,})|((?:www\.)?[a-z0-9][a-z0-9-]*(?:\.[a-z0-9-]+)*\.(?:it|com|net|org|eu)(?:/[^\s<>")]*[^\s<>").,;:!?])?)',
    caseSensitive: false,
  );
  static const _base = TextStyle(color: Color(0xFFE9EDF7), fontSize: 16.5, height: 1.62);

  List<InlineSpan> _riga(BuildContext context, String riga) {
    final out = <InlineSpan>[];
    var ultimo = 0;
    void testo(String s) {
      final parti = s.split(RegExp(r'\*\*'));
      for (var k = 0; k < parti.length; k++) {
        if (parti[k].isEmpty) continue;
        out.add(
          TextSpan(
            text: parti[k].replaceAll('*', ''),
            style: k.isOdd ? const TextStyle(color: bianco, fontWeight: FontWeight.w800) : null,
          ),
        );
      }
    }

    for (final m in _reLink.allMatches(riga)) {
      if (m.start > ultimo) testo(riga.substring(ultimo, m.start));
      final String url, mostra;
      var titolo = false;
      if (m.group(2) != null) {
        url = m.group(2)!;
        mostra = m.group(1)!;
        titolo = true;
      } else if (m.group(3) != null) {
        url = m.group(3)!;
        mostra = url.replaceFirst(RegExp(r'^https?://(www\.)?'), '').replaceFirst(RegExp(r'/$'), '');
      } else if (m.group(4) != null) {
        url = 'mailto:${m.group(4)}';
        mostra = m.group(4)!;
      } else {
        url = 'https://${m.group(5)}';
        mostra = m.group(5)!.replaceFirst(RegExp(r'^www\.'), '').replaceFirst(RegExp(r'/$'), '');
      }
      out.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: GestureDetector(
            onTap: () => apriLink(context, url),
            child: Text(
              mostra,
              style: _base.copyWith(
                color: titolo ? bianco : const Color(0xFF8DE8F2),
                fontWeight: titolo ? FontWeight.w800 : FontWeight.w500,
                decoration: TextDecoration.underline,
                decorationColor: const Color(0x668DE8F2),
              ),
            ),
          ),
        ),
      );
      ultimo = m.end;
    }
    if (ultimo < riga.length) testo(riga.substring(ultimo));
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final blocchi = testo.replaceAll('\r', '').split(RegExp(r'\n{2,}'));
    final figli = <Widget>[];
    var n = 0;
    for (final b in blocchi) {
      final righe = b.split('\n').where((r) => r.trim().isNotEmpty).toList();
      if (righe.isEmpty) continue;
      final elenco = righe.every((r) => RegExp(r'^\s*([-*•]|\d+[.)])\s+').hasMatch(r));
      Widget parte;
      if (elenco) {
        parte = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final r in righe)
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 10, right: 11, left: 2),
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [_accentoAi, _turchese]),
                      ),
                    ),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          style: _base,
                          children: _riga(context, r.replaceFirst(RegExp(r'^\s*([-*•]|\d+[.)])\s+'), '')),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      } else {
        parte = Text.rich(
          TextSpan(
            style: _base,
            children: [
              for (var i = 0; i < righe.length; i++) ...[
                if (i > 0) const TextSpan(text: '\n'),
                ..._riga(
                  context,
                  righe[i].replaceFirst(RegExp(r'^\s*#{1,6}\s+'), '').replaceFirst(RegExp(r'^\s*[-*]\s+'), '• '),
                ),
              ],
            ],
          ),
        );
      }
      figli.add(
        Entrata(
          ritardo: n++,
          spostamento: 10,
          child: Padding(padding: const EdgeInsets.only(bottom: 12), child: parte),
        ),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: figli);
  }
}

class _Fonte extends StatelessWidget {
  const _Fonte({required this.fonte});

  final FonteAi fonte;

  @override
  Widget build(BuildContext context) => Premibile(
    onTap: () {
      // un articolo del sito si apre nell'app, il resto nel browser
      final art = archivio.recenti.where((a) => a.link == fonte.url);
      if (art.isNotEmpty) {
        apriArticolo(context, art.first);
      } else {
        apriLink(context, fonte.url);
      }
    },
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bianco.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bianco.withValues(alpha: .11)),
      ),
      child: Row(
        children: [
          if (fonte.immagine.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: SizedBox(width: 52, height: 52, child: ImmagineRete(fonte.immagine)),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fonte.tipo.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF8DE8F2),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  fonte.titolo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: bianco, fontSize: 14.5, fontWeight: FontWeight.w800, height: 1.25),
                ),
                if (fonte.estratto.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      fonte.estratto,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: _tenue, fontSize: 12.5, height: 1.35),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.north_east_rounded, color: _tenue, size: 18),
        ],
      ),
    ),
  );
}

// ───────────────────────── attesa: passi che si accendono e righe che luccicano ─────────────────────────

class _Attesa extends StatefulWidget {
  const _Attesa();

  @override
  State<_Attesa> createState() => _AttesaState();
}

class _AttesaState extends State<_Attesa> {
  String _frase = _unaDi(_pensando);
  Timer? _lento;

  @override
  void initState() {
    super.initState();
    _lento = Timer(const Duration(seconds: 45), () {
      if (mounted) setState(() => _frase = _unaDi(_quasi));
    });
  }

  @override
  void dispose() {
    _lento?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Flexible(
        child: Text(_frase, style: TextStyle(color: Colors.white.withValues(alpha: .75), fontSize: 15, height: 1.3)),
      ),
      const SizedBox(width: 8),
      const PuntiniAi(),
    ],
  );
}

// ───────────────────────── pezzi ─────────────────────────

/// Logo di tk-ai (come l'icona del programma): portatile con «AI» e i quadretti che escono dallo schermo.
class _PittoreLogo extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 72;
    canvas.save();
    canvas.scale(s);
    canvas.translate(-14, -14);
    final p = Paint()..color = bianco;
    canvas.drawPath(
      Path()
        ..moveTo(54, 34.5)
        ..lineTo(28.2, 34.5)
        ..lineTo(28.2, 63)
        ..lineTo(73.6, 63)
        ..lineTo(73.6, 55.5),
      Paint()
        ..color = bianco
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      Path()
        ..moveTo(26.7, 65)
        ..lineTo(75.1, 65)
        ..lineTo(79.8, 71)
        ..lineTo(79.8, 72.6)
        ..lineTo(21, 72.6)
        ..lineTo(21, 71)
        ..close(),
      p,
    );
    for (final r in const [
      [73.5, 23.5, 11.5],
      [65.2, 24.6, 5.4],
      [64.4, 31.9, 7.5],
      [56.0, 32.9, 5.4],
      [70.0, 41.2, 9.3],
      [72.4, 52.4, 2.4],
    ]) {
      canvas.drawRect(Rect.fromLTWH(r[0], r[1], r[2], r[2]), p);
    }
    final t = TextPainter(
      text: const TextSpan(
        text: 'AI',
        style: TextStyle(color: bianco, fontSize: 21, fontWeight: FontWeight.w900, fontFamily: 'Roboto', height: 1),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    t.paint(canvas, Offset(50 - t.width / 2, 50 - t.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.lato});

  final double lato;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<AspettoAi>(
    valueListenable: aspettoAi,
    builder: (_, a, _) => Container(
    width: lato,
    height: lato,
    padding: EdgeInsets.all(lato * .14),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(lato * .3),
      color: a.logoColore,
      gradient: a.logoColore != null ? null : LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_accentoAi, Color(0xFF6D4BD8)],
      ),
      boxShadow: [
        BoxShadow(color: _accentoAi.withValues(alpha: .45), blurRadius: lato * .5, offset: Offset(0, lato * .15)),
      ],
    ),
    child: LogoAi(predefinito: CustomPaint(painter: _PittoreLogo())),
    ),
  );
}

/// Il logo grande della schermata iniziale: galleggia piano, con un alone colorato che gira.
class _LogoGalleggia extends StatefulWidget {
  const _LogoGalleggia();

  @override
  State<_LogoGalleggia> createState() => _LogoGalleggiaState();
}

class _LogoGalleggiaState extends State<_LogoGalleggia> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, figlio) => Transform.translate(
      offset: Offset(0, math.sin(_c.value * 2 * math.pi) * 6),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: SweepGradient(
                colors: [_accentoAi, _turchese, Color(0xFFEC4899), _accentoAi],
                transform: GradientRotation(_c.value * 2 * math.pi),
              ),
              boxShadow: [BoxShadow(color: _accentoAi.withValues(alpha: .55), blurRadius: 40, spreadRadius: 2)],
            ),
          ),
          figlio!,
        ],
      ),
    ),
    child: const _Avatar(lato: 86),
  );
}

/// Bordo che gira (blu, turchese, rosa) attorno alla barra in basso: più veloce mentre l'AI pensa.
class _BordoAurora extends StatefulWidget {
  const _BordoAurora({required this.child, required this.veloce});

  final Widget child;
  final bool veloce;

  @override
  State<_BordoAurora> createState() => _BordoAuroraState();
}

class _BordoAuroraState extends State<_BordoAurora> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();

  @override
  void didUpdateWidget(covariant _BordoAurora old) {
    super.didUpdateWidget(old);
    if (old.veloce != widget.veloce) {
      _c.duration = Duration(milliseconds: widget.veloce ? 1600 : 6000);
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, figlio) => Container(
      padding: const EdgeInsets.all(1.6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: SweepGradient(
          colors: [
            _accentoAi,
            _turchese,
            const Color(0xFFEC4899),
            _accentoAi,
          ].map((c) => c.withValues(alpha: widget.veloce ? 1 : .6)).toList(),
          transform: GradientRotation(_c.value * 2 * math.pi),
        ),
        boxShadow: [
          BoxShadow(
            color: (widget.veloce ? _turchese : Colors.black).withValues(alpha: widget.veloce ? .35 : .4),
            blurRadius: widget.veloce ? 26 : 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: figlio,
    ),
    child: widget.child,
  );
}

/// La foto mandata, intera e centrata; mentre l'AI la guarda passa lo «scan» con gli angoli del mirino.
class _FotoScan extends StatefulWidget {
  const _FotoScan({required this.byte, required this.scansiona});

  final List<int> byte;
  final bool scansiona;

  @override
  State<_FotoScan> createState() => _FotoScanState();
}

class _FotoScanState extends State<_FotoScan> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();
  late final _img = Uint8List.fromList(widget.byte);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(18),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300, maxHeight: 320),
      child: Stack(
        children: [
          Image.memory(_img, fit: BoxFit.contain),
          if (widget.scansiona)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _c,
                builder: (_, _) => CustomPaint(painter: _PittoreScan(_c.value)),
              ),
            ),
        ],
      ),
    ),
  );
}

class _PittoreScan extends CustomPainter {
  _PittoreScan(this.v);

  final double v;

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height * .34;
    final y = -h + (size.height + h) * Curves.easeInOut.transform(v);
    canvas.drawRect(
      Rect.fromLTWH(0, y, size.width, h),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, _turchese.withValues(alpha: .45), bianco],
          stops: const [0, .85, 1],
        ).createShader(Rect.fromLTWH(0, y, size.width, h)),
    );
    final angolo = Paint()
      ..color = bianco
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    const m = 10.0, l = 20.0;
    final w = size.width, hh = size.height;
    for (final (a, b, c) in [
      (Offset(m, m + l), const Offset(m, m), const Offset(m + l, m)),
      (Offset(w - m - l, m), Offset(w - m, m), Offset(w - m, m + l)),
      (Offset(m, hh - m - l), Offset(m, hh - m), Offset(m + l, hh - m)),
      (Offset(w - m - l, hh - m), Offset(w - m, hh - m), Offset(w - m, hh - m - l)),
    ]) {
      canvas.drawPath(
        Path()
          ..moveTo(a.dx, a.dy)
          ..lineTo(b.dx, b.dy)
          ..lineTo(c.dx, c.dy),
        angolo,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PittoreScan old) => old.v != v;
}

class _BarraVoce extends StatelessWidget {
  const _BarraVoce({required this.onde, required this.secondi});

  final ValueNotifier<List<double>> onde;
  final double secondi;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 44,
    child: Row(
      children: [
        const SizedBox(width: 6),
        const PuntinoVivo(colore: Color(0xFFEF4444)),
        const SizedBox(width: 10),
        Expanded(
          child: ValueListenableBuilder<List<double>>(
            valueListenable: onde,
            builder: (_, v, _) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final a in v)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 90),
                    width: 3,
                    height: 4 + 24 * a,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [_accentoAi, _turchese],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '0:${secondi.floor().toString().padLeft(2, '0')}',
          style: const TextStyle(
            color: bianco,
            fontWeight: FontWeight.w800,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(width: 6),
      ],
    ),
  );
}

class _Idea extends StatelessWidget {
  const _Idea({required this.testo, required this.onTap});

  final String testo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Premibile(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      decoration: BoxDecoration(
        color: bianco.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: bianco.withValues(alpha: .11)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              gradient: LinearGradient(colors: [_accentoAi.withValues(alpha: .9), _turchese.withValues(alpha: .8)]),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: bianco, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              testo,
              style: const TextStyle(color: bianco, fontSize: 15, fontWeight: FontWeight.w700, height: 1.3),
            ),
          ),
          Icon(Icons.north_east_rounded, color: _tenue, size: 17),
        ],
      ),
    ),
  );
}

class _TastoTondo extends StatelessWidget {
  const _TastoTondo({
    required this.icona,
    required this.etichetta,
    required this.onTap,
    this.trasparente = false,
    this.piccolo = false,
  });

  final IconData icona;
  final String etichetta;
  final VoidCallback onTap;
  final bool trasparente, piccolo;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: etichetta,
    child: Tooltip(
      message: etichetta,
      child: Premibile(
        onTap: onTap,
        child: Container(
          width: piccolo ? 28 : 44,
          height: piccolo ? 28 : 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: trasparente ? Colors.transparent : bianco.withValues(alpha: .08),
            border: trasparente ? null : Border.all(color: bianco.withValues(alpha: .12)),
          ),
          child: Icon(icona, color: trasparente ? _tenue : bianco, size: piccolo ? 16 : 22),
        ),
      ),
    ),
  );
}

class _TastoInvia extends StatelessWidget {
  const _TastoInvia({required this.attivo, required this.rosso, required this.onTap});

  final bool attivo, rosso;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: rosso ? 'Manda il vocale' : 'Invia',
    child: Premibile(
      onTap: attivo ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: attivo
              ? LinearGradient(
                  colors: rosso ? const [Color(0xFFEF4444), Color(0xFFEC4899)] : [_accentoAi, _turchese],
                )
              : null,
          color: attivo ? null : bianco.withValues(alpha: .1),
          boxShadow: attivo
              ? [
                  BoxShadow(
                    color: (rosso ? const Color(0xFFEF4444) : _accentoAi).withValues(alpha: .5),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Icon(Icons.arrow_upward_rounded, color: attivo ? bianco : bianco.withValues(alpha: .45), size: 22),
      ),
    ),
  );
}

class _Pillola extends StatelessWidget {
  const _Pillola({required this.icona, required this.testo, required this.onTap, this.pieno = false});

  final IconData icona;
  final String testo;
  final VoidCallback onTap;
  final bool pieno;

  @override
  Widget build(BuildContext context) => Premibile(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: pieno ? 18 : 14, vertical: pieno ? 11 : 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: pieno ? LinearGradient(colors: [_accentoAi, accentoScuro]) : null,
        border: pieno ? null : Border.all(color: bianco.withValues(alpha: .14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icona, size: 16, color: pieno ? bianco : _tenue),
          const SizedBox(width: 6),
          Text(
            testo,
            style: TextStyle(color: pieno ? bianco : _tenue, fontWeight: FontWeight.w700, fontSize: 13.5),
          ),
        ],
      ),
    ),
  );
}

class _VoceFoglio extends StatelessWidget {
  const _VoceFoglio({required this.icona, required this.testo, required this.onTap});

  final IconData icona;
  final String testo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    leading: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(colors: [_accentoAi, _turchese]),
      ),
      child: Icon(icona, color: bianco, size: 21),
    ),
    title: Text(
      testo,
      style: const TextStyle(color: bianco, fontWeight: FontWeight.w700),
    ),
  );
}
