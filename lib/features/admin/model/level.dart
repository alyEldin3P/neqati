import 'package:cloud_firestore/cloud_firestore.dart';

class Level {
  final String id;
  final String name;
  final String imageUrl;
  final int startingPoints;
  final double multiplier;
  final DateTime? createdAt;

  Level({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.startingPoints,
    required this.multiplier,
    this.createdAt,
  });

  factory Level.fromFirestore(Map<String, dynamic> data, String id) {
    return Level(
      id: id,
      name: data['name'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      startingPoints: data['startingPoints'] ?? 0,
      multiplier: (data['multiplier'] ?? 1.0).toDouble(),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'startingPoints': startingPoints,
      'multiplier': multiplier,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  Level copyWith({
    String? name,
    String? imageUrl,
    int? startingPoints,
    double? multiplier,
  }) {
    return Level(
      id: id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      startingPoints: startingPoints ?? this.startingPoints,
      multiplier: multiplier ?? this.multiplier,
      createdAt: createdAt,
    );
  }
}
