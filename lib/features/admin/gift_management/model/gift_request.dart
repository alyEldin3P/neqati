class GiftRequest {
  final String id;
  final String userId;
  final String giftId;
  final String status; // pending, approved, rejected
  final DateTime requestDate;
  final DateTime? updatedAt;
  final String? adminNotes;

  // Related data (from joins)
  final String? userName;
  final String? userPhone;
  final String? userEmail;
  final String? giftName;
  final int? giftPoints;

  GiftRequest({
    required this.id,
    required this.userId,
    required this.giftId,
    required this.status,
    required this.requestDate,
    this.updatedAt,
    this.adminNotes,
    this.userName,
    this.userPhone,
    this.userEmail,
    this.giftName,
    this.giftPoints,
  });

  // Create a GiftRequest from a Supabase response
  factory GiftRequest.fromSupabase(Map<String, dynamic> data) {
    // Handle nested user data
    final userData = data['users'] as Map<String, dynamic>?;
    final giftData = data['gifts'] as Map<String, dynamic>?;

    return GiftRequest(
      id: data['id'] as String? ?? '',
      userId: data['user_id'] as String? ?? '',
      giftId: data['gift_id'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
      requestDate:
          data['request_date'] != null
              ? DateTime.parse(data['request_date'])
              : DateTime.now(),
      updatedAt:
          data['updated_at'] != null
              ? DateTime.parse(data['updated_at'])
              : null,
      adminNotes: data['admin_notes'] as String?,
      userName: userData?['name'] as String?,
      userPhone: userData?['phone_number'] as String?,
      userEmail: userData?['email'] as String?,
      giftName: giftData?['name'] as String?,
      giftPoints: giftData?['points'] as int?,
    );
  }

  // Convert GiftRequest to a Map for Supabase
  Map<String, dynamic> toSupabase() {
    return {
      'user_id': userId,
      'gift_id': giftId,
      'status': status,
      'request_date': requestDate.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Create a copy of the GiftRequest with updated fields
  GiftRequest copyWith({
    String? status,
    DateTime? updatedAt,
    String? adminNotes,
  }) {
    return GiftRequest(
      id: id,
      userId: userId,
      giftId: giftId,
      status: status ?? this.status,
      requestDate: requestDate,
      updatedAt: updatedAt ?? this.updatedAt,
      adminNotes: adminNotes ?? this.adminNotes,
      userName: userName,
      userPhone: userPhone,
      userEmail: userEmail,
      giftName: giftName,
      giftPoints: giftPoints,
    );
  }

  // Helper methods
  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  String get statusDisplayName {
    switch (status) {
      case 'pending':
        return 'في الانتظار';
      case 'approved':
        return 'مقبول';
      case 'rejected':
        return 'مرفوض';
      default:
        return status;
    }
  }
}
