import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'main_navigation.dart';
import 'providers/app_providers.dart';
import 'providers/auth_provider.dart' as custom_auth;
import 'services/notification_service.dart';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/reminder_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  await ReminderPrefs.ensureMigrated(prefs);

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  // Initialize Notifications; daily time comes from preferences (after onboarding).
  try {
    final notificationService = NotificationService();
    await notificationService.init();
    await notificationService.syncScheduleWithPreferences();
  } catch (e) {
    debugPrint('Notification initialization failed: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => custom_auth.AuthProvider()),
        ChangeNotifierProvider(create: (_) => GospelProvider()),
        ChangeNotifierProvider(create: (_) => PrayerEntryProvider()),
        ChangeNotifierProvider(create: (_) => ReadingFontSizeProvider()),
        ChangeNotifierProvider(create: (_) => ThemeModeProvider()),
      ],
      child: Consumer<ThemeModeProvider>(
        builder: (context, themeMode, _) {
          return MaterialApp(
        title: 'Diálogo interior',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme(),
        darkTheme: AppTheme.darkTheme(),
        themeMode: themeMode.themeMode,
        builder: (context, child) {
          final brightness = Theme.of(context).brightness;
          final style = SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: brightness == Brightness.dark
                ? Brightness.light
                : Brightness.dark,
          );
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: style,
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            // Show loading screen while checking auth state
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            
            // Always show MainNavigation now, guest status will be handled per screen
            return MainNavigation(key: ValueKey(snapshot.data?.uid));
          },
        ),
      );
        },
      ),
    );
  }
}
