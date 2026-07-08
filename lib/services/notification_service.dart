// Service de notifications — rappel quotidien.
//
// Choix volontaire : programmation "inexacte" (androidScheduleMode:
// inexactAllowWhileIdle), pas une alarme exacte. Ça évite la permission
// SCHEDULE_EXACT_ALARM — restreinte et fragile sur Android récent — pour
// un simple rappel qui n'a pas besoin d'une précision à la minute près.
//
// Simplifications assumées pour cette première version :
// - Le fuseau horaire est fixé en dur sur celui du Bénin (Africa/Porto-Novo).
// - Pas de rappel après redémarrage du téléphone pour l'instant (à ajouter
//   plus tard si besoin) ; rouvrir l'app après un redémarrage suffit à
//   reprogrammer le rappel.

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const int _dailyReminderId = 1;

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Africa/Porto-Novo'));

    const androidSettings = AndroidInitializationSettings('@drawable/ic_notification');
    const settings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(settings: settings);

    _initialized = true;
  }

  /// Demande la permission d'afficher des notifications (Android 13+).
  /// Renvoie false si refusée, ou si la plateforme ne la propose pas.
  Future<bool> requestPermission() async {
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await androidImpl?.requestNotificationsPermission();
    return granted ?? false;
  }

  Future<void> scheduleDailyReminder({int hour = 20, int minute = 0}) async {
    await _plugin.zonedSchedule(
      id: _dailyReminderId,
      title: "Ta tenue t'attend",
      body: 'Ouvre AtmoStyle pour découvrir la tenue du jour.',
      scheduledDate: _nextInstanceOf(hour, minute),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'atmostyle_daily_reminder',
          'Rappel quotidien',
          channelDescription: 'Rappel du soir pour consulter la tenue proposée.',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelDailyReminder() async {
    await _plugin.cancel(id: _dailyReminderId);
  }

  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
