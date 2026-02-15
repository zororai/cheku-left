class StockSession {
  final int? id;
  final int butcherId;
  final int userId;
  final String openTime;
  final String? closeTime;
  final String status; // 'open' or 'closed'
  final String createdAt;

  // Optional fields for display
  final String? userName;

  StockSession({
    this.id,
    required this.butcherId,
    required this.userId,
    required this.openTime,
    this.closeTime,
    this.status = 'open',
    String? createdAt,
    this.userName,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'butcher_id': butcherId,
      'user_id': userId,
      'open_time': openTime,
      'close_time': closeTime,
      'status': status,
      'created_at': createdAt,
    };
  }

  factory StockSession.fromMap(Map<String, dynamic> map) {
    return StockSession(
      id: map['id'] as int?,
      butcherId: map['butcher_id'] as int,
      userId: map['user_id'] as int,
      openTime: map['open_time'] as String,
      closeTime: map['close_time'] as String?,
      status: map['status'] as String,
      createdAt: map['created_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'butcher_id': butcherId,
      'user_id': userId,
      'open_time': openTime,
      'close_time': closeTime,
      'status': status,
      'created_at': createdAt,
    };
  }

  StockSession copyWith({
    int? id,
    int? butcherId,
    int? userId,
    String? openTime,
    String? closeTime,
    String? status,
    String? createdAt,
    String? userName,
  }) {
    return StockSession(
      id: id ?? this.id,
      butcherId: butcherId ?? this.butcherId,
      userId: userId ?? this.userId,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      userName: userName ?? this.userName,
    );
  }

  bool get isOpen => status == 'open';
  bool get isClosed => status == 'closed';
}
