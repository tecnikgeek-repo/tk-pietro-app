// Notifiche di articoli nuovi e di novità in vetrina. Niente servizi esterni né account: ogni ora circa Android fa
// partire un controllo in sottofondo (WorkManager) che chiede al sito l'ultimo articolo e la vetrina, li confronta
// con quelli già visti e avvisa solo delle cose nuove.
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'api.dart';
import 'modelli.dart';

const _compito = 'tk-pietro-novita';
const _canale = AndroidNotificationChannel(
  'novita',
  'Articoli e novità',
  description: 'Articoli nuovi sul blog e plugin, app o programmi nuovi in vetrina',
  importance: Importance.high,
);

final _avvisi = FlutterLocalNotificationsPlugin();

/// Cosa aprire quando si tocca una notifica: `articolo:<id>` oppure `vetrina`.
final notificaToccata = ValueNotifier<String?>(null);

/// Da chiamare all'avvio: prepara il canale, riprende l'eventuale notifica che ha aperto l'app e pianifica il controllo.
Future<void> preparaNotifiche() async {
  if (defaultTargetPlatform != TargetPlatform.android) return;
  try {
    await _avvisi.initialize(
      settings: const InitializationSettings(android: AndroidInitializationSettings('ic_notifica')),
      onDidReceiveNotificationResponse: (r) => notificaToccata.value = r.payload,
    );
    await _avvisi
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_canale);
    final lancio = await _avvisi.getNotificationAppLaunchDetails();
    if (lancio?.didNotificationLaunchApp ?? false) notificaToccata.value = lancio!.notificationResponse?.payload;
    await Workmanager().initialize(controlloInSottofondo);
    await Workmanager().registerPeriodicTask(
      _compito,
      _compito,
      frequency: const Duration(hours: 1),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  } catch (e) {
    debugPrint('Notifiche non pronte: $e');
  }
}

/// Chiede il permesso (Android 13+). true = le notifiche possono arrivare.
Future<bool> chiediPermessoNotifiche() async {
  if (defaultTargetPlatform != TargetPlatform.android) return false;
  try {
    return await _avvisi
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission() ??
        false;
  } catch (_) {
    return false;
  }
}

/// Segna come già visto tutto quello che c'è ora: al primo avvio non arriva una raffica di notifiche vecchie.
Future<void> ricordaVisti({required List<Articolo> articoli, Catalogo? catalogo}) async {
  final p = await SharedPreferences.getInstance();
  if (articoli.isNotEmpty) {
    final max = articoli.map((a) => a.id).reduce((a, b) => a > b ? a : b);
    if (max > (p.getInt('notifica_ultimo_articolo') ?? 0)) await p.setInt('notifica_ultimo_articolo', max);
  }
  if (catalogo != null) {
    final visti = {...?p.getStringList('notifica_vetrina'), ..._slugVetrina(catalogo)};
    await p.setStringList('notifica_vetrina', visti.toList());
  }
}

Set<String> _slugVetrina(Catalogo c) => {
  for (final p in [...c.plugin, ...c.temi]) p.slug,
  for (final s in c.software) '${s.gruppo}/${s.slug}',
};

@pragma('vm:entry-point')
void controlloInSottofondo() {
  Workmanager().executeTask((_, _) async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      final p = await SharedPreferences.getInstance();
      if (!(p.getBool('notifiche') ?? true)) return true;
      final novita = await cercaNovita(Api(client: http.Client(), versione: 'sottofondo'), p);
      if (novita.isEmpty) return true;
      await _avvisi.initialize(
        settings: const InitializationSettings(android: AndroidInitializationSettings('ic_notifica')),
      );
      for (final n in novita) {
        await _avvisi.show(
          id: n.id,
          title: n.titolo,
          body: n.testo,
          payload: n.apri,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _canale.id,
              _canale.name,
              channelDescription: _canale.description,
              importance: Importance.high,
              priority: Priority.high,
              color: const Color(0xFF2093EC),
              styleInformation: BigTextStyleInformation(n.testo),
            ),
          ),
        );
      }
    } catch (_) {
      // senza rete o sito lento: si riprova al prossimo giro
    }
    return true;
  });
}

class Novita {
  const Novita(this.id, this.titolo, this.testo, this.apri);
  final int id;
  final String titolo, testo, apri;
}

/// Confronta sito e cose già viste; aggiorna le preferenze e ritorna le notifiche da mostrare (al massimo 3).
@visibleForTesting
Future<List<Novita>> cercaNovita(Api api, SharedPreferences p) async {
  final out = <Novita>[];
  final ultimo = p.getInt('notifica_ultimo_articolo') ?? 0;
  final articoli = await api.articoli(perPagina: 5);
  if (ultimo == 0) {
    await ricordaVisti(articoli: articoli); // prima volta: niente arretrati
  } else {
    final nuovi = articoli.where((a) => a.id > ultimo).toList();
    for (final a in nuovi.take(2)) {
      out.add(Novita(a.id, 'Nuovo articolo', a.titolo, 'articolo:${a.id}'));
    }
    if (nuovi.isNotEmpty) await ricordaVisti(articoli: nuovi);
  }

  final visti = p.getStringList('notifica_vetrina');
  final catalogo = Catalogo.daJson(await api.catalogoGrezzo());
  if (visti == null) {
    await ricordaVisti(articoli: const [], catalogo: catalogo);
  } else {
    final nuovi = _slugVetrina(catalogo).difference(visti.toSet());
    if (nuovi.isNotEmpty) {
      final nomi = <String>[
        for (final x in [...catalogo.plugin, ...catalogo.temi])
          if (nuovi.contains(x.slug)) x.nome,
        for (final s in catalogo.software)
          if (nuovi.contains('${s.gruppo}/${s.slug}')) s.nome,
      ];
      out.add(
        Novita(
          900000 + nuovi.length,
          'Novità in vetrina',
          nomi.length == 1 ? '${nomi.first} è appena arrivato: scopri cosa fa.' : 'Sono arrivati ${nomi.join(', ')}.',
          'vetrina',
        ),
      );
      await ricordaVisti(articoli: const [], catalogo: catalogo);
    }
  }
  return out.take(3).toList();
}
