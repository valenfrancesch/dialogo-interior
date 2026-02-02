import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class TimelineCard extends StatefulWidget {
  final String timeLabel;
  final String date;
  final String passage;
  final String summary;
  final String fullReflection;
  final int wordCount;
  final bool isFirstReflection;
  final VoidCallback? onViewFull;

  const TimelineCard({
    super.key,
    required this.timeLabel,
    required this.date,
    required this.passage,
    required this.summary,
    required this.fullReflection,
    required this.wordCount,
    this.isFirstReflection = false,
    this.onViewFull,
  });

  @override
  State<TimelineCard> createState() => _TimelineCardState();
}

class _TimelineCardState extends State<TimelineCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.accentMint, // Keep this, it's mapped to sacredRed
                    width: 2,
                  ),
                  color: Colors.white, // Updated to white for contrast
                ),
                child: const Icon(
                  Icons.history,
                  color: AppTheme.accentMint,
                  size: 20,
                ),
              ),
              Container(
                width: 2,
                height: 60,
                color: AppTheme.sacredGold.withOpacity(0.3), // Updated timeline line color
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Card content
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.cardDark, // Mapped to Colors.white
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.sacredGold.withOpacity(0.3), // Updated border color
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with date and badge
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.timeLabel,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.accentMint,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.date,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.sacredDark, // Fixed color
                                  ),
                                ),
                              ],
                            ),
                            if (widget.isFirstReflection)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.sacredGold.withOpacity(0.15), // Updated badge bg
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppTheme.sacredGold,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  'PRIMERA REFLEXIÓN',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.sacredGold, // Updated text color
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.passage,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: AppTheme.sacredDark.withOpacity(0.5), // Fixed color
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Divider
                  Container(
                    height: 1,
                    color: AppTheme.sacredGold.withOpacity(0.2), // Updated divider color
                  ),
                  // Summary
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.summary,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: AppTheme.sacredDark.withOpacity(0.9), // Fixed color
                            height: 1.6,
                          ),
                          maxLines: _isExpanded ? null : 2,
                          overflow:
                              _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                        ),
                        if (_isExpanded)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 12),
                              Text(
                                'Reflexión Completa:',
                                style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.accentMint,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.fullReflection,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: AppTheme.sacredDark.withOpacity(0.8), // Fixed color
                                  height: 1.6,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 14,
                                    color: AppTheme.sacredDark.withOpacity(0.4), // Fixed color
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${widget.wordCount} palabras',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppTheme.sacredDark.withOpacity(0.4), // Fixed color
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isExpanded = !_isExpanded;
                            });
                            widget.onViewFull?.call();
                          },
                          child: Row(
                            children: [
                              Text(
                                _isExpanded ? 'Ocultar Entrada' : 'Ver Entrada Completa',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.accentMint,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                _isExpanded
                                    ? Icons.keyboard_arrow_up
                                    : Icons.arrow_forward,
                                size: 16,
                                color: AppTheme.accentMint,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
