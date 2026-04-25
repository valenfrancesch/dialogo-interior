import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/notification_service.dart';
import '../services/reminder_preferences.dart';
import '../theme/app_theme.dart';

/// First-run: choose daily reminder time (default 9:00) after permission prompt.
Future<void> showNotificationReminderOnboardingSheet(
  BuildContext context,
) async {
  TimeOfDay selected = const TimeOfDay(hour: 9, minute: 0);

  await showModalBottomSheet<void>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.paddingOf(context).bottom + 24,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Recordatorio diario',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.sacredRed,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Elegí a qué hora querés que te recordemos leer el Evangelio. Podés cambiarlo después en Ajustes.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.5,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85),
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Hora',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  trailing: Text(
                    selected.format(context),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: selected,
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
                    if (picked != null) {
                      setModalState(() => selected = picked);
                    }
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool(ReminderPrefs.onboardingCompleted, true);
                    await prefs.setBool(ReminderPrefs.dailyReminderEnabled, true);
                    await prefs.setInt(ReminderPrefs.hour, selected.hour);
                    await prefs.setInt(ReminderPrefs.minute, selected.minute);
                    await NotificationService().syncScheduleWithPreferences();
                    if (context.mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Guardar',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool(ReminderPrefs.onboardingCompleted, true);
                    await prefs.setBool(ReminderPrefs.dailyReminderEnabled, false);
                    await prefs.setInt(ReminderPrefs.hour, 9);
                    await prefs.setInt(ReminderPrefs.minute, 0);
                    await NotificationService().syncScheduleWithPreferences();
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Text(
                    'Ahora no',
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
