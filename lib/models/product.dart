class Product {
  final int? id;
  final int butcherId;
  final String name;
  final double pricePerKg;
  final String unit; // 'kg', 'grams', 'item'
  final bool isActive;
  final String createdAt;
  final int
  currentStockGrams; // Current available stock in grams (or quantity for 'item' unit)
  final int
  minStockAlertGrams; // Minimum stock level before alert (0 = no alert)

  Product({
    this.id,
    required this.butcherId,
    required this.name,
    required this.pricePerKg,
    this.unit = 'kg',
    this.isActive = true,
    String? createdAt,
    this.currentStockGrams = 0,
    this.minStockAlertGrams = 0,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  /// Get price label based on unit type
  String get priceLabel {
    switch (unit) {
      case 'grams':
        return '\$${pricePerKg.toStringAsFixed(2)}/g';
      case 'item':
        return '\$${pricePerKg.toStringAsFixed(2)}/item';
      default:
        return '\$${pricePerKg.toStringAsFixed(2)}/kg';
    }
  }

  /// Get unit display name
  String get unitDisplay {
    switch (unit) {
      case 'grams':
        return 'Grams';
      case 'item':
        return 'Item';
      default:
        return 'Kg';
    }
  }

  /// Check if product is out of stock
  bool get isOutOfStock => currentStockGrams <= 0;

  /// Check if stock is low (below minimum alert level)
  bool get isLowStock =>
      minStockAlertGrams > 0 &&
      currentStockGrams <= minStockAlertGrams &&
      currentStockGrams > 0;

  /// Get formatted stock display
  String get stockDisplay {
    switch (unit) {
      case 'grams':
        return '${currentStockGrams}g';
      case 'item':
        return '$currentStockGrams pcs';
      default:
        return '${(currentStockGrams / 1000).toStringAsFixed(2)} kg';
    }
  }

  /// Check if there's enough stock for a sale
  bool hasEnoughStock(int requiredGrams) => currentStockGrams >= requiredGrams;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'butcher_id': butcherId,
      'name': name,
      'price_per_kg': pricePerKg,
      'unit': unit,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt,
      'current_stock_grams': currentStockGrams,
      'min_stock_alert_grams': minStockAlertGrams,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      butcherId: map['butcher_id'] as int,
      name: map['name'] as String,
      pricePerKg: (map['price_per_kg'] as num).toDouble(),
      unit: map['unit'] as String? ?? 'kg',
      isActive: (map['is_active'] as int) == 1,
      createdAt: map['created_at'] as String,
      currentStockGrams: (map['current_stock_grams'] as int?) ?? 0,
      minStockAlertGrams: (map['min_stock_alert_grams'] as int?) ?? 0,
    );
  }

  Product copyWith({
    int? id,
    int? butcherId,
    String? name,
    double? pricePerKg,
    String? unit,
    bool? isActive,
    String? createdAt,
    int? currentStockGrams,
    int? minStockAlertGrams,
  }) {
    return Product(
      id: id ?? this.id,
      butcherId: butcherId ?? this.butcherId,
      name: name ?? this.name,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      unit: unit ?? this.unit,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      currentStockGrams: currentStockGrams ?? this.currentStockGrams,
      minStockAlertGrams: minStockAlertGrams ?? this.minStockAlertGrams,
    );
  }
}
