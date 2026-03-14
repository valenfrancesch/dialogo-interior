import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class DiaryEntryCard extends StatelessWidget {
  final String date;
  final String passage;
  final String excerpt;
  final VoidCallback onTap;
  final bool isItalic;

  const DiaryEntryCard({
    super.key,
    required this.date,
    required this.passage,
    required this.excerpt,
    required this.onTap,
    this.isItalic = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.sacredDark.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fecha y referencia
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.sacredDark.withOpacity(0.5), // Visible text
                  ),
                ),
                Text(
                  passage,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.accentMint,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Excerpt
            Text(
              excerpt,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
                color: AppTheme.sacredDark.withOpacity(0.8), // Visible text
                height: 1.5,
              ),
              maxLines: 4, // Increased maxLines since title is gone
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // Etiquetas

          ],
        ),
      ),
    );
  }
}
