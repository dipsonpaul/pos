import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/product.dart';
import '../models/sale.dart';
import '../models/attendance.dart';
import '../models/user.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  // Collections
  static const String _productsCollection = 'products';
  static const String _salesCollection = 'sales';
  static const String _attendanceCollection = 'attendance';
  static const String _usersCollection = 'users';

  // Authentication
  static firebase_auth.User? get currentUser => _auth.currentUser;

  static Future<firebase_auth.UserCredential?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  static Future<firebase_auth.UserCredential?> createUserWithEmailAndPassword(
      String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } catch (e) {
      throw Exception('User creation failed: $e');
    }
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }

  // Products
  static Future<void> addProduct(Product product) async {
    try {
      await _firestore
          .collection(_productsCollection)
          .doc(product.id)
          .set(product.toJson());
    } catch (e) {
      throw Exception('Failed to add product: $e');
    }
  }

  static Future<void> updateProduct(Product product) async {
    try {
      await _firestore
          .collection(_productsCollection)
          .doc(product.id)
          .update(product.toJson());
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  static Future<void> deleteProduct(String productId) async {
    try {
      await _firestore
          .collection(_productsCollection)
          .doc(productId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  static Future<Product?> getProduct(String productId) async {
    try {
      final doc = await _firestore
          .collection(_productsCollection)
          .doc(productId)
          .get();
      
      if (doc.exists && doc.data() != null) {
        final data = Map<String, dynamic>.from(doc.data()!);
        data['id'] = data['id'] ?? doc.id;
        return Product.fromJson(data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get product: $e');
    }
  }

  static Stream<List<Product>> getProductsStream() {
    return _firestore
        .collection(_productsCollection)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = Map<String, dynamic>.from(doc.data());
              data['id'] = data['id'] ?? doc.id;
              return Product.fromJson(data);
            }).toList());
  }

  static Future<List<Product>> getAllProducts() async {
    try {
      final snapshot = await _firestore
          .collection(_productsCollection)
          .where('isActive', isEqualTo: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = data['id'] ?? doc.id;
        return Product.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get products: $e');
    }
  }

  // Sales
  static Future<void> addSale(Sale sale) async {
    try {
      await _firestore
          .collection(_salesCollection)
          .doc(sale.id)
          .set(sale.toJson());
    } catch (e) {
      throw Exception('Failed to add sale: $e');
    }
  }

  static Future<void> updateSale(Sale sale) async {
    try {
      await _firestore
          .collection(_salesCollection)
          .doc(sale.id)
          .update(sale.toJson());
    } catch (e) {
      throw Exception('Failed to update sale: $e');
    }
  }

  static Future<void> deleteSale(String saleId) async {
    try {
      await _firestore
          .collection(_salesCollection)
          .doc(saleId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete sale: $e');
    }
  }

  static Stream<List<Sale>> getSalesStream() {
    return _firestore
        .collection(_salesCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = Map<String, dynamic>.from(doc.data());
              data['id'] = data['id'] ?? doc.id;
              return Sale.fromJson(data);
            }).toList());
  }

  static Future<List<Sale>> getSales({
    DateTime? startDate,
    DateTime? endDate,
    String? staffId,
  }) async {
    try {
      Query query = _firestore
          .collection(_salesCollection)
          .orderBy('createdAt', descending: true);

      if (startDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: startDate);
      }

      if (endDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: endDate);
      }

      if (staffId != null) {
        query = query.where('staffId', isEqualTo: staffId);
      }

      final snapshot = await query.limit(100).get();
      
      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
        data['id'] = data['id'] ?? doc.id;
        return Sale.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get sales: $e');
    }
  }

  // Attendance
  static Future<void> addAttendance(Attendance attendance) async {
    try {
      await _firestore
          .collection(_attendanceCollection)
          .doc(attendance.id)
          .set(attendance.toJson());
    } catch (e) {
      throw Exception('Failed to add attendance: $e');
    }
  }

  static Future<void> updateAttendance(Attendance attendance) async {
    try {
      await _firestore
          .collection(_attendanceCollection)
          .doc(attendance.id)
          .update(attendance.toJson());
    } catch (e) {
      throw Exception('Failed to update attendance: $e');
    }
  }

  static Future<void> deleteAttendance(String attendanceId) async {
    try {
      await _firestore
          .collection(_attendanceCollection)
          .doc(attendanceId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete attendance: $e');
    }
  }

  static Stream<List<Attendance>> getAttendanceStream() {
    return _firestore
        .collection(_attendanceCollection)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = Map<String, dynamic>.from(doc.data());
              data['id'] = data['id'] ?? doc.id;
              return Attendance.fromJson(data);
            }).toList());
  }

  static Future<List<Attendance>> getAttendance({
    DateTime? startDate,
    DateTime? endDate,
    String? staffId,
  }) async {
    try {
      Query query = _firestore
          .collection(_attendanceCollection)
          .orderBy('timestamp', descending: true);

      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: startDate);
      }

      if (endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: endDate);
      }

      if (staffId != null) {
        query = query.where('staffId', isEqualTo: staffId);
      }

      final snapshot = await query.limit(100).get();
      
      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
        data['id'] = data['id'] ?? doc.id;
        return Attendance.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get attendance: $e');
    }
  }

  // Users
  static Future<void> addUser(User user) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(user.id)
          .set(user.toJson());
    } catch (e) {
      throw Exception('Failed to add user: $e');
    }
  }

  static Future<void> updateUser(User user) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(user.id)
          .update(user.toJson());
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  static Future<void> deleteUser(String userId) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  static Future<User?> getUser(String userId) async {
    try {
      final doc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();
      
      if (doc.exists && doc.data() != null) {
        final data = Map<String, dynamic>.from(doc.data()!);
        data['id'] = data['id'] ?? doc.id;
        return User.fromJson(data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  static Stream<List<User>> getUsersStream() {
    return _firestore
        .collection(_usersCollection)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = Map<String, dynamic>.from(doc.data());
              data['id'] = data['id'] ?? doc.id;
              return User.fromJson(data);
            }).toList());
  }

  static Future<List<User>> getAllUsers() async {
    try {
      final snapshot = await _firestore
          .collection(_usersCollection)
          .where('isActive', isEqualTo: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = data['id'] ?? doc.id;
        return User.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get users: $e');
    }
  }
}
