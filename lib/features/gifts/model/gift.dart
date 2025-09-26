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

  // Create a Gift from a Supabase response
  factory Gift.fromSupabase(Map<String, dynamic> data) {
    return Gift(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      points: data['points'] as int? ?? 0,
      stock: data['stock'] as int? ?? 0,
      imageUrl: data['image_url'] as String?,
      createdAt: data['created_at'] != null ? DateTime.parse(data['created_at']) : null,
    );
  }

  // Convert Gift to a Map for Supabase
  Map<String, dynamic> toSupabase() {
    return {
      'name': name,
      'points': points,
      'stock': stock,
      'image_url': imageUrl,
      'created_at': createdAt?.toIso8601String(),
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
