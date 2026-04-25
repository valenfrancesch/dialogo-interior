import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GospelButton extends StatelessWidget {
  final String title;
  //final String subtitle;
  // final IconData icon; // Removed
  final Color color;
  final VoidCallback onTap;

  const GospelButton({
    super.key,
    required this.title,
   // required this.subtitle,
    // required this.icon, // Removed
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? scheme.surfaceContainerHigh : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.28 : 0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon removed as per request
            Text(
              title,
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? scheme.onSurface : color,
              ),
            ),
            
          ],
        ),
      ),
    );
  }
}
