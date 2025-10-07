import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../services/hive_service.dart';
import '../../services/firebase_service.dart';
import '../../services/location_service.dart';
import '../../models/attendance.dart';
import '../../models/user.dart';
import 'attendance_event.dart';
import 'attendance_state.dart';

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final LocationService _locationService = LocationService();
  final Uuid _uuid = const Uuid();

  AttendanceBloc() : super(const AttendanceState()) {
    on<LoadAttendanceHistory>(_onLoadAttendanceHistory);
    on<MarkAttendance>(_onMarkAttendance);
    on<CheckLocationPermission>(_onCheckLocationPermission);
    on<GetCurrentLocation>(_onGetCurrentLocation);
    on<ValidateLocation>(_onValidateLocation);
    on<ClearAttendanceHistory>(_onClearAttendanceHistory);
  }

  Future<void> _onLoadAttendanceHistory(
    LoadAttendanceHistory event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      final currentUser = HiveService.getCurrentUser();
      List<Attendance> attendanceHistory = HiveService.getAllAttendance();
      // If staff, show only their own attendance
      if (currentUser != null && currentUser.role == UserRole.staff) {
        attendanceHistory = attendanceHistory
            .where((a) => a.staffId == currentUser.id)
            .toList();
      }
      // Sort by most recent first
      attendanceHistory.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      emit(state.copyWith(
        attendanceHistory: attendanceHistory,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to load attendance history: $e',
      ));
    }
  }

  Future<void> _onMarkAttendance(
    MarkAttendance event,
    Emitter<AttendanceState> emit,
  ) async {
    if (!state.canMarkAttendance || state.currentPosition == null) {
      emit(state.copyWith(
        error: 'Cannot mark attendance: Location not valid',
      ));
      return;
    }

    emit(state.copyWith(isLoading: true, error: null));

    try {
      final attendanceId = _uuid.v4();
      final now = DateTime.now();

      final attendance = Attendance(
        id: attendanceId,
        staffId: event.staffId,
        staffName: event.staffName,
        type: event.type,
        latitude: state.currentPosition!.latitude,
        longitude: state.currentPosition!.longitude,
        timestamp: now,
        notes: event.notes,
        isSynced: false,
      );

      // Save to local storage first
      await HiveService.addAttendance(attendance);

      // Try to sync to Firebase if online
      try {
        await FirebaseService.addAttendance(attendance);
        // Update as synced
        final syncedAttendance = attendance.copyWith(isSynced: true);
        await HiveService.updateAttendance(syncedAttendance);
      } catch (e) {
        print('Failed to sync attendance to Firebase: $e');
      }

      // Reload attendance history
      final updatedHistory = HiveService.getAllAttendance();

      emit(state.copyWith(
        isLoading: false,
        successMessage: '${event.type.name.toUpperCase()} marked successfully!',
        attendanceHistory: updatedHistory,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to mark attendance: $e',
      ));
    }
  }

  Future<void> _onCheckLocationPermission(
    CheckLocationPermission event,
    Emitter<AttendanceState> emit,
  ) async {
    try {
      // Use the new method from LocationService
      await _locationService.checkAndRequestPermissions();

      emit(state.copyWith(
        hasLocationPermission: true,
        isLocationServiceEnabled: true,
        locationValidationMessage: 'Location services are ready',
      ));
    } catch (e) {
      // Permission check failed - parse the error message
      final errorMessage = e.toString();
      final isServiceDisabled = errorMessage.contains('disabled');
      final isPermissionDenied = errorMessage.contains('denied');

      emit(state.copyWith(
        hasLocationPermission: !isPermissionDenied,
        isLocationServiceEnabled: !isServiceDisabled,
        locationValidationMessage: errorMessage,
        error: errorMessage,
      ));
    }
  }

  Future<void> _onGetCurrentLocation(
    GetCurrentLocation event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      final position = await _locationService.getCurrentPosition();

      if (position != null) {
        // Determine if within allowed area based on current user config
        final currentUser = HiveService.getCurrentUser();
        bool isValid = false;
        String validationMessage = 'Location acquired successfully';

        if (currentUser != null &&
            currentUser.allowedLatitude != null &&
            currentUser.allowedLongitude != null &&
            currentUser.locationRadius != null) {
          final distance = _locationService.calculateDistance(
            position.latitude,
            position.longitude,
            currentUser.allowedLatitude!,
            currentUser.allowedLongitude!,
          );
          isValid = distance <= currentUser.locationRadius!;
          validationMessage = isValid
              ? 'You are within the allowed area (${distance.toStringAsFixed(1)}m from center)'
              : 'You are outside the allowed area (${distance.toStringAsFixed(1)}m away, maximum allowed: ${currentUser.locationRadius}m)';
        } else {
          validationMessage = 'Location configuration missing for user';
        }

        emit(state.copyWith(
          currentPosition: position,
          isLocationValid: isValid,
          isLoading: false,
          locationValidationMessage: validationMessage,
        ));
      } else {
        emit(state.copyWith(
          isLoading: false,
          error: 'Failed to get current location',
        ));
      }
    } catch (e) {
      final errorMessage = e.toString();
      emit(state.copyWith(
        isLoading: false,
        error: 'Location error: $errorMessage',
        hasLocationPermission: !errorMessage.contains('permission'),
        isLocationServiceEnabled: !errorMessage.contains('disabled'),
      ));
    }
  }

  void _onValidateLocation(
    ValidateLocation event,
    Emitter<AttendanceState> emit,
  ) {
    try {
      if (state.currentPosition == null) {
        emit(state.copyWith(
          isLocationValid: false,
          locationValidationMessage: 'Current location not available',
        ));
        return;
      }

      final distance = _locationService.calculateDistance(
        state.currentPosition!.latitude,
        state.currentPosition!.longitude,
        event.allowedLatitude,
        event.allowedLongitude,
      );

      final isValid = distance <= event.radius;

      emit(state.copyWith(
        isLocationValid: isValid,
        locationValidationMessage: isValid
            ? 'You are within the allowed area (${distance.toStringAsFixed(1)}m from center)'
            : 'You are outside the allowed area (${distance.toStringAsFixed(1)}m away, maximum allowed: ${event.radius}m)',
      ));
    } catch (e) {
      emit(state.copyWith(
        isLocationValid: false,
        locationValidationMessage: 'Failed to validate location: $e',
      ));
    }
  }

  void _onClearAttendanceHistory(
    ClearAttendanceHistory event,
    Emitter<AttendanceState> emit,
  ) {
    emit(state.copyWith(
      attendanceHistory: const [],
      successMessage: 'Attendance history cleared',
    ));
  }

  /// Validate if user is within their allowed location
  bool validateUserLocation(User user) {
    if (state.currentPosition == null ||
        user.allowedLatitude == null ||
        user.allowedLongitude == null ||
        user.locationRadius == null) {
      return false;
    }

    return user.isWithinAllowedLocation(
      state.currentPosition!.latitude,
      state.currentPosition!.longitude,
    );
  }

  @override
  Future<void> close() {
    _locationService.dispose();
    return super.close();
  }
}