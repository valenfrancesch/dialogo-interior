import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/library_statistics.dart';
import '../theme/app_theme.dart';

class SpiritualGrowthCard extends StatelessWidget {
  final SpiritualGrowthInsight insight;
  final VoidCallback onTap;

  const SpiritualGrowthCard({
    super.key,
    required this.insight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardDark, // Mapped to Colors.white
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.sacredGold.withOpacity(0.3), width: 1), // Visible border
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado con pasaje bíblico
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.accentMint.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.auto_stories,
                    color: AppTheme.accentMint,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Crecimiento Espiritual',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.sacredDark.withOpacity(0.5), // Visible text
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        insight.gospelQuote,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.sacredDark, // Visible title
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Grid de estadísticas (2x2)
            Row(
              children: [
                Expanded(
                  child: _buildStatBlock(
                    label: 'Reflexiones',
                    value: insight.totalReflections.toString(),
                    icon: Icons.edit,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatBlock(
                    label: 'Palabras Escritas',
                    value: insight.totalWords.toString(),
                    icon: Icons.text_fields,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Sección de historiales (flashbacks)
            if (insight.historicalEntries.isNotEmpty) ...[
              Divider(
                color: AppTheme.sacredGold.withOpacity(0.2), // Visible divider
                height: 24,
                thickness: 1,
              ),
              Text(
                'Memorias de Años Pasados',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.sacredDark.withOpacity(0.5), // Visible text
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              ...insight.historicalEntries
                  .map((entry) => _buildHistoricalEntry(entry))
                  ,
            ],

            const SizedBox(height: 12),
            // Botón de expandir
            Center(
              child: Text(
                'Ver análisis completo',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.accentMint,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBlock({
    required String label,
    required String value,
    required IconData icon,
    bool isText = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.sacredCream, // Distinct background for blocks
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.sacredGold.withOpacity(0.2), width: 0.5), // Visible border
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppTheme.accentMint, size: 16),
          const SizedBox(height: 6),
          if (!isText)
            Text(
              value,
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.accentMint,
              ),
            )
          else
            Expanded(
              child: Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.sacredDark.withOpacity(0.8), // Visible text
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: AppTheme.sacredDark.withOpacity(0.5), // Visible text
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoricalEntry(LiturgicalMemoryEntry entry) {
    final yearsText = entry.yearsAgo == 1 ? 'Hace 1 año' : 'Hace 3 años';
    final backgroundColor = entry.yearsAgo == 1
        ? const Color(0xFF6366F1).withOpacity(0.1)
        : const Color(0xFFF59E0B).withOpacity(0.1);
    final borderColor = entry.yearsAgo == 1
        ? const Color(0xFF6366F1)
        : const Color(0xFFF59E0B);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor.withOpacity(0.3), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: borderColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  yearsText,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: borderColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _formatDate(entry.date),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppTheme.sacredDark.withOpacity(0.6), // Visible text
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            entry.reflection.length > 100
                ? '${entry.reflection.substring(0, 100)}...'
                : entry.reflection,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppTheme.sacredDark.withOpacity(0.8), // Visible text
              height: 1.4,
            ),
          ),

        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return '${date.day} de ${months[date.month - 1]}, ${date.year}';
  }
}
