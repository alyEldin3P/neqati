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

  factory Level.fromSupabase(Map<String, dynamic> data) {
    return Level(
      id: data['id']?.toString() ?? '',
      name: data['name'] ?? '',
      imageUrl: data['image_url'] ?? '',
      startingPoints: data['starting_points'] ?? 0,
      multiplier: (data['multiplier'] ?? 1.0).toDouble(),
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'name': name,
      'image_url': imageUrl,
      'starting_points': startingPoints,
      'multiplier': multiplier,
      'created_at': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
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
