import 'package:app_settings/app_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/notification_service.dart';
import '../services/reminder_preferences.dart';
import '../theme/app_theme.dart';

/// Settings tiles: daily reminder on/off and time of day.
class ReminderSettingsSection extends StatefulWidget {
  const ReminderSettingsSection({super.key});

  @override
  State<ReminderSettingsSection> createState() => _ReminderSettingsSectionState();
}

class _ReminderSettingsSectionState extends State<ReminderSettingsSection> {
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    await ReminderPrefs.ensureMigrated(p);
    if (mounted) setState(() => _prefs = p);
  }

  Future<void> _pickTime(BuildContext context) async {
    final prefs = _prefs;
    if (prefs == null) return;
    final h = prefs.getInt(ReminderPrefs.hour) ?? 9;
    final m = prefs.getInt(ReminderPrefs.minute) ?? 0;
    final initial = TimeOfDay(hour: h, minute: m);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (c, child) {
        final theme = Theme.of(c);
        final scheme = theme.colorScheme;
        final dark = theme.brightness == Brightness.dark;
        final selectedBg = scheme.primary;
        final selectedText = scheme.onPrimary;
        final unselectedBg = dark ? scheme.surfaceContainerHighest : scheme.surface;
        final unselectedText = scheme.onSurface;
        return Theme(
          data: theme.copyWith(
            colorScheme: dark
                ? ColorScheme.dark(
                    primary: scheme.primary,
                    onPrimary: scheme.onPrimary,
                    surface: AppTheme.darkSurfaceContainerHigh,
                    onSurface: AppTheme.darkOnSurface,
                  )
                : ColorScheme.light(
                    primary: scheme.primary,
                    onPrimary: scheme.onPrimary,
                    surface: scheme.surface,
                    onSurface: AppTheme.sacredDark,
                  ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: dark ? AppTheme.darkSurfaceContainerHigh : scheme.surface,
              dayPeriodColor: WidgetStateColor.resolveWith((states) {
                return states.contains(WidgetState.selected) ? selectedBg : unselectedBg;
              }),
              dayPeriodTextColor: WidgetStateColor.resolveWith((states) {
                return states.contains(WidgetState.selected) ? selectedText : unselectedText;
              }),
              hourMinuteColor: WidgetStateColor.resolveWith((states) {
                return states.contains(WidgetState.selected)
                    ? selectedBg.withOpacity(dark ? 0.35 : 0.16)
                    : unselectedBg;
              }),
              hourMinuteTextColor: WidgetStateColor.resolveWith((states) {
                return states.contains(WidgetState.selected) ? selectedBg : unselectedText;
              }),
              dialHandColor: selectedBg,
              dialTextColor: unselectedText,
              entryModeIconColor: selectedBg,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null || !mounted) return;
    await prefs.setInt(ReminderPrefs.hour, picked.hour);
    await prefs.setInt(ReminderPrefs.minute, picked.minute);
    await NotificationService().syncScheduleWithPreferences();
    setState(() {});
  }

  Future<void> _onReminderSwitch(bool value) async {
    final prefs = _prefs;
    if (prefs == null) return;
    if (value) {
      final granted = await NotificationService().requestPermissions();
      if (!granted && mounted) {
        final open = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Permisos de notificación'),
            content: const Text(
              'Para recibir el recordatorio, activá las notificaciones para Diálogo Interior en los ajustes del sistema.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(c, true),
                child: const Text('Abrir ajustes'),
              ),
            ],
          ),
        );
        if (open == true && !kIsWeb) {
          await AppSettings.openAppSettings(
            type: AppSettingsType.notification,
          );
        }
        return;
      }
      await prefs.setBool(ReminderPrefs.dailyReminderEnabled, true);
    } else {
      await prefs.setBool(ReminderPrefs.dailyReminderEnabled, false);
    }
    await NotificationService().syncScheduleWithPreferences();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (kIsWeb) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Notificaciones',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: scheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Card(
              color: scheme.surfaceContainerHighest,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: scheme.outline.withOpacity(0.25)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: scheme.primary, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'El recordatorio diario del Evangelio está disponible en la app para iPhone y Android. En el navegador no se pueden programar notificaciones.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          height: 1.45,
                          color: scheme.onSurface.withOpacity(0.88),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    final prefs = _prefs;
    if (prefs == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final enabled = prefs.getBool(ReminderPrefs.dailyReminderEnabled) ?? true;
    final h = prefs.getInt(ReminderPrefs.hour) ?? 9;
    final m = prefs.getInt(ReminderPrefs.minute) ?? 0;
    final timeLabel = TimeOfDay(hour: h, minute: m).format(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Notificaciones',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: scheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          title: Text(
            'Recordatorio diario del Evangelio',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            'Te avisamos para leer y reflexionar cada día.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
          value: enabled,
          activeColor: scheme.primary,
          onChanged: _onReminderSwitch,
          secondary: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: scheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.notifications_active_outlined, color: scheme.primary),
          ),
        ),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: scheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.schedule, color: scheme.primary),
          ),
          title: Text(
            'Hora del recordatorio',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            timeLabel,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontSize: 13,
            ),
          ),
          trailing: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
          onTap: enabled ? () => _pickTime(context) : () => _onReminderSwitch(true),
        ),
        if (!enabled)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              'Activá el recordatorio para elegir la hora.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }
}
