class SaleItem {
  final int? id;
  final int? saleId;
  final int productId;
  final String productName;
  final int weightGrams; // For items, this represents quantity
  final double pricePerKg; // For items/grams, this is price per unit
  final double totalPrice;
  final String unit; // 'kg', 'grams', 'item'

  SaleItem({
    this.id,
    this.saleId,
    required this.productId,
    required this.productName,
    required this.weightGrams,
    required this.pricePerKg,
    required this.totalPrice,
    this.unit = 'kg',
  });

  /// Calculate total price based on unit type
  static double calculateTotalPrice(int value, double price, String unit) {
    double result;
    switch (unit) {
      case 'grams':
        result = value * price;
        break;
      case 'item':
        result = value * price;
        break;
      default: // kg
        result = (value / 1000) * price;
    }
    return double.parse(result.toStringAsFixed(2));
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sale_id': saleId,
      'product_id': productId,
      'product_name': productName,
      'weight_grams': weightGrams,
      'price_per_kg': pricePerKg,
      'total_price': totalPrice,
    };
  }

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      id: map['id'] as int?,
      saleId: map['sale_id'] as int?,
      productId: map['product_id'] as int,
      productName: map['product_name'] as String,
      weightGrams: map['weight_grams'] as int,
      pricePerKg: (map['price_per_kg'] as num).toDouble(),
      totalPrice: (map['total_price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_name': productName,
      'weight_grams': weightGrams,
      'price_per_kg': pricePerKg,
      'total_price': totalPrice,
    };
  }

  SaleItem copyWith({
    int? id,
    int? saleId,
    int? productId,
    String? productName,
    int? weightGrams,
    double? pricePerKg,
    double? totalPrice,
  }) {
    return SaleItem(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      weightGrams: weightGrams ?? this.weightGrams,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      totalPrice: totalPrice ?? this.totalPrice,
    );
  }
}
