import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'dart:math';

part 'user.g.dart';

@HiveType(typeId: 6)
enum UserRole {
  @HiveField(0)
  admin,

  @HiveField(1)
  staff,
}

@HiveType(typeId: 7)
class User extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String email;

  @HiveField(3)
  final String phone;

  @HiveField(4)
  final UserRole role;

  @HiveField(5)
  final bool isActive;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final DateTime updatedAt;

  @HiveField(8)
  final String? profileImageUrl;

  @HiveField(9)
  final double? allowedLatitude;

  @HiveField(10)
  final double? allowedLongitude;

  @HiveField(11)
  final double? locationRadius; // in meters

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.profileImageUrl,
    this.allowedLatitude,
    this.allowedLongitude,
    this.locationRadius,
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? profileImageUrl,
    double? allowedLatitude,
    double? allowedLongitude,
    double? locationRadius,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      allowedLatitude: allowedLatitude ?? this.allowedLatitude,
      allowedLongitude: allowedLongitude ?? this.allowedLongitude,
      locationRadius: locationRadius ?? this.locationRadius,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.name,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'profileImageUrl': profileImageUrl,
      'allowedLatitude': allowedLatitude,
      'allowedLongitude': allowedLongitude,
      'locationRadius': locationRadius,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    final dynamic roleRaw = json['role'];
    final String roleName = roleRaw is String ? roleRaw : UserRole.staff.name;

    return User(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      phone: (json['phone'] as String?) ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == roleName,
        orElse: () => UserRole.staff,
      ),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
      profileImageUrl: json['profileImageUrl'] as String?,
      allowedLatitude: json['allowedLatitude'] != null
          ? (json['allowedLatitude'] as num).toDouble()
          : null,
      allowedLongitude: json['allowedLongitude'] != null
          ? (json['allowedLongitude'] as num).toDouble()
          : null,
      locationRadius: json['locationRadius'] != null
          ? (json['locationRadius'] as num).toDouble()
          : null,
    );
  }

  bool isWithinAllowedLocation(double latitude, double longitude) {
    if (allowedLatitude == null ||
        allowedLongitude == null ||
        locationRadius == null) {
      return false;
    }

    // Calculate distance using Haversine formula
    const double earthRadius = 6371000; // Earth's radius in meters
    final double lat1Rad = allowedLatitude! * (3.14159265359 / 180);
    final double lat2Rad = latitude * (3.14159265359 / 180);
    final double deltaLatRad = (latitude - allowedLatitude!) * (3.14159265359 / 180);
    final double deltaLonRad = (longitude - allowedLongitude!) * (3.14159265359 / 180);

    final double a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) *
            cos(lat2Rad) *
            sin(deltaLonRad / 2) *
            sin(deltaLonRad / 2);
    final double c = 2 * asin(sqrt(a));

    final double distance = earthRadius * c;

    return distance <= locationRadius!;
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        phone,
        role,
        isActive,
        createdAt,
        updatedAt,
        profileImageUrl,
        allowedLatitude,
        allowedLongitude,
        locationRadius,
      ];
}
