// Guscio dell'app: sei schede (al centro «AI», la chat con tk-ai) con la barra in basso fluttuante. All'avvio: benvenuto (una volta), aggiornamento
// dei dati, notifica che ha aperto l'app, controllo degli aggiornamenti dell'app.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../dati/archivio.dart';
import '../dati/notifiche.dart';
import '../tema.dart';
import '../tk_pro.dart';
import 'ai.dart';
import 'articoli.dart';
import 'comuni.dart';
import 'contatti.dart';
import 'inizio.dart';
import 'salvati.dart';
import 'vetrina.dart';

/// Scheda aperta: si può cambiare da qualunque schermata (es. «Contattami» dalla vetrina).
final schedaAttiva = ValueNotifier<int>(0);

const schedaInizio = 0, schedaArticoli = 1, schedaAi = 2, schedaVetrina = 3, schedaSalvati = 4, schedaScrivimi = 5;

class SchermataHome extends StatefulWidget {
  const SchermataHome({super.key, this.crash});

  final String? crash;

  @override
  State<SchermataHome> createState() => _SchermataHomeState();
}

class _SchermataHomeState extends State<SchermataHome> {
  // le schede si costruiscono la prima volta che si aprono, poi restano vive (la posizione non si perde)
  final _aperte = <int>{schedaInizio, schedaAttiva.value};

  @override
  void initState() {
    super.initState();
    schedaAttiva.addListener(_cambia);
    notificaToccata.addListener(_daNotifica);
    WidgetsBinding.instance.addPostFrameCallback((_) => _avvio());
  }

  @override
  void dispose() {
    schedaAttiva.removeListener(_cambia);
    notificaToccata.removeListener(_daNotifica);
    super.dispose();
  }

  void _cambia() => setState(() => _aperte.add(schedaAttiva.value));

  Future<void> _avvio() async {
    await benvenutoTk(context, righeExtra: const [righeBenvenuto]);
    if (!mounted) return;
    if (widget.crash != null) await _mostraCrash(widget.crash!);
    _daNotifica();
    await archivio.aggiorna();
    // quello che c'è ora è «già visto»: le notifiche arrivano solo per le cose nuove
    await ricordaVisti(articoli: archivio.recenti, catalogo: archivio.catalogo);
    if (mounted) await proponiAggiornamento(context, avvisaSeAggiornata: false);
    // invito al caffè: al massimo una volta al mese, mai sopra un'altra finestra
    if (mounted) invitoCaffe(context);
  }

  void _daNotifica() {
    final p = notificaToccata.value;
    if (p == null || !mounted) return;
    notificaToccata.value = null;
    if (p == 'vetrina') {
      schedaAttiva.value = schedaVetrina;
    } else if (p.startsWith('articolo:')) {
      final id = int.tryParse(p.substring(9)) ?? 0;
      final trovato = archivio.recenti.where((a) => a.id == id);
      if (trovato.isNotEmpty) {
        apriArticolo(context, trovato.first);
      } else {
        schedaAttiva.value = schedaArticoli;
      }
    }
  }

  Future<void> _mostraCrash(String testo) => showDialog<void>(
    context: context,
    builder: (d) => AlertDialog(
      title: const Text('L\'ultima volta qualcosa è andato storto'),
      content: SingleChildScrollView(child: Text(testo, style: const TextStyle(fontSize: 12))),
      actions: [
        TextButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: testo));
            Navigator.pop(d);
          },
          child: const Text('Copia'),
        ),
        FilledButton(onPressed: () => Navigator.pop(d), child: const Text('Chiudi')),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
    valueListenable: schedaAttiva,
    builder: (context, attiva, _) => PopScope(
      // «indietro» da una scheda riporta all'inizio prima di chiudere l'app
      canPop: attiva == schedaInizio,
      onPopInvokedWithResult: (fatto, _) {
        if (!fatto) schedaAttiva.value = schedaInizio;
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: carta,
          extendBody: true,
          body: IndexedStack(
            index: attiva,
            children: [
              const SchedaInizio(),
              if (_aperte.contains(schedaArticoli)) const SchedaArticoli() else const SizedBox(),
              if (_aperte.contains(schedaAi)) const SchedaAi() else const SizedBox(),
              if (_aperte.contains(schedaVetrina)) const SchedaVetrina() else const SizedBox(),
              if (_aperte.contains(schedaSalvati)) const SchedaSalvati() else const SizedBox(),
              if (_aperte.contains(schedaScrivimi)) const SchedaContatti() else const SizedBox(),
            ],
          ),
          bottomNavigationBar: _Barra(attiva: attiva),
        ),
      ),
    ),
  );
}

const _voci = [
  (Icons.home_rounded, Icons.home_outlined, 'Inizio'),
  (Icons.article_rounded, Icons.article_outlined, 'Articoli'),
  (Icons.forum_rounded, Icons.forum_outlined, 'AI'),
  (Icons.auto_awesome_rounded, Icons.auto_awesome_outlined, 'Vetrina'),
  (Icons.bookmark_rounded, Icons.bookmark_border_rounded, 'Salvati'),
  (Icons.mail_rounded, Icons.mail_outline_rounded, 'Scrivimi'),
];

/// Barra fluttuante color inchiostro: la voce attiva si allarga in una pillola blu con il nome.
class _Barra extends StatelessWidget {
  const _Barra({required this.attiva});

  final int attiva;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(14, 0, 14, 10 + MediaQuery.of(context).padding.bottom),
    child: Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: inchiostro,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x400B1424), blurRadius: 24, offset: Offset(0, 10))],
      ),
      child: Row(
        children: [
          for (var i = 0; i < _voci.length; i++)
            Expanded(
              flex: i == attiva ? 2 : 1,
              child: Semantics(
                button: true,
                selected: i == attiva,
                label: _voci[i].$3,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    schedaAttiva.value = i;
                  },
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      height: 44,
                      padding: EdgeInsets.symmetric(horizontal: i == attiva ? 12 : 0),
                      decoration: BoxDecoration(
                        gradient: i == attiva ? const LinearGradient(colors: [accento, accentoScuro]) : null,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            i == attiva ? _voci[i].$1 : _voci[i].$2,
                            color: i == attiva ? bianco : grigio400,
                            size: 23,
                          ),
                          if (i == attiva)
                            Flexible(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: Text(
                                  _voci[i].$3,
                                  maxLines: 1,
                                  overflow: TextOverflow.fade,
                                  softWrap: false,
                                  style: const TextStyle(color: bianco, fontWeight: FontWeight.w800, fontSize: 13),
                                ),
                              ),
                            ),
                          if (i == schedaSalvati && i != attiva) _ContaSalvati(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class _ContaSalvati extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: archivio,
    builder: (_, _) => archivio.salvati.isEmpty
        ? const SizedBox.shrink()
        : Container(
            margin: const EdgeInsets.only(left: 2),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(color: sole, borderRadius: BorderRadius.circular(10)),
            child: Text(
              '${archivio.salvati.length}',
              style: const TextStyle(color: inchiostro, fontSize: 10, fontWeight: FontWeight.w900),
            ),
          ),
  );
}

/// Informazioni del kit, con i dati dell'app e l'interruttore delle notifiche.
Future<void> apriInformazioniPietro(BuildContext context) => apriInformazioni(
  context,
  righe: () async => [
    ('Articoli salvati', '${archivio.salvati.length}'),
    ('Articoli letti', '${archivio.letti.length}'),
  ],
  notaDati: 'Restano su questo telefono.',
  interruttori: (_) => [
    ListenableBuilder(
      listenable: archivio,
      builder: (context, _) => RigaInterruttore(
        titolo: 'Notifiche di articoli e novità',
        spiegazione: 'Una volta ogni ora circa l\'app chiede al sito se c\'è qualcosa di nuovo.',
        valore: archivio.notifiche,
        scuro: true,
        onChanged: (v) async {
          if (v) await chiediPermessoNotifiche();
          archivio.notifiche = v;
        },
      ),
    ),
  ],
);

/// Riga in più nel benvenuto.
const righeBenvenuto =
    'Gli **articoli salvati** si leggono anche senza internet. Le **notifiche** degli articoli nuovi '
    'arrivano dal sito una volta ogni ora circa: puoi spegnerle in Informazioni.';
