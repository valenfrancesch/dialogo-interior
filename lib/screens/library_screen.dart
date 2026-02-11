import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../widgets/statistics_card.dart';
import '../widgets/diary_entry_card.dart';
import '../widgets/calendar_day.dart';
import '../repositories/gospel_repository.dart';
import '../repositories/prayer_repository.dart';
import '../services/library_statistics_service.dart';
import '../services/cache_manager.dart';
import '../models/library_statistics.dart';
import '../models/prayer_entry.dart';
import 'reading_screen.dart';
import '../widgets/gospel_button.dart';
import '../services/bible_service.dart';
import '../models/gospel_data.dart';
import 'gospel_reflections_screen.dart';

import '../widgets/global_error_widget.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final PrayerRepository _prayerRepository = PrayerRepository();
  late final LibraryStatisticsService _statisticsService;
  final CacheManager _cache = CacheManager();
  
  DateTime _displayedMonth = DateTime.now();
  
  // State for fetched data
  List<PrayerEntry> _allEntries = [];
  List<int> _daysWithEntries = [];
  bool _isLoading = true;
  bool _hasError = false; // Add error state
  
  // Pagination state
  DocumentSnapshot<Map<String, dynamic>>? _lastDocument;
  bool _hasMoreData = true;
  bool _isLoadingMore = false;

  // Cached futures to prevent reloading on setState
  late Future<List<dynamic>> _statsFuture;

  final GlobalKey _diarySectionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _statisticsService = LibraryStatisticsService(
      prayerRepository: _prayerRepository,
    );
    _initFutures();
    _loadInitialData();
  }

  void _initFutures() {
    // Try to get stats from cache first
    final cachedStats = _cache.get<List<dynamic>>(CacheKeys.libraryStats);
    
    if (cachedStats != null) {
      _statsFuture = Future.value(cachedStats);
    } else {
      _statsFuture = Future.wait([
        _statisticsService.calculateCurrentStreak(),
        _statisticsService.calculateReflectionCount(),
      ]).then((stats) {
        _cache.setUntilEndOfDay(CacheKeys.libraryStats, stats);
        return stats;
      });
    }
  }

  void _refreshStats() {
    // Invalidate cache and reload
    _cache.invalidate(CacheKeys.libraryStats);
    setState(() {
      _statsFuture = Future.wait([
        _statisticsService.calculateCurrentStreak(),
        _statisticsService.calculateReflectionCount(),
      ]).then((stats) {
        _cache.setUntilEndOfDay(CacheKeys.libraryStats, stats);
        return stats;
      });
    });
  }


  Future<void> _loadInitialData() async {
    // Try to get reflections from cache first
    final cachedReflections = _cache.get<List<PrayerEntry>>(CacheKeys.libraryReflections);
    final cachedDays = _cache.get<List<int>>(CacheKeys.libraryCalendar);
    
    if (cachedReflections != null && cachedDays != null) {
      // Use cached data
      setState(() {
        _allEntries = cachedReflections;
        _daysWithEntries = cachedDays;
        _hasMoreData = cachedReflections.length == 10;
        _isLoading = false;
        _hasError = false;
      });
      
      if (cachedReflections.isNotEmpty) {
        _fetchLastDocumentSnapshot();
      }
      return;
    }
    
    // No cache, fetch from Firebase
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Fetch first page of reflections (10 items) using repository method
      final entries = await _prayerRepository.getUserReflections(limit: 10);
      
      // Refresh stats to ensure they are up to date with potentially new entries
      _refreshStats();
      
      // Load calendar days for current month
      final days = await _prayerRepository.getDaysWithEntries(
        _displayedMonth.year, 
        _displayedMonth.month
      );

      // Cache the data until end of day
      _cache.setUntilEndOfDay(CacheKeys.libraryReflections, entries);
      _cache.setUntilEndOfDay(CacheKeys.libraryCalendar, days);

      if (mounted) {
        setState(() {
          _allEntries = entries;
          // Store last document for pagination - we'll need to fetch it separately
          _hasMoreData = entries.length == 10;
          _daysWithEntries = days;
          _isLoading = false;
        });
        
        // Fetch the last document snapshot for pagination
        if (entries.isNotEmpty) {
          _fetchLastDocumentSnapshot();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
        debugPrint('Error loading initial data: $e');
      }
    }
  }

  Future<void> _fetchLastDocumentSnapshot() async {
    if (_allEntries.isEmpty) return;
    
    try {
      final lastEntry = _allEntries.last;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('entries')
          .doc(lastEntry.id)
          .get();
      
      if (mounted) {
        setState(() {
          _lastDocument = doc;
        });
      }
    } catch (e) {
      // Silently fail - pagination won't work but app continues
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoadingMore || !_hasMoreData || _lastDocument == null) return;
    
    setState(() => _isLoadingMore = true);
    
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('entries')
          .orderBy('date', descending: true)
          .startAfterDocument(_lastDocument!)
          .limit(10)
          .get();
      
      final newEntries = snapshot.docs
          .map((doc) => PrayerEntry.fromFirestore(doc))
          .toList();
      
      if (mounted) {
        setState(() {
          _allEntries.addAll(newEntries);
          _lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : _lastDocument;
          _hasMoreData = snapshot.docs.length == 10;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cargar más reflexiones')),
        );
      }
    }
  }

  Future<void> _updateCalendarDays() async {
    try {
      final days = await _prayerRepository.getDaysWithEntries(
        _displayedMonth.year,
        _displayedMonth.month,
      );
      if (mounted) {
        setState(() {
          _daysWithEntries = days;
        });
      }
    } catch (e) {
      debugPrint('Error updating calendar: $e');
    }
  }

  void _changeMonth(int increment) {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + increment,
      );
    });
    _updateCalendarDays();
  }



  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.sacredCream, // Updated background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Icon(Icons.auto_stories, color: AppTheme.accentMint, size: 28),
        title: Text(
          'Biblioteca de Fe',
          style: GoogleFonts.montserrat(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.sacredRed, // Updated title color
          ),
        ),
      ),
      body: _hasError && _allEntries.isEmpty 
        ? GlobalErrorWidget(
            onRetry: _loadInitialData,
            message: 'No pudimos cargar tu biblioteca. Por favor, verifica tu conexión.',
          )
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [


                // 1. LOS SANTOS EVANGELIOS
                _buildGospelsSection(context),
                const SizedBox(height: 32),

                // 2. SECCIÓN DE CONSISTENCIA Y MEMORIA LITÚRGICA
                _buildConsistencyHeader(),
                const SizedBox(height: 12),
                _buildStatisticsCards(),
                const SizedBox(height: 24),



                // 3. CALENDARIO DE MEMORIA LITÚRGICA
                _buildCalendarSection(),
                const SizedBox(height: 24),

                // 4. MIS ETIQUETAS
                //_buildTagsSection(),
                // const SizedBox(height: 24),
                

                // 5. DIARIO Y REFLEXIONES
                _buildDiarySection(),
                const SizedBox(height: 100),
              ],
            ),
          ),
    );
  }

  // ===== WIDGETS PRIVADOS =====

  Widget _buildGospelsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tus reflexiones sobre los Santos Evangelios',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.sacredDark, // Updated text color
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: GospelButton(
                title: 'Mateo',

                // icon: Icons.person, 
                color: AppTheme.sacredRed,
                onTap: () => _navigateToGospel(context, 'Mateo'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GospelButton(
                title: 'Marcos',                // icon: Icons.pets, 
                color: AppTheme.sacredRed,
                onTap: () => _navigateToGospel(context, 'Marcos'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
             Expanded(
              child: GospelButton(
                title: 'Lucas',
                // icon: Icons.help_outline, 
                color: AppTheme.sacredRed, // Using consistent theme color, or maybe vary slightly? Design seems consistent.
                onTap: () => _navigateToGospel(context, 'Lucas'), // Lucas symbol is Ox.
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GospelButton(
                title: 'Juan',
                // icon: Icons.air, 
                color: AppTheme.sacredRed,
                onTap: () => _navigateToGospel(context, 'Juan'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _navigateToGospel(BuildContext context, String gospel) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GospelReflectionsScreen(gospelName: gospel),
      ),
    );
  }

  String _formatMonthYear(DateTime date) {
    // Requires intl package and initialization, or simple custom array
    // Using simple array for Spanish to avoid locale initialization issues if not set up
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _formatDate(DateTime date) {
     const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${date.day} de ${months[date.month - 1]}, ${date.year}';
  }



  Widget _buildConsistencyHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Consistencia',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.sacredDark, // Updated text color
          ),
        ),
        
      ],
    );
  }

  Widget _buildStatisticsCards() {
    return FutureBuilder(
      future: _statsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: StatisticsCard(
                    icon: Icons.local_fire_department,
                    label: 'Racha Actual',
                    mainValue: '...',
                    secondaryValue: 'cargando',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatisticsCard(
                    icon: Icons.book,
                    label: 'Reflexiones',
                    mainValue: '...',
                    secondaryValue: 'cargando',
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return GlobalErrorWidget(
            message: 'Error de estadísticas',
            onRetry: _refreshStats,
            isCompact: true,
          );
        }

        final data = snapshot.data as List<dynamic>;
        final streakData = data[0];
        final reflectionData = data[1];

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: StatisticsCard(
                    icon: Icons.local_fire_department,
                    label: 'Racha Actual',
                    mainValue: '${streakData.daysStreak} días',
                    secondaryValue: '+${streakData.percentageVsLastMonth.toStringAsFixed(1)}% vs mes anterior',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatisticsCard(
                    icon: Icons.book,
                    label: 'Reflexiones',
                    mainValue: reflectionData.totalReflections.toString(),
                    secondaryValue: '+${reflectionData.thisMonthCount} este mes',
                    onTap: () {
                      Scrollable.ensureVisible(
                        _diarySectionKey.currentContext!,
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                ),
              ],
            ),
          );
      },
    );
  }

  Widget _buildCalendarSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatMonthYear(_displayedMonth),
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.sacredDark, // Updated text color
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: AppTheme.accentMint),
                  onPressed: () => _changeMonth(-1),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: AppTheme.accentMint),
                  onPressed: () => _changeMonth(1),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Header de días de la semana
        GridView.count(
          crossAxisCount: 7,
          childAspectRatio: 1.2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: ['L', 'M', 'X', 'J', 'V', 'S', 'D']
              .map(
                (day) => Center(
                  child: Text(
                    day,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.sacredDark.withOpacity(0.6), // Updated text color
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        // Calendario de días
        GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 0.9,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 42,
          itemBuilder: (context, index) {
            
            final firstDayOfMonth = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
            final firstWeekday = firstDayOfMonth.weekday; // 1 = Mon, 7 = Sun
       
            int day = index - (firstWeekday - 1) + 1;
            int daysInMonth = DateUtils.getDaysInMonth(_displayedMonth.year, _displayedMonth.month);
            
            bool visible = day > 0 && day <= daysInMonth;
            bool hasEntry = visible && _daysWithEntries.contains(day);
            bool isToday = visible && 
                          day == DateTime.now().day && 
                          _displayedMonth.month == DateTime.now().month && 
                          _displayedMonth.year == DateTime.now().year;

            // Calculate if the day is disabled (more than 30 days away and no entry)
            bool isDisabled = false;
            if (visible) {
              final currentDate = DateTime(_displayedMonth.year, _displayedMonth.month, day);
              final today = DateTime.now();
              // Calculate difference in days. Note: simple difference might be off by hours, so strip time.
              final dateOnly = DateTime(currentDate.year, currentDate.month, currentDate.day);
              final todayOnly = DateTime(today.year, today.month, today.day);
              final diff = dateOnly.difference(todayOnly).inDays.abs();
              
              if (diff > 30 && !hasEntry) {
                isDisabled = true;
              }
            }

            return visible
                ? CalendarDay(
                    day: day,
                    hasEntry: hasEntry,
                    isToday: isToday,
                    isDisabled: isDisabled,
                    onTap: isDisabled 
                      ? () {} // Do nothing if disabled
                      : () => _loadGospelForDate(DateTime(_displayedMonth.year, _displayedMonth.month, day)),
                  )
                : const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Future<void> _loadGospelForDate(DateTime selectedDate) async {
    try {
      // Show loading indicator
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentMint),
            ),
          ),
        );
      }

      GospelData? gospel;
      
      final today = DateTime.now();
      // Calculate diff stripping time
      final todayDate = DateTime(today.year, today.month, today.day);
      final selectedDateDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      final diff = selectedDateDate.difference(todayDate).inDays.abs();
      
      bool isOutOfRange = diff > 30;

      if (isOutOfRange) {
        // Try to load from local entry
        // We use orElse just to get null safely (well, firstWhere throws if not found without orElse, so we handle it)
        final entry = _allEntries.firstWhere(
           (e) => 
             e.date.year == selectedDate.year &&
             e.date.month == selectedDate.month &&
             e.date.day == selectedDate.day,
           orElse: () => PrayerEntry(id: 'null', userId: '', date: selectedDate, gospelQuote: '', reflection: '')
        );

        if (entry.id != 'null' && entry.gospelQuote.isNotEmpty) {
           final bibleService = BibleService();
           final parsed = bibleService.parseReference(entry.gospelQuote);
           String content = '';
           
           if (parsed != null) {
              content = await bibleService.getVersiclesText(
                parsed['book'], 
                parsed['chapter'], 
                parsed['startVersicle'], 
                parsed['endVersicle']
              );
           }
           
           if (content.isNotEmpty) {
             gospel = GospelData(
               title: entry.gospelQuote,
               date: selectedDate,
               firstReading: 'Lectura Histórica',
               firstReadingReference: '',
               psalm: 'Lectura desde Historial',
               psalmReference: '',
               evangeliumText: content,
               commentTitle: 'Reflexión Guardada',
               commentBody: 'Esta es una lectura recuperada de tu historial de reflexiones.',
               commentAuthor: 'Historial',
               commentSource: '',
             );
           }
        }
      }

      if (gospel == null) {
         if (isOutOfRange) {
            // Should not happen if UI disables clicking, but safety check
            throw Exception("Lectura no disponible para esta fecha lejana.");
         }
         // Fetch the gospel for that date
         gospel = await GospelRepository.fetchGospelData(selectedDate);
      }
      
      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
        
        // Navigate to ReadingScreen with the gospel
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReadingScreen(gospel: gospel),
          ),
        ).then((_) {
          // Refresh data when returning from reading screen (in case a new entry was made)
          _loadInitialData();
        });
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar la lectura: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Removed _buildTagsSection

  Widget _buildDiarySection() {
    return Column(
      key: _diarySectionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Diario de Reflexiones',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.sacredDark,
          ),
        ),
        const SizedBox(height: 12),
        if (_isLoading)
          const Center(child: CircularProgressIndicator(color: AppTheme.accentMint))
        else if (_hasError)
          GlobalErrorWidget(
            message: 'No pudimos cargar tu diario',
            onRetry: _loadInitialData,
            isCompact: true,
          )
        else if (_allEntries.isEmpty)
           Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'No hay reflexiones aún.',
              style: GoogleFonts.inter(color: AppTheme.sacredDark.withOpacity(0.4)),
            ),
          )
        else
          ...[
            ..._allEntries.map(
              (entry) => DiaryEntryCard(
                date: _formatDate(entry.date),
                passage: entry.gospelQuote,
                title: 'Reflexión del día',
                excerpt: entry.reflection,
                onTap: () {
                   _loadGospelForDate(entry.date);
                },
              ),
            ),
            // Load More Button
            if (_hasMoreData)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: _isLoadingMore
                      ? const CircularProgressIndicator(color: AppTheme.accentMint)
                      : ElevatedButton.icon(
                          onPressed: _loadMoreData,
                          icon: const Icon(Icons.expand_more),
                          label: const Text('Cargar más'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.sacredRed,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                ),
              ),
          ],
      ],
    );
  }

}
