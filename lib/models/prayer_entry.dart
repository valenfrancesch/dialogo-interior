import 'package:cloud_firestore/cloud_firestore.dart';

class PrayerEntry {
  final String? id;
  final String userId;
  final DateTime date;
  final String gospelQuote; // Cita bíblica (ej: "Juan 3:16-21")
  final String reflection; // Texto de reflexión del usuario
  final String? highlightedText; // Texto destacado del pasaje
  final List<String> tags; // Etiquetas (Gratitud, Esperanza, etc)

  PrayerEntry({
    this.id,
    required this.userId,
    required this.date,
    required this.gospelQuote,
    required this.reflection,
    this.highlightedText,
    this.tags = const [],
  });

  /// Convierte un documento de Firestore a PrayerEntry
  factory PrayerEntry.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return PrayerEntry(
      id: doc.id,
      userId: data['userId'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      gospelQuote: data['gospelQuote'] ?? '',
      reflection: data['reflection'] ?? '',
      highlightedText: data['highlightedText'],
      tags: List<String>.from(data['tags'] ?? []),
    );
  }

  /// Convierte PrayerEntry a mapa para guardar en Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'gospelQuote': gospelQuote,
      'reflection': reflection,
      'highlightedText': highlightedText,
      'tags': tags,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// Copia con cambios (útil para actualizar)
  PrayerEntry copyWith({
    String? id,
    String? userId,
    DateTime? date,
    String? gospelQuote,
    String? reflection,
    String? highlightedText,
    List<String>? tags,
  }) {
    return PrayerEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      gospelQuote: gospelQuote ?? this.gospelQuote,
      reflection: reflection ?? this.reflection,
      highlightedText: highlightedText ?? this.highlightedText,
      tags: tags ?? this.tags,
    );
  }
}
