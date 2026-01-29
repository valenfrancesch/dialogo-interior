class GospelData {
  final String title; // Ej: "Juan 3:16-21"
  final String evangeliumText; // Texto completo del evangelio
  final String commentTitle; // Título del comentario
  final String commentBody; // Cuerpo del comentario
  final String commentAuthor; // Autor (Ej: San Agustín)
  final String commentSource; // Referencia/Fuente
  final DateTime date;

  GospelData({
    required this.title,
    required this.evangeliumText,
    required this.commentTitle,
    required this.commentBody,
    required this.commentAuthor,
    required this.commentSource,
    required this.date,
  });

  // Parse from API responses
  factory GospelData.fromApiResponses({
    required String title,
    required String evangeliumText,
    required String commentTitle,
    required String commentBody,
    required String commentAuthor,
    required String commentSource,
    required DateTime date,
  }) {
    return GospelData(
      title: title,
      evangeliumText: evangeliumText,
      commentTitle: commentTitle,
      commentBody: commentBody,
      commentAuthor: commentAuthor,
      commentSource: commentSource,
      date: date,
    );
  }

  // Convert to JSON for Firebase storage
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'evangelium_text': evangeliumText,
      'comment_title': commentTitle,
      'comment_body': commentBody,
      'comment_author': commentAuthor,
      'comment_source': commentSource,
      'date': date.toIso8601String(),
    };
  }

  // Create from JSON (Firebase)
  factory GospelData.fromFirebase(Map<String, dynamic> json) {
    return GospelData(
      title: json['title'] ?? '',
      evangeliumText: json['evangelium_text'] ?? '',
      commentTitle: json['comment_title'] ?? '',
      commentBody: json['comment_body'] ?? '',
      commentAuthor: json['comment_author'] ?? '',
      commentSource: json['comment_source'] ?? '',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
    );
  }
}

