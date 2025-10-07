import 'package:uuid/uuid.dart';
import '../models/product.dart';
import '../models/user.dart';
import 'hive_service.dart';

class SampleDataService {
  static final Uuid _uuid = const Uuid();

  static Future<void> seedSampleData() async {
    // Check if data already exists
    if (HiveService.getAllProducts().isNotEmpty) {
      return;
    }

    final now = DateTime.now();

    // Create sample products
    final sampleProducts = [
      Product(
        id: _uuid.v4(),
        name: 'Vanilla Ice Cream',
        category: 'Ice Cream',
        price: 50.0,
        description: 'Classic vanilla ice cream',
        stock: 100,
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: _uuid.v4(),
        name: 'Chocolate Ice Cream',
        category: 'Ice Cream',
        price: 55.0,
        description: 'Rich chocolate ice cream',
        stock: 80,
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: _uuid.v4(),
        name: 'Strawberry Ice Cream',
        category: 'Ice Cream',
        price: 52.0,
        description: 'Fresh strawberry ice cream',
        stock: 60,
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: _uuid.v4(),
        name: 'Mint Chocolate Chip',
        category: 'Ice Cream',
        price: 58.0,
        description: 'Refreshing mint with chocolate chips',
        stock: 40,
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: _uuid.v4(),
        name: 'Cone',
        category: 'Accessories',
        price: 5.0,
        description: 'Waffle cone',
        stock: 200,
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: _uuid.v4(),
        name: 'Cup',
        category: 'Accessories',
        price: 3.0,
        description: 'Disposable cup',
        stock: 300,
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: _uuid.v4(),
        name: 'Chocolate Sauce',
        category: 'Toppings',
        price: 8.0,
        description: 'Rich chocolate sauce',
        stock: 50,
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: _uuid.v4(),
        name: 'Caramel Sauce',
        category: 'Toppings',
        price: 8.0,
        description: 'Sweet caramel sauce',
        stock: 45,
        createdAt: now,
        updatedAt: now,
      ),
      // Dresses category (requested)
      Product(
        id: _uuid.v4(),
        name: 'Summer Dress',
        category: 'Dresses',
        price: 799.0,
        description: 'Light cotton summer dress',
        stock: 20,
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: _uuid.v4(),
        name: 'Evening Gown',
        category: 'Dresses',
        price: 2499.0,
        description: 'Elegant evening gown',
        stock: 10,
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: _uuid.v4(),
        name: 'Sprinkles',
        category: 'Toppings',
        price: 5.0,
        description: 'Colorful sprinkles',
        stock: 100,
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: _uuid.v4(),
        name: 'Nuts',
        category: 'Toppings',
        price: 12.0,
        description: 'Mixed nuts',
        stock: 30,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    // Save products to local storage
    for (final product in sampleProducts) {
      await HiveService.addProduct(product);
    }

    // Create sample admin user if no user exists
    if (HiveService.getAllUsers().isEmpty) {
      final adminUser = User(
        id: _uuid.v4(),
        name: 'Admin User',
        email: 'admin@icecream.com',
        phone: '+1234567890',
        role: UserRole.admin,
        createdAt: now,
        updatedAt: now,
        allowedLatitude: 28.6139, // Delhi coordinates (example)
        allowedLongitude: 77.2090,
        locationRadius: 100.0, // 100 meters
      );

      await HiveService.addUser(adminUser);
      await HiveService.setCurrentUser(adminUser.id);
    }
  }

  static Future<void> clearAllData() async {
    await HiveService.clearAllData();
  }
}
