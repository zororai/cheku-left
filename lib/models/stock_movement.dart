class StockMovement {
  final int? id;
  final int sessionId;
  final int productId;
  final int openingGrams; // For items, this represents quantity
  final int soldGrams; // For items, this represents quantity sold
  final int? closingGrams; // For items, this represents quantity remaining
  final int expectedClosingGrams;
  final int? varianceGrams;
  final String createdAt;

  // Optional fields for display
  final String? productName;
  final double? pricePerKg;
  final String unit; // 'kg', 'grams', 'item'

  StockMovement({
    this.id,
    required this.sessionId,
    required this.productId,
    required this.openingGrams,
    this.soldGrams = 0,
    this.closingGrams,
    int? expectedClosingGrams,
    this.varianceGrams,
    String? createdAt,
    this.productName,
    this.pricePerKg,
    this.unit = 'kg',
  }) : expectedClosingGrams =
           expectedClosingGrams ?? (openingGrams - soldGrams),
       createdAt = createdAt ?? DateTime.now().toIso8601String();

  /// Get the unit suffix for display
  String get unitSuffix {
    switch (unit) {
      case 'grams':
        return 'g';
      case 'item':
        return 'pcs';
      default:
        return 'kg'; // Display as kg for kg products
    }
  }

  /// Get formatted value with unit (converts grams to kg for kg products)
  String formatValue(int value) {
    switch (unit) {
      case 'kg':
        // Convert grams to kg for display
        final kgValue = value / 1000;
        return '${kgValue.toStringAsFixed(2)}kg';
      case 'grams':
        return '${value}g';
      case 'item':
        return '${value}pcs';
      default:
        final kgVal = value / 1000;
        return '${kgVal.toStringAsFixed(2)}kg';
    }
  }

  /// Get the input value from stored grams (for editing)
  double getInputValue(int storedValue) {
    switch (unit) {
      case 'kg':
        return storedValue / 1000; // Convert grams to kg
      default:
        return storedValue.toDouble();
    }
  }

  /// Get price label based on unit
  String get priceLabel {
    if (pricePerKg == null) return '';
    switch (unit) {
      case 'grams':
        return '\$${pricePerKg!.toStringAsFixed(2)}/g';
      case 'item':
        return '\$${pricePerKg!.toStringAsFixed(2)}/item';
      default:
        return '\$${pricePerKg!.toStringAsFixed(2)}/kg';
    }
  }

  /// Calculate expected closing stock
  static int calculateExpectedClosing(int openingGrams, int soldGrams) {
    return openingGrams - soldGrams;
  }

  /// Calculate variance (positive = gain, negative = loss)
  static int calculateVariance(int closingGrams, int expectedClosingGrams) {
    return closingGrams - expectedClosingGrams;
  }

  /// Calculate variance value in monetary terms
  double calculateVarianceValue(double pricePerKg) {
    if (varianceGrams == null) return 0.0;
    return (varianceGrams! / 1000) * pricePerKg;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'product_id': productId,
      'opening_grams': openingGrams,
      'sold_grams': soldGrams,
      'closing_grams': closingGrams,
      'expected_closing_grams': expectedClosingGrams,
      'variance_grams': varianceGrams,
      'created_at': createdAt,
    };
  }

  factory StockMovement.fromMap(Map<String, dynamic> map) {
    return StockMovement(
      id: map['id'] as int?,
      sessionId: map['session_id'] as int,
      productId: map['product_id'] as int,
      openingGrams: map['opening_grams'] as int,
      soldGrams: map['sold_grams'] as int? ?? 0,
      closingGrams: map['closing_grams'] as int?,
      expectedClosingGrams: map['expected_closing_grams'] as int?,
      varianceGrams: map['variance_grams'] as int?,
      createdAt: map['created_at'] as String,
      productName: map['product_name'] as String?,
      pricePerKg: map['price_per_kg'] != null
          ? (map['price_per_kg'] as num).toDouble()
          : null,
      unit: map['unit'] as String? ?? 'kg',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'product_id': productId,
      'opening_grams': openingGrams,
      'sold_grams': soldGrams,
      'closing_grams': closingGrams,
      'expected_closing_grams': expectedClosingGrams,
      'variance_grams': varianceGrams,
      'created_at': createdAt,
    };
  }

  StockMovement copyWith({
    int? id,
    int? sessionId,
    int? productId,
    int? openingGrams,
    int? soldGrams,
    int? closingGrams,
    int? expectedClosingGrams,
    int? varianceGrams,
    String? createdAt,
    String? productName,
    double? pricePerKg,
    String? unit,
  }) {
    return StockMovement(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      productId: productId ?? this.productId,
      openingGrams: openingGrams ?? this.openingGrams,
      soldGrams: soldGrams ?? this.soldGrams,
      closingGrams: closingGrams ?? this.closingGrams,
      expectedClosingGrams: expectedClosingGrams ?? this.expectedClosingGrams,
      varianceGrams: varianceGrams ?? this.varianceGrams,
      createdAt: createdAt ?? this.createdAt,
      productName: productName ?? this.productName,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      unit: unit ?? this.unit,
    );
  }

  /// Returns true if this movement has been finalized with closing stock
  bool get isFinalized => closingGrams != null;

  /// Get variance as a formatted string
  String get varianceDisplay {
    if (varianceGrams == null) return '-';
    if (varianceGrams == 0) return '0$unitSuffix';

    // Format variance based on unit type
    switch (unit) {
      case 'kg':
        final kgValue = varianceGrams! / 1000;
        return kgValue > 0
            ? '+${kgValue.toStringAsFixed(2)}kg'
            : '${kgValue.toStringAsFixed(2)}kg';
      case 'grams':
        return varianceGrams! > 0 ? '+${varianceGrams}g' : '${varianceGrams}g';
      case 'item':
        return varianceGrams! > 0
            ? '+${varianceGrams}pcs'
            : '${varianceGrams}pcs';
      default:
        final kgVal = varianceGrams! / 1000;
        return kgVal > 0
            ? '+${kgVal.toStringAsFixed(2)}kg'
            : '${kgVal.toStringAsFixed(2)}kg';
    }
  }
}
