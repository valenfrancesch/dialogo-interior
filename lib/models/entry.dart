import 'package:cloud_firestore/cloud_firestore.dart';

class Entry {
  final String id;
  final String userId;
  final String passage; // e.g., "Juan 3:16-21"
  final String reflection;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> highlights; // For storing highlighted text

  Entry({
    required this.id,
    required this.userId,
    required this.passage,
    required this.reflection,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
    this.highlights = const {},
  });

  factory Entry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Entry(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      passage: data['passage'] as String? ?? '',
      reflection: data['reflection'] as String? ?? '',
      tags: List<String>.from(data['tags'] as List<dynamic>? ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      highlights: data['highlights'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'passage': passage,
      'reflection': reflection,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'highlights': highlights,
    };
  }

  Entry copyWith({
    String? id,
    String? userId,
    String? passage,
    String? reflection,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? highlights,
  }) {
    return Entry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      passage: passage ?? this.passage,
      reflection: reflection ?? this.reflection,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      highlights: highlights ?? this.highlights,
    );
  }
}
