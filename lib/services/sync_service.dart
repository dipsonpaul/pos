import 'dart:async';
import 'firebase_service.dart';
import 'hive_service.dart';
import 'connectivity_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final ConnectivityService _connectivityService = ConnectivityService();
  StreamSubscription<bool>? _connectivitySubscription;
  Timer? _syncTimer;

  bool _isInitialized = false;

  Stream<bool> get connectionStream => _connectivityService.connectionStream;

  Future<void> init() async {
    if (_isInitialized) return;
    
    await _connectivityService.init();
    
    // Listen to connectivity changes
    _connectivitySubscription = _connectivityService.connectionStream.listen(
      (isOnline) {
        if (isOnline) {
          _startSync();
        } else {
          _stopSync();
        }
      },
    );

    // Check initial connectivity and sync if online
    if (_connectivityService.isOnline) {
      _startSync();
    }

    _isInitialized = true;
  }

  void _startSync() {
    // Sync immediately when connection is restored
    _syncAllData();
    
    // Set up periodic sync every 5 minutes
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _syncAllData();
    });
  }

  void _stopSync() {
    _syncTimer?.cancel();
  }

  Future<void> _syncAllData() async {
    try {
      await Future.wait([
        _syncProducts(),
        _syncSales(),
        _syncAttendance(),
        _syncUsers(),
      ]);
    } catch (e) {
      print('Sync failed: $e');
    }
  }

  // Sync Products
  Future<void> _syncProducts() async {
    try {
      // Download products from Firebase
      final firebaseProducts = await FirebaseService.getAllProducts();
      
      // Update local storage
      for (final product in firebaseProducts) {
        await HiveService.addProduct(product);
      }
    } catch (e) {
      print('Failed to sync products: $e');
    }
  }

  // Sync Sales
  Future<void> _syncSales() async {
    try {
      // Upload unsynced local sales to Firebase
      final unsyncedSales = HiveService.getUnsyncedSales();
      for (final sale in unsyncedSales) {
        try {
          await FirebaseService.addSale(sale);
          // Mark as synced
          final syncedSale = sale.copyWith(isSynced: true);
          await HiveService.updateSale(syncedSale);
        } catch (e) {
          print('Failed to sync sale ${sale.id}: $e');
        }
      }

      // Download recent sales from Firebase (last 30 days)
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final firebaseSales = await FirebaseService.getSales(startDate: thirtyDaysAgo);
      
      // Update local storage with recent sales
      for (final sale in firebaseSales) {
        await HiveService.addSale(sale);
      }
    } catch (e) {
      print('Failed to sync sales: $e');
    }
  }

  // Sync Attendance
  Future<void> _syncAttendance() async {
    try {
      // Upload unsynced local attendance to Firebase
      final unsyncedAttendance = HiveService.getUnsyncedAttendance();
      for (final attendance in unsyncedAttendance) {
        try {
          await FirebaseService.addAttendance(attendance);
          // Mark as synced
          final syncedAttendance = attendance.copyWith(isSynced: true);
          await HiveService.updateAttendance(syncedAttendance);
        } catch (e) {
          print('Failed to sync attendance ${attendance.id}: $e');
        }
      }

      // Download recent attendance from Firebase (last 30 days)
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final firebaseAttendance = await FirebaseService.getAttendance(startDate: thirtyDaysAgo);
      
      // Update local storage with recent attendance
      for (final attendance in firebaseAttendance) {
        await HiveService.addAttendance(attendance);
      }
    } catch (e) {
      print('Failed to sync attendance: $e');
    }
  }

  // Sync Users
  Future<void> _syncUsers() async {
    try {
      // Download users from Firebase
      final firebaseUsers = await FirebaseService.getAllUsers();
      
      // Update local storage
      for (final user in firebaseUsers) {
        await HiveService.addUser(user);
      }
    } catch (e) {
      print('Failed to sync users: $e');
    }
  }

  // Manual sync methods
  Future<void> syncProducts() async {
    if (_connectivityService.isOnline) {
      await _syncProducts();
    }
  }

  Future<void> syncSales() async {
    if (_connectivityService.isOnline) {
      await _syncSales();
    }
  }

  Future<void> syncAttendance() async {
    if (_connectivityService.isOnline) {
      await _syncAttendance();
    }
  }

  Future<void> syncUsers() async {
    if (_connectivityService.isOnline) {
      await _syncUsers();
    }
  }

  // Force sync all data
  Future<void> forceSyncAll() async {
    if (_connectivityService.isOnline) {
      await _syncAllData();
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
    _connectivityService.dispose();
  }
}
