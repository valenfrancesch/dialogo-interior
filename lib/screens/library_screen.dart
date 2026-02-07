import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// Added for date formatting
import '../theme/app_theme.dart';
import '../widgets/statistics_card.dart';
import '../widgets/diary_entry_card.dart';
import '../widgets/calendar_day.dart';
import '../widgets/spiritual_growth_card.dart';
import '../repositories/gospel_repository.dart';
import '../repositories/prayer_repository.dart';
import '../services/library_statistics_service.dart';
import '../models/library_statistics.dart';
import '../models/prayer_entry.dart';
import 'reading_screen.dart';
import '../widgets/gospel_button.dart';
import '../services/bible_service.dart';
import '../models/gospel_data.dart';
import 'gospel_reflections_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final PrayerRepository _prayerRepository = PrayerRepository();
  late final LibraryStatisticsService _statisticsService;
  
  DateTime _displayedMonth = DateTime.now();
  
  // State for fetched data
  // State for fetched data
  List<PrayerEntry> _allEntries = [];
  List<int> _daysWithEntries = [];
  bool _isLoading = true;

  // Cached futures to prevent reloading on setState
  late Future<List<dynamic>> _statsFuture;
  late Future<SpiritualGrowthInsight?> _growthFuture;

  final GlobalKey _diarySectionKey = GlobalKey();

  @override
  void initState() {
    _searchController.addListener(_onSearchChanged);
    super.initState();
    _statisticsService = LibraryStatisticsService(
      prayerRepository: _prayerRepository,
    );
    _initFutures();
    _loadInitialData();
  }

  void _initFutures() {
    _statsFuture = Future.wait([
      _statisticsService.calculateCurrentStreak(),
      _statisticsService.calculateReflectionCount(),
    ]);
    
    // Example quote for now
    _growthFuture = _statisticsService.calculateSpiritualGrowthInsight('Juan 3:16-21');
  }

  void _refreshStats() {
    setState(() {
      _statsFuture = Future.wait([
        _statisticsService.calculateCurrentStreak(),
        _statisticsService.calculateReflectionCount(),
      ]);
    });
  }

  void _onSearchChanged() {
    setState(() {
      // Trigger rebuild to update filtering
    });
  }



  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final entries = await _prayerRepository.getUserReflections();
      
      // Refresh stats to ensure they are up to date with potentially new entries
      _refreshStats();
      
      // Load calendar days for current month
      final days = await _prayerRepository.getDaysWithEntries(
        _displayedMonth.year, 
        _displayedMonth.month
      );

      if (mounted) {
        setState(() {
          _allEntries = entries;
          _daysWithEntries = days;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // ScafflodMessenger logic could go here
      }
    }
  }

  Future<void> _updateCalendarDays() async {
    final days = await _prayerRepository.getDaysWithEntries(
      _displayedMonth.year,
      _displayedMonth.month,
    );
    if (mounted) {
      setState(() {
        _daysWithEntries = days;
      });
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

  // ... (start of _filteredEntries)
  List<PrayerEntry> get _filteredEntries {
    List<PrayerEntry> entries = _allEntries;

    // 1. Filter by Tag
    // 2. Filter by Search Query
    final query = _searchController.text.toLowerCase().trim();
    if (query.isNotEmpty) {
      entries = entries.where((e) {
        return e.reflection.toLowerCase().contains(query) ||
            e.gospelQuote.toLowerCase().contains(query) ||
            (e.highlightedText?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    return entries;
  }

  @override
  void dispose() {
    _searchController.dispose();
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
      body: SingleChildScrollView(
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

            // 2.5 CRECIMIENTO ESPIRITUAL (Insight)
            _buildSpiritualGrowthSection(),
            const SizedBox(height: 24),

            // 3. CALENDARIO DE MEMORIA LITÚRGICA
            _buildCalendarSection(),
            const SizedBox(height: 24),

            // 4. MIS ETIQUETAS
            //_buildTagsSection(),
           // const SizedBox(height: 24),
                       // 1. BUSCADOR
            _buildSearchBar(),
            const SizedBox(height: 24),

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

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardDark, // Mapped to Colors.white
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.sacredGold.withOpacity(0.3), width: 1), // Updated border
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar reflexiones...',
          hintStyle: GoogleFonts.inter(
            fontSize: 14,
            color: AppTheme.sacredDark.withOpacity(0.4), // Updated hint color
          ),
          prefixIcon: Icon(Icons.search, color: AppTheme.accentMint),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        style: GoogleFonts.inter(
          fontSize: 14,
          color: AppTheme.sacredDark, // Updated text color
        ),
      ),
    );
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
          return Row(
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
          );
        }

        if (snapshot.hasError) {
          return Row(
            children: [
              Expanded(
                child: StatisticsCard(
                  icon: Icons.local_fire_department,
                  label: 'Racha Actual',
                  mainValue: '0 días',
                  secondaryValue: 'error',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatisticsCard(
                  icon: Icons.book,
                  label: 'Reflexiones',
                  mainValue: '0',
                  secondaryValue: 'error',
                ),
              ),
            ],
          );
        }

        final data = snapshot.data as List<dynamic>;
        final streakData = data[0];
        final reflectionData = data[1];

          return Row(
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

  Widget _buildSpiritualGrowthSection() {
    return FutureBuilder<SpiritualGrowthInsight?>(
      future: _growthFuture,
      builder: (context, snapshot) {
        // Si no hay datos o está cargando, mostrar un placeholder
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.sacredGold.withOpacity(0.3), width: 1), // Updated border
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentMint),
              ),
            ),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final insight = snapshot.data!;

        return SpiritualGrowthCard(
          insight: insight,
          onTap: () {
            // Navegar a una pantalla de análisis detallado
          },
        );
      },
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
            color: AppTheme.sacredDark, // Updated text color
          ),
        ),
        const SizedBox(height: 12),
        if (_isLoading)
          const Center(child: CircularProgressIndicator(color: AppTheme.accentMint))
        else if (_filteredEntries.isEmpty)
           Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'No hay reflexiones aún.',
              style: GoogleFonts.inter(color: AppTheme.sacredDark.withOpacity(0.4)), // Updated text color
            ),
          )
        else
          ..._filteredEntries.map(
            (entry) => DiaryEntryCard(
              date: _formatDate(entry.date),
              passage: entry.gospelQuote,
              title: 'Reflexión del día', // O un título dinámico si lo hubiera
              excerpt: entry.reflection,
              onTap: () {
                 _loadGospelForDate(entry.date);
              },
            ),
          ),
      ],
    );
  }

}
