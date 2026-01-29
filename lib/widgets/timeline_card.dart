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
                    color: AppTheme.accentMint,
                    width: 2,
                  ),
                  color: AppTheme.cardDark,
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
                color: Colors.white10,
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Card content
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white10,
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
                                    color: Colors.white.withOpacity(0.87),
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
                                  color: const Color(0xFFFFB800).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFFFFB800),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  'PRIMERA REFLEXIÓN',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFFFB800),
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
                            color: Colors.white30,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Divider
                  Container(
                    height: 1,
                    color: Colors.white10,
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
                            color: Colors.white.withOpacity(0.87),
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
                                  color: Colors.white.withOpacity(0.7),
                                  height: 1.6,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 14,
                                    color: Colors.white30,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${widget.wordCount} palabras',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Colors.white30,
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
