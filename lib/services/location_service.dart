import 'dart:async';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Position? _currentPosition;
  Position? get currentPosition => _currentPosition;

  StreamSubscription<Position>? _positionStreamSubscription;
  final StreamController<Position> _positionController = 
      StreamController<Position>.broadcast();
  Stream<Position> get positionStream => _positionController.stream;

  /// Check and request location permissions
  Future<bool> checkAndRequestPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are disabled, prompt user to enable
      return Future.error('Location services are disabled.');
    }

    // Check permission status
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are permanently denied
      return Future.error(
        'Location permissions are permanently denied. Please enable them in settings.',
      );
    }

    // Permissions granted
    return true;
  }

  /// Get current position once
  Future<Position?> getCurrentPosition() async {
    try {
      await checkAndRequestPermissions();

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Location request timed out');
        },
      );

      _currentPosition = position;
      return position;
    } catch (e) {
      print('Error getting current position: $e');
      rethrow; // Rethrow so UI can handle the error
    }
  }

  /// Start continuous location tracking
  Future<void> startLocationTracking() async {
    try {
      await checkAndRequestPermissions();

      // Stop existing stream if any
      await stopLocationTracking();

      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
        timeLimit: Duration(seconds: 30),
      );

      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) {
          _currentPosition = position;
          _positionController.add(position);
        },
        onError: (error) {
          print('Location tracking error: $error');
          _positionController.addError(error);
        },
        cancelOnError: false,
      );
    } catch (e) {
      print('Error starting location tracking: $e');
      rethrow;
    }
  }

  /// Stop location tracking
  Future<void> stopLocationTracking() async {
    await _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  /// Calculate distance between two coordinates in meters
  double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Check if current location is within range of target location
  bool isWithinRange(
    double currentLat,
    double currentLon,
    double targetLat,
    double targetLon,
    double radiusInMeters,
  ) {
    final distance = calculateDistance(
      currentLat,
      currentLon,
      targetLat,
      targetLon,
    );
    
    return distance <= radiusInMeters;
  }

  /// Get distance from current position to target
  double? getDistanceFromCurrent(double targetLat, double targetLon) {
    if (_currentPosition == null) return null;
    
    return calculateDistance(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      targetLat,
      targetLon,
    );
  }

  /// Dispose resources
  Future<void> dispose() async {
    await stopLocationTracking();
    await _positionController.close();
  }
}