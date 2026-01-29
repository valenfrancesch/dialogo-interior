import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // Added for date formatting
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

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final PrayerRepository _prayerRepository = PrayerRepository();
  late final LibraryStatisticsService _statisticsService;
  
  String _selectedTag = '';
  DateTime _displayedMonth = DateTime.now();
  
  // State for fetched data
  List<PrayerEntry> _allEntries = [];
  Set<String> _availableTags = {};
  List<int> _daysWithEntries = [];
  bool _isLoading = true;

  // Cached futures to prevent reloading on setState
  late Future<List<dynamic>> _statsFuture;
  late Future<SpiritualGrowthInsight?> _growthFuture;

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

  void _onSearchChanged() {
    setState(() {
      // Trigger rebuild to update filtering
    });
  }



  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      // Load all entries and tags
      final entries = await _prayerRepository.getUserReflections();
      final tags = await _prayerRepository.getUserUniqueTags();
      
      // Load calendar days for current month
      final days = await _prayerRepository.getDaysWithEntries(
        _displayedMonth.year, 
        _displayedMonth.month
      );

      if (mounted) {
        setState(() {
          _allEntries = entries;
          _availableTags = tags;
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
    if (_selectedTag.isNotEmpty) {
      entries = entries.where((e) => e.tags.contains(_selectedTag)).toList();
    }

    // 2. Filter by Search Query
    final query = _searchController.text.toLowerCase().trim();
    if (query.isNotEmpty) {
      entries = entries.where((e) {
        return e.reflection.toLowerCase().contains(query) ||
            e.gospelQuote.toLowerCase().contains(query) ||
            (e.highlightedText?.toLowerCase().contains(query) ?? false) ||
            e.tags.any((tag) => tag.toLowerCase().contains(query));
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
      backgroundColor: AppTheme.primaryDarkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Icon(Icons.auto_stories, color: AppTheme.accentMint, size: 28),
        title: Text(
          'Biblioteca de Fe',
          style: GoogleFonts.montserrat(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [


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
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10, width: 1),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar reflexiones...',
          hintStyle: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.white38,
          ),
          prefixIcon: Icon(Icons.search, color: AppTheme.accentMint),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        style: GoogleFonts.inter(
          fontSize: 14,
          color: Colors.white,
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
            color: Colors.white,
          ),
        ),
        Text(
          'MEMORIA LITÚRGICA',
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.accentMint,
            letterSpacing: 0.5,
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
                mainValue: reflectionData.thisMonthCount.toString(),
                secondaryValue: '+${reflectionData.percentageGrowth.toStringAsFixed(1)}% este mes',
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
                color: Colors.white,
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
                      color: Colors.white60,
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
            childAspectRatio: 1.2,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 42,
          itemBuilder: (context, index) {
            // Calculate day offset based on the first day of the month
            // Note: simple calculation assuming grid starts at correct offset
            // Ideally we need to know what day of week the 1st falls on
            
            final firstDayOfMonth = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
            final firstWeekday = firstDayOfMonth.weekday; // 1 = Mon, 7 = Sun
            // Our grid starts with Monday (L). 
            // If 1st is Monday (1), offset SHOULD be 0. 
            // If 1st is Tuesday (2), offset SHOULD be 1.
            // Formula: index - (weekday - 1) + 1
            
            int day = index - (firstWeekday - 1) + 1;
            int daysInMonth = DateUtils.getDaysInMonth(_displayedMonth.year, _displayedMonth.month);
            
            bool visible = day > 0 && day <= daysInMonth;
            bool hasEntry = visible && _daysWithEntries.contains(day);
            bool isToday = visible && 
                          day == DateTime.now().day && 
                          _displayedMonth.month == DateTime.now().month && 
                          _displayedMonth.year == DateTime.now().year;

            return visible
                ? CalendarDay(
                    day: day,
                    hasEntry: hasEntry,
                    isToday: isToday,
                    onTap: () => _loadGospelForDate(DateTime(_displayedMonth.year, _displayedMonth.month, day)),
                  )
                : const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildSpiritualGrowthSection() {
    // Para esta versión inicial, usamos un pasaje de ejemplo
    // En una versión posterior, esto será dinámico basado en el evangelio actual
    // const exampleGospelQuote = 'Juan 3:16-21'; // Moved to _initFutures

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
              border: Border.all(color: Colors.white10, width: 1),
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

      // Fetch the gospel for that date
      final gospel = await GospelRepository.fetchGospelData(selectedDate);
      
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

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Mis Etiquetas',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: Text(
                'Editar',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.accentMint,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
      
          children: [
            if (_availableTags.isEmpty)
              Text(
                'No hay etiquetas registradas',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white38),
              ),
            ..._availableTags.map(
              (tag) => GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTag = _selectedTag == tag ? '' : tag;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _selectedTag == tag
                        ? AppTheme.accentMint.withOpacity(0.2)
                        : AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _selectedTag == tag
                          ? AppTheme.accentMint
                          : Colors.white24,
                      width: _selectedTag == tag ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    tag,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _selectedTag == tag
                          ? AppTheme.accentMint
                          : Colors.white70,
                      ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDiarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Diario de #${_selectedTag.isNotEmpty ? _selectedTag : 'Reflexiones'}',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
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
              style: GoogleFonts.inter(color: Colors.white38),
            ),
          )
        else
          ..._filteredEntries.map(
            (entry) => DiaryEntryCard(
              date: _formatDate(entry.date),
              passage: entry.gospelQuote,
              title: 'Reflexión del día', // O un título dinámico si lo hubiera
              excerpt: entry.reflection,
              tags: entry.tags,
              onTap: () {
                 _loadGospelForDate(entry.date);
              },
            ),
          ),
      ],
    );
  }

}
