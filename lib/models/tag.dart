class Tag {
  final String id;
  final String name;
  final String emoji;

  Tag({
    required this.id,
    required this.name,
    required this.emoji,
  });

  // Predefined tags for the app
  static final List<Tag> defaultTags = [
    Tag(id: '1', name: 'Paz', emoji: '☮️'),
    Tag(id: '2', name: 'Gratitud', emoji: '🙏'),
    Tag(id: '3', name: 'Duda', emoji: '❓'),
    Tag(id: '4', name: 'Alegría', emoji: '😊'),
    Tag(id: '5', name: 'Esperanza', emoji: '✨'),
    Tag(id: '6', name: 'Amor', emoji: '❤️'),
  ];

  factory Tag.fromFirestore(Map<String, dynamic> json) {
    return Tag(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      emoji: json['emoji'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
    };
  }
}
