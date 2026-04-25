import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../models/prayer_entry.dart';
import '../../../providers/app_providers.dart';
import '../../../utils/text_formatter.dart';
import '../../../widgets/selectable_text_content.dart';
import '../models/reading_tab_descriptor.dart';

class ReadingTabPage extends StatelessWidget {
  const ReadingTabPage({
    super.key,
    required this.tab,
    required this.highlights,
    required this.onHighlight,
  });

  final ReadingTabDescriptor tab;
  final List<Highlight> highlights;
  final ValueChanged<String> onHighlight;

  @override
  Widget build(BuildContext context) {
    const sourceString = 'Extraído de la Biblia: Libro del Pueblo de Dios';
    final hasSource = tab.content.contains(sourceString);
    final cleanText = tab.content.replaceFirst(sourceString, '').trim();
    final fontSize = Provider.of<ReadingFontSizeProvider>(
      context,
      listen: false,
    ).fontSize;
    final content = tab.type == ReadingTabType.psalm
        ? TextFormatter.formatPsalm(cleanText)
        : TextFormatter.formatReadingText(cleanText);

    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: scheme.onSurface.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tab.title,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          if (tab.type == ReadingTabType.commentary) ...[
            const SizedBox(height: 8),
            Text(
              '— ${tab.reference}',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: scheme.primary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 16),
          SelectableTextContent(
            text: content,
            textStyle: GoogleFonts.inter(
              fontSize: fontSize,
              fontStyle: tab.italicContent ? FontStyle.italic : FontStyle.normal,
              height: 1.8,
              color: scheme.onSurface.withOpacity(0.9),
            ),
            highlightedTexts: highlights
                .where((h) => h.source == tab.label)
                .map((h) => h.text)
                .toList(),
            onHighlight: onHighlight,
          ),
          if (hasSource) ...[
            const SizedBox(height: 16),
            Text(
              sourceString,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: scheme.onSurface.withOpacity(0.45),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (tab.type == ReadingTabType.commentary && tab.source.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              tab.source,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: scheme.onSurface.withOpacity(0.55),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
