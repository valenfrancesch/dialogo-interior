import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class TimelineCard extends StatefulWidget {
  final String timeLabel;
  final String date;
  final String passage;
  final String fullReflection;
  final String? highlightedText;
  final String? purpose;
  final bool isFirstReflection;

  const TimelineCard({
    super.key,
    required this.timeLabel,
    required this.date,
    required this.passage,
    required this.fullReflection,
    this.highlightedText,
    this.purpose,
    this.isFirstReflection = false,
  });

  @override
  State<TimelineCard> createState() => _TimelineCardState();
}

class _TimelineCardState extends State<TimelineCard> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Timeline Line (dynamic height)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 24),
                  child: const Icon(Icons.auto_stories, size: 20, color: AppTheme.sacredGold),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppTheme.sacredGold.withOpacity(0.3),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            
            // Content
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Time Label + Date
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
                              fontSize: 12,
                              color: AppTheme.sacredDark.withOpacity(0.6),
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
                            color: AppTheme.sacredGold.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppTheme.sacredGold,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'PRIMERA',
                            style: GoogleFonts.montserrat(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.sacredGold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Highlighted Text (if exists)
                  if (widget.highlightedText != null && widget.highlightedText!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.sacredGold.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: const Border(left: BorderSide(color: AppTheme.sacredGold, width: 4)),
                      ),
                      child: Text(
                        '"${widget.highlightedText}"',
                        style: GoogleFonts.merriweather(
                          fontStyle: FontStyle.italic,
                          fontSize: 14,
                          color: AppTheme.sacredDark.withOpacity(0.8),
                        ),
                      ),
                    ),
                  
                  // Reflection
                  if (widget.fullReflection.trim().isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        widget.fullReflection,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          height: 1.5,
                          color: AppTheme.sacredDark,
                        ),
                      ),
                    ),
                  
                  // Purpose (if exists)
                  if (widget.purpose != null && widget.purpose!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.sacredGold.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.sacredGold.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.stars, color: AppTheme.sacredGold, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.purpose!,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.sacredDark,
                                height: 1.5,
                              ),
                            ),
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
    );
  }
}
