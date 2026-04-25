import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isToday ? scheme.primary : Colors.transparent,
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
                color: _getTextColor(context),
              ),
            ),
            const SizedBox(height: 2),
            if (hasEntry)
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: isToday ? scheme.onPrimary : scheme.primary,
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

  Color _getTextColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (!isCurrentMonth) return scheme.onSurface.withOpacity(0.28);
    if (isDisabled) return scheme.onSurface.withOpacity(0.4);
    if (isToday) return scheme.onPrimary;
    return scheme.onSurface;
  }
}
