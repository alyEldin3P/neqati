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

  // Create a Offer from Supabase data
  factory Offer.fromSupabase(Map<String, dynamic> data) {
    return Offer(
      id: data['id']?.toString(),
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['image_url'] ?? '',
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'])
          : null,
    );
  }

  // Convert Offer to a Map for Supabase
  Map<String, dynamic> toSupabase() {
    return {
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'created_at': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
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
