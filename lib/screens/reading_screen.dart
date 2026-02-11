import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:home_widget/home_widget.dart';
import '../theme/app_theme.dart';
import '../widgets/text_segment_toggle.dart';
import '../widgets/selectable_text_content.dart';
import '../widgets/timeline_card.dart';
import '../models/gospel_data.dart';
import '../models/prayer_entry.dart';
import '../repositories/gospel_repository.dart';
import '../repositories/prayer_repository.dart';
import '../services/notification_service.dart';
import '../services/cache_manager.dart';
import '../utils/text_formatter.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb and defaultTargetPlatform
import '../constants/app_data.dart';

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
            return _ReadingContent(
              gospel: snapshot.data!,
              showBackButton: widget.gospel != null,
            );
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
  final bool showBackButton;

  const _ReadingContent({
    required this.gospel,
    this.showBackButton = false,
  });

  @override
  State<_ReadingContent> createState() => _ReadingContentState();
}

class _ReadingContentState extends State<_ReadingContent> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0; // Index for the flattened list
  String _highlightedText = '';
  final TextEditingController _responseController = TextEditingController();
  final TextEditingController _purposeController = TextEditingController();
  final PrayerRepository _prayerRepository = PrayerRepository();
  final CacheManager _cache = CacheManager();
  late List<String> _tabs;
  late List<String> _tabLabels; // For the toggle display
  String _saveStatus = 'saved'; // 'saved', 'saving', 'error'
  String _lastReflectionText = '';
  String _lastPurposeText = '';
  late Future<List<PrayerEntry>> _historyFuture;
  final FocusNode _reflectionFocusNode = FocusNode();
  final FocusNode _purposeFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Add focus listeners to save when unfocusing
    _reflectionFocusNode.addListener(_onReflectionFocusChanged);
    _purposeFocusNode.addListener(_onPurposeFocusChanged);
    
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
    
    // Cache spiritual flashback (history) until end of day
    final historyCacheKey = CacheKeys.forDate(CacheKeys.readingHistory, widget.gospel.date);
    final cachedHistory = _cache.get<List<PrayerEntry>>(historyCacheKey);
    
    if (cachedHistory != null) {
      _historyFuture = Future.value(cachedHistory);
    } else {
      _historyFuture = _prayerRepository.getHistoryByGospel(widget.gospel.title).then((history) {
        _cache.setUntilEndOfDay(historyCacheKey, history);
        return history;
      });
    }
    
    _loadSavedReflection();
  }

  Future<void> _loadSavedReflection() async {
    // Try to get from cache first
    final reflectionCacheKey = CacheKeys.forDate(CacheKeys.readingReflection, widget.gospel.date);
    final cachedReflection = _cache.get<PrayerEntry>(reflectionCacheKey);
    
    if (cachedReflection != null) {
      setState(() {
        _responseController.text = cachedReflection.reflection;
        _lastReflectionText = cachedReflection.reflection;
        _highlightedText = cachedReflection.highlightedText ?? '';
        _purposeController.text = cachedReflection.purpose ?? '';
        _lastPurposeText = cachedReflection.purpose ?? '';
      });
      return;
    }
    
    // No cache, use the already-fetched history from _historyFuture
    try {
      final savedEntries = await _historyFuture;
      if (savedEntries.isNotEmpty && mounted) {
        final entry = savedEntries.first;
        
        // Cache until end of day
        _cache.setUntilEndOfDay(reflectionCacheKey, entry);
        
        setState(() {
          _responseController.text = entry.reflection;
          _lastReflectionText = entry.reflection; // Initialize last text
          _highlightedText = entry.highlightedText ?? '';
          _purposeController.text = entry.purpose ?? '';
          _lastPurposeText = entry.purpose ?? ''; // Initialize last text
        });
      }
    } catch (e) {
      print('Error loading reflection: $e');
    }
  }

  @override
  void dispose() {
    _reflectionFocusNode.dispose();
    _purposeFocusNode.dispose();
    _responseController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  void _onReflectionFocusChanged() {
    // Save when reflection field loses focus
    if (!_reflectionFocusNode.hasFocus) {
      final reflectionText = _responseController.text;
      if (reflectionText != _lastReflectionText) {
        _lastReflectionText = reflectionText;
        _saveReflection();
      }
    }
  }

  void _onPurposeFocusChanged() {
    // Save when purpose field loses focus
    if (!_purposeFocusNode.hasFocus) {
      final purposeText = _purposeController.text;
      if (purposeText != _lastPurposeText) {
        _lastPurposeText = purposeText;
        _saveReflection();
      }
    }
  }

  Future<void> _saveReflection() async {
    // No need to unfocus for autosave
    final reflectionText = _responseController.text.trim();
    final purposeText = _purposeController.text.trim();
    final highlightedText = _highlightedText.trim();

    // Don't save if all three fields are empty
    if (reflectionText.isEmpty && highlightedText.isEmpty && purposeText.isEmpty) {
      setState(() => _saveStatus = '');
      return;
    }

    try {
      setState(() => _saveStatus = 'saving');
      
      // Use cached history instead of fetching again
      final existingEntries = await _historyFuture;
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
        highlightedText: highlightedText.isNotEmpty ? highlightedText : null,
        purpose: purposeText.isNotEmpty ? purposeText : null,
      );

      await _prayerRepository.saveReflection(prayerEntry);

      // Update the history cache with the new entry
      final historyCacheKey = CacheKeys.forDate(CacheKeys.readingHistory, widget.gospel.date);
      final reflectionCacheKey = CacheKeys.forDate(CacheKeys.readingReflection, widget.gospel.date);
      
      // Update both caches
      _cache.setUntilEndOfDay(reflectionCacheKey, prayerEntry);
      
      // Update history cache - replace or add the entry
      final updatedHistory = existingEntries.isEmpty 
          ? [prayerEntry]
          : [prayerEntry, ...existingEntries.skip(1)];
      _cache.setUntilEndOfDay(historyCacheKey, updatedHistory);
      
      // Update the future so subsequent calls use the updated data
      _historyFuture = Future.value(updatedHistory);
      
      // Also invalidate library cache so it shows fresh data
      _cache.invalidateLibrary();

        setState(() => _saveStatus = 'saved');
        await _saveToSharedStorage();
    } catch (e) {
      if (mounted) {
        setState(() => _saveStatus = 'error');
        print('Error al guardar: $e');
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
      shareText.writeln('✨ Luz de hoy:');
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
    shareText.writeln('Compartido desde Diálogo Interior');

    try {
      await Share.share(shareText.toString());
    } catch (e) {
      if (mounted) {
        await Clipboard.setData(ClipboardData(text: shareText.toString()));
        if (mounted) {
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
  }

  Future<void> _saveToSharedStorage() async {
    // home_widget is not supported on Web
    if (kIsWeb) return;

    try {
      // Configure App Group for iOS
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await HomeWidget.setAppGroupId(AppData.appGroupId);
      }
 
      // Save the current date to track when data was last updated
      final today = DateTime.now();
      final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      await HomeWidget.saveWidgetData<String>('widget_date', dateKey);
      
      // Always save highlighted text (even if empty to clear previous value)
      await HomeWidget.saveWidgetData<String>(
        'highlighted_text', 
        _highlightedText.isNotEmpty ? _highlightedText : 'Abre la app para leer hoy'
      );
      
      // Always save purpose (even if empty to clear previous value)
      final purposeText = _purposeController.text.trim();
      await HomeWidget.saveWidgetData<String>(
        'purpose', 
        purposeText.isNotEmpty ? purposeText : ''
      );
      
      // Update the widget
      await HomeWidget.updateWidget(
        name: 'DialogoWidgetProvider', 
        androidName: 'DialogoWidgetProvider',
        iOSName: 'HomeWidgetProvider'
      );
      
      debugPrint('Widget updated: date="$dateKey", highlight="${_highlightedText}", purpose="$purposeText"');
    } catch (e) {
      debugPrint('Error saving to shared storage: $e');
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
    return SafeArea(
      top: true,
      bottom: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      color: AppTheme.primaryDarkBg,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (widget.showBackButton)
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: AppTheme.accentMint, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
          if (widget.showBackButton)
            const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPrepareHeartButton(),
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
    ),
  );
  }

  Widget _buildPrepareHeartButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: GestureDetector(
        onTap: _showPrepareHeartModal,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.accentMint.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(20),
            color: AppTheme.accentMint.withOpacity(0.05),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.favorite_outline, // Or CupertinoIcons.heart
                size: 16,
                color: AppTheme.accentMint,
              ),
              const SizedBox(width: 8),
              Text(
                "Preparar el corazón",
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.accentMint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrepareHeartModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.primaryDarkBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              // 1. Título
              Text(
                "Antes de empezar...",
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.sacredDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // 2. Recomendaciones
                _buildRecommendationItem(
                  "🤫",
                  "Haz silencio:",
                  "Acalla los ruidos de fuera, pero sobre todo los pensamientos de dentro.",
                ),
                const SizedBox(height: 16),
                _buildRecommendationItem(
                  "🔕",
                  "Desconéctate:",
                  "Para una mejor experiencia, te sugerimos silenciar las notificaciones durante este momento.",
                ),
              const SizedBox(height: 16),
              _buildRecommendationItem(
                "👣",
                "Detente:",
                "No leas con prisa. No es información, es una carta de amor para vos.",
              ),
              const SizedBox(height: 16),
              _buildRecommendationItem(
                "🙏",
                "Pide luz:",
                "La mente comprende, pero solo el Espíritu hace arder el corazón.",
              ),
              const SizedBox(height: 32),

              // 3. La Transición
              Text(
                "Nos ponemos en presencia del Señor e invocamos al Espíritu Santo:",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.sacredDark.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // 4. La Oración
              Container(
                padding: const EdgeInsets.all(20),
                decoration: _cardDecoration().copyWith(
                  color: AppTheme.sacredGold.withOpacity(0.1),
                  border: Border.all(color: AppTheme.sacredGold.withOpacity(0.3)),
                ),
                child: Text(
                  "Ven, Espíritu Santo, llena los corazones de tus fieles, y enciende en ellos el fuego de tu amor.\n\nEnvía tu Espíritu Creador y renueva la faz de la tierra.\n\nOh Dios, que has iluminado los corazones de tus hijos con la luz del Espíritu Santo; haznos dóciles a sus inspiraciones para gustar siempre el bien y gozar de su consuelo.\n\nPor Cristo nuestro Señor. Amén.",
                  style: GoogleFonts.merriweather(
                    fontSize: 14,
                    height: 1.6,
                    fontStyle: FontStyle.italic,
                    color: AppTheme.sacredDark.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),

              // 5. Botón de cierre
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentMint,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  "Estoy listo/a",
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16), // Bottom safe area spacer
            ],
          ),
        ),
      );
      },
    );
  }

  Widget _buildRecommendationItem(String icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          icon,
          style: const TextStyle(fontSize: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.5,
                color: AppTheme.sacredDark,
              ),
              children: [
                TextSpan(
                  text: "$title ",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: description,
                  style: TextStyle(color: AppTheme.sacredDark.withOpacity(0.8)),
                ),
              ],
            ),
          ),
        ),
      ],
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
    return GestureDetector(
      onTap: () {
        // Unfocus any active text field when tapping outside
        FocusScope.of(context).unfocus();
      },
      child: SingleChildScrollView(
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
                      highlightedText: _highlightedText,
                      onHighlight: (text) {
                        setState(() => _highlightedText = text);
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
                   highlightedText: _highlightedText,
                   onHighlight: (text) {
                     setState(() => _highlightedText = text);
                     NotificationService().scheduleFavoriteReminder(text, 20, 0);
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
                 Text('Luz de hoy', style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.accentMint)),
                 if (_highlightedText.isNotEmpty) TextButton.icon(onPressed: () => setState(() => _highlightedText = ''), icon: const Icon(Icons.clear, size: 18), label: const Text('Limpiar'), style: TextButton.styleFrom(foregroundColor: AppTheme.sacredRed)),
               ],
             ),
             const SizedBox(height: 8),
             if (_highlightedText.isNotEmpty)
               Container(
                 padding: const EdgeInsets.all(16),
                 decoration: BoxDecoration(
                   color: AppTheme.sacredGold.withOpacity(0.15),
                   borderRadius: BorderRadius.circular(12),
                   border: Border(left: BorderSide(color: AppTheme.sacredGold, width: 4)),
                 ),
                 child: Text(
                   '"$_highlightedText"',
                   style: GoogleFonts.merriweather(
                     fontStyle: FontStyle.italic,
                     fontSize: 14,
                     color: AppTheme.sacredDark.withOpacity(0.8),
                   ),
                 ),
               )
             else
               Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text('Mantén presionado sobre el texto para destacar.', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.sacredDark.withOpacity(0.4), fontStyle: FontStyle.italic))), // Fixed color
           ],
         ),
         const SizedBox(height: 24),
         Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('¿Qué me dice Dios hoy?', style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.accentMint)),
              _buildSaveStatusIndicator(),
            ],
         ),
         const SizedBox(height: 12),
         TextField(
           controller: _responseController,
           focusNode: _reflectionFocusNode,
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
         /* Saved Button Removed for Autosave */
         const SizedBox(height: 16),

          // Sección de Propósito
          Text(
            'Propósito del día',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.sacredGold,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _purposeController,
            focusNode: _purposeFocusNode,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.sacredDark,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'Escribe un propósito concreto...',
              hintStyle: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.sacredDark.withOpacity(0.4),
                fontStyle: FontStyle.italic,
              ),
              filled: true,
              fillColor: AppTheme.sacredGold.withOpacity(0.1),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.sacredGold)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.sacredGold.withOpacity(0.3))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.accentMint, width: 2)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              prefixIcon: const Icon(Icons.stars, color: AppTheme.sacredGold),
            ),
            maxLines: 2,
            minLines: 1,
          ),
          const SizedBox(height: 32),

         if (_selectedIndex == _tabs.indexOf('Evangelio') || _selectedIndex == _tabs.indexOf('Comentario')) // Only show history on main gospel-related tabs
            _buildMemoriaEspiritualSection(),
         const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSaveStatusIndicator() {
    switch (_saveStatus) {
      case 'saving':
        return const Icon(Icons.sync, color: AppTheme.accentMint, size: 20);
      case 'saved':
        return const Icon(Icons.cloud_done, color: AppTheme.accentMint, size: 20);
      case 'error':
        return const Icon(Icons.cloud_off, color: Colors.red, size: 20);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildMemoriaEspiritualSection() {
    return FutureBuilder<List<PrayerEntry>>(
      future: _historyFuture, // Use cached future
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
                    fullReflection: entry.reflection,
                    highlightedText: entry.highlightedText,
                    purpose: entry.purpose,
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
