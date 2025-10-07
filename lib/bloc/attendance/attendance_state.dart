import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/attendance.dart';

class AttendanceState extends Equatable {
  final List<Attendance> attendanceHistory;
  final bool isLoading;
  final String? error;
  final String? successMessage;
  final Position? currentPosition;
  final bool hasLocationPermission;
  final bool isLocationServiceEnabled;
  final bool isLocationValid;
  final String locationValidationMessage;

  const AttendanceState({
    this.attendanceHistory = const [],
    this.isLoading = false,
    this.error,
    this.successMessage,
    this.currentPosition,
    this.hasLocationPermission = false,
    this.isLocationServiceEnabled = false,
    this.isLocationValid = false,
    this.locationValidationMessage = '',
  });

  AttendanceState copyWith({
    List<Attendance>? attendanceHistory,
    bool? isLoading,
    String? error,
    String? successMessage,
    Position? currentPosition,
    bool? hasLocationPermission,
    bool? isLocationServiceEnabled,
    bool? isLocationValid,
    String? locationValidationMessage,
  }) {
    return AttendanceState(
      attendanceHistory: attendanceHistory ?? this.attendanceHistory,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
      currentPosition: currentPosition ?? this.currentPosition,
      hasLocationPermission: hasLocationPermission ?? this.hasLocationPermission,
      isLocationServiceEnabled: isLocationServiceEnabled ?? this.isLocationServiceEnabled,
      isLocationValid: isLocationValid ?? this.isLocationValid,
      locationValidationMessage: locationValidationMessage ?? this.locationValidationMessage,
    );
  }

  bool get canMarkAttendance {
    return hasLocationPermission && 
           isLocationServiceEnabled && 
           isLocationValid && 
           currentPosition != null;
  }

  @override
  List<Object?> get props => [
        attendanceHistory,
        isLoading,
        error,
        successMessage,
        currentPosition,
        hasLocationPermission,
        isLocationServiceEnabled,
        isLocationValid,
        locationValidationMessage,
      ];
}
