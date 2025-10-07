import 'package:equatable/equatable.dart';
import '../../models/attendance.dart';

abstract class AttendanceEvent extends Equatable {
  const AttendanceEvent();

  @override
  List<Object?> get props => [];
}

class LoadAttendanceHistory extends AttendanceEvent {
  const LoadAttendanceHistory();
}

class MarkAttendance extends AttendanceEvent {
  final String staffId;
  final String staffName;
  final AttendanceType type;
  final String? notes;

  const MarkAttendance({
    required this.staffId,
    required this.staffName,
    required this.type,
    this.notes,
  });

  @override
  List<Object?> get props => [staffId, staffName, type, notes];
}

class CheckLocationPermission extends AttendanceEvent {
  const CheckLocationPermission();
}

class GetCurrentLocation extends AttendanceEvent {
  const GetCurrentLocation();
}

class ValidateLocation extends AttendanceEvent {
  final double latitude;
  final double longitude;
  final double allowedLatitude;
  final double allowedLongitude;
  final double radius;

  const ValidateLocation({
    required this.latitude,
    required this.longitude,
    required this.allowedLatitude,
    required this.allowedLongitude,
    required this.radius,
  });

  @override
  List<Object?> get props => [latitude, longitude, allowedLatitude, allowedLongitude, radius];
}

class ClearAttendanceHistory extends AttendanceEvent {
  const ClearAttendanceHistory();
}
