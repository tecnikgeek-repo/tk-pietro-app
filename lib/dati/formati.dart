// Date e numeri scritti come sul sito: «3 ore fa», «2 giorni fa», «1.234».

const _mesi = [
  'gennaio',
  'febbraio',
  'marzo',
  'aprile',
  'maggio',
  'giugno',
  'luglio',
  'agosto',
  'settembre',
  'ottobre',
  'novembre',
  'dicembre',
];

/// «adesso», «5 minuti fa», «3 ore fa», «ieri», «4 giorni fa», poi la data («12 ottobre 2026»).
/// [breve]: oltre la settimana «12 mar 2025» invece di «12 marzo 2025» (righe strette).
String tempoFa(DateTime quando, {DateTime? ora, bool breve = false}) {
  final adesso = ora ?? DateTime.now();
  final d = adesso.difference(quando);
  if (d.inMinutes < 1) return 'adesso';
  if (d.inMinutes < 60) return d.inMinutes == 1 ? '1 minuto fa' : '${d.inMinutes} minuti fa';
  if (d.inHours < 24) return d.inHours == 1 ? '1 ora fa' : '${d.inHours} ore fa';
  final giorni = DateTime(
    adesso.year,
    adesso.month,
    adesso.day,
  ).difference(DateTime(quando.year, quando.month, quando.day)).inDays;
  if (giorni <= 1) return 'ieri';
  if (giorni < 7) return '$giorni giorni fa';
  return breve ? '${quando.day} ${_mesi[quando.month - 1].substring(0, 3)} ${quando.year}' : dataLunga(quando);
}

String dataLunga(DateTime d) => '${d.day} ${_mesi[d.month - 1]} ${d.year}';

/// 1234 → «1.234».
String numero(int n) {
  final s = n.abs().toString();
  final b = StringBuffer(n < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return b.toString();
}

/// «1 lettura», «23 letture».
String letture(int n) => n == 1 ? '1 lettura' : '${numero(n)} letture';
