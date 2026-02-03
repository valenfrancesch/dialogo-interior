import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
        decoration: BoxDecoration(
          color: AppTheme.sacredCream, // Using the cream background
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.sacredGold.withOpacity(0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.sacredGold.withOpacity(0.1),
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
                color: AppTheme.sacredRed,
              ),
            ),
            
          ],
        ),
      ),
    );
  }
}
