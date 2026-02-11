import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/prayer_entry.dart';

class PrayerRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Obtiene el ID del usuario actual desde Firebase Auth
  String? _getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  Future<String> saveReflection(PrayerEntry entry) async {
    try {
      final userId = _getCurrentUserId();
      if (userId == null) {
        throw Exception(
          'Usuario no autenticado. No se puede guardar la reflexión.',
        );
      }

      // 1. Asegura que el userId coincida con el usuario actual
      final entryToSave = entry.copyWith(userId: userId);

      // 2. Usamos el ID de la entrada (que es la fecha formatada) en lugar de .add()
      // Si el 'entry.id' es "2026-01-28", Firestore buscará ese doc específico
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('entries')
          .doc(entryToSave.id) // Usamos el ID predecible basado en la fecha
          .set(
            entryToSave.toFirestore(),
            SetOptions(
              merge: true,
            ),
          );

      return entryToSave.id!;
    } catch (e) {
      throw Exception('Error al guardar o actualizar reflexión: $e');
    }
  }

  /// Obtiene reflexiones del usuario actual con paginación
  /// [startAfter] - Documento desde donde continuar la paginación
  /// [limit] - Número de reflexiones por página (default: 10)
  Future<List<PrayerEntry>> getUserReflections({
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = 10,
  }) async {
    try {
      final userId = _getCurrentUserId();
      if (userId == null) {
        throw Exception('Usuario no autenticado.');
      }

      var query = _firestore
          .collection('users')
          .doc(userId)
          .collection('entries')
          .orderBy('date', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }


      final snapshot = await query.get();


      return snapshot.docs
          .map((doc) => PrayerEntry.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener reflexiones: $e');
    }
  }



  /// Obtiene reflexiones históricas del mismo pasaje bíblico
  /// Esto es el corazón del "Flashback Espiritual"
  /// Busca todas las reflexiones donde gospelQuote coincida
  Future<List<PrayerEntry>> getHistoryByGospel(String gospelQuote) async {
    try {
      final userId = _getCurrentUserId();
      if (userId == null) {
        throw Exception('Usuario no autenticado.');
      }


      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('entries')
          .where('gospelQuote', isEqualTo: gospelQuote)
          .orderBy('date', descending: true)
          .get();


      return snapshot.docs
          .map((doc) => PrayerEntry.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener historial: $e');
    }
  }





  /// Obtiene estadísticas del usuario para la Biblioteca (Optimizado con agregaciones)
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      final userId = _getCurrentUserId();
      if (userId == null) {
        throw Exception('Usuario no autenticado.');
      }

      final entriesRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('entries');

      // Usa agregación de Firestore para contar total de reflexiones

      final totalCount = await entriesRef.count().get();
      final totalReflections = totalCount.count ?? 0;


      // Para la racha, solo obtiene entradas recientes (últimos 60 días)
      final cutoffDate = DateTime.now().subtract(const Duration(days: 60));

      final recentSnapshot = await entriesRef
          .where('date', isGreaterThanOrEqualTo: cutoffDate)
          .orderBy('date', descending: true)
          .get();


      final streak = _calculateStreak(recentSnapshot.docs);

      // Cuenta reflexiones de este mes usando agregación
      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      final lastDayOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      

      final monthlyCount = await entriesRef
          .where('date', isGreaterThanOrEqualTo: firstDayOfMonth)
          .where('date', isLessThanOrEqualTo: lastDayOfMonth)
          .count()
          .get();


      return {
        'totalReflections': totalReflections,
        'streak': streak,
        'thisMonth': monthlyCount.count ?? 0,
      };
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }

  /// Calcula la racha de días consecutivos con reflexiones
  /// Retorna 0 si la racha está rota (última reflexión hace más de 1 día)
  int _calculateStreak(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    if (docs.isEmpty) return 0;

    final entries = docs
        .map((doc) => PrayerEntry.fromFirestore(doc))
        .toList()
        .cast<PrayerEntry>();

    // Ordena por fecha descendente
    entries.sort((a, b) => b.date.compareTo(a.date));

    final today = DateTime.now();
    final todayNormalized = DateTime(today.year, today.month, today.day);
    
    DateTime lastDate = DateTime(
      entries[0].date.year,
      entries[0].date.month,
      entries[0].date.day,
    );

    // Verifica si la racha está activa (hoy o ayer)
    final daysSinceLastEntry = todayNormalized.difference(lastDate).inDays;
    if (daysSinceLastEntry > 1) {
      return 0; // La racha está rota
    }

    int streak = 1;
    for (int i = 1; i < entries.length; i++) {
      final currentDate = DateTime(
        entries[i].date.year,
        entries[i].date.month,
        entries[i].date.day,
      );
      final difference = lastDate.difference(currentDate).inDays;

      if (difference == 1) {
        streak++;
        lastDate = currentDate;
      } else {
        break;
      }
    }

    return streak;
  }





  /// Elimina una reflexión
  Future<void> deleteReflection(String entryId) async {
    try {
      final userId = _getCurrentUserId();
      if (userId == null) {
        throw Exception('Usuario no autenticado.');
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('entries')
          .doc(entryId)
          .delete();
    } catch (e) {
      throw Exception('Error al eliminar reflexión: $e');
    }
  }

  /// Obtiene una reflexión específica por ID
  Future<PrayerEntry?> getReflectionById(String entryId) async {
    try {
      final userId = _getCurrentUserId();
      if (userId == null) {
        throw Exception('Usuario no autenticado.');
      }

      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('entries')
          .doc(entryId)
          .get();

      if (!doc.exists) return null;

      return PrayerEntry.fromFirestore(doc);
    } catch (e) {
      throw Exception('Error al obtener reflexión: $e');
    }
  }

  /// Obtiene los días del mes que tienen reflexiones (para calendario)
  Future<List<int>> getDaysWithEntries(int year, int month) async {
    try {
      final userId = _getCurrentUserId();
      if (userId == null) {
        throw Exception('Usuario no autenticado.');
      }

      // Define el rango del mes para la consulta
      final firstDay = DateTime(year, month, 1);
      final lastDay = DateTime(year, month + 1, 0, 23, 59, 59);


      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('entries')
          .where('date', isGreaterThanOrEqualTo: firstDay)
          .where('date', isLessThanOrEqualTo: lastDay)
          .get();


      // Extrae el día de cada fecha y elimina duplicados con .toSet()
      final days = snapshot.docs
          .map((doc) => (doc.data()['date'] as Timestamp).toDate().day)
          .toSet()
          .toList();

      days.sort(); // Ordena de menor a mayor para el calendario
      return days;
    } catch (e) {
      throw Exception('Error al obtener días con entradas: $e');
    }
  }
}
