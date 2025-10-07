import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/product.dart';
import '../services/hive_service.dart';
import '../services/firebase_service.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() =>
      _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  final Uuid _uuid = const Uuid();

  @override
  Widget build(BuildContext context) {
    final products = HiveService.getAllProducts();
    final categories = products.map((p) => p.category).toSet().toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Products'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        elevation: 2, // Add elevation for depth
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Product',
            onPressed: _showAddEditDialog,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ],
      ),
      body:
          products.isEmpty
              ? Center(
                child: Text(
                  'No products yet. Tap + to add.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final categoryProducts =
                      products.where((p) => p.category == category).toList()
                        ..sort((a, b) => a.name.compareTo(b.name));
                  return Card(
                    elevation: 3, // Subtle elevation for cards
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ExpansionTile(
                      title: Text(
                        category,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                      children:
                          categoryProducts.map((p) {
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              title: Text(
                                p.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              subtitle: Text(
                                '₹${p.price.toStringAsFixed(2)} • Stock: ${p.stock}',
                                style: TextStyle(
                                  color:
                                      p.stock < 5
                                          ? Colors.redAccent
                                          : Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Decrease stock',
                                    icon: Icon(
                                      Icons.remove_circle_outline,
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.secondary,
                                    ),
                                    onPressed: () => _adjustStock(p, -1),
                                  ),
                                  IconButton(
                                    tooltip: 'Increase stock',
                                    icon: Icon(
                                      Icons.add_circle_outline,
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.secondary,
                                    ),
                                    onPressed: () => _adjustStock(p, 1),
                                  ),
                                  IconButton(
                                    tooltip: 'Edit product',
                                    icon: const Icon(Icons.edit),
                                    onPressed:
                                        () => _showAddEditDialog(existing: p),
                                  ),
                                  IconButton(
                                    tooltip: 'Delete product',
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _confirmDelete(p),
                                  ),
                                ],
                              ),
                              onTap: () => _showQuickStockDialog(p),
                            );
                          }).toList(),
                    ),
                  );
                },
              ),
      // Removed redundant FAB since AppBar has an add button
    );
  }

  Future<void> _confirmDelete(Product product) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Delete Product',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            content: Text(
              'Are you sure you want to delete ${product.name}?',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
    if (ok == true) {
      await HiveService.deleteProduct(product.id);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${product.name} deleted')));
      }
    }
  }

  void _showAddEditDialog({Product? existing}) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final categoryController = TextEditingController(
      text: existing?.category ?? '',
    );
    final priceController = TextEditingController(
      text: existing?.price.toString() ?? '',
    );
    final stockController = TextEditingController(
      text: existing?.stock.toString() ?? '0',
    );
    final descriptionController = TextEditingController(
      text: existing?.description ?? '',
    );
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              existing == null ? 'Add Product' : 'Edit Product',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.label),
                      ),
                      validator:
                          (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: categoryController,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.category),
                      ),
                      validator:
                          (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: priceController,
                      decoration: InputDecoration(
                        labelText: 'Price',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.attach_money),
                        prefixText: '₹',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) {
                        final d = double.tryParse(v ?? '');
                        if (d == null || d < 0) return 'Enter valid price';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: stockController,
                      decoration: InputDecoration(
                        labelText: 'Stock',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.inventory),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final i = int.tryParse(v ?? '');
                        if (i == null || i < 0) return 'Enter valid stock';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description (Optional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.description),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              StatefulBuilder(
                builder: (context, setDialogState) {
                  return ElevatedButton(
                    onPressed:
                        isLoading
                            ? null
                            : () async {
                              if (!formKey.currentState!.validate()) return;
                              setDialogState(() => isLoading = true);
                              final now = DateTime.now();
                              final product = (existing ??
                                      Product(
                                        id: _uuid.v4(),
                                        name: nameController.text.trim(),
                                        category:
                                            categoryController.text.trim(),
                                        price: double.parse(
                                          priceController.text.trim(),
                                        ),
                                        description:
                                            descriptionController.text.trim(),
                                        stock: int.parse(
                                          stockController.text.trim(),
                                        ),
                                        createdAt: now,
                                        updatedAt: now,
                                      ))
                                  .copyWith(
                                    name: nameController.text.trim(),
                                    category: categoryController.text.trim(),
                                    price: double.parse(
                                      priceController.text.trim(),
                                    ),
                                    description:
                                        descriptionController.text.trim(),
                                    stock: int.parse(
                                      stockController.text.trim(),
                                    ),
                                    updatedAt: now,
                                  );

                              if (existing == null) {
                                await HiveService.addProduct(product);
                              } else {
                                await HiveService.updateProduct(product);
                              }

                              if (mounted) {
                                setState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      existing == null
                                          ? 'Product added'
                                          : 'Product updated',
                                    ),
                                  ),
                                );
                              }
                              if (context.mounted) Navigator.pop(context);
                            },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child:
                        isLoading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Text('Save'),
                  );
                },
              ),
            ],
          ),
    );
  }

  Future<void> _adjustStock(Product product, int delta) async {
    final int newStock = (product.stock + delta).clamp(0, 1 << 31);
    if (newStock == product.stock) return;
    final updated = product.copyWith(
      stock: newStock,
      updatedAt: DateTime.now(),
    );
    await HiveService.updateProduct(updated);
    try {
      await FirebaseService.updateProduct(updated);
    } catch (_) {}
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stock updated for ${product.name}')),
      );
    }
  }

  void _showQuickStockDialog(Product product) {
    final controller = TextEditingController(text: product.stock.toString());
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Update Stock • ${product.name}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            content: Form(
              key: formKey,
              child: TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Stock',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.inventory),
                ),
                validator: (v) {
                  final i = int.tryParse(v ?? '');
                  if (i == null || i < 0) return 'Enter valid stock';
                  return null;
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              StatefulBuilder(
                builder: (context, setDialogState) {
                  return ElevatedButton(
                    onPressed:
                        isLoading
                            ? null
                            : () async {
                              if (!formKey.currentState!.validate()) return;
                              setDialogState(() => isLoading = true);
                              final newStock = int.parse(
                                controller.text.trim(),
                              );
                              final updated = product.copyWith(
                                stock: newStock,
                                updatedAt: DateTime.now(),
                              );
                              await HiveService.updateProduct(updated);
                              try {
                                await FirebaseService.updateProduct(updated);
                              } catch (_) {}
                              if (mounted) {
                                setState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Stock updated for ${product.name}',
                                    ),
                                  ),
                                );
                              }
                              if (context.mounted) Navigator.pop(context);
                            },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child:
                        isLoading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Text('Save'),
                  );
                },
              ),
            ],
          ),
    );
  }
}
