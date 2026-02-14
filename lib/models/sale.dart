import 'sale_item.dart';

class Sale {
  final int? id;
  final int butcherId;
  final int userId;
  final String saleNumber;
  final double totalAmount;
  final String paymentMethod;
  final String createdAt;
  final bool isSynced;
  final List<SaleItem> items;

  // Optional fields for display (not stored in DB)
  final String? userName;
  final String? butcherName;

  Sale({
    this.id,
    required this.butcherId,
    required this.userId,
    required this.saleNumber,
    required this.totalAmount,
    required this.paymentMethod,
    String? createdAt,
    this.isSynced = false,
    this.items = const [],
    this.userName,
    this.butcherName,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'butcher_id': butcherId,
      'user_id': userId,
      'sale_number': saleNumber,
      'total_amount': totalAmount,
      'payment_method': paymentMethod,
      'created_at': createdAt,
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map, {List<SaleItem>? items}) {
    return Sale(
      id: map['id'] as int?,
      butcherId: map['butcher_id'] as int,
      userId: map['user_id'] as int,
      saleNumber: map['sale_number'] as String,
      totalAmount: (map['total_amount'] as num).toDouble(),
      paymentMethod: map['payment_method'] as String,
      createdAt: map['created_at'] as String,
      isSynced: (map['is_synced'] as int) == 1,
      items: items ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'butcher_id': butcherId,
      'user_id': userId,
      'sale_number': saleNumber,
      'total_amount': totalAmount,
      'payment_method': paymentMethod,
      'created_at': createdAt,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  Sale copyWith({
    int? id,
    int? butcherId,
    int? userId,
    String? saleNumber,
    double? totalAmount,
    String? paymentMethod,
    String? createdAt,
    bool? isSynced,
    List<SaleItem>? items,
    String? userName,
    String? butcherName,
  }) {
    return Sale(
      id: id ?? this.id,
      butcherId: butcherId ?? this.butcherId,
      userId: userId ?? this.userId,
      saleNumber: saleNumber ?? this.saleNumber,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
      items: items ?? this.items,
      userName: userName ?? this.userName,
      butcherName: butcherName ?? this.butcherName,
    );
  }
}
