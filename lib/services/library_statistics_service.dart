import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/library_statistics.dart';
import '../repositories/prayer_repository.dart';

/// Servicio especializado para calcular estadísticas de la Biblioteca de Fe
/// Utiliza FutureBuilder para evitar lecturas innecesarias de Firestore
class LibraryStatisticsService {
  final PrayerRepository _prayerRepository;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  LibraryStatisticsService({
    required PrayerRepository prayerRepository,
  }) : _prayerRepository = prayerRepository;

  // Cached stats to avoid duplicate calls
  Map<String, dynamic>? _cachedStats;
  DateTime? _statsLoadedAt;
  Future<Map<String, dynamic>>? _pendingStatsFuture;

  /// Gets user stats from cache or fetches if needed
  /// Cache is valid for 10 seconds to handle rapid successive calls or component rebuilds
  Future<Map<String, dynamic>> _getStatsWithCache() async {
    final now = DateTime.now();
    
    // 1. Return cached stats if available and fresh (within 10 seconds)
    if (_cachedStats != null && 
        _statsLoadedAt != null && 
        now.difference(_statsLoadedAt!).inSeconds < 10) {
      return _cachedStats!;
    }
    
    // 2. Return pending future if exists (request coalescing)
    // This prevents duplicate calls when multiple widgets request stats simultaneously
    if (_pendingStatsFuture != null) {
      return _pendingStatsFuture!;
    }
    
    // 3. Fetch fresh stats
    _pendingStatsFuture = _prayerRepository.getUserStats().then((stats) {
      _cachedStats = stats;
      _statsLoadedAt = DateTime.now();
      _pendingStatsFuture = null; // Clear pending after completion
      return stats;
    }).catchError((e) {
      _pendingStatsFuture = null; // Clear pending on error
      throw e;
    });
    
    return _pendingStatsFuture!;
  }

  /// ===== ESTADÍSTICA 1: RACHA ACTUAL (Días consecutivos) =====
  /// Ahora usa getUserStats() optimizado del repositorio con cache
  Future<StreakData> calculateCurrentStreak() async {
    try {
      final stats = await _getStatsWithCache();
      final streak = stats['streak'] as int;
      
      // Calcula porcentaje vs mes anterior
      final percentageVsLastMonth = await _calculateStreakGrowthPercentage();

      return StreakData(
        daysStreak: streak,
        percentageVsLastMonth: percentageVsLastMonth,
        lastEntryDate: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Error al calcular racha: $e');
    }
  }

  /// Calcula el crecimiento de la racha respecto al mes anterior
  /// Obtiene el valor guardado en el documento de perfil del usuario
  Future<double> _calculateStreakGrowthPercentage() async {
    try {
      // Simulación: En producción, obtendría del documento de perfil
      // final profileDoc = await _firestore
      //     .collection('users')
      //     .doc(userId)
      //     .get();
      // final lastMonthStreak = profileDoc['lastMonthStreak'] ?? 0;

      // Por ahora retorna un valor simulado
      return 2.0; // +2% vs mes anterior
    } catch (e) {
      return 0.0;
    }
  }

  /// ===== ESTADÍSTICA 2: CONTADOR TOTAL DE REFLEXIONES =====
  /// Ahora reutiliza los datos de getUserStats() para evitar duplicados
  Future<ReflectionCountData> calculateReflectionCount() async {
    try {
      // Reutiliza los datos de getUserStats() que ya incluyen total y thisMonth
      final stats = await _getStatsWithCache();
      final totalReflections = stats['totalReflections'] as int;
      final thisMonthCount = stats['thisMonth'] as int;
     
      // Calcula crecimiento porcentual
      final percentageGrowth = await _calculateMonthlyGrowthPercentage(
        thisMonthCount,
        DateTime(DateTime.now().year, DateTime.now().month, 1),
      );

      return ReflectionCountData(
        totalReflections: totalReflections,
        thisMonthCount: thisMonthCount,
        percentageGrowth: percentageGrowth,
      );
    } catch (e) {
      throw Exception('Error al calcular reflexiones: $e');
    }
  }

  /// Calcula el crecimiento porcentual mensual
  Future<double> _calculateMonthlyGrowthPercentage(
    int currentMonthCount,
    DateTime currentMonthStart,
  ) async {
    try {
      final userId = _getCurrentUserId();
      if (userId == null) return 0.0;

      // Calcula las fechas del mes anterior
      final lastMonthStart = DateTime(
        currentMonthStart.year,
        currentMonthStart.month - 1,
        1,
      );
      final lastMonthEnd = DateTime(
        currentMonthStart.year,
        currentMonthStart.month,
        0,
        23,
        59,
        59,
      );

      final lastMonthQuery = _firestore
          .collection('users')
          .doc(userId)
          .collection('entries')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(lastMonthStart))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(lastMonthEnd))
          .count();

      final lastMonthSnapshot = await lastMonthQuery.get();
      final lastMonthCount = lastMonthSnapshot.count ?? 0;

      if (lastMonthCount == 0) return 0.0;

      final growth = ((currentMonthCount.toDouble() - lastMonthCount.toDouble()) / lastMonthCount.toDouble()) * 100;
      return growth;
    } catch (e) {
      return 0.0;
    }
  }

  /// ===== ESTADÍSTICA 3: MEMORIA LITÚRGICA (Flashback 1 y 3 años) =====
  /// Complejidad: ALTA
  /// - Busca reflexiones pasadas del mismo evangelio (gospelQuote)
  /// - Compara diferencias de años (1 año, 3 años)
  /// - Crea tarjetas de flashback temporal
  Future<List<LiturgicalMemoryEntry>> getLiturgicalMemory(
    String currentGospelQuote,
  ) async {
    try {
      final userId = _getCurrentUserId();
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      // Obtiene reflexiones pasadas del mismo pasaje
      final pastEntries = await _prayerRepository.getHistoryByGospel(
        currentGospelQuote,
      );

      // Filtra solo las que son anteriores a hoy
      final today = DateTime.now();
      final filteredEntries = pastEntries
          .where((entry) => entry.date.isBefore(today))
          .toList();

      // Crea lista de LiturgicalMemoryEntry con años identificados
      final liturgicalMemories = <LiturgicalMemoryEntry>[];

      for (final entry in filteredEntries) {
        final yearsAgo = _calculateYearsDifference(entry.date, today);

        // Solo incluye si es 1 año o 3 años antes
        if (yearsAgo == 1 || yearsAgo == 3) {
          liturgicalMemories.add(
            LiturgicalMemoryEntry(
              id: entry.id!,
              date: entry.date,
              reflection: entry.reflection,
              gospelQuote: entry.gospelQuote,
              yearsAgo: yearsAgo,
            ),
          );
        }
      }

      return liturgicalMemories;
    } catch (e) {
      throw Exception('Error al obtener memoria litúrgica: $e');
    }
  }

  /// Calcula la diferencia de años entre dos fechas
  int _calculateYearsDifference(DateTime past, DateTime now) {
    int years = now.year - past.year;
    if (now.month < past.month ||
        (now.month == past.month && now.day < past.day)) {
      years--;
    }
    return years;
  }

  /// ===== ESTADÍSTICA 4: SPIRITUAL GROWTH INSIGHT =====
  /// Complejidad: MUY ALTA
  /// - Resume actividad histórica sobre un pasaje específico
  /// - Contea reflexiones por pasaje
  /// - Suma total de palabras en reflexiones
  /// - Identifica tema recurrente (tag más frecuente)
  Future<SpiritualGrowthInsight?> calculateSpiritualGrowthInsight(
    String gospelQuote,
  ) async {
    try {
      final userId = _getCurrentUserId();
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      // Obtiene todas las reflexiones sobre este pasaje
      final reflectionsOnGospel = await _prayerRepository.getHistoryByGospel(
        gospelQuote,
      );

      if (reflectionsOnGospel.isEmpty) {
        return null;
      }

      // 1. Contea reflexiones sobre este evangelio
      final totalReflections = reflectionsOnGospel.length;

      // 2. Suma total de palabras
      int totalWords = 0;
      for (final entry in reflectionsOnGospel) {
        totalWords += entry.reflection.split(' ').length;
      }



      // 4. Obtiene entradas históricas
      final historicalEntries = await getLiturgicalMemory(gospelQuote);

      return SpiritualGrowthInsight(
        gospelQuote: gospelQuote,
        totalReflections: totalReflections,
        totalWords: totalWords,
        historicalEntries: historicalEntries,
      );
    } catch (e) {
      throw Exception('Error al calcular crecimiento espiritual: $e');
    }
  }

  /// Obtiene el ID del usuario actual
  String? _getCurrentUserId() {
    return _auth.currentUser?.uid;
  }
}
