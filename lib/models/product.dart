class Product {
  final int? id;
  final int butcherId;
  final String name;
  final double pricePerKg;
  final String unit; // 'kg', 'grams', 'item'
  final bool isActive;
  final String createdAt;

  Product({
    this.id,
    required this.butcherId,
    required this.name,
    required this.pricePerKg,
    this.unit = 'kg',
    this.isActive = true,
    String? createdAt,
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'butcher_id': butcherId,
      'name': name,
      'price_per_kg': pricePerKg,
      'unit': unit,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt,
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
  }) {
    return Product(
      id: id ?? this.id,
      butcherId: butcherId ?? this.butcherId,
      name: name ?? this.name,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      unit: unit ?? this.unit,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
