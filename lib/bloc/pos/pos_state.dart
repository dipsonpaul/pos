import 'package:equatable/equatable.dart';
import '../../models/product.dart';
import '../../models/sale.dart';

class PosState extends Equatable {
  final List<Product> products;
  final List<Product> filteredProducts;
  final Map<String, int> cart;
  final double subtotal;
  final double tax;
  final double discount;
  final double total;
  final bool isLoading;
  final String? error;
  final String? successMessage;
  final String selectedCategory;
  final String searchQuery;
  final PaymentMethod selectedPaymentMethod;

  const PosState({
    this.products = const [],
    this.filteredProducts = const [],
    this.cart = const {},
    this.subtotal = 0.0,
    this.tax = 0.0,
    this.discount = 0.0,
    this.total = 0.0,
    this.isLoading = false,
    this.error,
    this.successMessage,
    this.selectedCategory = 'All',
    this.searchQuery = '',
    this.selectedPaymentMethod = PaymentMethod.cash,
  });

  PosState copyWith({
    List<Product>? products,
    List<Product>? filteredProducts,
    Map<String, int>? cart,
    double? subtotal,
    double? tax,
    double? discount,
    double? total,
    bool? isLoading,
    String? error,
    String? successMessage,
    String? selectedCategory,
    String? searchQuery,
    PaymentMethod? selectedPaymentMethod,
  }) {
    return PosState(
      products: products ?? this.products,
      filteredProducts: filteredProducts ?? this.filteredProducts,
      cart: cart ?? this.cart,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedPaymentMethod: selectedPaymentMethod ?? this.selectedPaymentMethod,
    );
  }

  List<Product> get cartProducts {
    return cart.entries
        .map((entry) {
          final product = products.firstWhere(
            (p) => p.id == entry.key,
            orElse: () => Product(
              id: '',
              name: 'Unknown Product',
              category: '',
              price: 0.0,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
          return product;
        })
        .toList();
  }

  List<SaleItem> get cartItems {
    return cart.entries
        .map((entry) {
          final product = products.firstWhere(
            (p) => p.id == entry.key,
            orElse: () => Product(
              id: '',
              name: 'Unknown Product',
              category: '',
              price: 0.0,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
          return SaleItem(
            productId: product.id,
            productName: product.name,
            price: product.price,
            quantity: entry.value,
            total: product.price * entry.value,
          );
        })
        .toList();
  }

  List<String> get categories {
    final categories = products.map((p) => p.category).toSet().toList();
    categories.sort();
    return ['All', ...categories];
  }

  @override
  List<Object?> get props => [
        products,
        filteredProducts,
        cart,
        subtotal,
        tax,
        discount,
        total,
        isLoading,
        error,
        successMessage,
        selectedCategory,
        searchQuery,
        selectedPaymentMethod,
      ];
}
