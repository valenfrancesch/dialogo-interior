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
import '../utils/text_formatter.dart';

class ReadingScreen extends StatefulWidget {
  final GospelData? gospel;

  const ReadingScreen({super.key, this.gospel});

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  late Future<GospelData> _gospelFuture;

  @override
  void initState() {
    super.initState();
    if (widget.gospel != null) {
      _gospelFuture = Future.value(widget.gospel!);
    } else {
      _gospelFuture = GospelRepository.fetchGospelData(DateTime.now());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDarkBg, // Now sacredCream
      body: FutureBuilder<GospelData>(
        future: _gospelFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          } else if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          } else if (snapshot.hasData) {
            return _ReadingContent(gospel: snapshot.data!);
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
              color: AppTheme.sacredDark.withOpacity(0.7), // Fixed text color
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
                  color: AppTheme.sacredDark, // Fixed text color
                ),
              ),
              const SizedBox(height: 12),
              Text(
                error,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.sacredDark.withOpacity(0.7), // Fixed text color
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _gospelFuture = GospelRepository.fetchGospelData(DateTime.now());
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentMint,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadingContent extends StatefulWidget {
  final GospelData gospel;

  const _ReadingContent({required this.gospel});

  @override
  State<_ReadingContent> createState() => _ReadingContentState();
}

class _ReadingContentState extends State<_ReadingContent> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0; // Index for the flattened list
  String _highlightedText = '';
  final TextEditingController _responseController = TextEditingController();
  final PrayerRepository _prayerRepository = PrayerRepository();
  late List<String> _tabs;
  late List<String> _tabLabels; // For the toggle display

  @override
  void initState() {
    super.initState();
    _tabs = ['1ª Lectura', 'Salmo'];
    _tabLabels = ['1ª Lec', 'Salmo'];
    
    if (widget.gospel.secondReading != null && widget.gospel.secondReading!.isNotEmpty) {
      _tabs.add('2ª Lectura');
      _tabLabels.add('2ª Lec');
    }
    _tabs.add('Evangelio');
    _tabLabels.add('Evangelio');
    
    _tabs.add('Comentario');
    _tabLabels.add('Comentario');

    // Default to Gospel (index of 'Evangelio')
    _selectedIndex = _tabs.indexOf('Evangelio');
    
    _loadSavedReflection();
  }

  Future<void> _loadSavedReflection() async {
    try {
      final savedEntries = await _prayerRepository.getHistoryByGospel(widget.gospel.title);
      if (savedEntries.isNotEmpty && mounted) {
        setState(() {
          _responseController.text = savedEntries.first.reflection;
          _highlightedText = savedEntries.first.highlightedText ?? '';
        });
      }
    } catch (e) {
      print('Error loading reflection: $e');
    }
  }

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  Future<void> _saveReflection() async {
    final reflectionText = _responseController.text.trim();
    if (reflectionText.isEmpty && _highlightedText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor escribe tu reflexión o destaca un texto')),
      );
      return;
    }

    try {
      final existingEntries = await _prayerRepository.getHistoryByGospel(widget.gospel.title);
      String entryId = '';
      if (existingEntries.isNotEmpty) {
        entryId = existingEntries.first.id ?? '';
      } else {
        final now = widget.gospel.date;
        entryId = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      }

      final prayerEntry = PrayerEntry(
        id: entryId,
        userId: '1',
        date: widget.gospel.date,
        gospelQuote: widget.gospel.title,
        reflection: reflectionText,
        highlightedText: _highlightedText.isNotEmpty ? _highlightedText : null,
        tags: existingEntries.isNotEmpty ? existingEntries.first.tags : [],
      );

      await _prayerRepository.saveReflection(prayerEntry);

      if (mounted) {
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
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    }
  }

  Future<void> _shareReflection() async {
    final StringBuffer shareText = StringBuffer();
    shareText.writeln('📖 ${widget.gospel.title}');
    shareText.writeln('📅 ${_formatDate(widget.gospel.date)}');
    shareText.writeln();

    shareText.writeln('═══ Evangelio ═══');
    shareText.writeln(widget.gospel.evangeliumText);
    shareText.writeln();

    if (_highlightedText.isNotEmpty) {
      shareText.writeln('✨ Pasaje Destacado:');
      shareText.writeln('"$_highlightedText"');
      shareText.writeln();
    }

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

  String _formatDate(DateTime date) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${date.day} de ${months[date.month - 1]}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        // Navigation Toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextSegmentToggle(
            segments: _tabLabels,
            initialIndex: _selectedIndex,
            onChanged: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
        ),
        
        Expanded(
          child: _buildCurrentContent(),
        ),
      ],
    );
  }

  Widget _buildCurrentContent() {
    final currentTab = _tabs[_selectedIndex];

    if (currentTab == '1ª Lectura') {
      return _buildReadingTab(widget.gospel.firstReading, widget.gospel.firstReadingReference);
    }
    if (currentTab == 'Salmo') {
      return _buildPsalmTab(widget.gospel.psalm, widget.gospel.psalmReference);
    }
    if (currentTab == '2ª Lectura') {
      return _buildReadingTab(widget.gospel.secondReading!, widget.gospel.secondReadingReference!);
    }
    if (currentTab == 'Evangelio') {
      return _buildGospelTab();
    }
    if (currentTab == 'Comentario') {
      return _buildCommentaryTab();
    }

    return const SizedBox.shrink();
  }

  Widget _buildHeader() {
    String dateStr = _formatDate(widget.gospel.date);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 44, 16, 0),
      color: AppTheme.primaryDarkBg,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.gospel.feast != null && widget.gospel.feast!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      widget.gospel.feast!.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.accentMint,
                        letterSpacing: 1.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                Text(
                  dateStr,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.sacredDark.withOpacity(0.7), // Fixed text color
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.share, color: AppTheme.accentMint, size: 20),
            onPressed: _shareReflection,
          ),
        ],
      ),
    );
  }

  // Helper for consistent card styling
  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: AppTheme.cardDark,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.sacredGold.withOpacity(0.3), width: 1), // Updated border color
    );
  }

  Widget _buildReadingTab(String text, String reference) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20), // Matched padding with others
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center, // Reference centered
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              reference,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.sacredDark, // Fixed text color
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(), // Added card decoration
            child: SelectableTextContent(
              text: TextFormatter.formatReadingText(text),
              textStyle: GoogleFonts.inter(
                fontSize: 16,
                height: 1.8,
                color: AppTheme.sacredDark.withOpacity(0.9), // Fixed text color
              ),
              onHighlight: (_) {},
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildPsalmTab(String text, String reference) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20), // Matched padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
           Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              reference,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.sacredDark, // Fixed text color
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(), // Added card decoration
            child: SelectableTextContent(
              text: TextFormatter.formatPsalm(text),
              textStyle: GoogleFonts.inter(
                fontSize: 16,
                height: 1.8,
                color: AppTheme.sacredDark.withOpacity(0.9), // Fixed text color
                fontStyle: FontStyle.italic,
              ),
              onHighlight: (_) {},
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildGospelTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Text(
              widget.gospel.title,
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.sacredDark, // Fixed text color
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: _cardDecoration(), // Updated to shared decoration
                  child: SelectableTextContent(
                    text: TextFormatter.formatReadingText(widget.gospel.evangeliumText),
                    textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, color: AppTheme.sacredDark.withOpacity(0.9), height: 1.8), // Fixed text color
                    onHighlight: (text) {
                      setState(() => _highlightedText = text);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pasaje destacado actualizado'), duration: Duration(milliseconds: 1500)));
                      _saveReflection();
                    },
                  ),
                ),
                
                 _buildReflectionInputSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(), // Updated to shared decoration
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(widget.gospel.commentTitle, style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.sacredDark)), // Fixed color
                 const SizedBox(height: 16),
                 SelectableTextContent(
                   text: widget.gospel.commentBody,
                   textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w400, color: AppTheme.sacredDark.withOpacity(0.9), height: 1.8), // Fixed color
                   onHighlight: (text) {
                     setState(() => _highlightedText = text);
                     NotificationService().scheduleFavoriteReminder(text, 20, 0);
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pasaje destacado actualizado y programado'), duration: Duration(milliseconds: 2000)));
                     _saveReflection();
                   },
                 ),
                 const SizedBox(height: 16),
                 Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text('— ${widget.gospel.commentAuthor}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.accentMint, fontStyle: FontStyle.italic)),
                     if (widget.gospel.commentSource.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(widget.gospel.commentSource, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.sacredDark.withOpacity(0.5)))), // Fixed color
                   ],
                 ),
               ],
             ),
           ),
           _buildReflectionInputSection(),
        ],
      ),
    );
  }

  Widget _buildReflectionInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         const SizedBox(height: 24),
         Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Text('Pasaje Destacado', style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.accentMint)),
                 if (_highlightedText.isNotEmpty) TextButton.icon(onPressed: () => setState(() => _highlightedText = ''), icon: const Icon(Icons.clear, size: 18), label: const Text('Limpiar'), style: TextButton.styleFrom(foregroundColor: AppTheme.sacredRed)),
               ],
             ),
             const SizedBox(height: 8),
             if (_highlightedText.isNotEmpty)
               Container(
                 padding: const EdgeInsets.all(12),
                 decoration: BoxDecoration(color: AppTheme.accentMint.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.accentMint.withOpacity(0.3))),
                 child: Text(_highlightedText, style: GoogleFonts.inter(fontSize: 14, color: AppTheme.sacredDark.withOpacity(0.9), fontStyle: FontStyle.italic)), // Fixed color
               )
             else
               Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text('Mantén presionado sobre el texto para destacar.', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.sacredDark.withOpacity(0.4), fontStyle: FontStyle.italic))), // Fixed color
           ],
         ),
         const SizedBox(height: 24),
         Text('¿Qué me dice Dios hoy?', style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.accentMint)),
         const SizedBox(height: 12),
         TextField(
           controller: _responseController,
           maxLines: 5,
           minLines: 3,
           style: GoogleFonts.inter(fontSize: 14, color: AppTheme.sacredDark), // Fixed color
           decoration: InputDecoration(
             hintText: 'Escribe tu reflexión personal...',
             hintStyle: GoogleFonts.inter(fontSize: 14, color: AppTheme.sacredDark.withOpacity(0.3)), // Fixed color
             filled: true,
             fillColor: AppTheme.cardDark,
             border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.sacredGold)),
             enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.sacredGold.withOpacity(0.3))),
             focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.accentMint, width: 2)),
             contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
           ),
         ),
         const SizedBox(height: 16),
         SizedBox(
           width: double.infinity,
           height: 48,
           child: ElevatedButton.icon(
             onPressed: _saveReflection,
             icon: const Icon(Icons.save),
             label: const Text('Guardar Reflexión', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
             style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentMint, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
           ),
         ),
         const SizedBox(height: 32),
         if (_selectedIndex == _tabs.indexOf('Evangelio') || _selectedIndex == _tabs.indexOf('Comentario')) // Only show history on main gospel-related tabs
            _buildMemoriaEspiritualSection(),
         const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildMemoriaEspiritualSection() {
    return FutureBuilder<List<PrayerEntry>>(
      future: _prayerRepository.getHistoryByGospel(widget.gospel.title),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.accentMint));
        } else if (snapshot.hasError) {
          return Text('Error al cargar reflexiones anteriores', style: GoogleFonts.inter(color: Colors.red));
        } else if (snapshot.data == null || snapshot.data!.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: _cardDecoration(), // Shared decoration
            child: Row(
              children: [
                const Icon(Icons.auto_stories, color: AppTheme.accentMint, size: 32),
                const SizedBox(width: 16),
                Expanded(child: Text('Esta es la primera vez que reflexionas sobre este evangelio. ¡Qué emocionante comenzar este camino espiritual!', style: GoogleFonts.inter(fontSize: 14, color: AppTheme.sacredDark.withOpacity(0.9), height: 1.6))), // Fixed color
              ],
            ),
          );
        } else {
          final entries = snapshot.data!;
          if (entries.length <= 1) {
             return Container(
                padding: const EdgeInsets.all(20),
                decoration: _cardDecoration(), // Shared decoration
                child: Row(
                  children: [
                    const Icon(Icons.auto_stories, color: AppTheme.accentMint, size: 32),
                    const SizedBox(width: 16),
                    Expanded(child: Text('Esta es la primera vez que reflexionas sobre este evangelio.', style: GoogleFonts.inter(fontSize: 14, color: AppTheme.sacredDark.withOpacity(0.9), height: 1.6))), // Fixed color
                  ],
                ),
              );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Memoria Espiritual', style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.sacredDark)), // Fixed color
              const SizedBox(height: 16),
              Column(
                children: entries.where((entry) => entry.id != entries.first.id).map((entry) {
                  final yearsAgo = _calculateYearsAgo(entry.date);
                  return TimelineCard(
                    timeLabel: yearsAgo,
                    date: _formatDate(entry.date),
                    passage: entry.gospelQuote,
                    summary: entry.reflection.length > 100 ? '${entry.reflection.substring(0, 100)}...' : entry.reflection,
                    fullReflection: entry.reflection,
                    wordCount: entry.reflection.split(' ').length,
                    isFirstReflection: false,
                  );
                }).toList(),
              ),
            ],
          );
        }
      },
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
