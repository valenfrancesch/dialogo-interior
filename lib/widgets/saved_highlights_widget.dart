import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/prayer_entry.dart';
import '../theme/app_theme.dart';

class SavedHighlightsWidget extends StatelessWidget {
  final List<Highlight> highlights;
  final Function(Highlight)? onDelete;

  const SavedHighlightsWidget({
    super.key,
    required this.highlights,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (highlights.isEmpty) return const SizedBox.shrink();

    // Group highlights by source
    final groupedHighlights = <String, List<Highlight>>{};
    for (var highlight in highlights) {
      if (!groupedHighlights.containsKey(highlight.source)) {
        groupedHighlights[highlight.source] = [];
      }
      groupedHighlights[highlight.source]!.add(highlight);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: groupedHighlights.entries.map((entry) {
        final source = entry.key;
        final sourceHighlights = entry.value;

        return Padding(
          padding: const EdgeInsets.only(bottom: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header combining source and title of the first highlight (or dynamically if they differ)
              // Usually the source and title are standard for a given reading in the app
              if (sourceHighlights.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(
                    sourceHighlights.first.title.isNotEmpty 
                        ? '$source - ${sourceHighlights.first.title}' 
                        : source,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.accentMint,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              // List of highlights for this source
              ...sourceHighlights.map((highlight) => _buildHighlightItem(highlight)).toList(),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHighlightItem(Highlight highlight) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 48.0, 16.0),
            decoration: BoxDecoration(
              color: AppTheme.sacredGold.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: const Border(
                left: BorderSide(
                  color: AppTheme.sacredGold, 
                  width: 3,
                ),
              ),
            ),
            child: Text(
              '"${highlight.text}"',
              style: GoogleFonts.merriweather(
                fontStyle: FontStyle.italic,
                fontSize: 14,
                color: AppTheme.sacredDark.withOpacity(0.85),
                height: 1.6,
              ),
            ),
          ),
          if (onDelete != null)
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: const Icon(Icons.close, size: 20),
                color: AppTheme.sacredDark.withOpacity(0.4),
                onPressed: () => onDelete!(highlight),
                tooltip: 'Eliminar luz',
              ),
            ),
        ],
      ),
    );
  }
}
