import 'package:cloud_firestore/cloud_firestore.dart';

class Offer {
  final String? id;
  final String title;
  final String description;
  final String imageUrl;
  final DateTime? createdAt;

  Offer({
    this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    this.createdAt,
  });

  // Create a Offer from Firestore data
  factory Offer.fromFirestore(Map<String, dynamic> data, String docId) {
    return Offer(
      id: docId,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Convert Offer to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  // Create a copy of this Offer with the given fields replaced with new values
  Offer copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    DateTime? createdAt,
  }) {
    return Offer(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
