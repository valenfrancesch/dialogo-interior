import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class CalendarDay extends StatelessWidget {
  final int day;
  final bool hasEntry;
  final bool isToday;
  final VoidCallback onTap;
  final bool isDisabled;

  const CalendarDay({
    super.key,
    required this.day,
    required this.hasEntry,
    required this.isToday,
    required this.onTap,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          color: hasEntry ? AppTheme.accentMint.withOpacity(0.15) : Colors.transparent, // Visible bg
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isToday
                ? AppTheme.accentMint
                : (hasEntry
                    ? AppTheme.accentMint.withOpacity(0.5)
                    : AppTheme.sacredGold.withOpacity(isDisabled ? 0.1 : 0.3)), // Dimmed border if disabled
            width: isToday ? 2 : 1,
          ),
        ),
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                day.toString(),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDisabled 
                      ? AppTheme.sacredDark.withOpacity(0.2) // Disabled color
                      : (hasEntry ? AppTheme.accentMint : AppTheme.sacredDark.withOpacity(0.7)),
                ),
              ),
              if (hasEntry)
                Positioned(
                  bottom: 4,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.accentMint,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
