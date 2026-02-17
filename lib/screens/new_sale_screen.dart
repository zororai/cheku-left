import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/product_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/sale_provider.dart';
import '../providers/auth_provider.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../services/print_service.dart';

class NewSaleScreen extends StatefulWidget {
  const NewSaleScreen({super.key});

  @override
  State<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends State<NewSaleScreen> {
  final _weightController = TextEditingController();
  final _amountReceivedController = TextEditingController();
  final _buyerNameController = TextEditingController();
  final _chargeController = TextEditingController();
  Product? _selectedProduct;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      context.read<ProductProvider>().loadProducts(butcherId: auth.butcherId);
    });
  }

  @override
  void dispose() {
    _weightController.dispose();
    _amountReceivedController.dispose();
    _buyerNameController.dispose();
    _chargeController.dispose();
    super.dispose();
  }

  void _addToCart() {
    if (_selectedProduct == null) {
      _showSnackBar('Please select a product', isError: true);
      return;
    }

    final value = int.tryParse(_weightController.text);
    if (value == null || value <= 0) {
      final errorMsg = _selectedProduct!.unit == 'item'
          ? 'Please enter valid quantity'
          : 'Please enter valid weight in grams';
      _showSnackBar(errorMsg, isError: true);
      return;
    }

    context.read<CartProvider>().addItem(_selectedProduct!, value);
    _weightController.clear();

    // Show appropriate unit in message
    final unitLabel = _selectedProduct!.unit == 'item' ? 'pcs' : 'g';
    _showSnackBar('Added ${_selectedProduct!.name} ($value$unitLabel) to cart');
  }

  /// Get cart item subtitle based on product unit type
  String _getCartItemSubtitle(item) {
    final product = item.product;
    switch (product.unit) {
      case 'item':
        return '${item.weightGrams} pcs @ ${product.priceLabel}';
      case 'grams':
        return '${item.weightGrams}g @ ${product.priceLabel}';
      default: // kg
        return '${item.weightGrams}g @ ${product.priceLabel}';
    }
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

  Future<void> _completeSale() async {
    final cart = context.read<CartProvider>();

    if (cart.isEmpty) {
      _showSnackBar('Cart is empty', isError: true);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          'Complete Sale',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total: \$${cart.totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Payment: ${cart.selectedPaymentMethod}',
              style: const TextStyle(color: Colors.white70),
            ),
            Text(
              'Items: ${cart.itemCount}',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final auth = context.read<AuthProvider>();
      final saleProvider = context.read<SaleProvider>();
      final saleNumber = await saleProvider.createSale(
        butcherId: auth.butcherId!,
        userId: auth.userId!,
        totalAmount: cart.totalAmount,
        paymentMethod: cart.selectedPaymentMethod,
        items: cart.toSaleItems(),
      );

      final saleItems = cart.toSaleItems();
      final sale = Sale(
        butcherId: auth.butcherId!,
        userId: auth.userId!,
        saleNumber: saleNumber,
        totalAmount: cart.totalAmount,
        paymentMethod: cart.selectedPaymentMethod,
      );

      // Save buyer info before clearing
      final buyerName = _buyerNameController.text.trim();
      final charge = double.tryParse(_chargeController.text) ?? 0;

      cart.clear();
      _amountReceivedController.clear();
      _buyerNameController.clear();
      _chargeController.clear();

      if (mounted) {
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF16213E),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 32),
                SizedBox(width: 12),
                Text('Sale Complete', style: TextStyle(color: Colors.white)),
              ],
            ),
            content: Text(
              'Sale $saleNumber recorded successfully!',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton.icon(
                onPressed: () async {
                  final printService = PrintService.instance;
                  if (printService.isConnected) {
                    final prefs = await SharedPreferences.getInstance();
                    final shopName = prefs.getString('shop_name');
                    final shopAddress = prefs.getString('shop_address');
                    final shopPhone = prefs.getString('shop_phone');

                    final success = await printService.printReceipt(
                      sale: sale,
                      items: saleItems,
                      shopName: (shopName != null && shopName.isNotEmpty)
                          ? shopName
                          : (auth.butcherName ?? 'Butcher Shop'),
                      cashierName: auth.fullName ?? 'Cashier',
                      shopAddress: shopAddress,
                      shopPhone: shopPhone,
                      buyerName: buyerName.isNotEmpty ? buyerName : null,
                      charge: charge > 0 ? charge : null,
                    );
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text(
                            success ? 'Receipt printed!' : 'Print failed',
                          ),
                          backgroundColor: success ? Colors.green : Colors.red,
                        ),
                      );
                    }
                  } else {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Printer not connected. Go to Dashboard > Printer',
                          ),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.print, color: Colors.white70),
                label: const Text(
                  'Print',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                ),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      _showSnackBar('Error creating sale: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('New Sale'),
        actions: [
          Consumer<CartProvider>(
            builder: (context, cart, _) {
              if (cart.isEmpty) return const SizedBox.shrink();
              return TextButton.icon(
                onPressed: () {
                  cart.clear();
                  _showSnackBar('Cart cleared');
                },
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text('Clear', style: TextStyle(color: Colors.red)),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProductSelector(),
                  const SizedBox(height: 16),
                  _buildWeightInput(),
                  const SizedBox(height: 24),
                  _buildCartSection(),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildProductSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Product',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Consumer<ProductProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (provider.activeProducts.isEmpty) {
                return const Text(
                  'No products available',
                  style: TextStyle(color: Colors.white60),
                );
              }

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: provider.activeProducts.map((product) {
                  final isSelected = _selectedProduct?.id == product.id;
                  return ChoiceChip(
                    label: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(product.name),
                        Text(
                          product.priceLabel,
                          style: const TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        _selectedProduct = product;
                        _weightController.clear();
                      });
                    },
                    selectedColor: const Color(0xFFE94560),
                    backgroundColor: const Color(0xFF1A1A2E),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWeightInput() {
    // Determine input label and suffix based on product unit
    String inputLabel = 'Enter Weight (grams)';
    String inputSuffix = 'g';

    if (_selectedProduct != null) {
      switch (_selectedProduct!.unit) {
        case 'kg':
          inputLabel = 'Enter Weight (grams)';
          inputSuffix = 'g';
          break;
        case 'grams':
          inputLabel = 'Enter Weight (grams)';
          inputSuffix = 'g';
          break;
        case 'item':
          inputLabel = 'Enter Quantity';
          inputSuffix = 'pcs';
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            inputLabel,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _weightController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 32,
              ),
              suffixText: inputSuffix,
              suffixStyle: const TextStyle(fontSize: 24, color: Colors.white70),
              filled: true,
              fillColor: const Color(0xFF1A1A2E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE94560)),
              ),
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _addToCart(),
          ),
          if (_selectedProduct != null && _weightController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Builder(
                builder: (context) {
                  final value = int.tryParse(_weightController.text) ?? 0;
                  double total;

                  switch (_selectedProduct!.unit) {
                    case 'kg':
                      total = (value / 1000) * _selectedProduct!.pricePerKg;
                      break;
                    case 'grams':
                      total = value * _selectedProduct!.pricePerKg;
                      break;
                    case 'item':
                      total = value * _selectedProduct!.pricePerKg;
                      break;
                    default:
                      total = (value / 1000) * _selectedProduct!.pricePerKg;
                  }

                  return Text(
                    'Total: \$${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4CAF50),
                    ),
                    textAlign: TextAlign.center,
                  );
                },
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _addToCart,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Add Item'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartSection() {
    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        if (cart.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF16213E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  size: 48,
                  color: Colors.white30,
                ),
                SizedBox(height: 12),
                Text('Cart is empty', style: TextStyle(color: Colors.white60)),
                Text(
                  'Add products to get started',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF16213E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Cart Items',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${cart.itemCount} items',
                    style: const TextStyle(color: Colors.white60),
                  ),
                ],
              ),
              const Divider(color: Colors.white24),
              ...cart.items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE94560).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.restaurant,
                      color: Color(0xFFE94560),
                    ),
                  ),
                  title: Text(
                    item.product.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    _getCartItemSubtitle(item),
                    style: const TextStyle(color: Colors.white60),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '\$${item.totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Color(0xFF4CAF50),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        onPressed: () => cart.removeItem(index),
                        iconSize: 20,
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xFF16213E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Payment Method',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'Cash', label: Text('Cash')),
                      ButtonSegment(value: 'EcoCash', label: Text('EcoCash')),
                      ButtonSegment(value: 'Card', label: Text('Card')),
                    ],
                    selected: {cart.selectedPaymentMethod},
                    onSelectionChanged: (selected) {
                      cart.setPaymentMethod(selected.first);
                    },
                    style: ButtonStyle(
                      foregroundColor: WidgetStateProperty.resolveWith((
                        states,
                      ) {
                        if (states.contains(WidgetState.selected)) {
                          return Colors.white;
                        }
                        return Colors.white70;
                      }),
                      backgroundColor: WidgetStateProperty.resolveWith((
                        states,
                      ) {
                        if (states.contains(WidgetState.selected)) {
                          return const Color(0xFFE94560);
                        }
                        return const Color(0xFF1A1A2E);
                      }),
                    ),
                  ),
                ),
                if (cart.selectedPaymentMethod == 'Cash') ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _amountReceivedController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}'),
                            ),
                          ],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Amount Received (optional)',
                            labelStyle: const TextStyle(
                              color: Colors.white60,
                              fontSize: 14,
                            ),
                            hintText: '0.00',
                            hintStyle: const TextStyle(color: Colors.white30),
                            prefixText: '\$ ',
                            prefixStyle: const TextStyle(
                              color: Colors.white70,
                              fontSize: 18,
                            ),
                            filled: true,
                            fillColor: const Color(0xFF1A1A2E),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Builder(
                        builder: (context) {
                          final received =
                              double.tryParse(_amountReceivedController.text) ??
                              0;
                          final change = received - cart.totalAmount;
                          if (received > 0 && change >= 0) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'Change',
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '\$${change.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Color(0xFF4CAF50),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                // Optional buyer name and charge fields
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _buyerNameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Buyer Name (optional)',
                          labelStyle: const TextStyle(
                            color: Colors.white60,
                            fontSize: 14,
                          ),
                          hintText: 'Enter name',
                          hintStyle: const TextStyle(color: Colors.white30),
                          filled: true,
                          fillColor: const Color(0xFF1A1A2E),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          prefixIcon: const Icon(
                            Icons.person_outline,
                            color: Colors.white54,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _chargeController,
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
                          labelText: 'Balance/Charge (optional)',
                          labelStyle: const TextStyle(
                            color: Colors.white60,
                            fontSize: 14,
                          ),
                          hintText: '0.00',
                          hintStyle: const TextStyle(color: Colors.white30),
                          prefixText: '\$ ',
                          prefixStyle: const TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: const Color(0xFF1A1A2E),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Amount',
                          style: TextStyle(color: Colors.white70),
                        ),
                        Text(
                          '\$${cart.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: cart.isEmpty ? null : _completeSale,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE94560),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                        ),
                        icon: const Icon(Icons.check),
                        label: const Text(
                          'COMPLETE',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
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
  }
}
