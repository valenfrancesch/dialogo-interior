import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/saved_highlights_widget.dart';
import '../reading_session_controller.dart';
import 'spiritual_memory_section.dart';

class ReflectionSection extends StatelessWidget {
  const ReflectionSection({
    super.key,
    required this.controller,
    required this.onGuestTap,
    required this.purposeKey,
    required this.reflectionKey,
  });

  final ReadingSessionController controller;
  final VoidCallback onGuestTap;
  final Key purposeKey;
  final Key reflectionKey;

  @override
  Widget build(BuildContext context) {
    final isGuest = controller.isGuest;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          'Luces de hoy',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.accentMint,
          ),
        ),
        const SizedBox(height: 8),
        if (controller.highlights.isNotEmpty)
          SavedHighlightsWidget(
            highlights: controller.highlights,
            onDelete: (highlight) => controller.removeHighlight(highlight),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'Mantén presionado sobre el texto para destacar.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppTheme.sacredDark.withOpacity(0.4),
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '¿Qué me dice Dios hoy?',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.accentMint,
              ),
            ),
            _SaveStatusIndicator(status: controller.saveStatus),
          ],
        ),
        const SizedBox(height: 12),
        Stack(
          key: reflectionKey,
          alignment: Alignment.bottomRight,
          children: [
            TextField(
              controller: controller.reflectionController,
              focusNode: controller.reflectionFocusNode,
              onChanged: (_) => controller.onTextChanged(),
              readOnly: isGuest,
              onTap: isGuest ? onGuestTap : null,
              minLines: 3,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                hintText: 'Escribe una reflexión personal...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.sacredDark.withOpacity(0.3),
                ),
                filled: true,
                fillColor: AppTheme.cardDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.fromLTRB(16, 12, 48, 12),
              ),
            ),
            if (controller.reflectionFocusNode.hasFocus && !isGuest)
              Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 8),
                child: IconButton(
                  onPressed: () async {
                    controller.reflectionFocusNode.unfocus();
                    await controller.saveNow();
                  },
                  icon: const Icon(Icons.check, color: Colors.white, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.sacredRed,
                    padding: const EdgeInsets.all(8),
                    minimumSize: const Size(36, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Propósito del día',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.accentMint,
          ),
        ),
        const SizedBox(height: 12),
        Stack(
          key: purposeKey,
          alignment: Alignment.bottomRight,
          children: [
            TextField(
              controller: controller.purposeController,
              focusNode: controller.purposeFocusNode,
              onChanged: (_) => controller.onTextChanged(),
              readOnly: isGuest,
              onTap: isGuest ? onGuestTap : null,
              minLines: 1,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.stars, color: AppTheme.accentMint),
                hintText: 'Escribe un propósito concreto...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.sacredDark.withOpacity(0.3),
                  fontStyle: FontStyle.italic,
                ),
                filled: true,
                fillColor: AppTheme.cardDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.fromLTRB(16, 14, 48, 14),
              ),
            ),
            if (controller.purposeFocusNode.hasFocus && !isGuest)
              Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 8),
                child: IconButton(
                  onPressed: () async {
                    controller.purposeFocusNode.unfocus();
                    await controller.saveNow();
                  },
                  icon: const Icon(Icons.check, color: Colors.white, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.sacredRed,
                    padding: const EdgeInsets.all(8),
                    minimumSize: const Size(36, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 32),
        SpiritualMemorySection(
          historyFuture: controller.historyFuture,
          formatDate: _formatDate,
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return '${date.day} de ${months[date.month - 1]}, ${date.year}';
  }
}

class _SaveStatusIndicator extends StatelessWidget {
  const _SaveStatusIndicator({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case 'saving':
        return const Icon(Icons.sync, color: AppTheme.sacredGold, size: 20);
      case 'saved':
        return const Icon(Icons.cloud_done, color: AppTheme.sacredGold, size: 20);
      case 'error':
        return const Icon(Icons.cloud_off, color: Colors.red, size: 20);
      default:
        return const SizedBox.shrink();
    }
  }
}
