import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

import 'reminder_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const int gospelNotificationId = 100;

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    try {
      tz_data.initializeTimeZones();
      await _configureLocalTimeZone();

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/launcher_icon');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {},
      );

      if (!kIsWeb && Platform.isAndroid) {
        await _notifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      }
    } catch (e) {
      debugPrint('NotificationService: Initialization failed: $e');
    }
  }

  Future<void> _configureLocalTimeZone() async {
    try {
      final localName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localName));
    } catch (e) {
      debugPrint('NotificationService: timezone detection failed: $e');
      try {
        tz.setLocalLocation(tz.getLocation('America/Argentina/Buenos_Aires'));
      } catch (_) {
        tz.setLocalLocation(tz.getLocation('UTC'));
      }
    }
  }

  /// Request alert/badge/sound (iOS) or post-notifications (Android 13+).
  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    if (Platform.isIOS) {
      final impl = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final result = await impl?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return result ?? false;
    }
    if (Platform.isAndroid) {
      final impl = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await impl?.requestNotificationsPermission();
      return granted ?? false;
    }
    return false;
  }

  Future<void> cancelGospelReminder() async {
    await _notifications.cancel(gospelNotificationId);
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// Daily gospel reminder at [hour]:[minute] local time.
  Future<void> scheduleGospelReminder(int hour, int minute) async {
    await cancelGospelReminder();
    try {
      await _notifications.zonedSchedule(
        gospelNotificationId,
        'Diálogo Interior',
        'Es momento de leer el Evangelio y vivificar la Palabra.',
        _nextInstanceOfTime(hour, minute),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'gospel_channel',
            'Evangelio Diario',
            channelDescription:
                'Recordatorio diario para la lectura del Evangelio',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint(
        'NotificationService: exact schedule failed ($e), retrying inexact',
      );
      await _notifications.zonedSchedule(
        gospelNotificationId,
        'Diálogo Interior',
        'Es momento de leer el Evangelio y vivificar la Palabra.',
        _nextInstanceOfTime(hour, minute),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'gospel_channel',
            'Evangelio Diario',
            channelDescription:
                'Recordatorio diario para la lectura del Evangelio',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  /// Cancels and re-schedules from [SharedPreferences], or only cancels if disabled / onboarding incomplete.
  Future<void> syncScheduleWithPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await ReminderPrefs.ensureMigrated(prefs);
    await cancelGospelReminder();
    final onboardingDone =
        prefs.getBool(ReminderPrefs.onboardingCompleted) ?? false;
    if (!onboardingDone) return;
    final enabled = prefs.getBool(ReminderPrefs.dailyReminderEnabled) ?? true;
    if (!enabled) return;
    final h = prefs.getInt(ReminderPrefs.hour) ?? 9;
    final m = prefs.getInt(ReminderPrefs.minute) ?? 0;
    await scheduleGospelReminder(h, m);
  }

  /// Recordatorio de Versículo Favorito
  Future<void> scheduleFavoriteReminder(
    String verse,
    int hour,
    int minute,
  ) async {
    await _notifications.zonedSchedule(
      200,
      'Tu luz de hoy',
      '"$verse"',
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'fav_channel',
          'Versículo Favorito',
          channelDescription: 'Recordatorio de tus versículos destacados',
          importance: Importance.max,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(''),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
