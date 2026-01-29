import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String surname;
  final String country;
  final String province;
  final DateTime birthDate;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.surname,
    required this.country,
    required this.province,
    required this.birthDate,
    required this.createdAt,
  });

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'surname': surname,
      'country': country,
      'province': province,
      'birthDate': Timestamp.fromDate(birthDate),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      surname: data['surname'] ?? '',
      country: data['country'] ?? '',
      province: data['province'] ?? '',
      birthDate: (data['birthDate'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Get full name
  String get fullName => '$name $surname';
}
