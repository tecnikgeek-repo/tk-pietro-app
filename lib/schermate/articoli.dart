// Scheda «Articoli»: tutti gli articoli del blog, con ricerca e categorie; ne carica altri scorrendo.
// Senza rete mostra quelli già scaricati.
import 'dart:async';

import 'package:flutter/material.dart';

import '../dati/api.dart';
import '../dati/archivio.dart';
import '../dati/modelli.dart';
import '../tema.dart';
import 'comuni.dart';

/// Categoria da mostrare quando si apre la scheda (es. un argomento toccato in Inizio); la scheda la consuma.
final categoriaRichiesta = ValueNotifier<int?>(null);

class SchedaArticoli extends StatefulWidget {
  const SchedaArticoli({super.key});

  @override
  State<SchedaArticoli> createState() => _SchedaArticoliState();
}

class _SchedaArticoliState extends State<SchedaArticoli> {
  final _cerca = TextEditingController();
  final _scorri = ScrollController();
  Timer? _attesa;
  int? _categoria;
  List<Articolo> _lista = [];
  int _pagina = 0;
  bool _finiti = false, _carico = false;
  String? _errore;
  int _giro = 0; // le risposte di una ricerca vecchia non sovrascrivono quella nuova

  @override
  void initState() {
    super.initState();
    _lista = archivio.recenti;
    _scorri.addListener(() {
      if (_scorri.position.extentAfter < 600) _altri();
    });
    categoriaRichiesta.addListener(_richiesta);
    _categoria = categoriaRichiesta.value;
    categoriaRichiesta.value = null;
    _ricomincia();
  }

  void _richiesta() {
    final c = categoriaRichiesta.value;
    if (c == null) return;
    categoriaRichiesta.value = null;
    _cerca.clear();
    _categoria = c;
    _ricomincia();
  }

  @override
  void dispose() {
    categoriaRichiesta.removeListener(_richiesta);
    _attesa?.cancel();
    _cerca.dispose();
    _scorri.dispose();
    super.dispose();
  }

  bool get _filtrato => _categoria != null || _cerca.text.trim().isNotEmpty;

  Future<void> _ricomincia() async {
    _giro++;
    _pagina = 0;
    _finiti = false;
    _errore = null;
    if (_scorri.hasClients) _scorri.jumpTo(0);
    setState(() => _lista = _filtrato ? [] : archivio.recenti);
    await _altri(primo: true);
  }

  Future<void> _altri({bool primo = false}) async {
    if (_carico || _finiti || (!primo && _errore != null)) return;
    final giro = _giro;
    setState(() => _carico = true);
    try {
      final nuovi = await archivio.api.articoli(
        pagina: _pagina + 1,
        perPagina: 12,
        categoria: _categoria,
        cerca: _cerca.text,
      );
      if (giro != _giro || !mounted) return;
      setState(() {
        _pagina++;
        _lista = _pagina == 1 ? nuovi : [..._lista, ...nuovi.where((n) => _lista.every((a) => a.id != n.id))];
        _finiti = nuovi.length < 12;
        _errore = null;
      });
    } on ErroreSito catch (e) {
      if (giro == _giro && mounted) setState(() => _errore = e.messaggio);
    } finally {
      if (giro == _giro && mounted) setState(() => _carico = false);
    }
  }

  void _scrivendo(String _) {
    _attesa?.cancel();
    _attesa = Timer(const Duration(milliseconds: 450), _ricomincia);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cima = MediaQuery.of(context).padding.top;
    return ListenableBuilder(
      listenable: archivio,
      builder: (context, _) => RefreshIndicator(
        onRefresh: _ricomincia,
        color: accento,
        edgeOffset: cima + 150,
        child: CustomScrollView(
          controller: _scorri,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: ClipRRect(
                borderRadius: BorderRadius.zero,
                child: FondoGriglia(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, cima + 16, 20, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Articoli', style: stileTitolo(32, colore: bianco)),
                        const SizedBox(height: 4),
                        const Text(
                          'Autismo, tecnologia, scuola, sanità e il mio territorio.',
                          style: TextStyle(color: grigio300, fontSize: 13.5),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _cerca,
                          onChanged: _scrivendo,
                          textInputAction: TextInputAction.search,
                          style: const TextStyle(color: bianco, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            hintText: 'Cerca negli articoli',
                            hintStyle: const TextStyle(color: grigio400),
                            prefixIcon: const Icon(Icons.search_rounded, color: grigio300),
                            suffixIcon: _cerca.text.isEmpty
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.close_rounded, color: grigio300),
                                    tooltip: 'Cancella',
                                    onPressed: () {
                                      _cerca.clear();
                                      _ricomincia();
                                    },
                                  ),
                            fillColor: bianco.withValues(alpha: .08),
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
            if (archivio.categorie.isNotEmpty)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 58,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                    children: [
                      _Filtro('Tutti', _categoria == null, () {
                        _categoria = null;
                        _ricomincia();
                      }),
                      for (final c in archivio.categorie)
                        _Filtro(c.nome, _categoria == c.id, () {
                          _categoria = _categoria == c.id ? null : c.id;
                          _ricomincia();
                        }),
                    ],
                  ),
                ),
              ),
            if (_errore != null && _lista.isEmpty)
              SliverToBoxAdapter(child: AvvisoRete(_errore!, riprova: _ricomincia))
            else if (_errore != null && !_filtrato)
              SliverToBoxAdapter(
                child: AvvisoRete(
                  'Senza connessione: questi sono gli ultimi articoli scaricati.',
                  riprova: _ricomincia,
                ),
              ),
            if (_lista.isEmpty && !_carico && _errore == null)
              const SliverToBoxAdapter(
                child: StatoVuoto(
                  Icons.search_off_rounded,
                  'Nessun articolo',
                  'Prova con un\'altra parola o un\'altra categoria.',
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              sliver: SliverList.separated(
                itemCount: _lista.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, i) => Entrata(
                  ritardo: i % 12,
                  child: RigaArticolo(_lista[i], azione: TastoSalva(_lista[i])),
                ),
              ),
            ),
            if (_carico)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                sliver: SliverList.separated(
                  itemCount: _lista.isEmpty ? 4 : 1,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, _) => const SizedBox(height: 124, child: Luccichio(raggio: 20)),
                ),
              ),
            if (_finiti && _lista.length > 6)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, 22, 24, 0),
                  child: Center(
                    child: Text(
                      'Hai visto tutto. Ne arrivano di nuovi ogni pochi giorni.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: grigio500, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            SliverToBoxAdapter(child: SizedBox(height: MediaQuery.of(context).padding.bottom + 16)),
          ],
        ),
      ),
    );
  }
}

class _Filtro extends StatelessWidget {
  const _Filtro(this.testo, this.scelto, this.onTap);

  final String testo;
  final bool scelto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: scelto ? inchiostro : bianco,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: scelto ? inchiostro : grigio200),
        ),
        child: Text(
          testo,
          style: TextStyle(color: scelto ? bianco : testoPieno, fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
    ),
  );
}
