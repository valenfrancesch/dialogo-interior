import 'package:cloud_firestore/cloud_firestore.dart';

class Highlight {
  final String text;
  final String source;
  final String title;

  Highlight({
    required this.text,
    required this.source,
    required this.title,
  });

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'source': source,
      'title': title,
    };
  }

  factory Highlight.fromMap(Map<String, dynamic> map) {
    return Highlight(
      text: map['text'] as String? ?? '',
      source: map['source'] as String? ?? '',
      title: map['title'] as String? ?? '',
    );
  }
}

class PrayerEntry {
  final String? id;
  final String userId;
  final DateTime date;
  final String gospelQuote; // Cita bíblica (ej: "Juan 3:16-21")
  final String reflection; // Texto de reflexión del usuario
  final String? highlightedText; // Texto destacado del pasaje (Legacy)
  final List<Highlight>? highlights; // Lista de textos destacados
  final String? purpose; // Propósito del día

  PrayerEntry({
    this.id,
    required this.userId,
    required this.date,
    required this.gospelQuote,
    required this.reflection,
    this.highlightedText,
    this.highlights,
    this.purpose,
  });

  /// Convierte un documento de Firestore a PrayerEntry
  factory PrayerEntry.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    
    List<Highlight>? parsedHighlights;
    if (data['highlights'] != null) {
      final list = data['highlights'] as List<dynamic>;
      parsedHighlights = list.map((e) => Highlight.fromMap(e as Map<String, dynamic>)).toList();
    }

    // Fallback logic for backward compatibility
    if ((parsedHighlights == null || parsedHighlights.isEmpty) && 
        data['highlightedText'] != null && 
        data['highlightedText'].toString().isNotEmpty) {
      parsedHighlights = [
        Highlight(
          text: data['highlightedText'],
          source: 'Evangelio',
          title: '',
        )
      ];
    }

    return PrayerEntry(
      id: doc.id,
      userId: data['userId'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      gospelQuote: data['gospelQuote'] ?? '',
      reflection: data['reflection'] ?? '',
      highlightedText: data['highlightedText'],
      highlights: parsedHighlights,
      purpose: data['purpose'],
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
      'highlights': highlights?.map((h) => h.toMap()).toList(),
      'purpose': purpose,
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
    List<Highlight>? highlights,
    String? purpose,
  }) {
    return PrayerEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      gospelQuote: gospelQuote ?? this.gospelQuote,
      reflection: reflection ?? this.reflection,
      highlightedText: highlightedText ?? this.highlightedText,
      highlights: highlights ?? this.highlights,
      purpose: purpose ?? this.purpose,
    );
  }
}
