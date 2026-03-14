import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class StatisticsCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String mainValue;
  final String? mainValueSuffix;
  final String? secondaryValue;
  final Color? valueColor;
  final VoidCallback? onTap;
  final Color? backgroundColor;

  const StatisticsCard({
    super.key,
    required this.icon,
    required this.label,
    required this.mainValue,
    this.mainValueSuffix,
    this.secondaryValue,
    this.valueColor,
    this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor ?? AppTheme.cardDark, // Mapped to Colors.white
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
            Row(
              children: [
                Icon(
                  icon,
                  color: AppTheme.accentMint,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.sacredDark.withOpacity(0.6), // Visible text
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            RichText(
              text: TextSpan(
                style: GoogleFonts.montserrat(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: valueColor ?? AppTheme.sacredDark,
                ),
                children: [
                  TextSpan(text: mainValue),
                  if (mainValueSuffix != null)
                    TextSpan(
                      text: ' $mainValueSuffix',
                      style: GoogleFonts.inter( // Smaller and different font for the unit/suffix
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.sacredDark.withOpacity(0.5),
                      ),
                    ),
                ],
              ),
            ),
            if (secondaryValue != null) ...[
              const SizedBox(height: 8),
              Text(
                secondaryValue!,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.accentMint,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
