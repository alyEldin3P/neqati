class Offer {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;

  Offer({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.startDate,
    required this.endDate,
    required this.isActive,
  });

  factory Offer.fromSupabase(Map<String, dynamic> data, String id) {
    return Offer(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['image_url'] ?? '',
      startDate: DateTime.parse(data['start_date']),
      endDate: DateTime.parse(data['end_date']),
      isActive: data['is_active'] ?? false,
    );
  }


  Map<String, dynamic> toSupabase() {
    return {
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'is_active': isActive,
    };
  }
}
