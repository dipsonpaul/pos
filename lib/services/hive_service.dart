import 'package:hive_flutter/hive_flutter.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../models/attendance.dart';
import '../models/user.dart';

class HiveService {
  static const String _productsBox = 'products';
  static const String _salesBox = 'sales';
  static const String _attendanceBox = 'attendance';
  static const String _usersBox = 'users';
  static const String _settingsBox = 'settings';

  static late Box<Product> _products;
  static late Box<Sale> _sales;
  static late Box<Attendance> _attendance;
  static late Box<User> _users;
  static late Box _settings;

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(ProductAdapter());
    Hive.registerAdapter(SaleAdapter());
    Hive.registerAdapter(SaleItemAdapter());
    Hive.registerAdapter(PaymentMethodAdapter());
    Hive.registerAdapter(AttendanceAdapter());
    Hive.registerAdapter(AttendanceTypeAdapter());
    Hive.registerAdapter(UserAdapter());
    Hive.registerAdapter(UserRoleAdapter());

    // Open boxes
    _products = await Hive.openBox<Product>(_productsBox);
    _sales = await Hive.openBox<Sale>(_salesBox);
    _attendance = await Hive.openBox<Attendance>(_attendanceBox);
    _users = await Hive.openBox<User>(_usersBox);
    _settings = await Hive.openBox(_settingsBox);
  }

  // Products
  static Box<Product> get products => _products;
  
  static Future<void> addProduct(Product product) async {
    await _products.put(product.id, product);
  }

  static Future<void> updateProduct(Product product) async {
    await _products.put(product.id, product);
  }

  static Future<void> deleteProduct(String productId) async {
    await _products.delete(productId);
  }

  static Product? getProduct(String productId) {
    return _products.get(productId);
  }

  static List<Product> getAllProducts() {
    return _products.values.toList();
  }

  static List<Product> getProductsByCategory(String category) {
    return _products.values
        .where((product) => product.category == category)
        .toList();
  }

  // Sales
  static Box<Sale> get sales => _sales;

  static Future<void> addSale(Sale sale) async {
    await _sales.put(sale.id, sale);
  }

  static Future<void> updateSale(Sale sale) async {
    await _sales.put(sale.id, sale);
  }

  static Future<void> deleteSale(String saleId) async {
    await _sales.delete(saleId);
  }

  static Sale? getSale(String saleId) {
    return _sales.get(saleId);
  }

  static List<Sale> getAllSales() {
    return _sales.values.toList();
  }

  static List<Sale> getUnsyncedSales() {
    return _sales.values.where((sale) => !sale.isSynced).toList();
  }

  // Attendance
  static Box<Attendance> get attendance => _attendance;

  static Future<void> addAttendance(Attendance attendance) async {
    await _attendance.put(attendance.id, attendance);
  }

  static Future<void> updateAttendance(Attendance attendance) async {
    await _attendance.put(attendance.id, attendance);
  }

  static Future<void> deleteAttendance(String attendanceId) async {
    await _attendance.delete(attendanceId);
  }

  static Attendance? getAttendance(String attendanceId) {
    return _attendance.get(attendanceId);
  }

  static List<Attendance> getAllAttendance() {
    return _attendance.values.toList();
  }

  static List<Attendance> getUnsyncedAttendance() {
    return _attendance.values.where((attendance) => !attendance.isSynced).toList();
  }

  // Users
  static Box<User> get users => _users;

  static Future<void> addUser(User user) async {
    await _users.put(user.id, user);
  }

  static Future<void> updateUser(User user) async {
    await _users.put(user.id, user);
  }

  static Future<void> deleteUser(String userId) async {
    await _users.delete(userId);
  }

  static User? getUser(String userId) {
    return _users.get(userId);
  }

  static List<User> getAllUsers() {
    return _users.values.toList();
  }

  static User? getCurrentUser() {
    final userId = _settings.get('currentUserId');
    if (userId != null) {
      return _users.get(userId);
    }
    return null;
  }

  static Future<void> setCurrentUser(String userId) async {
    await _settings.put('currentUserId', userId);
  }

  static Future<void> clearCurrentUser() async {
    await _settings.delete('currentUserId');
  }

  // Settings
  static Future<void> setSetting(String key, dynamic value) async {
    await _settings.put(key, value);
  }

  static T? getSetting<T>(String key) {
    return _settings.get(key) as T?;
  }

  static Future<void> removeSetting(String key) async {
    await _settings.delete(key);
  }

  // Clear all data
  static Future<void> clearAllData() async {
    await _products.clear();
    await _sales.clear();
    await _attendance.clear();
    await _users.clear();
    await _settings.clear();
  }

  // Close all boxes
  static Future<void> close() async {
    await _products.close();
    await _sales.close();
    await _attendance.close();
    await _users.close();
    await _settings.close();
  }
}
