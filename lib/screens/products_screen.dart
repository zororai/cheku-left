import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/stock_provider.dart';
import '../models/product.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      context.read<ProductProvider>().loadProducts(butcherId: auth.butcherId);
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showProductDialog({Product? product}) async {
    final isEditing = product != null;
    final nameController = TextEditingController(text: product?.name ?? '');
    final priceController = TextEditingController(
      text: product?.pricePerKg.toStringAsFixed(2) ?? '',
    );
    final formKey = GlobalKey<FormState>();
    String selectedUnit = product?.unit ?? 'kg';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF16213E),
          title: Text(
            isEditing ? 'Edit Product' : 'Add Product',
            style: const TextStyle(color: Colors.white),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Product Name',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: const Color(0xFF1A1A2E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter product name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedUnit,
                  dropdownColor: const Color(0xFF1A1A2E),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Unit Type',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: const Color(0xFF1A1A2E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'kg', child: Text('Kilogram (kg)')),
                    DropdownMenuItem(value: 'grams', child: Text('Grams (g)')),
                    DropdownMenuItem(value: 'item', child: Text('Item/Piece')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedUnit = value ?? 'kg';
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: selectedUnit == 'kg'
                        ? 'Price per KG (\$)'
                        : selectedUnit == 'grams'
                        ? 'Price per Gram (\$)'
                        : 'Price per Item (\$)',
                    labelStyle: const TextStyle(color: Colors.white70),
                    prefixText: '\$ ',
                    prefixStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: const Color(0xFF1A1A2E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter price';
                    }
                    final price = double.tryParse(value);
                    if (price == null || price <= 0) {
                      return 'Please enter valid price';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(ctx, true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE94560),
              ),
              child: Text(isEditing ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );

    if (result != true) return;

    final auth = context.read<AuthProvider>();
    final provider = context.read<ProductProvider>();
    final newProduct = Product(
      id: product?.id,
      butcherId: product?.butcherId ?? auth.butcherId!,
      name: nameController.text.trim(),
      pricePerKg: double.parse(priceController.text),
      unit: selectedUnit,
      isActive: product?.isActive ?? true,
      createdAt: product?.createdAt,
      currentStockGrams: product?.currentStockGrams ?? 0,
      minStockAlertGrams: product?.minStockAlertGrams ?? 0,
    );

    bool success;
    if (isEditing) {
      success = await provider.updateProduct(newProduct);
    } else {
      success = await provider.addProduct(newProduct);

      // If product was added successfully and there's an open stock session,
      // add a stock movement for the new product
      if (success && mounted) {
        final stockProvider = context.read<StockProvider>();
        if (stockProvider.isDayOpen) {
          // Get the newly added product's ID from the reloaded products list
          final addedProduct = provider.products.firstWhere(
            (p) =>
                p.name == newProduct.name &&
                p.butcherId == newProduct.butcherId,
            orElse: () => newProduct,
          );
          if (addedProduct.id != null) {
            await stockProvider.addProductToOpenSession(addedProduct.id!);
          }
        }
      }
    }

    if (mounted) {
      _showSnackBar(
        success
            ? '${isEditing ? 'Updated' : 'Added'} ${newProduct.name}'
            : 'Failed to ${isEditing ? 'update' : 'add'} product',
        isError: !success,
      );
    }
  }

  Future<void> _deleteProduct(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          'Delete Product',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete "${product.name}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await context.read<ProductProvider>().deleteProduct(
      product.id!,
    );
    if (mounted) {
      _showSnackBar(
        success ? 'Deleted ${product.name}' : 'Failed to delete product',
        isError: !success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Products'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProductDialog(),
        backgroundColor: const Color(0xFFE94560),
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
      body: Consumer<ProductProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: Colors.white30,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No products yet',
                    style: TextStyle(fontSize: 18, color: Colors.white60),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap the button below to add your first product',
                    style: TextStyle(color: Colors.white38),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.products.length,
            itemBuilder: (context, index) {
              final product = provider.products[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF16213E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: product.isActive
                          ? const Color(0xFF4CAF50).withOpacity(0.2)
                          : Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.restaurant,
                      color: product.isActive
                          ? const Color(0xFF4CAF50)
                          : Colors.grey,
                    ),
                  ),
                  title: Text(
                    product.name,
                    style: TextStyle(
                      color: product.isActive ? Colors.white : Colors.white38,
                      fontWeight: FontWeight.bold,
                      decoration: product.isActive
                          ? null
                          : TextDecoration.lineThrough,
                    ),
                  ),
                  subtitle: Text(
                    product.priceLabel,
                    style: TextStyle(
                      color: product.isActive
                          ? const Color(0xFF4CAF50)
                          : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: product.isActive,
                        onChanged: (_) => provider.toggleProductStatus(product),
                        activeColor: const Color(0xFF4CAF50),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert,
                          color: Colors.white60,
                        ),
                        color: const Color(0xFF1A1A2E),
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showProductDialog(product: product);
                          } else if (value == 'delete') {
                            _deleteProduct(product);
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit,
                                  color: Colors.white70,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Edit',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
