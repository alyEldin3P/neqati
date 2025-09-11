
class Level {
  final String id;
  final String name;
  final String imageUrl;
  final int startingPoints;
  final double multiplier;

  Level({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.startingPoints,
    required this.multiplier,
  });

  factory Level.fromFirestore(Map<String, dynamic> data, String id) {
    return Level(
      id: id,
      name: data['name'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      startingPoints: data['startingPoints'] as int? ?? 0,
      multiplier: (data['multiplier'] is int)
          ? (data['multiplier'] as int).toDouble()
          : data['multiplier'] as double? ?? 1.0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'startingPoints': startingPoints,
      'multiplier': multiplier,
    };
  }

  @override
  String toString() {
    return 'Level(id: $id, name: $name, startingPoints: $startingPoints, multiplier: $multiplier)';
  }
}
