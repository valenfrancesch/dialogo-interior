import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../theme/app_theme.dart';
import '../models/prayer_entry.dart';

class Lecture {
  final String title;
  final String content;
  final String? reference;
  final String? longTitle;
  final String? source;

  Lecture({
    required this.title,
    required this.content,
    this.reference,
    this.longTitle,
    this.source,
  });
}

class ShareBottomSheet extends StatefulWidget {
  final DateTime date;
  final List<Lecture> availableLectures;
  final List<Highlight> highlights;
  final String? reflection;
  final String? purpose;

  const ShareBottomSheet({
    super.key,
    required this.date,
    required this.availableLectures,
    required this.highlights,
    this.reflection,
    this.purpose,
  });

  @override
  State<ShareBottomSheet> createState() => _ShareBottomSheetState();
}

class _ShareBottomSheetState extends State<ShareBottomSheet> {
  final Map<String, bool> _selectedState = {};
  bool _isGeneratingPdf = false;

  @override
  void initState() {
    super.initState();
    for (var lecture in widget.availableLectures) {
      _selectedState[lecture.title] = true;
    }
    if (widget.highlights.isNotEmpty) {
      _selectedState['Luces de hoy'] = true;
    }
    if (widget.reflection != null && widget.reflection!.trim().isNotEmpty) {
      _selectedState['Reflexión'] = true;
    }
    if (widget.purpose != null && widget.purpose!.trim().isNotEmpty) {
      _selectedState['Propósito'] = true;
    }
  }

  List<Map<String, String>> _getSelectedItems() {
    final List<Map<String, String>> selectedItems = [];

    for (var lecture in widget.availableLectures) {
      if (_selectedState[lecture.title] == true) {
        final cleanContent = lecture.content.replaceAll('Extraído de la Biblia: Libro del Pueblo de Dios.', '').trim();
        selectedItems.add({
          'title': lecture.title,
          'content': cleanContent,
          'reference': lecture.reference ?? '',
          'longTitle': lecture.longTitle ?? '',
          'source': lecture.source ?? '',
        });
      }
    }

    if (_selectedState['Luces de hoy'] == true && widget.highlights.isNotEmpty) {
      final highlightsText = widget.highlights.map((h) => '"${h.text}" (${h.source})').join('\n\n');
      selectedItems.add({
        'title': 'Luces de hoy',
        'content': highlightsText,
      });
    }

    if (_selectedState['Reflexión'] == true && widget.reflection != null && widget.reflection!.trim().isNotEmpty) {
      selectedItems.add({
        'title': 'Mi Reflexión',
        'content': widget.reflection!.trim(),
      });
    }

    if (_selectedState['Propósito'] == true && widget.purpose != null && widget.purpose!.trim().isNotEmpty) {
      selectedItems.add({
        'title': 'Propósito del día',
        'content': widget.purpose!.trim(),
      });
    }

    return selectedItems;
  }

  Future<void> _shareViaWhatsApp() async {
    final items = _getSelectedItems();
    if (items.isEmpty) return;

    final StringBuffer buffer = StringBuffer();
    final dateStr = DateFormat('dd/MM/yyyy').format(widget.date);
    buffer.writeln('📖 Diálogo Interior - $dateStr\n');

    for (var item in items) {
      final isLecture = ['1ª Lectura', 'Salmo', '2ª Lectura', 'Evangelio', 'Comentario'].contains(item['title']);
      final hasRef = item.containsKey('reference') && item['reference']!.trim().isNotEmpty && 
                     item['reference'] != 'Lectura del Día' && item['reference'] != 'Reflexión Guardada';

      if (isLecture && hasRef) {
        buffer.writeln(item['title']!.toUpperCase());
        buffer.writeln('═══ ${item['reference']} ═══');
      } else {
        buffer.writeln('═══ ${item['title']} ═══');
        if (hasRef && item['reference'] != item['title']) {
          buffer.writeln('${item['reference']}\n');
        }
      }
      
      if (item['content']!.isNotEmpty) {
        buffer.writeln('${item['content']}\n');
      }
    }

    buffer.writeln('───────────────');
    buffer.writeln('Compartido desde Diálogo Interior');

    try {
      final box = context.findRenderObject() as RenderBox?;
      final sharePositionOrigin = box != null
          ? Rect.fromLTWH(0, 0, box.size.width, box.size.height / 2)
          : null;
      
      await Share.share(
        buffer.toString(),
        sharePositionOrigin: sharePositionOrigin,
      );
      
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al compartir: $e')),
        );
      }
    }
  }

  Future<void> _generateAndSavePDF() async {
    final items = _getSelectedItems();
    if (items.isEmpty) return;

    setState(() => _isGeneratingPdf = true);

    // Give the UI a frame to show the loading spinner before starting heavy work
    await Future.delayed(const Duration(milliseconds: 300));

    try {
      final logoBytes = await rootBundle.load('assets/images/logo.png');
    final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

    // Avoid runtime font downloads (can hang on iOS preview/share flow).
    final fontRegular = pw.Font.times();
    final fontBold = pw.Font.timesBold();
    final fontItalic = pw.Font.timesItalic();

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(
        base: fontRegular,
        bold: fontBold,
        italic: fontItalic,
      ),
    );
    final dateStr = DateFormat('dd/MM/yyyy').format(widget.date);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: (pw.Context context) {
          return pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Row(
                children: [
                  pw.Image(logoImage, width: 14, height: 14),
                  pw.SizedBox(width: 6),
                  pw.Text('Diálogo interior', style: pw.TextStyle(fontSize: 10, color: const PdfColor.fromInt(0xffA83232))),
                ],
              ),
              pw.Text(
                'Página ${context.pageNumber} de ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 10, color: PdfColor(0.5, 0.5, 0.5)),
              ),
            ],
          );
        },
        build: (pw.Context context) {
          final List<pw.Widget> widgets = [];
          
          widgets.add(
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                   pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Image(logoImage, width: 28, height: 28),
                      pw.SizedBox(width: 8),
                      pw.Text('Diálogo Interior', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: const PdfColor(0.2, 0.2, 0.2))),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text('Reflexión del $dateStr', style: const pw.TextStyle(fontSize: 14, color: PdfColor(0.5, 0.5, 0.5))),
                  pw.SizedBox(height: 16),
                  pw.Divider(color: const PdfColor(0.8, 0.8, 0.8)),
                ],
              )
            )
          );
          
          widgets.add(pw.SizedBox(height: 16));

          for (var item in items) {
            final isLecture = ['1ª Lectura', 'Salmo', '2ª Lectura', 'Evangelio', 'Comentario'].contains(item['title']);
            final isComment = item['title'] == 'Comentario';
            final hasRef = item.containsKey('reference') && item['reference']!.trim().isNotEmpty && 
                           item['reference'] != 'Lectura del Día' && item['reference'] != 'Reflexión Guardada';
            final hasLongTitle = item.containsKey('longTitle') && item['longTitle']!.trim().isNotEmpty;
            final source = item['source']?.trim() ?? '';
            final author = item['reference']?.trim() ?? '';
            final commentAttribution = <String>[
              if (author.isNotEmpty) author,
              if (source.isNotEmpty) source,
            ].join(' • ');

            if (isLecture && (hasRef || hasLongTitle)) {
              final lectureDisplayTitle = hasLongTitle
                  ? item['longTitle']!
                  : (item['reference'] ?? item['title']!);
              widgets.add(pw.Text(
                item['title']!.toUpperCase(), 
                style: pw.TextStyle(
                  fontSize: 10, 
                  fontWeight: pw.FontWeight.bold, 
                  color: const PdfColor(0.5, 0.5, 0.5),
                  letterSpacing: 1.2
                )
              ));
              widgets.add(pw.SizedBox(height: 2));
              widgets.add(pw.Text(
                lectureDisplayTitle, 
                style: pw.TextStyle(
                  fontSize: 18, 
                  fontWeight: pw.FontWeight.bold, 
                  color: const PdfColor.fromInt(0xffA83232)
                )
              ));
              if (isComment && commentAttribution.isNotEmpty) {
                widgets.add(pw.SizedBox(height: 4));
                widgets.add(pw.Text(
                  commentAttribution,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontStyle: pw.FontStyle.italic,
                    color: const PdfColor(0.4, 0.4, 0.4),
                  ),
                ));
              }
            } else {
              widgets.add(pw.Text(
                item['title']!, 
                style: pw.TextStyle(
                  fontSize: 18, 
                  fontWeight: pw.FontWeight.bold, 
                  color: const PdfColor.fromInt(0xffA83232)
                )
              ));
              if (hasRef && item['reference'] != item['title']) {
                widgets.add(pw.SizedBox(height: 4));
                widgets.add(pw.Text(
                  item['reference']!, 
                  style: pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic, color: const PdfColor(0.4, 0.4, 0.4))
                ));
              }
            }

            if (item['content']!.isNotEmpty) {
              widgets.add(pw.SizedBox(height: 8));
              for (var line in item['content']!.replaceAll('\r\n', '\n').split('\n')) {
                final text = line.trim();
                if (text.isEmpty) {
                  widgets.add(pw.SizedBox(height: 8));
                } else {
                  widgets.add(pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Text(
                      text,
                      style: const pw.TextStyle(fontSize: 12, lineSpacing: 1.5, color: PdfColor(0.1, 0.1, 0.1))
                    ),
                  ));
                }
              }
            }
            
            widgets.add(pw.SizedBox(height: 24));
          }

          return widgets;
        },
      ),
    );

    final pdfBytes = await doc.save();

    final fileName = '${DateFormat('yyyy-MM-dd').format(widget.date)}-dialogo-interior.pdf';
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
    } else {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: fileName,
      );
    }
    
    if (mounted) {
      setState(() => _isGeneratingPdf = false);
      Navigator.pop(context);
    }
    } catch (e) {
      if (mounted) setState(() => _isGeneratingPdf = false);
      print('Error generating PDF: $e');
    }
  }

  Widget _buildCheckboxRow(BuildContext context, String key, String title) {
    final scheme = Theme.of(context).colorScheme;
    return CheckboxListTile(
      value: _selectedState[key] ?? false,
      onChanged: (val) {
        if (val != null) {
          setState(() {
            _selectedState[key] = val;
          });
        }
      },
      title: Text(
        title,
        style: GoogleFonts.inter(fontSize: 14, color: scheme.onSurface),
      ),
      activeColor: scheme.primary,
      checkColor: scheme.onPrimary,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      visualDensity: VisualDensity.compact,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    bool hasNotes = widget.highlights.isNotEmpty ||
        (widget.reflection != null && widget.reflection!.trim().isNotEmpty) ||
        (widget.purpose != null && widget.purpose!.trim().isNotEmpty);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Compartir',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: scheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Selecciona qué contenido deseas incluir',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: scheme.onSurface.withOpacity(0.72),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          if (widget.availableLectures.isNotEmpty) ...[
            Text(
              'Lecturas',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            ...widget.availableLectures
                .map((lecture) => _buildCheckboxRow(context, lecture.title, lecture.title))
                .toList(),
            const SizedBox(height: 16),
          ],
          
          if (hasNotes) ...[
            Text(
              'Mis apuntes',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            if (widget.highlights.isNotEmpty)
              _buildCheckboxRow(context, 'Luces de hoy', 'Luces de hoy'),
            if (widget.reflection != null && widget.reflection!.trim().isNotEmpty)
              _buildCheckboxRow(context, 'Reflexión', 'Reflexión'),
            if (widget.purpose != null && widget.purpose!.trim().isNotEmpty)
              _buildCheckboxRow(context, 'Propósito', 'Propósito del día'),
            const SizedBox(height: 28),
          ],

          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _shareViaWhatsApp,
                  icon: const Icon(Icons.ios_share, size: 20),
                  label: const Text('Texto plano'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: scheme.primary,
                    side: BorderSide(color: scheme.primary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isGeneratingPdf ? null : _generateAndSavePDF,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: _isGeneratingPdf ? scheme.primary : scheme.onPrimary,
                    backgroundColor: _isGeneratingPdf
                        ? scheme.surface
                        : scheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: _isGeneratingPdf 
                        ? BorderSide(color: scheme.primary, width: 2)
                        : BorderSide.none,
                    ),
                    elevation: 0,
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _isGeneratingPdf 
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.picture_as_pdf, size: 20),
                            SizedBox(width: 8),
                            Text('Guardar PDF', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
