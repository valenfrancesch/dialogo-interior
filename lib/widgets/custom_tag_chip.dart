import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/tag.dart';
import '../theme/app_theme.dart';

class CustomTagChip extends StatelessWidget {
  final Tag tag;
  final bool isSelected;
  final VoidCallback onTap;

  const CustomTagChip({
    super.key,
    required this.tag,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accentMint.withOpacity(0.2)
              : AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.accentMint : Colors.white24,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tag.emoji,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 6),
            Text(
              '#${tag.name}',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? AppTheme.accentMint : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
