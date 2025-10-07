import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../models/product.dart';
import '../../models/sale.dart';
import '../../services/hive_service.dart';
import '../../services/firebase_service.dart';
import '../../services/sync_service.dart';
import 'pos_event.dart';
import 'pos_state.dart';

class PosBloc extends Bloc<PosEvent, PosState> {
  final SyncService _syncService = SyncService();
  final Uuid _uuid = const Uuid();

  PosBloc() : super(const PosState()) {
    on<LoadProducts>(_onLoadProducts);
    on<AddProductToCart>(_onAddProductToCart);
    on<RemoveProductFromCart>(_onRemoveProductFromCart);
    on<UpdateCartItemQuantity>(_onUpdateCartItemQuantity);
    on<ClearCart>(_onClearCart);
    on<ApplyDiscount>(_onApplyDiscount);
    on<ProcessPayment>(_onProcessPayment);
    on<FilterProductsByCategory>(_onFilterProductsByCategory);
    on<SearchProducts>(_onSearchProducts);
  }

  Future<void> _onLoadProducts(LoadProducts event, Emitter<PosState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      // First try to get products from local storage
      List<Product> products = HiveService.getAllProducts();

      // If no local products, try to sync from Firebase
      if (products.isEmpty) {
        await _syncService.syncProducts();
        products = HiveService.getAllProducts();
      }

      // Extract unique categories
      final categories = <String>{'All'};
      for (var product in products) {
        if (product.isActive) {
          categories.add(product.category);
        }
      }

      // Filter products based on current search and category
      final filteredProducts = _filterProducts(products, state.searchQuery, state.selectedCategory);

      emit(state.copyWith(
        products: products,
        filteredProducts: filteredProducts,
        // categories: categories.toList(),
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to load products: $e',
      ));
    }
  }

  void _onAddProductToCart(AddProductToCart event, Emitter<PosState> emit) {
    final newCart = Map<String, int>.from(state.cart);
    final currentQuantity = newCart[event.product.id] ?? 0;
    final desired = currentQuantity + event.quantity;
    final maxAllowed = event.product.stock;
    final nextQty = desired > maxAllowed ? maxAllowed : desired;

    if (nextQty <= 0) {
      newCart.remove(event.product.id);
    } else {
      newCart[event.product.id] = nextQty;
    }

    final overflow = desired > maxAllowed;
    final newState = _calculateTotals(state.copyWith(
      cart: newCart,
      error: overflow ? 'Only $maxAllowed in stock for ${event.product.name}' : null,
    ));
    emit(newState);
  }

  void _onRemoveProductFromCart(RemoveProductFromCart event, Emitter<PosState> emit) {
    final newCart = Map<String, int>.from(state.cart);
    newCart.remove(event.productId);

    final newState = _calculateTotals(state.copyWith(cart: newCart));
    emit(newState);
  }

  void _onUpdateCartItemQuantity(UpdateCartItemQuantity event, Emitter<PosState> emit) {
    final newCart = Map<String, int>.from(state.cart);
    final product = state.products.firstWhere(
      (p) => p.id == event.productId,
      orElse: () => Product(
        id: '',
        name: 'Unknown Product',
        category: '',
        price: 0.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    final maxAllowed = product.id.isEmpty ? event.quantity : product.stock;
    final nextQty = event.quantity > maxAllowed ? maxAllowed : event.quantity;

    if (nextQty <= 0) {
      newCart.remove(event.productId);
    } else {
      newCart[event.productId] = nextQty;
    }

    final overflow = event.quantity > maxAllowed;
    final newState = _calculateTotals(state.copyWith(
      cart: newCart,
      error: overflow ? 'Only $maxAllowed in stock for ${product.name}' : null,
    ));
    emit(newState);
  }

  void _onClearCart(ClearCart event, Emitter<PosState> emit) {
    emit(_calculateTotals(state.copyWith(
      cart: const {},
      discount: 0.0,
    )));
  }

  void _onApplyDiscount(ApplyDiscount event, Emitter<PosState> emit) {
    final newState = _calculateTotals(state.copyWith(discount: event.discountAmount));
    emit(newState);
  }

  Future<void> _onProcessPayment(ProcessPayment event, Emitter<PosState> emit) async {
    if (state.cart.isEmpty) {
      emit(state.copyWith(error: 'Cart is empty'));
      return;
    }

    emit(state.copyWith(isLoading: true, error: null));

    try {
      final saleId = _uuid.v4();
      final now = DateTime.now();
      
      // Validate stock availability before processing
      for (final entry in state.cart.entries) {
        final product = state.products.firstWhere((p) => p.id == entry.key);
        if (product.stock < entry.value) {
          emit(state.copyWith(
            isLoading: false,
            error: 'Insufficient stock for ${product.name}. Available: ${product.stock}',
          ));
          return;
        }
      }

      final sale = Sale(
        id: saleId,
        items: state.cartItems,
        subtotal: state.subtotal,
        tax: state.tax,
        discount: state.discount,
        total: state.total,
        customerName: event.customerName,
        customerPhone: event.customerPhone,
        staffId: event.staffId,
        staffName: event.staffName,
        createdAt: now,
        paymentMethod: event.paymentMethod,
        notes: event.notes,
        isSynced: false,
      );

      // Update product stock locally first
      final updatedProducts = <Product>[];
      for (final product in state.products) {
        final cartQuantity = state.cart[product.id] ?? 0;
        if (cartQuantity > 0) {
          final updatedProduct = product.copyWith(
            stock: product.stock - cartQuantity,
            updatedAt: now,
          );
          updatedProducts.add(updatedProduct);
          await HiveService.updateProduct(updatedProduct);
        } else {
          updatedProducts.add(product);
        }
      }

      // Save sale to local storage
      await HiveService.addSale(sale);

      // Try to sync to Firebase if online
      bool firebaseSynced = false;
      try {
        // Add sale to Firebase
        await FirebaseService.addSale(sale);
        
        // Update product stock in Firebase
        for (final product in updatedProducts) {
          final cartQuantity = state.cart[product.id] ?? 0;
          if (cartQuantity > 0) {
            await FirebaseService.updateProduct(product);
          }
        }
        
        firebaseSynced = true;
        
        // Mark sale as synced in local storage
        final syncedSale = sale.copyWith(isSynced: true);
        await HiveService.updateSale(syncedSale);
        
      } catch (e) {
        // Sale and stock update saved locally, will sync later
        print('Failed to sync to Firebase: $e');
        // Add to sync queue for later retry
        // await _syncService.addToSyncQueue(sale.id);
      }

      // Update filtered products list
      final filteredProducts = _filterProducts(
        updatedProducts,
        state.searchQuery,
        state.selectedCategory,
      );

      emit(state.copyWith(
        isLoading: false,
        successMessage: firebaseSynced 
            ? 'Payment processed successfully!' 
            : 'Payment processed! Will sync when online.',
        cart: const {},
        subtotal: 0.0,
        tax: 0.0,
        discount: 0.0,
        total: 0.0,
        products: updatedProducts,
        filteredProducts: filteredProducts,
      ));

      // Clear success message after a short delay
      await Future.delayed(const Duration(milliseconds: 100));
      emit(state.copyWith(successMessage: null));

    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to process payment: $e',
      ));
    }
  }

  void _onFilterProductsByCategory(FilterProductsByCategory event, Emitter<PosState> emit) {
    final filteredProducts = _filterProducts(state.products, state.searchQuery, event.category);
    emit(state.copyWith(
      selectedCategory: event.category,
      filteredProducts: filteredProducts,
    ));
  }

  void _onSearchProducts(SearchProducts event, Emitter<PosState> emit) {
    final filteredProducts = _filterProducts(state.products, event.query, state.selectedCategory);
    emit(state.copyWith(
      searchQuery: event.query,
      filteredProducts: filteredProducts,
    ));
  }

  List<Product> _filterProducts(List<Product> products, String searchQuery, String category) {
    List<Product> filtered = products.where((product) => product.isActive).toList();

    // Filter by category
    if (category != 'All') {
      filtered = filtered.where((product) => product.category == category).toList();
    }

    // Filter by search query
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((product) =>
          product.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          product.description.toLowerCase().contains(searchQuery.toLowerCase())).toList();
    }

    return filtered;
  }

  PosState _calculateTotals(PosState currentState) {
    double subtotal = 0.0;

    for (final entry in currentState.cart.entries) {
      final product = currentState.products.firstWhere(
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
      subtotal += product.price * entry.value;
    }

    const double taxRate = 0.10; // 10% tax
    final double tax = subtotal * taxRate;
    final double total = subtotal + tax - currentState.discount;

    return currentState.copyWith(
      subtotal: subtotal,
      tax: tax,
      total: total,
    );
  }
}