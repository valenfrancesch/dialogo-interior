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
import '../widgets/saved_highlights_widget.dart';
import '../services/notification_service.dart';
import '../services/cache_manager.dart';
import '../utils/text_formatter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as custom_auth;
import 'package:flutter/foundation.dart'; // For kIsWeb and defaultTargetPlatform
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_data.dart';
import 'auth_screen.dart';
import 'package:upgrader/upgrader.dart';
import '../widgets/kindle_clock.dart';
import '../providers/app_providers.dart';
import '../widgets/share_bottom_sheet.dart';

class ReadingScreen extends StatefulWidget {
  final GospelData? gospel;
  final DateTime? date;
  final String? gospelReference;

  const ReadingScreen({
    super.key,
    this.gospel,
    this.date,
    this.gospelReference,
  });

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
      _gospelFuture = GospelRepository.fetchGospelData(
        widget.date ?? DateTime.now(),
        reference: widget.gospelReference,
      );
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
              showBackButton: widget.gospel != null || widget.date != null,
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
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
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
                  color: AppTheme.sacredDark.withOpacity(
                    0.7,
                  ), // Fixed text color
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _gospelFuture = GospelRepository.fetchGospelData(
                      widget.date ?? DateTime.now(),
                      reference: widget.gospelReference,
                    );
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

class _SliverTabHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _SliverTabHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;
  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverTabHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}

class _ReadingContent extends StatefulWidget {
  final GospelData gospel;
  final bool showBackButton;

  const _ReadingContent({required this.gospel, this.showBackButton = false});

  @override
  State<_ReadingContent> createState() => _ReadingContentState();
}

class _ReadingContentState extends State<_ReadingContent>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0; // Index for the flattened list
  List<Highlight> _highlights = [];
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
  final ScrollController _scrollController = ScrollController();
  late PageController _pageController;
  late final Upgrader _upgrader;
  bool _isImmersiveMode = false;

  bool get _isGuest => !Provider.of<custom_auth.AuthProvider>(
    context,
    listen: false,
  ).isAuthenticated;

  void _showGuestBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Guarda tu diálogo interior ❤️',
              style: GoogleFonts.montserrat(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.sacredRed,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Empieza a construir tu diario espiritual. Crea una cuenta sin costo para registrar tus propósitos de cada día y mantener tus reflexiones siempre seguras contigo, vayas donde vayas.',
              style: GoogleFonts.inter(
                fontSize: 15,
                color: AppTheme.sacredDark.withOpacity(0.8),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const AuthScreen(initialLoginMode: false),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentMint,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Crear cuenta gratis',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const AuthScreen(initialLoginMode: true),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.accentMint),
                foregroundColor: AppTheme.accentMint,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Ya tengo cuenta',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Quizás más tarde',
                style: TextStyle(color: AppTheme.sacredDark.withOpacity(0.5)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _onHighlightSelected(
    String text,
    String source,
    String title, {
    bool scheduleReminder = false,
  }) {
    if (_isGuest) {
      _showGuestBottomSheet();
    } else {
      // Remove trailing newline if it exists
      if (text.endsWith('\n')) {
        text = text.replaceFirst(RegExp(r'\n+$'), '');
      }

      setState(() {
        _highlights.add(Highlight(text: text, source: source, title: title));
      });

      /* if (scheduleReminder) {
      NotificationService().scheduleFavoriteReminder(text, 20, 0);
    } */
      _saveReflection();
    }
  }

  @override
  void initState() {
    super.initState();
    _checkImmersiveMode();
    // Add focus listeners to save when unfocusing
    _reflectionFocusNode.addListener(_onReflectionFocusChanged);
    _purposeFocusNode.addListener(_onPurposeFocusChanged);

    // Add autocapitalization listeners
    _responseController.addListener(_handleAutocapitalizationReflection);
    _purposeController.addListener(_handleAutocapitalizationPurpose);

    _tabs = [];
    _tabLabels = [];

    // Dynamically add tabs that have real content
    if (widget.gospel.firstReading.isNotEmpty &&
        widget.gospel.firstReading != 'Lectura Histórica' &&
        widget.gospel.firstReading != 'No disponible') {
      _tabs.add('1ª Lectura');
      _tabLabels.add('1ª Lec');
    }

    if (widget.gospel.psalm.isNotEmpty &&
        widget.gospel.psalm != 'Lectura desde Historial' &&
        widget.gospel.psalm != 'No disponible') {
      _tabs.add('Salmo');
      _tabLabels.add('Salmo');
    }

    if (widget.gospel.secondReading != null &&
        widget.gospel.secondReading!.isNotEmpty &&
        widget.gospel.secondReading != 'No disponible') {
      _tabs.add('2ª Lectura');
      _tabLabels.add('2ª Lec');
    }

    if (widget.gospel.evangeliumText.isNotEmpty &&
        widget.gospel.evangeliumText != 'No disponible' &&
        !widget.gospel.evangeliumText.contains('Contenido no encontrado')) {
      _tabs.add('Evangelio');
      _tabLabels.add('Evangelio');
    }

    if (widget.gospel.commentBody.isNotEmpty &&
        widget.gospel.commentTitle != 'Reflexión histórica' &&
        widget.gospel.commentTitle != 'Reflexión Guardada' &&
        widget.gospel.commentBody != 'Reflexión disponible en evangelizo.org' &&
        widget.gospel.commentBody != 'No disponible') {
      _tabs.add('Comentario');
      _tabLabels.add('Comentario');
    }

    // Default to Gospel (index of 'Evangelio') or the first tab if Gospel isn't there (unlikely)
    _selectedIndex = _tabs.indexOf('Evangelio');
    if (_selectedIndex == -1 && _tabs.isNotEmpty) {
      _selectedIndex = 0;
    }

    if (_isGuest) {
      _historyFuture = Future.value([]);
    } else {
      // Cache spiritual flashback (history) until end of day
      final historyCacheKey = CacheKeys.forDate(
        CacheKeys.readingHistory,
        widget.gospel.date,
      );
      final cachedHistory = _cache.get<List<PrayerEntry>>(historyCacheKey);

      if (cachedHistory != null) {
        _historyFuture = Future.value(cachedHistory);
      } else {
        _historyFuture = _prayerRepository
            .getHistoryByGospel(widget.gospel.title)
            .then((history) {
              _cache.setUntilEndOfDay(historyCacheKey, history);
              return history;
            });
      }

      _loadSavedReflection();
    }

    _pageController = PageController(initialPage: _selectedIndex);
    _upgrader = Upgrader(
      durationUntilAlertAgain: const Duration(days: 2),
      messages: UpgraderMessages(code: 'es'),
    );
  }

  Future<void> _checkImmersiveMode() async {
    final prefs = await SharedPreferences.getInstance();
    final isImmersive = prefs.getBool('isImmersiveModeEnabled') ?? true;
    if (isImmersive) {
      _isImmersiveMode = true;
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      if (mounted) setState(() {});
    }
  }

  Future<void> _loadSavedReflection() async {
    // Try to get from cache first
    final reflectionCacheKey = CacheKeys.forDate(
      CacheKeys.readingReflection,
      widget.gospel.date,
    );
    final cachedReflection = _cache.get<PrayerEntry>(reflectionCacheKey);

    if (cachedReflection != null) {
      setState(() {
        _responseController.text = cachedReflection.reflection;
        _lastReflectionText = cachedReflection.reflection;
        _highlights = List.from(cachedReflection.highlights ?? []);
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
          _highlights = List.from(entry.highlights ?? []);
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
    if (_isImmersiveMode) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    _scrollController.dispose();
    _pageController.dispose();
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
    // Rebuild to show/hide floating check button
    setState(() {});
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
    // Rebuild to show/hide floating check button
    setState(() {});
  }

  void _handleAutocapitalizationReflection() {
    _handleAutocapitalization(_responseController);
  }

  void _handleAutocapitalizationPurpose() {
    _handleAutocapitalization(_purposeController);
  }

  void _handleAutocapitalization(TextEditingController controller) {
    String text = controller.text;
    int selectionIndex = controller.selection.baseOffset;

    // Pattern: . followed by space, then a lowercase letter
    // Match ". a" -> ". A"
    if (selectionIndex > 2 && text.length >= selectionIndex) {
      String segment = text.substring(0, selectionIndex);
      if (segment.endsWith(' ') && segment.length >= 3) {
        String beforeSpace = segment.substring(
          segment.length - 2,
          segment.length - 1,
        );
        String lastChar = segment.substring(
          segment.length - 1,
        ); // This is the space

        // We need to check if what was BEFORE the space was a punctuation mark
        if (RegExp(r'[.!?]').hasMatch(beforeSpace)) {
          // This doesn't help yet because the user hasn't typed the NEW letter.
          // We need to wait for the NEXT character.
        }
      }
    }

    // Better logic: if the text just changed and the last character is lowercase
    // and it follows a ". " pattern.
    if (selectionIndex > 0) {
      String segment = text.substring(0, selectionIndex);
      if (segment.length >= 3) {
        String lastChar = segment.substring(segment.length - 1);
        String punctSpace = segment.substring(
          segment.length - 3,
          segment.length - 1,
        );

        if (RegExp(r'[.!?] ').hasMatch(punctSpace) &&
            RegExp(r'[a-z]').hasMatch(lastChar)) {
          String newText =
              text.substring(0, selectionIndex - 1) +
              lastChar.toUpperCase() +
              text.substring(selectionIndex);

          controller.value = controller.value.copyWith(
            text: newText,
            selection: TextSelection.collapsed(offset: selectionIndex),
          );
        }
      }
    }
  }

  Future<void> _saveReflection() async {
    // No need to unfocus for autosave
    final reflectionText = _responseController.text.trim();
    final purposeText = _purposeController.text.trim();

    // Don't save if all three fields are empty
    if (reflectionText.isEmpty && _highlights.isEmpty && purposeText.isEmpty) {
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
        entryId =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      }

      final prayerEntry = PrayerEntry(
        id: entryId,
        userId: '1',
        date: widget.gospel.date,
        gospelQuote: widget.gospel.title,
        reflection: reflectionText,
        highlights: _highlights.isNotEmpty ? _highlights : null,
        purpose: purposeText.isNotEmpty ? purposeText : null,
      );

      await _prayerRepository.saveReflection(prayerEntry);

      // Update the history cache with the new entry
      final historyCacheKey = CacheKeys.forDate(
        CacheKeys.readingHistory,
        widget.gospel.date,
      );
      final reflectionCacheKey = CacheKeys.forDate(
        CacheKeys.readingReflection,
        widget.gospel.date,
      );

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

  void _shareReflection() {
    final availableLectures = <Lecture>[];

    if (widget.gospel.firstReading.isNotEmpty &&
        widget.gospel.firstReading != 'Lectura Histórica' &&
        widget.gospel.firstReading != 'No disponible') {
      availableLectures.add(
        Lecture(
          title: '1ª Lectura',
          content: TextFormatter.formatReadingText(widget.gospel.firstReading),
          reference: widget.gospel.firstReadingReference,
        ),
      );
    }
    if (widget.gospel.psalm.isNotEmpty &&
        widget.gospel.psalm != 'Lectura desde Historial' &&
        widget.gospel.psalm != 'No disponible') {
      availableLectures.add(
        Lecture(
          title: 'Salmo',
          content: TextFormatter.formatPsalm(widget.gospel.psalm),
          reference: widget.gospel.psalmReference,
        ),
      );
    }
    if (widget.gospel.secondReading != null &&
        widget.gospel.secondReading!.isNotEmpty &&
        widget.gospel.secondReading != 'No disponible') {
      availableLectures.add(
        Lecture(
          title: '2ª Lectura',
          content: TextFormatter.formatReadingText(
            widget.gospel.secondReading!,
          ),
          reference: widget.gospel.secondReadingReference,
        ),
      );
    }
    if (widget.gospel.evangeliumText.isNotEmpty &&
        widget.gospel.evangeliumText != 'No disponible' &&
        !widget.gospel.evangeliumText.contains('Contenido no encontrado')) {
      availableLectures.add(
        Lecture(
          title: 'Evangelio',
          content: TextFormatter.formatReadingText(
            widget.gospel.evangeliumText,
          ),
          reference: widget.gospel.title,
        ),
      );
    }
    if (widget.gospel.commentBody.isNotEmpty &&
        widget.gospel.commentTitle != 'Reflexión histórica' &&
        widget.gospel.commentTitle != 'Reflexión Guardada' &&
        widget.gospel.commentBody != 'Reflexión disponible en evangelizo.org' &&
        widget.gospel.commentBody != 'No disponible') {
      availableLectures.add(
        Lecture(
          title: 'Comentario',
          content: widget.gospel.commentBody,
          reference: widget.gospel.commentTitle,
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ShareBottomSheet(
        date: widget.gospel.date,
        availableLectures: availableLectures,
        highlights: _highlights,
        reflection: _responseController.text,
        purpose: _purposeController.text,
      ),
    );
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
      final dateKey =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      await HomeWidget.saveWidgetData<String>('widget_date', dateKey);

      // Sort highlights: Gospel ('Evangelio') first, then everything else
      final sortedHighlights = List<Highlight>.from(_highlights);
      sortedHighlights.sort((a, b) {
        if (a.source == 'Evangelio' && b.source != 'Evangelio') return -1;
        if (a.source != 'Evangelio' && b.source == 'Evangelio') return 1;
        return 0;
      });

      // Always save highlighted text (even if empty to clear previous value)
      final highlightToSave = sortedHighlights.isNotEmpty
          ? sortedHighlights.map((h) => '• ${h.text}').join('\n\n')
          : '¿Qué mensaje te dice Jesús hoy?\nAbre la app para leer el Evangelio';

      await HomeWidget.saveWidgetData<String>(
        'highlighted_text',
        highlightToSave,
      );

      // Always save purpose (even if empty to clear previous value)
      final purposeText = _purposeController.text.trim();
      await HomeWidget.saveWidgetData<String>('purpose', purposeText);

      // Update the widget
      await HomeWidget.updateWidget(
        name: 'DialogoWidgetProvider',
        androidName: 'DialogoWidgetProvider',
        iOSName: 'HomeWidgetProvider',
      );

      debugPrint(
        'Widget updated: date="$dateKey", highlights=${_highlights.length}, purpose="$purposeText"',
      );
    } catch (e) {
      debugPrint('Error saving to shared storage: $e');
    }
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

  Widget build(BuildContext context) {
    Provider.of<custom_auth.AuthProvider>(
      context,
    ); // Trigger rebuild on auth changes
    Provider.of<ReadingFontSizeProvider>(
      context,
    ); // Trigger rebuild on font size changes
    return SafeArea(
      top: true,
      bottom: false,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isImmersiveMode)
              Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                width: double.infinity,
                padding: const EdgeInsets.only(left: 16, top: 4),
                child: const KindleClock(),
              ),
            Expanded(
              child: NestedScrollView(
                controller: _scrollController,
                physics: const ClampingScrollPhysics(),
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverToBoxAdapter(child: _buildHeader()),
                    SliverToBoxAdapter(
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          cardColor: Theme.of(context).cardTheme.color,
                          cardTheme: const CardThemeData(elevation: 2),
                          textTheme: Theme.of(context).textTheme.copyWith(
                            titleMedium: GoogleFonts.inter(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                            bodyMedium: GoogleFonts.inter(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.8),
                            ),
                          ),
                          elevatedButtonTheme: ElevatedButtonThemeData(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.sacredRed,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        child: UpgradeCard(
                          upgrader: _upgrader,
                          margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          showReleaseNotes: false,
                          showIgnore: false,
                        ),
                      ),
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _SliverTabHeaderDelegate(
                        minHeight: 66,
                        maxHeight: 66,
                        child: Container(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: TextSegmentToggle(
                            segments: _tabLabels,
                            initialIndex: _selectedIndex,
                            onChanged: (index) {
                              FocusScope.of(context).unfocus();
                              _saveReflection();
                              setState(() {
                                _selectedIndex = index;
                              });
                              _pageController.animateToPage(
                                index,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ];
                },
                body: PageView.builder(
                  controller: _pageController,
                  itemCount: _tabs.length,
                  onPageChanged: (index) {
                    FocusScope.of(context).unfocus();
                    _saveReflection();
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return SingleChildScrollView(
                      primary: true,
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                      child: _buildContentForIndex(index),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentForIndex(int index) {
    final currentTab = _tabs[index];
    Widget readingContent;

    if (currentTab == '1ª Lectura') {
      readingContent = _buildReadingTab(
        widget.gospel.firstReading,
        widget.gospel.firstReadingReference,
        widget.gospel.firstReadingLongTitle,
      );
    } else if (currentTab == 'Salmo') {
      readingContent = _buildPsalmTab(
        widget.gospel.psalm,
        widget.gospel.psalmReference,
        widget.gospel.psalmLongTitle,
      );
    } else if (currentTab == '2ª Lectura') {
      readingContent = _buildReadingTab(
        widget.gospel.secondReading!,
        widget.gospel.secondReadingReference!,
        widget.gospel.secondReadingLongTitle,
      );
    } else if (currentTab == 'Evangelio') {
      readingContent = _buildGospelTab();
    } else if (currentTab == 'Comentario') {
      readingContent = _buildCommentaryTab();
    } else {
      readingContent = const SizedBox.shrink();
    }

    return Column(
      key: ValueKey(index),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [readingContent, _buildReflectionInputSection()],
    );
  }

  Widget _buildHeader() {
    String dateStr = _formatDate(widget.gospel.date);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Branding Header (Logo + Title)
          Row(
            children: [
              Image.asset('assets/images/logo.png', height: 32, width: 32),
              const SizedBox(width: 12),
              Text(
                'Diálogo interior',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.sacredDark
                      : AppTheme.sacredRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (widget.showBackButton)
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    color: AppTheme.accentMint,
                    size: 20,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              if (widget.showBackButton) const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPrepareHeartButton(),
                    if (widget.gospel.feast != null &&
                        widget.gospel.feast!.isNotEmpty)
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
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.ios_share,
                  color: AppTheme.accentMint,
                  size: 20,
                ),
                onPressed: _shareReflection,
              ),
            ],
          ),
        ],
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                  "Hacé silencio:",
                  "Acallá los ruidos de fuera, pero sobre todo los pensamientos de dentro.",
                ),
                const SizedBox(height: 16),
                _buildRecommendationItem(
                  "🔕",
                  "Desconectate:",
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
                    border: Border.all(
                      color: AppTheme.sacredGold.withOpacity(0.3),
                    ),
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

  Widget _buildRecommendationItem(
    String icon,
    String title,
    String description,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
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
      boxShadow: [
        BoxShadow(
          color: AppTheme.sacredDark.withOpacity(0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _buildReadingTab(String text, String reference, [String? longTitle]) {
    const String sourceString =
        'Extraído de la Biblia: Libro del Pueblo de Dios';
    final bool hasSource = text.contains(sourceString);
    final String cleanText = text.replaceFirst(sourceString, '').trim();
    final String source = _tabs[_selectedIndex];

    final double readingFontSize = Provider.of<ReadingFontSizeProvider>(
      context,
      listen: false,
    ).fontSize;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                longTitle ?? reference,
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.sacredDark,
                ),
              ),
              const SizedBox(height: 16),
              SelectableTextContent(
                text: TextFormatter.formatReadingText(cleanText),
                textStyle: GoogleFonts.inter(
                  fontSize: readingFontSize,
                  height: 1.8,
                  color: AppTheme.sacredDark.withOpacity(0.9),
                ),
                highlightedTexts: _highlights
                    .where((h) => h.source == source)
                    .map((h) => h.text)
                    .toList(),
                onHighlight: (text) =>
                    _onHighlightSelected(text, source, reference),
              ),
              if (hasSource) ...[
                const SizedBox(height: 16),
                Text(
                  sourceString,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppTheme.sacredDark.withOpacity(0.4),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildPsalmTab(String text, String reference, [String? longTitle]) {
    const String sourceString =
        'Extraído de la Biblia: Libro del Pueblo de Dios';
    final bool hasSource = text.contains(sourceString);
    final String cleanText = text.replaceFirst(sourceString, '').trim();
    final String source = _tabs[_selectedIndex];

    final double readingFontSize = Provider.of<ReadingFontSizeProvider>(
      context,
      listen: false,
    ).fontSize;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                longTitle ?? reference,
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.sacredDark,
                ),
              ),
              const SizedBox(height: 16),
              SelectableTextContent(
                text: TextFormatter.formatPsalm(cleanText),
                textStyle: GoogleFonts.inter(
                  fontSize: readingFontSize,
                  height: 1.8,
                  color: AppTheme.sacredDark.withOpacity(0.9),
                  fontStyle: FontStyle.italic,
                ),
                highlightedTexts: _highlights
                    .where((h) => h.source == source)
                    .map((h) => h.text)
                    .toList(),
                onHighlight: (text) =>
                    _onHighlightSelected(text, source, reference),
              ),
              if (hasSource) ...[
                const SizedBox(height: 16),
                Text(
                  sourceString,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppTheme.sacredDark.withOpacity(0.4),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildGospelTab() {
    const String sourceString =
        'Extraído de la Biblia: Libro del Pueblo de Dios';
    final String text = widget.gospel.evangeliumText;
    final bool hasSource = text.contains(sourceString);
    final String cleanText = text.replaceFirst(sourceString, '').trim();
    final String source = _tabs[_selectedIndex];

    final double readingFontSize = Provider.of<ReadingFontSizeProvider>(
      context,
      listen: false,
    ).fontSize;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.gospel.gospelLongTitle ?? widget.gospel.title,
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.sacredDark,
                ),
              ),
              const SizedBox(height: 16),
              SelectableTextContent(
                text: TextFormatter.formatReadingText(cleanText),
                textStyle: GoogleFonts.inter(
                  fontSize: readingFontSize,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.sacredDark.withOpacity(0.9),
                  height: 1.8,
                ),
                highlightedTexts: _highlights
                    .where((h) => h.source == source)
                    .map((h) => h.text)
                    .toList(),
                onHighlight: (text) =>
                    _onHighlightSelected(text, source, widget.gospel.title),
              ),
              if (hasSource) ...[
                const SizedBox(height: 16),
                Text(
                  sourceString,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppTheme.sacredDark.withOpacity(0.4),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommentaryTab() {
    final String source = _tabs[_selectedIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(), // Updated to shared decoration
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.gospel.commentTitle,
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.sacredDark,
                ),
              ), // Fixed color
              const SizedBox(height: 16),
              SelectableTextContent(
                text: widget.gospel.commentBody,
                textStyle: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.sacredDark.withOpacity(0.9),
                  height: 1.8,
                ), // Fixed color
                highlightedTexts: _highlights
                    .where((h) => h.source == source)
                    .map((h) => h.text)
                    .toList(),
                onHighlight: (text) => _onHighlightSelected(
                  text,
                  source,
                  widget.gospel.commentTitle,
                  scheduleReminder: true,
                ),
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '— ${widget.gospel.commentAuthor}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.accentMint,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  if (widget.gospel.commentSource.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        widget.gospel.commentSource,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.sacredDark.withOpacity(0.5),
                        ),
                      ),
                    ), // Fixed color
                ],
              ),
            ],
          ),
        ),
      ],
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
                Text(
                  'Luces de hoy',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.accentMint,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_highlights.isNotEmpty)
              SavedHighlightsWidget(
                highlights: _highlights,
                onDelete: (highlight) {
                  setState(() {
                    _highlights.remove(highlight);
                  });
                  _saveReflection();
                },
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
            ), // Fixed color
          ],
        ),
        const SizedBox(height: 24),
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
            _buildSaveStatusIndicator(),
          ],
        ),
        const SizedBox(height: 12),
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            TextField(
              controller: _responseController,
              focusNode: _reflectionFocusNode,
              maxLines: null,
              minLines: 3,
              keyboardType: TextInputType.multiline,
              readOnly: _isGuest,
              onTap: _isGuest ? _showGuestBottomSheet : null,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.sacredDark,
              ),
              decoration: InputDecoration(
                hintText: 'Escribe tu reflexión personal...',
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
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppTheme.accentMint,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.fromLTRB(
                  16,
                  12,
                  48,
                  12,
                ), // Extra right padding for the button
              ),
            ),
            if (_reflectionFocusNode.hasFocus && !_isGuest)
              Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 8),
                child: IconButton(
                  onPressed: () {
                    _reflectionFocusNode.unfocus();
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

        // Sección de Propósito
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
          alignment: Alignment.centerRight,
          children: [
            TextField(
              controller: _purposeController,
              focusNode: _purposeFocusNode,
              readOnly: _isGuest,
              onTap: _isGuest ? _showGuestBottomSheet : null,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.sacredDark,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
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
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppTheme.accentMint,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.fromLTRB(
                  16,
                  14,
                  48,
                  14,
                ), // Extra right padding for the button
                prefixIcon: const Icon(Icons.stars, color: AppTheme.accentMint),
              ),
              maxLines: null,
              minLines: 1,
              keyboardType: TextInputType.multiline,
            ),
            if (_purposeFocusNode.hasFocus && !_isGuest)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  onPressed: () {
                    _purposeFocusNode.unfocus();
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
        const SizedBox(height: 32),
        _buildMemoriaEspiritualSection(),
        const SizedBox(height: 32),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSaveStatusIndicator() {
    switch (_saveStatus) {
      case 'saving':
        return const Icon(Icons.sync, color: AppTheme.sacredGold, size: 20);
      case 'saved':
        return const Icon(
          Icons.cloud_done,
          color: AppTheme.sacredGold,
          size: 20,
        );
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
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.accentMint),
          );
        } else if (snapshot.hasError) {
          return Text(
            'Error al cargar reflexiones anteriores',
            style: GoogleFonts.inter(color: Colors.red),
          );
        } else if (snapshot.data == null || snapshot.data!.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: _cardDecoration().copyWith(
              color: const Color(0xFFEBE8E3),
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
                    'Esta es la primera vez que reflexionas sobre este evangelio. ¡Qué emocionante comenzar este camino espiritual!',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.sacredDark.withOpacity(0.9),
                      height: 1.6,
                    ),
                  ),
                ), // Fixed color
              ],
            ),
          );
        } else {
          final entries = snapshot.data!;
          if (entries.length <= 1) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: _cardDecoration().copyWith(
                color: const Color(0xFFEBE8E3),
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
                      'Esta es la primera vez que reflexionas sobre este evangelio.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppTheme.sacredDark.withOpacity(0.9),
                        height: 1.6,
                      ),
                    ),
                  ), // Fixed color
                ],
              ),
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
              ), // Fixed color
              const SizedBox(height: 16),
              Column(
                children: entries
                    .where((entry) => entry.id != entries.first.id)
                    .map<Widget>((entry) {
                      final yearsAgo = _calculateYearsAgo(entry.date);
                      return TimelineCard(
                        timeLabel: yearsAgo,
                        date: _formatDate(entry.date),
                        passage: entry.gospelQuote,
                        fullReflection: entry.reflection,
                        highlights: entry.highlights,
                        purpose: entry.purpose,
                        isFirstReflection: false,
                      );
                    })
                    .toList(),
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
