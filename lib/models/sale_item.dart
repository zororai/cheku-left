class SaleItem {
  final int? id;
  final int? saleId;
  final int productId;
  final String productName;
  final int weightGrams;
  final double pricePerKg;
  final double totalPrice;

  SaleItem({
    this.id,
    this.saleId,
    required this.productId,
    required this.productName,
    required this.weightGrams,
    required this.pricePerKg,
    required this.totalPrice,
  });

  static double calculateTotalPrice(int weightGrams, double pricePerKg) {
    double result = (weightGrams / 1000) * pricePerKg;
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
