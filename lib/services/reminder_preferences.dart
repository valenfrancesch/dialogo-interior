import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences keys for daily gospel reminder and onboarding.
class ReminderPrefs {
  ReminderPrefs._();

  static const String onboardingCompleted = 'onboarding_notifications_completed';
  static const String dailyReminderEnabled = 'daily_reminder_enabled';
  static const String hour = 'daily_reminder_hour';
  static const String minute = 'daily_reminder_minute';

  /// Heuristic: user had opened settings / reading before this feature shipped.
  static bool _looksLikeExistingInstall(SharedPreferences prefs) {
    return prefs.containsKey('readingFontSize') ||
        prefs.containsKey('isImmersiveModeEnabled');
  }

  /// One-time defaults for installs that never had these keys.
  static Future<void> ensureMigrated(SharedPreferences prefs) async {
    if (prefs.containsKey(onboardingCompleted)) return;
    final existing = _looksLikeExistingInstall(prefs);
    await prefs.setBool(onboardingCompleted, existing);
    await prefs.setBool(dailyReminderEnabled, true);
    await prefs.setInt(hour, 9);
    await prefs.setInt(minute, 0);
  }
}
