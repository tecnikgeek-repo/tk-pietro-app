// Scheda «Scrivimi»: lo stesso modulo Contatti del sito (il messaggio finisce nei Messaggi del sito e arriva per
// email), con l'argomento a pillole; nome ed email restano ricordati. Sotto: caffè e social.
import 'package:flutter/material.dart';

import '../dati/api.dart';
import '../dati/archivio.dart';
import '../tema.dart';
import 'comuni.dart';
import 'inizio.dart' show social;

/// Argomento e inizio del messaggio da mettere nel modulo (es. «Contattami» dalla scheda di un plugin).
final bozzaContatto = ValueNotifier<(String, String)?>(null);

const argomenti = [
  'Un sito WordPress',
  'Un plugin o il suo Pro',
  'Un’app',
  'Assistenza o manutenzione',
  'Un articolo del blog',
  'Altro',
];

class SchedaContatti extends StatefulWidget {
  const SchedaContatti({super.key});

  @override
  State<SchedaContatti> createState() => _SchedaContattiState();
}

class _SchedaContattiState extends State<SchedaContatti> {
  final _modulo = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _telefono = TextEditingController();
  final _messaggio = TextEditingController();
  String? _argomento;
  bool _invio = false, _inviato = false;

  @override
  void initState() {
    super.initState();
    _nome.text = archivio.prefs.getString('contatto_nome') ?? '';
    _email.text = archivio.prefs.getString('contatto_email') ?? '';
    bozzaContatto.addListener(_bozza);
    _bozza();
  }

  @override
  void dispose() {
    bozzaContatto.removeListener(_bozza);
    for (final c in [_nome, _email, _telefono, _messaggio]) {
      c.dispose();
    }
    super.dispose();
  }

  void _bozza() {
    final b = bozzaContatto.value;
    if (b == null) return;
    bozzaContatto.value = null;
    setState(() {
      _inviato = false;
      _argomento = argomenti.contains(b.$1) ? b.$1 : 'Altro';
      _messaggio.text = b.$2;
    });
  }

  Future<void> _invia() async {
    if (_argomento == null) {
      avviso(context, 'Scegli per cosa mi scrivi');
      return;
    }
    if (!_modulo.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _invio = true);
    try {
      await archivio.api.inviaMessaggio(
        nome: _nome.text.trim(),
        email: _email.text.trim(),
        telefono: _telefono.text.trim(),
        argomento: _argomento!,
        messaggio: _messaggio.text.trim(),
      );
      await archivio.prefs.setString('contatto_nome', _nome.text.trim());
      await archivio.prefs.setString('contatto_email', _email.text.trim());
      if (!mounted) return;
      setState(() {
        _inviato = true;
        _messaggio.clear();
        _telefono.clear();
        _argomento = null;
      });
    } on ErroreSito catch (e) {
      if (mounted) avviso(context, e.messaggio);
    } finally {
      if (mounted) setState(() => _invio = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cima = MediaQuery.of(context).padding.top;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: ClipRRect(
            borderRadius: BorderRadius.zero,
            child: FondoGriglia(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, cima + 16, 20, 22),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Scrivimi', style: stileTitolo(32, colore: bianco)),
                          const SizedBox(height: 6),
                          const Text(
                            'Un sito, un plugin, un\'app o solo due parole su un articolo: rispondo io, di solito entro un giorno.',
                            style: TextStyle(color: grigio300, fontSize: 13.5, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Container(
                      width: 74,
                      height: 74,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: sole, width: 3),
                        boxShadow: [BoxShadow(color: sole.withValues(alpha: .35), blurRadius: 20)],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'assets/img/pietro.jpg',
                        fit: BoxFit.cover,
                        alignment: const Alignment(0, -.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
          sliver: SliverToBoxAdapter(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              switchInCurve: Curves.easeOutBack,
              transitionBuilder: (c, a) => FadeTransition(
                opacity: a,
                child: ScaleTransition(scale: a, child: c),
              ),
              child: _inviato ? _Inviato(onAltro: () => setState(() => _inviato = false)) : _moduloWidget(),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
            child: Row(
              children: [
                for (final s in social)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Premibile(
                        onTap: () => apriLink(context, s.$3),
                        child: Container(
                          height: 54,
                          decoration: BoxDecoration(color: bianco, borderRadius: BorderRadius.circular(16)),
                          child: Icon(s.$1, color: s.$4, size: 26, semanticLabel: s.$2),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: TestoConLink(
              'I dati del modulo servono solo a risponderti: [Privacy]($urlPrivacy) · [Termini]($urlTermini)',
              allineamento: TextAlign.center,
              stile: const TextStyle(color: grigio500, fontSize: 12.5),
              coloreLink: accentoScuro,
            ),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: MediaQuery.of(context).padding.bottom + 100)),
      ],
    );
  }

  Widget _moduloWidget() => Container(
    key: const ValueKey('modulo'),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: bianco,
      borderRadius: BorderRadius.circular(24),
      boxShadow: const [BoxShadow(color: Color(0x0F0B1424), blurRadius: 16, offset: Offset(0, 6))],
    ),
    child: Form(
      key: _modulo,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TitoloSezione('Per cosa mi scrivi?'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final a in argomenti)
                GestureDetector(
                  onTap: () => setState(() => _argomento = a),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                    decoration: BoxDecoration(
                      gradient: _argomento == a ? const LinearGradient(colors: [accento, accentoScuro]) : null,
                      color: _argomento == a ? null : grigio100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      a,
                      style: TextStyle(
                        color: _argomento == a ? bianco : testoPieno,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: _nome,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Nome e cognome', prefixIcon: Icon(Icons.person_rounded)),
            validator: (v) => (v ?? '').trim().length < 2 ? 'Scrivi il tuo nome' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.alternate_email_rounded)),
            validator: (v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch((v ?? '').trim())
                ? null
                : 'Controlla l\'indirizzo email',
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _telefono,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Telefono (facoltativo)',
              prefixIcon: Icon(Icons.phone_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _messaggio,
            minLines: 5,
            maxLines: 10,
            maxLength: 5000,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Messaggio',
              alignLabelWithHint: true,
              hintText: 'Raccontami cosa ti serve: più dettagli mi dai, più precisa sarà la risposta.',
            ),
            validator: (v) => (v ?? '').trim().length < 10 ? 'Scrivi qualcosa in più' : null,
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _invio
                ? const SizedBox(height: 50, child: Center(child: CircularProgressIndicator(strokeWidth: 3)))
                : BottoneTk(testo: 'Invia il messaggio', icona: Icons.send_rounded, onTap: _invia),
          ),
        ],
      ),
    ),
  );
}

/// Spunta che si disegna, poi «Messaggio inviato!».
class _Inviato extends StatelessWidget {
  const _Inviato({required this.onAltro});

  final VoidCallback onAltro;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('inviato'),
    padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
    decoration: BoxDecoration(color: bianco, borderRadius: BorderRadius.circular(24)),
    child: Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (_, v, _) => Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF22C55E).withValues(alpha: .12 * v),
            ),
            child: CustomPaint(painter: _Spunta(v)),
          ),
        ),
        const SizedBox(height: 16),
        Text('Messaggio inviato!', style: stileTitolo(24)),
        const SizedBox(height: 6),
        const Text(
          'Grazie: ti ho mandato una conferma per email. Ti rispondo appena posso.',
          textAlign: TextAlign.center,
          style: TextStyle(color: testoMuto, height: 1.4),
        ),
        const SizedBox(height: 18),
        BottoneTk(testo: 'Scrivi un altro messaggio', icona: Icons.edit_rounded, chiaro: true, onTap: onAltro),
      ],
    ),
  );
}

class _Spunta extends CustomPainter {
  _Spunta(this.v);

  final double v;

  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = const Color(0xFF16A34A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final a = Offset(s.width * .28, s.height * .52),
        b = Offset(s.width * .44, s.height * .67),
        c = Offset(s.width * .73, s.height * .36);
    final path = Path()..moveTo(a.dx, a.dy);
    if (v < .45) {
      final t = v / .45;
      path.lineTo(a.dx + (b.dx - a.dx) * t, a.dy + (b.dy - a.dy) * t);
    } else {
      final t = (v - .45) / .55;
      path
        ..lineTo(b.dx, b.dy)
        ..lineTo(b.dx + (c.dx - b.dx) * t, b.dy + (c.dy - b.dy) * t);
    }
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant _Spunta old) => old.v != v;
}
