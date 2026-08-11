class AppUser {
  final String id;
  final String? name;
  final String? phoneNumber;
  final String? email;
  final String? nationalId;
  final String? address;
  final bool isVerified;
  final bool isBlocked;
  final bool isAdmin;
  final bool isApproved;
  final int points;
  final String level;
  final String? position;
  final DateTime? createdAt;
  final String? deviceToken;

  AppUser({
    required this.id,
    this.name,
    this.phoneNumber,
    this.email,
    this.nationalId,
    this.address,
    this.isVerified = false,
    this.isBlocked = false,
    this.isAdmin = false,
    this.isApproved = false,
    this.points = 0,
    this.level = 'مبتدئ',
    this.position,
    this.createdAt,
    this.deviceToken,
  });

  factory AppUser.fromSupabase(Map<String, dynamic> data, String id) {
    return AppUser(
      id: id,
      name: data['name'] as String?,
      phoneNumber: data['phone_number'] as String?,
      email: data['email'] as String?,
      nationalId: data['national_id'] as String?,
      address: data['address'] as String?,
      isVerified: data['is_verified'] as bool? ?? false,
      isBlocked: data['is_blocked'] as bool? ?? false,
      isAdmin: data['is_admin'] as bool? ?? false,
      isApproved: data['is_approved'] as bool? ?? false,
      points: data['points'] as int? ?? 0,
      level: data['level'] as String? ?? 'مبتدئ',
      position: data['position'] as String?,
      createdAt:
          data['created_at'] != null
              ? DateTime.parse(data['created_at'] as String)
              : null,
      deviceToken: data['device_token'] as String?,
    );
  }


  Map<String, dynamic> toSupabase() {
    return {
      'name': name,
      'phone_number': phoneNumber,
      'email': email,
      'national_id': nationalId,
      'address': address,
      'is_verified': isVerified,
      'is_blocked': isBlocked,
      'is_admin': isAdmin,
      'is_approved': isApproved,
      'points': points,
      'level': level,
      'position': position,
      'created_at': createdAt?.toIso8601String(),
      'device_token': deviceToken,
    };
  }

  AppUser copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? email,
    String? nationalId,
    String? address,
    bool? isVerified,
    bool? isBlocked,
    bool? isAdmin,
    bool? isApproved,
    int? points,
    String? level,
    String? position,
    DateTime? createdAt,
    String? deviceToken,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      nationalId: nationalId ?? this.nationalId,
      address: address ?? this.address,
      isVerified: isVerified ?? this.isVerified,
      isBlocked: isBlocked ?? this.isBlocked,
      isAdmin: isAdmin ?? this.isAdmin,
      isApproved: isApproved ?? this.isApproved,
      points: points ?? this.points,
      level: level ?? this.level,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
      deviceToken: deviceToken ?? this.deviceToken,
    );
  }
}
