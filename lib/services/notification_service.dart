import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class _MealReminder {
  final int id;
  final String body;
  final int hour;
  final int minute;

  const _MealReminder({
    required this.id,
    required this.body,
    required this.hour,
    required this.minute,
  });
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'dieta_channel',
      'Lembretes de Refeição',
      channelDescription: 'Notificações para os horários da dieta',
      importance: Importance.max,
      priority: Priority.high,
    ),
  );

  static const List<_MealReminder> _schedules = [
    _MealReminder(id: 1, body: 'Café da Manhã em 15 min!', hour: 7, minute: 15),
    _MealReminder(id: 2, body: 'Almoço em 15 min!', hour: 11, minute: 45),
    _MealReminder(
      id: 3,
      body: 'Lanche da Tarde em 15 min!',
      hour: 15,
      minute: 15,
    ),
    _MealReminder(id: 4, body: 'Jantar em 15 min!', hour: 19, minute: 15),
    _MealReminder(id: 5, body: 'Ceia em 15 min!', hour: 21, minute: 45),
  ];

  static Future<void> init() async {
    tz_data.initializeTimeZones();
    // Sem isso o tz.local fica em UTC e os alarmes disparam fora de hora.
    tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(settings: initializationSettings);

    // Android 13+ exige permissão para exibir notificações.
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  // Agenda uma notificação. Se o Android recusar o alarme exato,
  // tenta de novo com alarme aproximado (pode atrasar alguns minutos).
  static Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime date,
    DateTimeComponents? repeat,
  }) async {
    try {
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: date,
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: repeat,
      );
    } on PlatformException catch (e) {
      if (e.code != 'exact_alarms_not_permitted') rethrow;
      debugPrint('Alarme exato não permitido; usando alarme aproximado.');
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: date,
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: repeat,
      );
    }
  }

  static Future<void> scheduleMealNotifications() async {
    for (final reminder in _schedules) {
      try {
        final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

        tz.TZDateTime scheduledDate = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          reminder.hour,
          reminder.minute,
        );

        if (scheduledDate.isBefore(now)) {
          scheduledDate = scheduledDate.add(const Duration(days: 1));
        }

        await _schedule(
          id: reminder.id,
          title: 'Hora de Comer!',
          body: reminder.body,
          date: scheduledDate,
          repeat: DateTimeComponents.time,
        );
        debugPrint('Agendado: ${reminder.body} -> $scheduledDate');
      } catch (e) {
        debugPrint('Falha ao agendar "${reminder.body}": $e');
      }
    }

    final pending = await _notificationsPlugin.pendingNotificationRequests();
    debugPrint('Notificações pendentes: ${pending.length}');
  }

  // Botão de teste (sino na tela Hoje): manda uma notificação agora
  // e agenda outra para 1 minuto depois. Devolve uma mensagem para a tela.
  static Future<String> sendTestNotifications() async {
    try {
      await _notificationsPlugin.show(
        id: 100,
        title: 'Teste imediato',
        body: 'Se você está vendo isso, as notificações funcionam.',
        notificationDetails: _details,
      );

      final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      await _schedule(
        id: 101,
        title: 'Teste agendado',
        body: 'Esta chegou 1 minuto depois de você tocar no sino.',
        date: now.add(const Duration(minutes: 1)),
      );

      return 'Teste enviado! Outra chega em 1 minuto (saia do app e espere).';
    } catch (e) {
      debugPrint('Erro no teste de notificação: $e');
      return 'Erro no teste: $e';
    }
  }
}
