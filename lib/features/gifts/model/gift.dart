import 'package:cloud_firestore/cloud_firestore.dart';

class Gift {
  final String id;
  final String name;
  final int points;
  final int stock;
  final String? imageUrl;
  final DateTime? createdAt;

  Gift({
    required this.id,
    required this.name,
    required this.points,
    required this.stock,
    this.imageUrl,
    this.createdAt,
  });

  // Create a Gift from a Firestore document
  factory Gift.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Gift(
      id: doc.id,
      name: data['name'] as String? ?? '',
      points: data['points'] as int? ?? 0,
      stock: data['stock'] as int? ?? 0,
      imageUrl: data['imageUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  // Convert Gift to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'points': points,
      'stock': stock,
      'imageUrl': imageUrl,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  // Create a copy of the Gift with updated fields
  Gift copyWith({
    String? name,
    int? points,
    int? stock,
    String? imageUrl,
  }) {
    return Gift(
      id: id,
      name: name ?? this.name,
      points: points ?? this.points,
      stock: stock ?? this.stock,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt,
    );
  }
}
