import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/attendance/attendance_bloc.dart';
import '../bloc/attendance/attendance_event.dart';
import '../bloc/attendance/attendance_state.dart';
import '../models/attendance.dart';
import '../models/user.dart';
import '../services/hive_service.dart';
import 'dart:math' show cos, sqrt, asin;

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<AttendanceBloc>().add(const LoadAttendanceHistory());
    context.read<AttendanceBloc>().add(const CheckLocationPermission());
    context.read<AttendanceBloc>().add(const GetCurrentLocation());
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  // Filter attendance history based on user role
  List<Attendance> _getFilteredAttendance(
    List<Attendance> history,
    User? currentUser,
  ) {
    if (currentUser == null) return [];

    // Admin sees all attendance records
    if (currentUser.role == UserRole.admin) {
      return history;
    }

    // Staff sees only their own attendance records
    return history
        .where((attendance) => attendance.staffId == currentUser.id)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<AttendanceBloc>().add(const LoadAttendanceHistory());
              context.read<AttendanceBloc>().add(const GetCurrentLocation());
            },
          ),
        ],
      ),
      body: BlocConsumer<AttendanceBloc, AttendanceState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          }
          if (state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage!),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        builder: (context, state) {
          final currentUser = HiveService.getCurrentUser();
          final filteredHistory = _getFilteredAttendance(
            state.attendanceHistory,
            currentUser,
          );

          return SingleChildScrollView(
            child: Column(
              children: [
                // Location status card (only for staff)
                if (currentUser?.role == UserRole.staff)
                  _buildLocationStatusCard(state),
                // Attendance actions (only for staff)
                if (currentUser?.role == UserRole.staff)
                  _buildAttendanceActions(state),
                // Attendance history (filtered based on role)
                _buildAttendanceHistory(state, filteredHistory, currentUser),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLocationStatusCard(AttendanceState state) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  state.canMarkAttendance
                      ? Icons.location_on
                      : Icons.location_off,
                  color: state.canMarkAttendance ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Location Status',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: state.canMarkAttendance ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              state.locationValidationMessage,
              style: TextStyle(
                color: state.canMarkAttendance ? Colors.green : Colors.red,
                fontSize: 12,
              ),
            ),
            if (state.currentPosition != null) ...[
              const SizedBox(height: 8),
              Text(
                'Current Location: ${state.currentPosition!.latitude.toStringAsFixed(6)}, ${state.currentPosition!.longitude.toStringAsFixed(6)}',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
            if (!state.hasLocationPermission) ...[
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () {
                  context.read<AttendanceBloc>().add(
                    const CheckLocationPermission(),
                  );
                },
                icon: const Icon(Icons.location_on),
                label: const Text('Enable Location'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Helper method to get today's attendance status
  AttendanceType? _getTodayLastAttendanceType(
    List<Attendance> history,
    String staffId,
  ) {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);

    // Filter today's attendance for the current user
    final todayAttendance =
        history.where((a) {
          final attendanceDate = DateTime(
            a.timestamp.year,
            a.timestamp.month,
            a.timestamp.day,
          );
          return a.staffId == staffId &&
              attendanceDate.isAtSameMomentAs(todayStart);
        }).toList();

    if (todayAttendance.isEmpty) return null;

    // Sort by timestamp descending to get the latest
    todayAttendance.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return todayAttendance.first.type;
  }

  Widget _buildAttendanceActions(AttendanceState state) {
    final currentUser = HiveService.getCurrentUser();
    if (currentUser == null) {
      return Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.person_off, size: 48, color: Colors.grey),
              const SizedBox(height: 8),
              const Text(
                'Please login to mark attendance',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    // Only staff can mark attendance; admins see history only
    if (currentUser.role == UserRole.admin) {
      return const SizedBox.shrink();
    }

    // Check if location configuration is missing
    if (currentUser.allowedLatitude == null ||
        currentUser.allowedLongitude == null ||
        currentUser.locationRadius == null) {
      return Card(
        margin: const EdgeInsets.all(16),
        color: Colors.orange.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.orange),
              const SizedBox(height: 8),
              const Text(
                'Location Configuration Missing',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please contact your administrator to set up your allowed location area.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    // Get today's last attendance type
    final lastAttendanceType = _getTodayLastAttendanceType(
      state.attendanceHistory,
      currentUser.id,
    );

    // Determine what action should be enabled
    final shouldEnableCheckIn =
        lastAttendanceType == null ||
        lastAttendanceType == AttendanceType.checkOut;
    final shouldEnableCheckOut = lastAttendanceType == AttendanceType.checkIn;

    // Validate user location
    bool isUserLocationValid = false;
    double? distanceInMeters;
    if (state.currentPosition != null) {
      isUserLocationValid = currentUser.isWithinAllowedLocation(
        state.currentPosition!.latitude,
        state.currentPosition!.longitude,
      );
      // Calculate distance for display
      distanceInMeters = _calculateDistance(
        state.currentPosition!.latitude,
        state.currentPosition!.longitude,
        currentUser.allowedLatitude!,
        currentUser.allowedLongitude!,
      );
    }

    // Check if we can mark attendance (location-wise)
    final canMarkLocation =
        state.canMarkAttendance &&
        isUserLocationValid &&
        !state.isLoading &&
        state.currentPosition != null;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mark Attendance',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                // Status indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        shouldEnableCheckOut
                            ? Colors.green.shade50
                            : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: shouldEnableCheckOut ? Colors.green : Colors.grey,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        shouldEnableCheckOut
                            ? Icons.check_circle
                            : Icons.schedule,
                        size: 16,
                        color:
                            shouldEnableCheckOut ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        shouldEnableCheckOut ? 'Checked In' : 'Not Checked In',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color:
                              shouldEnableCheckOut ? Colors.green : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Notes field
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        (canMarkLocation && shouldEnableCheckIn)
                            ? () => _markAttendance(
                              AttendanceType.checkIn,
                              currentUser,
                            )
                            : null,
                    icon: const Icon(Icons.login),
                    label: const Text('Check In'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        (canMarkLocation && shouldEnableCheckOut)
                            ? () => _markAttendance(
                              AttendanceType.checkOut,
                              currentUser,
                            )
                            : null,
                    icon: const Icon(Icons.logout),
                    label: const Text('Check Out'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),

            // Status messages
            const SizedBox(height: 12),

            // Sequence guidance message
            if (!shouldEnableCheckIn && !shouldEnableCheckOut) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'You have already checked out today. Check in again tomorrow.',
                        style: TextStyle(color: Colors.blue, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (shouldEnableCheckOut) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'You are checked in. Remember to check out when leaving.',
                        style: TextStyle(color: Colors.green, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (state.currentPosition == null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.orange,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Fetching your current location...',
                        style: TextStyle(color: Colors.orange, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (!isUserLocationValid) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Outside Allowed Area',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'You are ${distanceInMeters?.toStringAsFixed(0) ?? '?'} meters away from the allowed location. Please move within ${currentUser.locationRadius!.toStringAsFixed(0)}m radius.',
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (!state.hasLocationPermission) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_off,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Location permission required. Please enable location services.',
                        style: TextStyle(color: Colors.orange, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Calculate distance between two coordinates using Haversine formula
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a =
        0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742000 * asin(sqrt(a)); // 2 * R * 1000; R = 6371 km
  }

  Widget _buildAttendanceHistory(
    AttendanceState state,
    List<Attendance> filteredHistory,
    User? currentUser,
  ) {
    if (state.isLoading && filteredHistory.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (filteredHistory.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.history, size: 48, color: Colors.grey),
              const SizedBox(height: 8),
              Text(
                currentUser?.role == UserRole.admin
                    ? 'No attendance records found for any user'
                    : 'No attendance records found',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Attendance History',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (currentUser?.role == UserRole.admin)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.admin_panel_settings,
                        size: 14,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'All Users',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: filteredHistory.length,
          itemBuilder: (context, index) {
            final attendance = filteredHistory[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      attendance.type == AttendanceType.checkIn
                          ? Colors.green
                          : Colors.red,
                  child: Icon(
                    attendance.type == AttendanceType.checkIn
                        ? Icons.login
                        : Icons.logout,
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  '${attendance.type.name.toUpperCase()} - ${attendance.staffName}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      DateFormat(
                        'MMM dd, yyyy - HH:mm:ss',
                      ).format(attendance.timestamp),
                    ),
                    Text(
                      'Location: ${attendance.latitude.toStringAsFixed(4)}, ${attendance.longitude.toStringAsFixed(4)}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    if (attendance.notes != null &&
                        attendance.notes!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Notes: ${attendance.notes}',
                        style: const TextStyle(
                          fontStyle: FontStyle.italic,
                          fontSize: 11,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          attendance.isSynced
                              ? Icons.cloud_done
                              : Icons.cloud_off,
                          size: 14,
                          color:
                              attendance.isSynced
                                  ? Colors.green
                                  : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          attendance.isSynced ? 'Synced' : 'Pending Sync',
                          style: TextStyle(
                            color:
                                attendance.isSynced
                                    ? Colors.green
                                    : Colors.orange,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _markAttendance(AttendanceType type, User user) {
    context.read<AttendanceBloc>().add(
      MarkAttendance(
        staffId: user.id,
        staffName: user.name,
        type: type,
        notes:
            _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
      ),
    );

    // Clear notes after marking
    _notesController.clear();
  }
}
