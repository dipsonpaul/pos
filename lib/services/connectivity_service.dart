import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  bool _isOnline = false;
  bool get isOnline => _isOnline;

  final StreamController<bool> _connectionController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connectionController.stream;

  Future<void> init() async {
    // Check initial connectivity
    final result = await _connectivity.checkConnectivity();
    _updateConnectionStatus(result);

    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
      onError: (error) {
        _isOnline = false;
        _connectionController.add(false);
      },
    );
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final isConnected = results.any((result) => 
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet);
    
    if (_isOnline != isConnected) {
      _isOnline = isConnected;
      _connectionController.add(_isOnline);
    }
  }

  Future<bool> checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      final isConnected = result.any((r) => 
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.ethernet);
      
      _isOnline = isConnected;
      return isConnected;
    } catch (e) {
      _isOnline = false;
      return false;
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _connectionController.close();
  }
}
