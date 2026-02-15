class StockMovement {
  final int? id;
  final int sessionId;
  final int productId;
  final int openingGrams;
  final int soldGrams;
  final int? closingGrams;
  final int expectedClosingGrams;
  final int? varianceGrams;
  final String createdAt;

  // Optional fields for display
  final String? productName;
  final double? pricePerKg;

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
  }) : expectedClosingGrams =
           expectedClosingGrams ?? (openingGrams - soldGrams),
       createdAt = createdAt ?? DateTime.now().toIso8601String();

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
    );
  }

  /// Returns true if this movement has been finalized with closing stock
  bool get isFinalized => closingGrams != null;

  /// Get variance as a formatted string
  String get varianceDisplay {
    if (varianceGrams == null) return '-';
    if (varianceGrams == 0) return '0g';
    return varianceGrams! > 0 ? '+${varianceGrams}g' : '${varianceGrams}g';
  }
}
