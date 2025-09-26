class AdminStats {
  final int totalUsers;
  final int totalPendingUsers;
  final int totalScans;
  final int totalQrCodes;
  final int totalGifts;
  final int totalOffers;
  final int totalPendingGiftRequests;

  AdminStats({
    required this.totalUsers,
    required this.totalPendingUsers,
    required this.totalScans,
    required this.totalQrCodes,
    required this.totalGifts,
    required this.totalOffers,
    required this.totalPendingGiftRequests,
  });

  factory AdminStats.initial() {
    return AdminStats(
      totalUsers: 0,
      totalPendingUsers: 0,
      totalScans: 0,
      totalQrCodes: 0,
      totalGifts: 0,
      totalOffers: 0,
      totalPendingGiftRequests: 0,
    );
  }

  factory AdminStats.fromSupabase(Map<String, dynamic> stats) {
    return AdminStats(
      totalUsers: stats['totalUsers'] ?? 0,
      totalPendingUsers: stats['totalPendingUsers'] ?? 0,
      totalScans: stats['totalScans'] ?? 0,
      totalQrCodes: stats['totalQrCodes'] ?? 0,
      totalGifts: stats['totalGifts'] ?? 0,
      totalOffers: stats['totalOffers'] ?? 0,
      totalPendingGiftRequests: stats['totalPendingGiftRequests'] ?? 0,
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'totalUsers': totalUsers,
      'totalPendingUsers': totalPendingUsers,
      'totalScans': totalScans,
      'totalQrCodes': totalQrCodes,
      'totalGifts': totalGifts,
      'totalOffers': totalOffers,
      'totalPendingGiftRequests': totalPendingGiftRequests,
    };
  }

  AdminStats copyWith({
    int? totalUsers,
    int? totalPendingUsers,
    int? totalScans,
    int? totalQrCodes,
    int? totalGifts,
    int? totalOffers,
    int? totalPendingGiftRequests,
  }) {
    return AdminStats(
      totalUsers: totalUsers ?? this.totalUsers,
      totalPendingUsers: totalPendingUsers ?? this.totalPendingUsers,
      totalScans: totalScans ?? this.totalScans,
      totalQrCodes: totalQrCodes ?? this.totalQrCodes,
      totalGifts: totalGifts ?? this.totalGifts,
      totalOffers: totalOffers ?? this.totalOffers,
      totalPendingGiftRequests:
          totalPendingGiftRequests ?? this.totalPendingGiftRequests,
    );
  }
}
