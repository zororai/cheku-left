import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/stock_provider.dart';
import '../providers/product_provider.dart';
import '../models/product.dart';
import 'stock_report_screen.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  final Map<int, TextEditingController> _openingControllers = {};
  final Map<int, TextEditingController> _closingControllers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthProvider>();
    final stockProvider = context.read<StockProvider>();
    final productProvider = context.read<ProductProvider>();

    stockProvider.setCurrentUser(
      butcherId: auth.butcherId!,
      userId: auth.userId!,
    );

    await Future.wait([
      stockProvider.loadCurrentSession(butcherId: auth.butcherId),
      productProvider.loadProducts(butcherId: auth.butcherId),
    ]);

    _initControllers();
  }

  void _initControllers() {
    final stockProvider = context.read<StockProvider>();
    final productProvider = context.read<ProductProvider>();

    for (var product in productProvider.activeProducts) {
      _openingControllers[product.id!] = TextEditingController();

      // Find movement if exists, otherwise create empty controller
      final movements = stockProvider.stockMovements.where(
        (m) => m.productId == product.id,
      );

      if (movements.isNotEmpty) {
        _closingControllers[product.id!] = TextEditingController(
          text: movements.first.closingGrams?.toString() ?? '',
        );
      } else {
        _closingControllers[product.id!] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _openingControllers.values) {
      controller.dispose();
    }
    for (var controller in _closingControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _openDay() async {
    final auth = context.read<AuthProvider>();
    final stockProvider = context.read<StockProvider>();
    final productProvider = context.read<ProductProvider>();
    final products = productProvider.activeProducts;

    if (products.isEmpty) {
      _showError('No active products found. Please add products first.');
      return;
    }

    // Show opening stock entry dialog
    final openingStock = await _showOpeningStockDialog(products);
    if (openingStock == null) return;

    final success = await stockProvider.openDay(
      butcherId: auth.butcherId!,
      userId: auth.userId!,
      products: products,
      openingStockGrams: openingStock,
    );

    if (success) {
      _showSuccess('Day opened successfully!');
      _initControllers();
    } else {
      _showError(stockProvider.error ?? 'Failed to open day');
    }
  }

  Future<Map<int, int>?> _showOpeningStockDialog(List<Product> products) async {
    final controllers = <int, TextEditingController>{};
    for (var product in products) {
      controllers[product.id!] = TextEditingController(text: '0');
    }

    // Helper to get unit suffix for display
    String getUnitSuffix(String unit) {
      switch (unit) {
        case 'grams':
          return 'g';
        case 'item':
          return 'pcs';
        default:
          return 'kg'; // kg products input in kg
      }
    }

    // Helper to get hint text
    String getHintText(String unit) {
      switch (unit) {
        case 'grams':
          return 'grams';
        case 'item':
          return 'quantity';
        default:
          return 'kg'; // kg products input in kg
      }
    }

    // Helper to convert input value to grams for storage
    int convertToGrams(String unit, double value) {
      switch (unit) {
        case 'kg':
          return (value * 1000).round(); // Convert kg to grams
        case 'grams':
        case 'item':
        default:
          return value.round(); // Already in grams or is quantity
      }
    }

    return showDialog<Map<int, int>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          'Enter Opening Stock',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              final unitSuffix = getUnitSuffix(product.unit);
              final hintText = getHintText(product.unit);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(color: Colors.white),
                          ),
                          Text(
                            product.priceLabel,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: controllers[product.id!],
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: hintText,
                          hintStyle: const TextStyle(color: Colors.white38),
                          filled: true,
                          fillColor: const Color(0xFF1A1A2E),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 30,
                      child: Text(
                        unitSuffix,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final result = <int, int>{};
              for (var product in products) {
                final text = controllers[product.id!]?.text ?? '0';
                final value = double.tryParse(text) ?? 0;
                // Convert to grams for kg products, keep as-is for others
                result[product.id!] = convertToGrams(product.unit, value);
              }
              Navigator.pop(ctx, result);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F3460),
            ),
            child: const Text('Open Day'),
          ),
        ],
      ),
    );
  }

  Future<void> _closeDay() async {
    final stockProvider = context.read<StockProvider>();
    final session = stockProvider.currentSession;

    if (session == null) {
      _showError('No open session found');
      return;
    }

    // Check if all closing stocks are entered
    final movements = stockProvider.stockMovements;
    final missingClosing = movements
        .where((m) => m.closingGrams == null)
        .toList();

    if (missingClosing.isNotEmpty) {
      _showError('Please enter closing stock for all products first.');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Close Day', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to close today\'s session?',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            _buildVarianceSummary(),
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
              backgroundColor: const Color(0xFFE94560),
            ),
            child: const Text('Close Day'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await stockProvider.closeDay(session.id!);
      if (success) {
        _showSuccess('Day closed successfully!');
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StockReportScreen(sessionId: session.id!),
            ),
          );
        }
      } else {
        _showError(stockProvider.error ?? 'Failed to close day');
      }
    }
  }

  Widget _buildVarianceSummary() {
    final stockProvider = context.read<StockProvider>();
    final variance = stockProvider.totalVarianceGrams;
    final varianceValue = stockProvider.totalVarianceValue;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Variance:',
                style: TextStyle(color: Colors.white70),
              ),
              Text(
                '${variance >= 0 ? '+' : ''}${variance}g',
                style: TextStyle(
                  color: variance >= 0 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Variance Value:',
                style: TextStyle(color: Colors.white70),
              ),
              Text(
                '\$${varianceValue.abs().toStringAsFixed(2)}',
                style: TextStyle(
                  color: varianceValue >= 0 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _updateClosingStock(
    int movementId,
    int productId,
    String unit,
  ) async {
    final controller = _closingControllers[productId];
    if (controller == null) return;

    final value = double.tryParse(controller.text) ?? 0;
    final stockProvider = context.read<StockProvider>();

    // Convert kg to grams for storage
    int grams;
    if (unit == 'kg') {
      grams = (value * 1000).round();
    } else {
      grams = value.round();
    }

    await stockProvider.recordClosingStock(movementId, grams);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stockProvider = context.watch<StockProvider>();
    final productProvider = context.watch<ProductProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Stock Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.inventory),
            onPressed: () => _showStockInventory(productProvider),
            tooltip: 'Stock Inventory',
          ),
          if (stockProvider.currentSession != null)
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () => _showSessionHistory(),
              tooltip: 'History',
            ),
        ],
      ),
      body: stockProvider.isLoading || productProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(stockProvider, productProvider),
    );
  }

  Widget _buildBody(
    StockProvider stockProvider,
    ProductProvider productProvider,
  ) {
    final session = stockProvider.currentSession;

    if (session == null) {
      return _buildOpenDayView();
    }

    return _buildStockOverview(stockProvider, productProvider);
  }

  Widget _buildOpenDayView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.white24),
          const SizedBox(height: 24),
          const Text(
            'No Active Session',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Open a new day to start tracking stock',
            style: TextStyle(color: Colors.white54),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _openDay,
            icon: const Icon(Icons.play_arrow),
            label: const Text('OPEN DAY'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F3460),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockOverview(
    StockProvider stockProvider,
    ProductProvider productProvider,
  ) {
    final movements = stockProvider.stockMovements;

    return Column(
      children: [
        _buildSessionHeader(stockProvider),
        Expanded(
          child: movements.isEmpty
              ? const Center(
                  child: Text(
                    'No stock movements recorded',
                    style: TextStyle(color: Colors.white54),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: movements.length,
                  itemBuilder: (context, index) {
                    final movement = movements[index];
                    return _buildMovementCard(movement);
                  },
                ),
        ),
        SafeArea(top: false, child: _buildBottomActions(stockProvider)),
      ],
    );
  }

  Widget _buildSessionHeader(StockProvider stockProvider) {
    final session = stockProvider.currentSession!;

    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF16213E),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'DAY OPEN',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            'Opened: ${_formatTime(session.openTime)}',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildMovementCard(movement) {
    final isFinalized = movement.closingGrams != null;
    final unitSuffix = movement.unitSuffix;
    final closingLabel = movement.unit == 'item'
        ? 'Closing Stock (pcs)'
        : 'Closing Stock (${unitSuffix})';

    return Card(
      color: const Color(0xFF16213E),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  movement.productName ?? 'Product ${movement.productId}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (movement.pricePerKg != null)
                  Text(
                    movement.priceLabel,
                    style: const TextStyle(color: Colors.white54),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStockColumn(
                  'Opening',
                  movement.formatValue(movement.openingGrams),
                  Colors.blue,
                ),
                _buildStockColumn(
                  'Sold',
                  movement.formatValue(movement.soldGrams),
                  Colors.orange,
                ),
                _buildStockColumn(
                  'Expected',
                  movement.formatValue(movement.expectedClosingGrams),
                  Colors.white54,
                ),
              ],
            ),
            const Divider(color: Colors.white24),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _closingControllers[movement.productId],
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: closingLabel,
                      labelStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF1A1A2E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _updateClosingStock(
                      movement.id!,
                      movement.productId,
                      movement.unit,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => _updateClosingStock(
                    movement.id!,
                    movement.productId,
                    movement.unit,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFinalized
                        ? Colors.green
                        : const Color(0xFF0F3460),
                  ),
                  child: Text(isFinalized ? 'Update' : 'Save'),
                ),
              ],
            ),
            if (isFinalized) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Actual Closing: ${movement.formatValue(movement.closingGrams!)}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  Text(
                    'Variance: ${movement.varianceDisplay}',
                    style: TextStyle(
                      color: (movement.varianceGrams ?? 0) >= 0
                          ? Colors.green
                          : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStockColumn(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(StockProvider stockProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF16213E),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                if (stockProvider.currentSession != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StockReportScreen(
                        sessionId: stockProvider.currentSession!.id!,
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.assessment),
              label: const Text('VIEW REPORT'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F3460),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _closeDay,
              icon: const Icon(Icons.close),
              label: const Text('CLOSE DAY'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE94560),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showSessionHistory() async {
    final stockProvider = context.read<StockProvider>();
    final sessions = await stockProvider.getSessionHistory();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16213E),
      builder: (ctx) => Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Session History',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index];
                return ListTile(
                  leading: Icon(
                    session.isOpen ? Icons.lock_open : Icons.lock,
                    color: session.isOpen ? Colors.green : Colors.white54,
                  ),
                  title: Text(
                    _formatDate(session.openTime),
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    session.isOpen ? 'In Progress' : 'Closed',
                    style: TextStyle(
                      color: session.isOpen ? Colors.green : Colors.white54,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Colors.white54,
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            StockReportScreen(sessionId: session.id!),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoDate;
    }
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return isoDate;
    }
  }

  void _showStockInventory(ProductProvider productProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16213E),
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Consumer<ProductProvider>(
          builder: (context, provider, _) {
            final outOfStock = provider.outOfStockProducts;
            final lowStock = provider.lowStockProducts;
            final products = provider.activeProducts;

            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Text(
                        'Stock Inventory',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                if (outOfStock.isNotEmpty)
                  _buildStockAlertBanner(
                    'Out of Stock',
                    '${outOfStock.length} product(s)',
                    Colors.red,
                    Icons.warning,
                  ),
                if (lowStock.isNotEmpty)
                  _buildStockAlertBanner(
                    'Low Stock',
                    '${lowStock.length} product(s)',
                    Colors.orange,
                    Icons.info,
                  ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return _buildStockInventoryCard(product, provider);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStockAlertBanner(
    String title,
    String subtitle,
    Color color,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Text(subtitle, style: TextStyle(color: color.withOpacity(0.8))),
        ],
      ),
    );
  }

  Widget _buildStockInventoryCard(
    Product product,
    ProductProvider productProvider,
  ) {
    final isOutOfStock = product.isOutOfStock;
    final isLowStock = product.isLowStock;

    Color statusColor = Colors.green;
    String statusText = 'In Stock';
    if (isOutOfStock) {
      statusColor = Colors.red;
      statusText = 'Out of Stock';
    } else if (isLowStock) {
      statusColor = Colors.orange;
      statusText = 'Low Stock';
    }

    return Card(
      color: const Color(0xFF1A1A2E),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          product.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Row(
          children: [
            Text(
              'Stock: ${product.stockDisplay}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit, color: Colors.white54),
          onPressed: () => _showUpdateStockDialog(product, productProvider),
        ),
      ),
    );
  }

  Future<void> _showUpdateStockDialog(
    Product product,
    ProductProvider productProvider,
  ) async {
    final stockController = TextEditingController();
    final minAlertController = TextEditingController(
      text: product.minStockAlertGrams > 0
          ? (product.unit == 'kg'
                ? (product.minStockAlertGrams / 1000).toString()
                : product.minStockAlertGrams.toString())
          : '',
    );

    String getUnitSuffix() {
      switch (product.unit) {
        case 'grams':
          return 'g';
        case 'item':
          return 'pcs';
        default:
          return 'kg';
      }
    }

    final result = await showDialog<Map<String, int>>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: Text(
          'Update Stock: ${product.name}',
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Current Stock: ${product.stockDisplay}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: stockController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Add Stock (${getUnitSuffix()})',
                labelStyle: const TextStyle(color: Colors.white54),
                hintText: 'Enter quantity to add',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF1A1A2E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: minAlertController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Min Stock Alert (${getUnitSuffix()})',
                labelStyle: const TextStyle(color: Colors.white54),
                hintText: 'Alert when stock falls below',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF1A1A2E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final stockValue = double.tryParse(stockController.text) ?? 0;
              final minAlertValue =
                  double.tryParse(minAlertController.text) ?? 0;

              int stockGrams;
              int minAlertGrams;

              if (product.unit == 'kg') {
                stockGrams = (stockValue * 1000).round();
                minAlertGrams = (minAlertValue * 1000).round();
              } else {
                stockGrams = stockValue.round();
                minAlertGrams = minAlertValue.round();
              }

              Navigator.pop(ctx, {
                'addStock': stockGrams,
                'minAlert': minAlertGrams,
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F3460),
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      final auth = context.read<AuthProvider>();
      final provider = context.read<ProductProvider>();

      bool updated = false;

      if (result['addStock']! > 0) {
        final success = await provider.addStock(
          product.id!,
          result['addStock']!,
          butcherId: auth.butcherId,
        );
        updated = success;
      }

      if (result['minAlert'] != product.minStockAlertGrams) {
        // Refresh product from provider to get latest data
        final currentProduct = provider.products.firstWhere(
          (p) => p.id == product.id,
          orElse: () => product,
        );
        final updatedProduct = currentProduct.copyWith(
          minStockAlertGrams: result['minAlert'],
        );
        final success = await provider.updateProduct(updatedProduct);
        updated = updated || success;
      }

      if (mounted && updated) {
        _showSuccess('Stock updated successfully!');
      }
    }
  }
}
