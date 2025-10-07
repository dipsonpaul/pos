import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

part 'attendance.g.dart';

@HiveType(typeId: 4)
enum AttendanceType {
  @HiveField(0)
  checkIn,

  @HiveField(1)
  checkOut,
}

@HiveType(typeId: 5)
class Attendance extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String staffId;

  @HiveField(2)
  final String staffName;

  @HiveField(3)
  final AttendanceType type;

  @HiveField(4)
  final double latitude;

  @HiveField(5)
  final double longitude;

  @HiveField(6)
  final DateTime timestamp;

  @HiveField(7)
  final String? notes;

  @HiveField(8)
  final bool isSynced;

  @HiveField(9)
  final String? imageUrl;

  const Attendance({
    required this.id,
    required this.staffId,
    required this.staffName,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.notes,
    this.isSynced = false,
    this.imageUrl,
  });

  Attendance copyWith({
    String? id,
    String? staffId,
    String? staffName,
    AttendanceType? type,
    double? latitude,
    double? longitude,
    DateTime? timestamp,
    String? notes,
    bool? isSynced,
    String? imageUrl,
  }) {
    return Attendance(
      id: id ?? this.id,
      staffId: staffId ?? this.staffId,
      staffName: staffName ?? this.staffName,
      type: type ?? this.type,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timestamp: timestamp ?? this.timestamp,
      notes: notes ?? this.notes,
      isSynced: isSynced ?? this.isSynced,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'staffId': staffId,
      'staffName': staffName,
      'type': type.name,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'notes': notes,
      'isSynced': isSynced,
      'imageUrl': imageUrl,
    };
  }

  factory Attendance.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    final String typeName = (json['type'] as String?) ?? AttendanceType.checkIn.name;

    return Attendance(
      id: (json['id'] as String?) ?? '',
      staffId: (json['staffId'] as String?) ?? '',
      staffName: (json['staffName'] as String?) ?? '',
      type: AttendanceType.values.firstWhere(
        (e) => e.name == typeName,
        orElse: () => AttendanceType.checkIn,
      ),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      timestamp: parseDate(json['timestamp']),
      notes: json['notes'] as String?,
      isSynced: json['isSynced'] as bool? ?? false,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        staffId,
        staffName,
        type,
        latitude,
        longitude,
        timestamp,
        notes,
        isSynced,
        imageUrl,
      ];
}
