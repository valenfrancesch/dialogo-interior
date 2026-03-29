import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class KindleClock extends StatefulWidget {
  const KindleClock({super.key});

  @override
  State<KindleClock> createState() => _KindleClockState();
}

class _KindleClockState extends State<KindleClock> {
  late Timer _timer;
  late String _currentTime;

  @override
  void initState() {
    super.initState();
    // 1. Configuramos la hora inicial
    _currentTime = _formatTime(DateTime.now());
    
    // 2. Revisamos cada segundo para estar perfectamente sincronizados
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _checkAndUpdateTime();
    });
  }

  String _formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  void _checkAndUpdateTime() {
    final newTime = _formatTime(DateTime.now());
    // Solo hacemos setState si el texto de la hora realmente cambió
    if (newTime != _currentTime) {
      setState(() {
        _currentTime = newTime;
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _currentTime,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppTheme.sacredDark.withOpacity(0.35),
        letterSpacing: 0.5,
      ),
    );
  }
}