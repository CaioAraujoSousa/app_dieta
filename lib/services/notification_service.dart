import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz_data.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(settings: initializationSettings);
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

    final List<Map<String, dynamic>> schedules = [
      {'id': 1, 'title': 'Café da Manhã em 15 min!', 'hour': 7, 'minute': 15},
      {'id': 2, 'title': 'Almoço em 15 min!', 'hour': 11, 'minute': 45},
      {
        'id': 3,
        'title': 'Lanche da Tarde em 15 min!',
        'hour': 15,
        'minute': 15,
      },
      {'id': 4, 'title': 'Jantar em 15 min!', 'hour': 19, 'minute': 15},
      {'id': 5, 'title': 'Ceia em 15 min!', 'hour': 21, 'minute': 45},
    ];

    for (var s in schedules) {
      var now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        s['hour'] as int,
        s['minute'] as int,
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _notificationsPlugin.zonedSchedule(
        id: s['id'] as int,
        title: 'Hora de Comer!',
        body: s['title'] as String,
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }
}
