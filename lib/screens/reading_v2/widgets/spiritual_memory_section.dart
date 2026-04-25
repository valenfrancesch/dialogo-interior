import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/prayer_entry.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/timeline_card.dart';

class SpiritualMemorySection extends StatelessWidget {
  const SpiritualMemorySection({
    super.key,
    required this.historyFuture,
    required this.formatDate,
  });

  final Future<List<PrayerEntry>> historyFuture;
  final String Function(DateTime) formatDate;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PrayerEntry>>(
      future: historyFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.accentMint),
          );
        }
        if (snapshot.hasError) {
          return Text(
            'Error al cargar reflexiones anteriores',
            style: GoogleFonts.inter(color: Colors.red),
          );
        }
        final entries = snapshot.data ?? <PrayerEntry>[];
        if (entries.isEmpty) {
          return _buildFirstTimeCard(
            'Esta es la primera vez que reflexionas sobre este evangelio. ¡Qué emocionante comenzar este camino espiritual!',
          );
        }
        if (entries.length == 1) {
          return _buildFirstTimeCard(
            'Esta es la primera vez que reflexionas sobre este evangelio.',
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Memoria Espiritual',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.sacredDark,
              ),
            ),
            const SizedBox(height: 16),
            Column(
              children: entries
                  .where((entry) => entry.id != entries.first.id)
                  .map(
                    (entry) => TimelineCard(
                      timeLabel: _calculateYearsAgo(entry.date),
                      date: formatDate(entry.date),
                      passage: entry.gospelQuote,
                      fullReflection: entry.reflection,
                      highlights: entry.highlights,
                      purpose: entry.purpose,
                    ),
                  )
                  .toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFirstTimeCard(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEBE8E3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.auto_stories,
            color: AppTheme.sacredRed,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.sacredDark.withOpacity(0.9),
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _calculateYearsAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    if (difference < 365) return 'Reciente';
    final years = (difference / 365).floor();
    return 'Hace $years Año${years > 1 ? 's' : ''}';
  }
}
