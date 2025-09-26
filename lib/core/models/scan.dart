class Scan {
  final String id;
  final String userId;
  final String qrCodeId;
  final int pointsEarned;
  final DateTime scanDate;
  final String? branch;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Optional user data when joined with users table
  final Map<String, dynamic>? user;

  Scan({
    required this.id,
    required this.userId,
    required this.qrCodeId,
    required this.pointsEarned,
    required this.scanDate,
    this.branch,
    this.createdAt,
    this.updatedAt,
    this.user,
  });

  factory Scan.fromSupabase(Map<String, dynamic> data) {
    return Scan(
      id: data['id'] as String,
      userId: data['user_id'] as String,
      qrCodeId: data['qr_code_id'] as String,
      pointsEarned: data['points_earned'] as int? ?? 0,
      scanDate: DateTime.parse(data['scan_date'] as String),
      branch: data['branch'] as String?,
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'] as String)
          : null,
      updatedAt: data['updated_at'] != null
          ? DateTime.parse(data['updated_at'] as String)
          : null,
      user: data['users'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'user_id': userId,
      'qr_code_id': qrCodeId,
      'points_earned': pointsEarned,
      'scan_date': scanDate.toIso8601String(),
      'branch': branch,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Scan copyWith({
    String? id,
    String? userId,
    String? qrCodeId,
    int? pointsEarned,
    DateTime? scanDate,
    String? branch,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? user,
  }) {
    return Scan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      qrCodeId: qrCodeId ?? this.qrCodeId,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      scanDate: scanDate ?? this.scanDate,
      branch: branch ?? this.branch,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      user: user ?? this.user,
    );
  }

  // Helper methods for display
  String get userName => user?['name'] ?? 'مستخدم غير معروف';
  String get userPhone => user?['phone_number'] ?? '';
  
  String get formattedScanDate {
    return '${scanDate.day}/${scanDate.month}/${scanDate.year} - ${scanDate.hour}:${scanDate.minute.toString().padLeft(2, '0')}';
  }

  @override
  String toString() {
    return 'Scan{id: $id, userId: $userId, qrCodeId: $qrCodeId, pointsEarned: $pointsEarned, scanDate: $scanDate, branch: $branch}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Scan &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
