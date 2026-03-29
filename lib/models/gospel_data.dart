class GospelData {
  final String firstReading;
  final String firstReadingReference;
  final String? firstReadingLongTitle; // Long title from reading_lt
  final String psalm;
  final String psalmReference;
  final String? psalmLongTitle; // Long title from reading_lt
  final String? secondReading;
  final String? secondReadingReference;
  final String? secondReadingLongTitle; // Long title from reading_lt
  final String? feast;
  final String title;
  final String? gospelLongTitle; // Long title from reading_lt for GSP
  final String evangeliumText;
  final String commentTitle;
  final String commentBody;
  final String commentAuthor;
  final String commentSource;
  final DateTime date;

  GospelData({
    required this.firstReading,
    required this.firstReadingReference,
    this.firstReadingLongTitle,
    required this.psalm,
    required this.psalmReference,
    this.psalmLongTitle,
    this.secondReading,
    this.secondReadingReference,
    this.secondReadingLongTitle,
    this.feast,
    required this.title,
    this.gospelLongTitle,
    required this.evangeliumText,
    required this.commentTitle,
    required this.commentBody,
    required this.commentAuthor,
    required this.commentSource,
    required this.date,
  });

  // Parse from API responses
  factory GospelData.fromApiResponses({
    required String firstReading,
    required String firstReadingReference,
    String? firstReadingLongTitle,
    required String psalm,
    required String psalmReference,
    String? psalmLongTitle,
    String? secondReading,
    String? secondReadingReference,
    String? secondReadingLongTitle,
    String? feast,
    required String title,
    String? gospelLongTitle,
    required String evangeliumText,
    required String commentTitle,
    required String commentBody,
    required String commentAuthor,
    required String commentSource,
    required DateTime date,
  }) {
    return GospelData(
      firstReading: firstReading,
      firstReadingReference: firstReadingReference,
      firstReadingLongTitle: firstReadingLongTitle,
      psalm: psalm,
      psalmReference: psalmReference,
      psalmLongTitle: psalmLongTitle,
      secondReading: secondReading,
      secondReadingReference: secondReadingReference,
      secondReadingLongTitle: secondReadingLongTitle,
      feast: feast,
      title: title,
      gospelLongTitle: gospelLongTitle,
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
      'first_reading': firstReading,
      'first_reading_reference': firstReadingReference,
      'psalm': psalm,
      'psalm_reference': psalmReference,
      'second_reading': secondReading,
      'second_reading_reference': secondReadingReference,
      'feast': feast,
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
      firstReading: json['first_reading'] ?? '',
      firstReadingReference: json['first_reading_reference'] ?? '',
      psalm: json['psalm'] ?? '',
      psalmReference: json['psalm_reference'] ?? '',
      secondReading: json['second_reading'],
      secondReadingReference: json['second_reading_reference'],
      feast: json['feast'],
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

