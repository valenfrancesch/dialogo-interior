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

  /// Obtiene todas las reflexiones del usuario actual
  Future<List<PrayerEntry>> getUserReflections() async {
    try {
      final userId = _getCurrentUserId();
      if (userId == null) {
        throw Exception('Usuario no autenticado.');
      }

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('entries')
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PrayerEntry.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener reflexiones: $e');
    }
  }

  /// Obtiene las últimas N reflexiones del usuario (Optimizada para estadísticas)
  Future<List<PrayerEntry>> getRecentReflections([int limit = 60]) async {
    try {
      final userId = _getCurrentUserId();
      if (userId == null) {
        throw Exception('Usuario no autenticado.');
      }

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('entries')
          .orderBy('date', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => PrayerEntry.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener reflexiones recientes: $e');
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





  /// Obtiene estadísticas del usuario para la Biblioteca
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      final userId = _getCurrentUserId();
      if (userId == null) {
        throw Exception('Usuario no autenticado.');
      }

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('entries')
          .get();

      final totalReflections = snapshot.docs.length;

      // Calcula la racha (días consecutivos con reflexión)
      final streak = _calculateStreak(snapshot.docs);

      // Cuenta reflexiones de este mes
      final now = DateTime.now();
      final thisMonth = snapshot.docs.where((doc) {
        final entry = PrayerEntry.fromFirestore(doc);
        return entry.date.month == now.month && entry.date.year == now.year;
      }).length;

      return {
        'totalReflections': totalReflections,
        'streak': streak,
        'thisMonth': thisMonth,
      };
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }

  /// Calcula la racha de días consecutivos con reflexiones
  int _calculateStreak(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    if (docs.isEmpty) return 0;

    final entries = docs
        .map((doc) => PrayerEntry.fromFirestore(doc))
        .toList()
        .cast<PrayerEntry>();

    // Ordena por fecha descendente
    entries.sort((a, b) => b.date.compareTo(a.date));

    int streak = 1;
    DateTime lastDate = DateTime(
      entries[0].date.year,
      entries[0].date.month,
      entries[0].date.day,
    );

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

  /// Busca reflexiones por texto
  Future<List<PrayerEntry>> searchReflections(String query) async {
    try {
      final userId = _getCurrentUserId();
      if (userId == null) {
        throw Exception('Usuario no autenticado.');
      }

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('entries')
          .get();

      final lowerQuery = query.toLowerCase();

      final results = snapshot.docs
          .map((doc) => PrayerEntry.fromFirestore(doc))
          .where((entry) {
            return entry.reflection.toLowerCase().contains(lowerQuery) ||
                (entry.highlightedText?.toLowerCase().contains(lowerQuery) ?? false) ||
                entry.gospelQuote.toLowerCase().contains(lowerQuery);
          })
          .toList();

      results.sort((a, b) => b.date.compareTo(a.date));
      return results;
    } catch (e) {
      throw Exception('Error al buscar reflexiones: $e');
    }
  }

  /// Actualiza una reflexión existente
  Future<void> updateReflection(PrayerEntry entry) async {
    try {
      if (entry.id == null) {
        throw Exception('No se puede actualizar: ID de entrada no disponible');
      }

      final userId = _getCurrentUserId();
      if (userId == null) {
        throw Exception('Usuario no autenticado.');
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('entries')
          .doc(entry.id)
          .update(entry.toFirestore());
    } catch (e) {
      throw Exception('Error al actualizar reflexión: $e');
    }
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

  Future<List<int>> getDaysWithEntries(int year, int month) async {
    final userId = _getCurrentUserId();

    // Definimos el rango del mes para la consulta
    DateTime firstDay = DateTime(year, month, 1);
    DateTime lastDay = DateTime(year, month + 1, 0);

    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('entries')
        .where('date', isGreaterThanOrEqualTo: firstDay)
        .where('date', isLessThanOrEqualTo: lastDay)
        .get();

    // Extraemos el día de cada fecha y eliminamos duplicados con .toSet()
    final days = snapshot.docs
        .map((doc) => (doc.data()['date'] as Timestamp).toDate().day)
        .toSet()
        .toList();

    days.sort(); // Ordenamos de menor a mayor para el calendario
    return days;
  }
}
