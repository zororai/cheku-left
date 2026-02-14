class User {
  final int? id;
  final int butcherId;
  final String username;
  final String fullName;
  final String role; // 'admin', 'cashier', 'manager'
  final bool isActive;
  final String createdAt;

  User({
    this.id,
    required this.butcherId,
    required this.username,
    required this.fullName,
    required this.role,
    this.isActive = true,
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'butcher_id': butcherId,
      'username': username,
      'full_name': fullName,
      'role': role,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      butcherId: map['butcher_id'] as int,
      username: map['username'] as String,
      fullName: map['full_name'] as String,
      role: map['role'] as String,
      isActive: (map['is_active'] as int) == 1,
      createdAt: map['created_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'butcher_id': butcherId,
      'username': username,
      'full_name': fullName,
      'role': role,
    };
  }

  bool get isAdmin => role == 'admin';
  bool get isManager => role == 'manager';
  bool get isCashier => role == 'cashier';
}
