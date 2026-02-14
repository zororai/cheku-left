class ButcherShop {
  final int? id;
  final String name;
  final String? address;
  final String? phone;
  final String? licenseNumber;
  final bool isActive;
  final String createdAt;

  ButcherShop({
    this.id,
    required this.name,
    this.address,
    this.phone,
    this.licenseNumber,
    this.isActive = true,
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'license_number': licenseNumber,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt,
    };
  }

  factory ButcherShop.fromMap(Map<String, dynamic> map) {
    return ButcherShop(
      id: map['id'] as int?,
      name: map['name'] as String,
      address: map['address'] as String?,
      phone: map['phone'] as String?,
      licenseNumber: map['license_number'] as String?,
      isActive: (map['is_active'] as int) == 1,
      createdAt: map['created_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'license_number': licenseNumber,
    };
  }
}
