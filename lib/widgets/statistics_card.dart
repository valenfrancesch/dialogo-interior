import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class StatisticsCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String mainValue;
  final String? secondaryValue;
  final Color? valueColor;

  const StatisticsCard({
    super.key,
    required this.icon,
    required this.label,
    required this.mainValue,
    this.secondaryValue,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white10,
          width: 1,
        ),
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
                  color: Colors.white60,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            mainValue,
            style: GoogleFonts.montserrat(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.white,
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
    );
  }
}
