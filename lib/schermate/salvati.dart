// Scheda «Salvati»: articoli scaricati sul telefono, leggibili senza internet. Scorri per toglierli.
import 'package:flutter/material.dart';

import '../dati/archivio.dart';
import '../tema.dart';
import 'comuni.dart';
import 'home.dart';

class SchedaSalvati extends StatelessWidget {
  const SchedaSalvati({super.key});

  @override
  Widget build(BuildContext context) {
    final cima = MediaQuery.of(context).padding.top;
    return ListenableBuilder(
      listenable: archivio,
      builder: (context, _) {
        final s = archivio.salvati;
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: ClipRRect(
                borderRadius: BorderRadius.zero,
                child: FondoGriglia(
                  alone: sole,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, cima + 16, 20, 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Salvati', style: stileTitolo(32, colore: bianco)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.offline_pin_rounded, color: sole, size: 18),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                s.isEmpty
                                    ? 'Qui trovi gli articoli da leggere con calma, anche senza internet.'
                                    : '${s.length} ${s.length == 1 ? 'articolo' : 'articoli'} da leggere anche senza internet.',
                                style: const TextStyle(color: grigio300, fontSize: 13.5),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (s.isEmpty)
              SliverToBoxAdapter(
                child: StatoVuoto(
                  Icons.bookmark_add_rounded,
                  'Ancora niente',
                  'Tocca il segnalibro su un articolo: lo trovi qui, con le foto, anche in aereo o in metro.',
                  azione: BottoneTk(
                    testo: 'Vai agli articoli',
                    icona: Icons.article_rounded,
                    onTap: () => schedaAttiva.value = schedaArticoli,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverList.separated(
                  itemCount: s.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => Dismissible(
                    key: ValueKey('salvato-${s[i].id}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 24),
                      decoration: BoxDecoration(color: rosso, borderRadius: BorderRadius.circular(20)),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Togli',
                            style: TextStyle(color: bianco, fontWeight: FontWeight.w800),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.delete_outline_rounded, color: bianco),
                        ],
                      ),
                    ),
                    onDismissed: (_) {
                      final tolto = s[i];
                      archivio.togli(tolto.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Tolto dai salvati'),
                          action: SnackBarAction(
                            label: 'Annulla',
                            textColor: sole,
                            onPressed: () => archivio.salva(tolto),
                          ),
                        ),
                      );
                    },
                    child: Entrata(ritardo: i, child: RigaArticolo(s[i])),
                  ),
                ),
              ),
            SliverToBoxAdapter(child: SizedBox(height: MediaQuery.of(context).padding.bottom + 100)),
          ],
        );
      },
    );
  }
}
