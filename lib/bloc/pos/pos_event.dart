import 'package:equatable/equatable.dart';
import '../../models/product.dart';
import '../../models/sale.dart';

abstract class PosEvent extends Equatable {
  const PosEvent();

  @override
  List<Object?> get props => [];
}

class LoadProducts extends PosEvent {
  const LoadProducts();
}

class AddProductToCart extends PosEvent {
  final Product product;
  final int quantity;

  const AddProductToCart({
    required this.product,
    this.quantity = 1,
  });

  @override
  List<Object?> get props => [product, quantity];
}

class RemoveProductFromCart extends PosEvent {
  final String productId;

  const RemoveProductFromCart(this.productId);

  @override
  List<Object?> get props => [productId];
}

class UpdateCartItemQuantity extends PosEvent {
  final String productId;
  final int quantity;

  const UpdateCartItemQuantity({
    required this.productId,
    required this.quantity,
  });

  @override
  List<Object?> get props => [productId, quantity];
}

class ClearCart extends PosEvent {
  const ClearCart();
}

class ApplyDiscount extends PosEvent {
  final double discountAmount;

  const ApplyDiscount(this.discountAmount);

  @override
  List<Object?> get props => [discountAmount];
}

class ProcessPayment extends PosEvent {
  final String customerName;
  final String customerPhone;
  final PaymentMethod paymentMethod;
  final String staffId;
  final String staffName;
  final String? notes;

  const ProcessPayment({
    required this.customerName,
    required this.customerPhone,
    required this.paymentMethod,
    required this.staffId,
    required this.staffName,
    this.notes,
  });

  @override
  List<Object?> get props => [
        customerName,
        customerPhone,
        paymentMethod,
        staffId,
        staffName,
        notes,
      ];
}

class FilterProductsByCategory extends PosEvent {
  final String category;

  const FilterProductsByCategory(this.category);

  @override
  List<Object?> get props => [category];
}

class SearchProducts extends PosEvent {
  final String query;

  const SearchProducts(this.query);

  @override
  List<Object?> get props => [query];
}
