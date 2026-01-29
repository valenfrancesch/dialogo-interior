import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final DateTime createdAt;
  final int streak;
  final int totalEntries;

  AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.createdAt,
    this.streak = 0,
    this.totalEntries = 0,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      streak: data['streak'] as int? ?? 0,
      totalEntries: data['totalEntries'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'createdAt': Timestamp.fromDate(createdAt),
      'streak': streak,
      'totalEntries': totalEntries,
    };
  }

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    DateTime? createdAt,
    int? streak,
    int? totalEntries,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt ?? this.createdAt,
      streak: streak ?? this.streak,
      totalEntries: totalEntries ?? this.totalEntries,
    );
  }
}
