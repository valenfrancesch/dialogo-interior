import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'main_navigation.dart';
import 'screens/auth_screen.dart';
import 'providers/app_providers.dart';
import 'providers/auth_provider.dart' as custom_auth;
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  // Initialize Notifications and Schedule Gospel Reminder
  // We don't want a notification failure to crash the entire app
  try {
    final notificationService = NotificationService();
    await notificationService.init();
    
    // Schedule daily Gospel reminder (9:00 AM)
    await notificationService.scheduleGospelReminder(9, 0);
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
      ],
      child: MaterialApp(
        title: 'Diálogo interior',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme(),
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
            
            // If user is authenticated, show main navigation
            if (snapshot.hasData && snapshot.data != null) {
              return const MainNavigation();
            }
            
            // If not authenticated, show auth screen
            return const AuthScreen();
          },
        ),
      ),
    );
  }
}
