import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/reading_screen.dart';
import '../screens/library_screen.dart';
import '../screens/auth_screen.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    ReadingScreen(),
    LibraryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDarkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Diálogo interior'),
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppTheme.cardDark,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
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
        ],
      ),
    );
  }
}
