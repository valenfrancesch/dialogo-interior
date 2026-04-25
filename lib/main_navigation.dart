import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/reading_screen_v2.dart';
import 'screens/library_screen.dart';
import 'screens/settings_screen.dart';
import 'services/notification_service.dart';
import 'services/reminder_preferences.dart';
import 'widgets/notification_reminder_onboarding_sheet.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  static int _lastSelectedIndex = 0;
  int _currentIndex = _lastSelectedIndex;
  bool _notificationOnboardingQueued = false;

  final List<Widget> _screens = const [
    ReadingScreenV2(),
    LibraryScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_notificationOnboardingQueued) return;
      _notificationOnboardingQueued = true;
      unawaited(_maybeRunNotificationOnboarding());
    });
  }

  Future<void> _maybeRunNotificationOnboarding() async {
    if (kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    await ReminderPrefs.ensureMigrated(prefs);
    final done = prefs.getBool(ReminderPrefs.onboardingCompleted) ?? false;
    if (!mounted || done) return;
    await NotificationService().requestPermissions();
    if (!mounted) return;
    await showNotificationReminderOnboardingSheet(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            _lastSelectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Lectura',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books),
            label: 'Biblioteca',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}
