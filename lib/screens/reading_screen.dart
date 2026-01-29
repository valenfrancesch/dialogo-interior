import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_theme.dart';
import '../widgets/text_segment_toggle.dart';
import '../widgets/selectable_text_content.dart';
import '../widgets/timeline_card.dart';
import '../models/gospel_data.dart';
import '../models/prayer_entry.dart';
import '../repositories/gospel_repository.dart';
import '../repositories/prayer_repository.dart';
import '../services/notification_service.dart';

class ReadingScreen extends StatefulWidget {
  final GospelData? gospel;

  const ReadingScreen({super.key, this.gospel});

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  int _selectedSegment = 0;
  late TextEditingController _responseController;
  late Future<GospelData> _gospelFuture;
  String _highlightedText = '';
  final PrayerRepository _prayerRepository = PrayerRepository();

  @override
  void initState() {
    super.initState();
    _responseController = TextEditingController();
    
    // Si viene gospel de Flashback, usarlo; si no, traer del API
    if (widget.gospel != null) {
      _gospelFuture = Future.value(widget.gospel!);
      _loadSavedReflection(widget.gospel!);
    } else {
      _gospelFuture = GospelRepository.fetchGospelData(DateTime.now());
      _gospelFuture.then((gospel) {
        _loadSavedReflection(gospel);
      });
    }
  }

  Future<void> _loadSavedReflection(GospelData gospel) async {
    try {
      final prayerRepository = PrayerRepository();
      final savedEntries = await prayerRepository.getHistoryByGospel(gospel.title);
      
      if (savedEntries.isNotEmpty && mounted) {
        setState(() {
          // Precargar la reflexión en el TextEditingController
          _responseController.text = savedEntries.first.reflection;
          _highlightedText = savedEntries.first.highlightedText ?? '';
        });
        print('✅ Reflexión precargada: ${gospel.title}');
      } else {
        print('⚠️ No hay reflexiones previas para: ${gospel.title}');
        // Para testing: mostrar reflexión de ejemplo si no hay datos
        
      }
    } catch (e) {
      print('❌ Error al cargar reflexión: $e');
      // Silently fail - just don't show the saved entry
    }
  }

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  Future<void> _shareReflection(GospelData gospel) async {
    final StringBuffer shareText = StringBuffer();
    
    // Add date and title
    shareText.writeln('📖 ${gospel.title}');
    shareText.writeln('📅 ${_formatDate(gospel.date)}');
    shareText.writeln();
    
    // Add gospel text
    shareText.writeln('═══ Evangelio ═══');
    shareText.writeln(gospel.evangeliumText);
    shareText.writeln();
    
    // Add highlighted text if exists
    if (_highlightedText.isNotEmpty) {
      shareText.writeln('✨ Pasaje Destacado:');
      shareText.writeln('"$_highlightedText"');
      shareText.writeln();
    }
    
    // Add reflection if exists
    final reflection = _responseController.text.trim();
    if (reflection.isNotEmpty) {
      shareText.writeln('💭 Mi Reflexión:');
      shareText.writeln(reflection);
      shareText.writeln();
    }
    
    shareText.writeln('───────────────');
    shareText.writeln('Compartido desde Diálogo interior');
    
    try {
      await Share.share(shareText.toString());
    } catch (e) {
      // Fallback for web or platforms where share isn't supported
      if (mounted) {
        await Clipboard.setData(ClipboardData(text: shareText.toString()));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Texto copiado al portapapeles'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _saveReflection(GospelData gospel) async {
  final reflectionText = _responseController.text.trim();
  
  if (reflectionText.isEmpty && _highlightedText.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Por favor escribe tu reflexión o destaca un texto antes de guardar')),
    );
    return;
  }

  try {
    final prayerRepository = PrayerRepository();
    
    // Check if an entry already exists for this gospel
    final existingEntries = await prayerRepository.getHistoryByGospel(gospel.title);
    
    String entryId = ''; // Firestore will generate this if new
    
    if (existingEntries.isNotEmpty) {
      // Use the ID of the existing entry to update it
      entryId = existingEntries.first.id ?? '';
    } else {
      // For new entries, use date in YYYY-MM-DD format as ID
      final now = gospel.date;
      entryId = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    }

    print(entryId);
    // Create a PrayerEntry with the appropriate ID
    final prayerEntry = PrayerEntry(
      id: entryId, // Will be empty for new entries (Firestore generates), or existing ID for updates
      userId: '1', // Hardcoded for now
      date: gospel.date,
      gospelQuote: gospel.title,
      reflection: _responseController.text.trim(),
      highlightedText: _highlightedText.isNotEmpty ? _highlightedText : null,
      tags: existingEntries.isNotEmpty ? existingEntries.first.tags : [],
    );

    // Save to Firebase (will update if ID exists, create if new)
    await prayerRepository.saveReflection(prayerEntry);

    // Reflection saved successfully
    if (mounted) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Reflexión guardada exitosamente'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDarkBg,
      body: FutureBuilder<GospelData>(
        future: _gospelFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          } else if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          } else if (snapshot.hasData) {
            final gospel = snapshot.data!;
            return _buildContentState(gospel);
          }
          return _buildErrorState('Estado desconocido');
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentMint),
          ),
          const SizedBox(height: 16),
          Text(
            'Cargando lectura del día...',
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDarkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppTheme.accentMint,
              ),
              const SizedBox(height: 16),
              Text(
                'Error al cargar el evangelio',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                error,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _gospelFuture =
                        GospelRepository.fetchGospelData(DateTime.now());
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentMint,
                  foregroundColor: AppTheme.primaryDarkBg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    // Example: "Jueves, 28 de Enero" would be nice, but simple is safer:
    // User requested "top of the reading title".
    return '${date.day} de ${months[date.month - 1]}, ${date.year}';
  }

  Widget _buildContentState(GospelData gospel) {
    return SingleChildScrollView(
      child: Column(
        children: [
          AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            toolbarHeight: 70, // Increased height to accommodate two lines
            title: Column(
              children: [
                Text(
                  _formatDate(gospel.date).toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.accentMint,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  gospel.title,
                  style: GoogleFonts.montserrat(
                    fontSize: 18, // Slightly smaller to fit better
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share, color: AppTheme.accentMint),
                onPressed: () => _shareReflection(gospel),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Segment Toggle
                TextSegmentToggle(
                  segments: const ['Evangelio', 'Comentario'],
                  initialIndex: 0,
                  onChanged: (index) {
                    setState(() {
                      _selectedSegment = index;
                    });
                  },
                ),
                const SizedBox(height: 24),

                // Scripture Text Content
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white10,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_selectedSegment == 0) ...[
                        // Pestaña Evangelio
                        SelectableTextContent(
                          text: gospel.evangeliumText,
                          textStyle: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withOpacity(0.87),
                            height: 1.8,
                          ),
                          onHighlight: (text) {
                            setState(() => _highlightedText = text);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Pasaje destacado actualizado'),
                                duration: Duration(milliseconds: 1500),
                              ),
                            );
                            _saveReflection(gospel);
                          },
                        ),
                      ] else ...[
                        // Pestaña Comentario (Catena Aurea)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              gospel.commentTitle,
                              style: GoogleFonts.montserrat(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SelectableTextContent(
                              text: gospel.commentBody,
                              textStyle: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withOpacity(0.87),
                                height: 1.8,
                              ),
                          onHighlight: (text) {
                            setState(() => _highlightedText = text);
                            
                            // Schedule notification for favorite verse (e.g., 20:00)
                            NotificationService().scheduleFavoriteReminder(text, 20, 0);

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Pasaje destacado actualizado y programado como recordatorio'),
                                duration: Duration(milliseconds: 2000),
                              ),
                            );
                            _saveReflection(gospel);
                          },
                            ),
                            const SizedBox(height: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '— ${gospel.commentAuthor}',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.accentMint,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                if (gospel.commentSource.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      gospel.commentSource,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Colors.white30,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ],  // Cierra else spread
                    ],    // Cierra children del Container
                  ),      // Cierra Column
                ),        // Cierra Container
                const SizedBox(height: 24),

                // Highlighted Text Section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Pasaje Destacado',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.accentMint,
                          ),
                        ),
                        if (_highlightedText.isNotEmpty)
                          TextButton.icon(
                            onPressed: () => setState(() => _highlightedText = ''),
                            icon: const Icon(Icons.clear, size: 18),
                            label: const Text('Limpiar'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_highlightedText.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.accentMint.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.accentMint.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          _highlightedText,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.87),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Mantén presionado sobre el texto del evangelio para seleccionar y presiona "Destacar" para guardarlo aquí.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white30,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),

                // God's Message Question Section
                Text(
                  '¿Qué me dice Dios hoy?',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.accentMint,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _responseController,
                  maxLines: 5,
                  minLines: 3,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.87),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Escribe tu reflexión personal...',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white30,
                    ),
                    filled: true,
                    fillColor: AppTheme.cardDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.white10,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.white10,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppTheme.accentMint,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Save Reflection Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => _saveReflection(gospel),
                    icon: const Icon(Icons.save),
                    label: const Text(
                      'Guardar Reflexión',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentMint,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Memoria Espiritual Section (Flashback)
                _buildMemoriaEspiritualSection(gospel),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoriaEspiritualSection(GospelData gospel) {
    return FutureBuilder<List<PrayerEntry>>(
      future: _prayerRepository.getHistoryByGospel(gospel.title),
      builder: (context, snapshot) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Memoria Espiritual',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(
                child: CircularProgressIndicator(color: AppTheme.accentMint),
              )
            else if (snapshot.hasError)
              Text(
                'Error al cargar reflexiones anteriores',
                style: GoogleFonts.inter(color: Colors.red),
              )
            else if (snapshot.data == null || snapshot.data!.length <= 1)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_stories,
                      color: AppTheme.accentMint,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Esta es la primera vez que reflexionas sobre este evangelio. ¡Qué emocionante comenzar este camino espiritual!',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.87),
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: snapshot.data!
                    .where((entry) => entry.id != snapshot.data!.first.id)
                    .map((entry) {
                  final yearsAgo = _calculateYearsAgo(entry.date);
                  return TimelineCard(
                    timeLabel: yearsAgo,
                    date: _formatDate(entry.date),
                    passage: entry.gospelQuote,
                    summary: entry.reflection.length > 100
                        ? '${entry.reflection.substring(0, 100)}...'
                        : entry.reflection,
                    fullReflection: entry.reflection,
                    wordCount: entry.reflection.split(' ').length,
                    isFirstReflection: false,
                  );
                }).toList(),
              ),
          ],
        );
      },
    );
  }

  String _calculateYearsAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference < 365) {
      return 'Reciente';
    }
    
    final years = (difference / 365).floor();
    return 'Hace $years Año${years > 1 ? 's' : ''}';
  }
}
