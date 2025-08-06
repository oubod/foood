// lib/models/user_model.dart
class UserProfile {
  final String id;
  final String email;
  final String? fullName;
  final String? phone;
  final String role;
  final String? profileImageUrl;
  final DateTime? createdAt;
  final bool emailVerified;

  UserProfile({
    required this.id,
    required this.email,
    this.fullName,
    this.phone,
    required this.role,
    this.profileImageUrl,
    this.createdAt,
    this.emailVerified = false,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      email: map['email'] as String,
      fullName: map['full_name'] as String?,
      phone: map['phone'] as String?,
      role: map['role'] as String,
      profileImageUrl: map['profile_image_url'] as String?,
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at'] as String)
          : null,
      emailVerified: map['email_verified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'role': role,
      'profile_image_url': profileImageUrl,
      'created_at': createdAt?.toIso8601String(),
      'email_verified': emailVerified,
    };
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phone,
    String? role,
    String? profileImageUrl,
    DateTime? createdAt,
    bool? emailVerified,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      emailVerified: emailVerified ?? this.emailVerified,
    );
  }
}