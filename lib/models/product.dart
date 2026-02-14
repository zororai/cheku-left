class Product {
  final int? id;
  final int butcherId;
  final String name;
  final double pricePerKg;
  final bool isActive;
  final String createdAt;

  Product({
    this.id,
    required this.butcherId,
    required this.name,
    required this.pricePerKg,
    this.isActive = true,
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'butcher_id': butcherId,
      'name': name,
      'price_per_kg': pricePerKg,
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
      isActive: (map['is_active'] as int) == 1,
      createdAt: map['created_at'] as String,
    );
  }

  Product copyWith({
    int? id,
    int? butcherId,
    String? name,
    double? pricePerKg,
    bool? isActive,
    String? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      butcherId: butcherId ?? this.butcherId,
      name: name ?? this.name,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
