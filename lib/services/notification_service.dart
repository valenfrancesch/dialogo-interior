import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter/foundation.dart';
import 'dart:io';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    try {
      // Initialize timezones
      tz.initializeTimeZones();
      
      // Set local timezone - use a common default or detect from DateTime
      try {
        // Try to use the system's local timezone
        // For most cases, using 'America/Argentina/Buenos_Aires' or detecting from DateTime.now()
        final String timeZoneName = DateTime.now().timeZoneName;
        try {
          tz.setLocalLocation(tz.getLocation(timeZoneName));
        } catch (e) {
          // Fallback to a reasonable default for Argentina
          tz.setLocalLocation(tz.getLocation('America/Argentina/Buenos_Aires'));
        }
      } catch (e) {
        debugPrint('NotificationService: Could not initialize timezone: $e');
        // Fallback to UTC
        tz.setLocalLocation(tz.getLocation('UTC'));
      }

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/launcher_icon');

      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // Handle notification tap
        },
      );

      // Request permissions for Android 13+
      // Use kIsWeb to avoid dart:io Platform errors on web
      if (!kIsWeb && Platform.isAndroid) {
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
      }
    } catch (e) {
      debugPrint('NotificationService: Initialization failed: $e');
    }
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

  /// Recordatorio diario del Evangelio
  Future<void> scheduleGospelReminder(int hour, int minute) async {
    await _notifications.zonedSchedule(
      100, // ID único para el Evangelio
      'Diálogo Interior',
      'Es momento de leer el Evangelio y vivificar la Palabra.',
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'gospel_channel',
          'Evangelio Diario',
          channelDescription: 'Recordatorio diario para la lectura del Evangelio',
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
  }

  /// Recordatorio de Versículo Favorito
  Future<void> scheduleFavoriteReminder(String verse, int hour, int minute) async {
    await _notifications.zonedSchedule(
      200, // ID único para el Favorito
      'Tu Palabra de Vida',
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
