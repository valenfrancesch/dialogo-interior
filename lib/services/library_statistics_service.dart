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

  /// ===== ESTADÍSTICA 1: RACHA ACTUAL (Días consecutivos) =====
  /// Complejidad: ALTA
  /// - Obtiene últimas 30 entradas ordenadas por fecha
  /// - Verifica si existe entrada para hoy/ayer
  /// - Itera hacia atrás contando días consecutivos de 24 horas
  /// - Calcula porcentaje vs mes anterior (guardado en perfil)
  Future<StreakData> calculateCurrentStreak() async {
    try {
      final entries = await _prayerRepository.getRecentReflections(60);
      if (entries.isEmpty) {
        return StreakData(
          daysStreak: 0,
          percentageVsLastMonth: 0.0,
          lastEntryDate: DateTime.now(),
        );
      }

      // Ordena por fecha descendente (más reciente primero)
      entries.sort((a, b) => b.date.compareTo(a.date));

      // Toma las últimas 30 entradas
      final recentEntries = entries.take(30).toList();

      int streak = 0;
      DateTime today = DateTime.now();
      DateTime checkDate = DateTime(today.year, today.month, today.day);

      // Verifica si existe entrada para hoy
      bool hasEntryToday = recentEntries.any((entry) {
        final entryDate = DateTime(entry.date.year, entry.date.month, entry.date.day);
        return entryDate.compareTo(checkDate) == 0;
      });

      if (!hasEntryToday) {
        // Si no hay entrada hoy, verifica ayer
        checkDate = checkDate.subtract(const Duration(days: 1));
      }

      // Itera hacia atrás mientras la diferencia sea exactamente 24 horas
      for (final entry in recentEntries) {
        final entryDate = DateTime(entry.date.year, entry.date.month, entry.date.day);

        if (entryDate.compareTo(checkDate) == 0) {
          streak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        } else if (entryDate.isBefore(checkDate)) {
          break;
        }
      }

      // Calcula porcentaje vs mes anterior
      final percentageVsLastMonth = await _calculateStreakGrowthPercentage();

      return StreakData(
        daysStreak: streak,
        percentageVsLastMonth: percentageVsLastMonth,
        lastEntryDate: recentEntries.first.date,
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
  /// Complejidad: MEDIA
  /// - Usa Firestore count() para eficiencia
  /// - Filtra mensualmente con where()
  /// - Calcula crecimiento porcentual mensual
  Future<ReflectionCountData> calculateReflectionCount() async {
    try {
      final userId = _getCurrentUserId();
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      // Obtiene el conteo total de reflexiones
      final countQuery = _firestore
          .collection('users')
          .doc(userId)
          .collection('entries')
          .count();
      final countSnapshot = await countQuery.get();
      final totalReflections = countSnapshot.count ?? 0;

      // Obtiene entradas de este mes
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      final thisMonthQuery = _firestore
          .collection('users')
          .doc(userId)
          .collection('entries')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .count();

      final thisMonthSnapshot = await thisMonthQuery.get();
      final thisMonthCount = thisMonthSnapshot.count ?? 0;
     
      // Calcula crecimiento porcentual
      final percentageGrowth = await _calculateMonthlyGrowthPercentage(
        thisMonthCount,
        startOfMonth,
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
