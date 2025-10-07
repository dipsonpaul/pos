import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/pos/pos_bloc.dart';
import '../bloc/pos/pos_event.dart';
import '../bloc/pos/pos_state.dart';
import '../services/hive_service.dart';
import 'payment_dialog.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<PosBloc>().add(const LoadProducts());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Point of Sale'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          BlocBuilder<PosBloc, PosState>(
            builder: (context, state) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    onPressed: () {
                      final bloc = context.read<PosBloc>();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BlocProvider.value(
                            value: bloc,
                            child: const CartScreen(),
                          ),
                        ),
                      );
                    },
                  ),
                  if (state.cart.isNotEmpty)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '${state.cart.length}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocConsumer<PosBloc, PosState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: Colors.red,
              ),
            );
          }
          if (state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage!),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.isLoading && state.products.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search products...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                      onChanged: (query) {
                        context.read<PosBloc>().add(SearchProducts(query));
                      },
                    ),
                    const SizedBox(height: 12),
                    if (state.categories.isNotEmpty)
                      SizedBox(
                        height: 40,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: state.categories.length,
                          itemBuilder: (context, index) {
                            final category = state.categories[index];
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: FilterChip(
                                label: Text(category),
                                selected: state.selectedCategory == category,
                                onSelected: (selected) {
                                  context.read<PosBloc>().add(
                                        FilterProductsByCategory(category),
                                      );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: state.filteredProducts.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No products found',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final crossAxisCount = (constraints.maxWidth ~/ 180).clamp(2, 6);
                          return GridView.builder(
                            padding: const EdgeInsets.all(16.0),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              childAspectRatio: 0.75,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: state.filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = state.filteredProducts[index];
                              final cartQuantity = state.cart[product.id] ?? 0;
                              final remainingStock = product.stock - cartQuantity;
                              final isSoldOut = remainingStock <= 0;

                              return Card(
                                elevation: cartQuantity > 0 ? 4 : 2,
                                child: InkWell(
                                  onTap: () {
                                    // If item is in cart, show options to add more or remove
                                    if (cartQuantity > 0) {
                                      _showItemOptions(context, product, cartQuantity, remainingStock);
                                    } else if (product.stock > 0) {
                                      // Add to cart if not in cart and has stock
                                      context.read<PosBloc>().add(
                                            AddProductToCart(product: product),
                                          );
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('${product.name} added to cart'),
                                          duration: const Duration(seconds: 1),
                                          behavior: SnackBarBehavior.floating,
                                          margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Product out of stock'),
                                          duration: Duration(seconds: 1),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                  child: Stack(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Center(
                                                child: Icon(
                                                  Icons.shopping_bag,
                                                  size: 48,
                                                  color: isSoldOut
                                                      ? Colors.grey
                                                      : (product.stock > 0
                                                          ? Colors.blue
                                                          : Colors.grey),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              product.name,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: isSoldOut ? Colors.grey : Colors.black,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              product.category,
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  '₹${product.price.toStringAsFixed(2)}',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: isSoldOut ? Colors.grey : Colors.green,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                Text(
                                                  'Stock: $remainingStock',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: isSoldOut
                                                        ? Colors.red
                                                        : (remainingStock > 0
                                                            ? Colors.grey
                                                            : Colors.red),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (cartQuantity > 0) ...[
                                              const SizedBox(height: 6),
                                              Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: isSoldOut ? Colors.grey : Colors.blue,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  'In Cart: $cartQuantity',
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      // SOLD OUT Overlay
                                      if (isSoldOut)
                                        Positioned.fill(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.6),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Center(
                                              child: Transform.rotate(
                                                angle: -0.2,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 8,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red,
                                                    borderRadius: BorderRadius.circular(4),
                                                    border: Border.all(
                                                      color: Colors.white,
                                                      width: 2,
                                                    ),
                                                  ),
                                                  child: const Text(
                                                    'SOLD OUT',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                      letterSpacing: 2,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: BlocBuilder<PosBloc, PosState>(
        builder: (context, state) {
          if (state.cart.isEmpty) return const SizedBox.shrink();

          return FloatingActionButton.extended(
            onPressed: () {
              final bloc = context.read<PosBloc>();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BlocProvider.value(
                    value: bloc,
                    child: const CartScreen(),
                  ),
                ),
              );
            },
            backgroundColor: Colors.green,
            icon: const Icon(Icons.shopping_cart_checkout),
            label: Text(
              'View Cart (${state.cart.length})',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          );
        },
      ),
    );
  }

  void _showItemOptions(BuildContext context, dynamic product, int cartQuantity, int remainingStock) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.shopping_bag, size: 32, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'In Cart: $cartQuantity',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (remainingStock > 0)
              ListTile(
                leading: const Icon(Icons.add_circle, color: Colors.green),
                title: const Text('Add More'),
                subtitle: Text('$remainingStock remaining in stock'),
                onTap: () {
                  context.read<PosBloc>().add(
                        AddProductToCart(product: product),
                      );
                  Navigator.pop(sheetContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${product.name} added to cart'),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.remove_shopping_cart, color: Colors.red),
              title: const Text('Remove from Cart'),
              subtitle: const Text('Remove all items'),
              onTap: () {
                context.read<PosBloc>().add(
                      RemoveProductFromCart(product.id),
                    );
                Navigator.pop(sheetContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${product.name} removed from cart'),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          BlocBuilder<PosBloc, PosState>(
            builder: (context, state) {
              if (state.cart.isEmpty) return const SizedBox.shrink();
              return TextButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Clear Cart'),
                      content: const Text(
                          'Are you sure you want to remove all items from cart?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            context.read<PosBloc>().add(const ClearCart());
                            Navigator.pop(dialogContext);
                          },
                          child: const Text('Clear',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.clear_all, color: Colors.white),
                label: const Text('Clear',
                    style: TextStyle(color: Colors.white)),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocConsumer<PosBloc, PosState>(
        listener: (context, state) {
          if (state.successMessage != null && Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        },
        builder: (context, state) {
          if (state.cart.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_cart_outlined,
                      size: 100, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Your cart is empty',
                    style: TextStyle(fontSize: 20, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Continue Shopping'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.cartItems.length,
                  itemBuilder: (context, index) {
                    final item = state.cartItems[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.shopping_bag,
                                  size: 32, color: Colors.blue),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₹${item.price.toStringAsFixed(2)} each',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Total: ₹${item.total.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline),
                                      onPressed: () {
                                        context.read<PosBloc>().add(
                                              UpdateCartItemQuantity(
                                                productId: item.productId,
                                                quantity: item.quantity - 1,
                                              ),
                                            );
                                      },
                                      color: Colors.red,
                                      iconSize: 28,
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '${item.quantity}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline),
                                      onPressed: () {
                                        context.read<PosBloc>().add(
                                              UpdateCartItemQuantity(
                                                productId: item.productId,
                                                quantity: item.quantity + 1,
                                              ),
                                            );
                                      },
                                      color: Colors.green,
                                      iconSize: 28,
                                    ),
                                  ],
                                ),
                                TextButton.icon(
                                  onPressed: () {
                                    context.read<PosBloc>().add(
                                          RemoveProductFromCart(item.productId),
                                        );
                                  },
                                  icon: const Icon(Icons.delete_outline, size: 18),
                                  label: const Text('Remove'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTotalRow('Subtotal', state.subtotal),
                      _buildTotalRow('Tax (10%)', state.tax),
                      if (state.discount > 0)
                        _buildTotalRow('Discount', -state.discount),
                      const Divider(height: 24),
                      _buildTotalRow('Total', state.total, isTotal: true),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showPaymentDialog(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.payment, color: Colors.white),
                          label: const Text(
                            'PROCEED TO CHECKOUT',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 16,
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 16,
              color: isTotal ? Colors.green : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(BuildContext context) {
    final posBloc = context.read<PosBloc>();
    final state = posBloc.state;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PaymentDialog(
        total: state.total,
        cartItems: state.cartItems,
        onPayment: (customerName, customerPhone, paymentMethod, notes) {
          final currentUser = HiveService.getCurrentUser();
          if (currentUser != null) {
            posBloc.add(
              ProcessPayment(
                customerName: customerName,
                customerPhone: customerPhone,
                paymentMethod: paymentMethod,
                staffId: currentUser.id,
                staffName: currentUser.name,
                notes: notes,
              ),
            );
            Navigator.of(dialogContext).pop();
          }
        },
      ),
    );
  }
}