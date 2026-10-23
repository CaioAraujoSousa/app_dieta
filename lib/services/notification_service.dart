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

    // Na v20+ o parâmetro é nomeado (settings:).
    await _notificationsPlugin.initialize(settings: initializationSettings);

    // Android 13+ exige permissão para exibir notificações.
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  static Future<void> scheduleMealNotifications() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'dieta_channel',
          'Lembretes de Refeição',
          channelDescription: 'Notificações para os horários da dieta',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    for (final reminder in _schedules) {
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

      // Na v20+ todos os parâmetros são nomeados, e o
      // uiLocalNotificationDateInterpretation não existe mais.
      await _notificationsPlugin.zonedSchedule(
        id: reminder.id,
        title: 'Hora de Comer!',
        body: reminder.body,
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }
}
