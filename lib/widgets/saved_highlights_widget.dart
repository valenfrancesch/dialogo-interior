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
    final scheme = Theme.of(context).colorScheme;

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
                      color: scheme.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              // List of highlights for this source
              ...sourceHighlights
                  .map((highlight) => _buildHighlightItem(context, highlight))
                  .toList(),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHighlightItem(BuildContext context, Highlight highlight) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 48.0, 16.0),
            decoration: BoxDecoration(
              color: AppTheme.sacredGold.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border(
                left: BorderSide(
                  color: AppTheme.sacredGold,
                  width: 4,
                ),
              ),
            ),
            child: Text(
              '"${highlight.text}"',
              style: GoogleFonts.merriweather(
                fontStyle: FontStyle.italic,
                fontSize: 14,
                color: scheme.onSurface.withOpacity(0.8),
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
                color: scheme.onSurface.withOpacity(0.55),
                onPressed: () => onDelete!(highlight),
                tooltip: 'Eliminar luz',
              ),
            ),
        ],
      ),
    );
  }
}
