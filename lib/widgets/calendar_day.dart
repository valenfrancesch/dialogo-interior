import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class CalendarDay extends StatelessWidget {
  final int day;
  final bool hasEntry;
  final bool isToday;
  final VoidCallback onTap;
  final bool isDisabled;
  final bool isCurrentMonth;

  const CalendarDay({
    super.key,
    required this.day,
    required this.hasEntry,
    required this.isToday,
    required this.onTap,
    this.isDisabled = false,
    this.isCurrentMonth = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isToday ? AppTheme.sacredGold : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              day.toString(),
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                color: _getTextColor(),
              ),
            ),
            const SizedBox(height: 2),
            if (hasEntry)
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: isToday ? Colors.white : AppTheme.sacredRed,
                  shape: BoxShape.circle,
                ),
              )
            else
              const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Color _getTextColor() {
    if (!isCurrentMonth) return AppTheme.sacredDark.withOpacity(0.15);
    if (isDisabled) return AppTheme.sacredDark.withOpacity(0.2);
    if (isToday) return Colors.white;
    return AppTheme.sacredDark;
  }
}
