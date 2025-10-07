import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';

part 'sale.g.dart';

@HiveType(typeId: 1)
class SaleItem extends Equatable {
  @HiveField(0)
  final String productId;

  @HiveField(1)
  final String productName;

  @HiveField(2)
  final double price;

  @HiveField(3)
  final int quantity;

  @HiveField(4)
  final double total;

  const SaleItem({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.total,
  });

  SaleItem copyWith({
    String? productId,
    String? productName,
    double? price,
    int? quantity,
    double? total,
  }) {
    return SaleItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      total: total ?? this.total,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'price': price,
      'quantity': quantity,
      'total': total,
    };
  }

  factory SaleItem.fromJson(Map<String, dynamic> json) {
    return SaleItem(
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'] as int,
      total: (json['total'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => [productId, productName, price, quantity, total];
}

@HiveType(typeId: 2)
class Sale extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final List<SaleItem> items;

  @HiveField(2)
  final double subtotal;

  @HiveField(3)
  final double tax;

  @HiveField(4)
  final double discount;

  @HiveField(5)
  final double total;

  @HiveField(6)
  final String customerName;

  @HiveField(7)
  final String customerPhone;

  @HiveField(8)
  final String staffId;

  @HiveField(9)
  final String staffName;

  @HiveField(10)
  final DateTime createdAt;

  @HiveField(11)
  final PaymentMethod paymentMethod;

  @HiveField(12)
  final bool isSynced;

  @HiveField(13)
  final String? notes;

  const Sale({
    required this.id,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.discount,
    required this.total,
    this.customerName = '',
    this.customerPhone = '',
    required this.staffId,
    required this.staffName,
    required this.createdAt,
    required this.paymentMethod,
    this.isSynced = false,
    this.notes,
  });

  Sale copyWith({
    String? id,
    List<SaleItem>? items,
    double? subtotal,
    double? tax,
    double? discount,
    double? total,
    String? customerName,
    String? customerPhone,
    String? staffId,
    String? staffName,
    DateTime? createdAt,
    PaymentMethod? paymentMethod,
    bool? isSynced,
    String? notes,
  }) {
    return Sale(
      id: id ?? this.id,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      staffId: staffId ?? this.staffId,
      staffName: staffName ?? this.staffName,
      createdAt: createdAt ?? this.createdAt,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isSynced: isSynced ?? this.isSynced,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'discount': discount,
      'total': total,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'staffId': staffId,
      'staffName': staffName,
      'createdAt': createdAt.toIso8601String(),
      'paymentMethod': paymentMethod.name,
      'isSynced': isSynced,
      'notes': notes,
    };
  }

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: json['id'] as String,
      items: (json['items'] as List)
          .map((item) => SaleItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      subtotal: (json['subtotal'] as num).toDouble(),
      tax: (json['tax'] as num).toDouble(),
      discount: (json['discount'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      customerName: json['customerName'] as String? ?? '',
      customerPhone: json['customerPhone'] as String? ?? '',
      staffId: json['staffId'] as String,
      staffName: json['staffName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == json['paymentMethod'],
        orElse: () => PaymentMethod.cash,
      ),
      isSynced: json['isSynced'] as bool? ?? false,
      notes: json['notes'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        items,
        subtotal,
        tax,
        discount,
        total,
        customerName,
        customerPhone,
        staffId,
        staffName,
        createdAt,
        paymentMethod,
        isSynced,
        notes,
      ];
}

@HiveType(typeId: 3)
enum PaymentMethod {
  @HiveField(0)
  cash,

  @HiveField(1)
  card,

  @HiveField(2)
  upi,

  @HiveField(3)
  wallet,
}
