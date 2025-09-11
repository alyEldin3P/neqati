import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String? name;
  final String? phoneNumber;
  final String? email;
  final bool isVerified;
  final bool isBlocked;
  final bool isAdmin;
  final int points;
  final String level;
  final DateTime? createdAt;

  AppUser({
    required this.id,
    this.name,
    this.phoneNumber,
    this.email,
    this.isVerified = false,
    this.isBlocked = false,
    this.isAdmin = false,
    this.points = 0,
    this.level = 'مبتدئ',
    this.createdAt,
  });

  factory AppUser.fromFirestore(Map<String, dynamic> data, String id) {
    return AppUser(
      id: id,
      name: data['name'] as String?,
      phoneNumber: data['phoneNumber'] as String?,
      email: data['email'] as String?,
      isVerified: data['isVerified'] as bool? ?? false,
      isBlocked: data['isBlocked'] as bool? ?? false,
      isAdmin: data['isAdmin'] as bool? ?? false,
      points: data['points'] as int? ?? 0,
      level: data['level'] as String? ?? 'مبتدئ',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'email': email,
      'isVerified': isVerified,
      'isBlocked': isBlocked,
      'isAdmin': isAdmin,
      'points': points,
      'level': level,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  AppUser copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? email,
    bool? isVerified,
    bool? isBlocked,
    bool? isAdmin,
    int? points,
    String? level,
    DateTime? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      isVerified: isVerified ?? this.isVerified,
      isBlocked: isBlocked ?? this.isBlocked,
      isAdmin: isAdmin ?? this.isAdmin,
      points: points ?? this.points,
      level: level ?? this.level,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
