import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/stock_session.dart';
import '../models/stock_movement.dart';
import '../models/product.dart';

class StockProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  StockSession? _currentSession;
  List<StockMovement> _stockMovements = [];
  bool _isLoading = false;
  String? _error;

  int? _currentButcherId;
  int? _currentUserId;

  StockSession? get currentSession => _currentSession;
  List<StockMovement> get stockMovements => _stockMovements;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isDayOpen => _currentSession?.isOpen ?? false;

  int get totalVarianceGrams {
    int total = 0;
    for (var m in _stockMovements) {
      total += m.varianceGrams ?? 0;
    }
    return total;
  }

  double get totalVarianceValue {
    double total = 0;
    for (var m in _stockMovements) {
      if (m.pricePerKg != null && m.varianceGrams != null) {
        total += m.calculateVarianceValue(m.pricePerKg!);
      }
    }
    return total;
  }

  void setCurrentUser({required int butcherId, required int userId}) {
    _currentButcherId = butcherId;
    _currentUserId = userId;
  }

  Future<void> loadCurrentSession({int? butcherId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final bId = butcherId ?? _currentButcherId;
      if (bId == null) {
        _error = 'Butcher ID not set';
        _isLoading = false;
        notifyListeners();
        return;
      }

      _currentSession = await _db.getOpenSession(butcherId: bId);

      if (_currentSession != null) {
        _stockMovements = await _db.getSessionMovements(_currentSession!.id!);
      } else {
        _stockMovements = [];
      }
    } catch (e) {
      debugPrint('Error loading current session: $e');
      _error = 'Failed to load session';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> openDay({
    required int butcherId,
    required int userId,
    required List<Product> products,
    required Map<int, int> openingStockGrams,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Check if there's already an open session
      final existingSession = await _db.getOpenSession(butcherId: butcherId);
      if (existingSession != null) {
        _error = 'A session is already open. Please close it first.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Check for unclosed previous session
      final todaySession = await _db.getTodaySession(butcherId: butcherId);
      if (todaySession != null && todaySession.isOpen) {
        _error = 'Today\'s session is already open.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final now = DateTime.now().toIso8601String();

      // Create new session
      final session = StockSession(
        butcherId: butcherId,
        userId: userId,
        openTime: now,
        status: 'open',
      );

      final sessionId = await _db.insertStockSession(session);

      // Create stock movements for each product with opening stock
      for (var product in products) {
        final openingGrams = openingStockGrams[product.id] ?? 0;

        final movement = StockMovement(
          sessionId: sessionId,
          productId: product.id!,
          openingGrams: openingGrams,
          soldGrams: 0,
          expectedClosingGrams: openingGrams,
        );

        await _db.insertStockMovement(movement);
      }

      // Reload session
      await loadCurrentSession(butcherId: butcherId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error opening day: $e');
      _error = 'Failed to open day: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> closeDay(int sessionId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Check if all movements have closing stock recorded
      final allHaveClosing = await _db.allMovementsHaveClosingStock(sessionId);
      if (!allHaveClosing) {
        _error = 'Please record closing stock for all products first.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final closeTime = DateTime.now().toIso8601String();
      await _db.closeStockSession(sessionId, closeTime);

      _currentSession = null;
      _stockMovements = [];

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error closing day: $e');
      _error = 'Failed to close day: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> recordClosingStock(int movementId, int closingGrams) async {
    try {
      await _db.updateStockMovementClosing(movementId, closingGrams);

      // Reload movements
      if (_currentSession != null) {
        _stockMovements = await _db.getSessionMovements(_currentSession!.id!);
        notifyListeners();
      }

      return true;
    } catch (e) {
      debugPrint('Error recording closing stock: $e');
      _error = 'Failed to record closing stock';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateSoldGrams(int productId, int additionalGrams) async {
    if (_currentSession == null) {
      _error = 'No open session';
      return false;
    }

    try {
      await _db.updateStockMovementSoldGrams(
        _currentSession!.id!,
        productId,
        additionalGrams,
      );

      // Reload movements
      _stockMovements = await _db.getSessionMovements(_currentSession!.id!);
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Error updating sold grams: $e');
      return false;
    }
  }

  Future<void> loadSessionMovements(int sessionId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _stockMovements = await _db.getSessionMovements(sessionId);
    } catch (e) {
      debugPrint('Error loading session movements: $e');
      _error = 'Failed to load stock movements';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> calculateDailyStockReport(int sessionId) async {
    try {
      return await _db.getStockReport(sessionId);
    } catch (e) {
      debugPrint('Error calculating stock report: $e');
      return {};
    }
  }

  Future<List<StockSession>> getSessionHistory({int? butcherId}) async {
    try {
      final bId = butcherId ?? _currentButcherId;
      return await _db.getAllSessions(butcherId: bId);
    } catch (e) {
      debugPrint('Error getting session history: $e');
      return [];
    }
  }

  Future<StockSession?> getSessionById(int id) async {
    try {
      return await _db.getSessionById(id);
    } catch (e) {
      debugPrint('Error getting session: $e');
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Add a stock movement for a newly added product to the current open session
  Future<bool> addProductToOpenSession(int productId) async {
    if (_currentSession == null) {
      return false;
    }

    try {
      // Check if movement already exists for this product
      final existing = await _db.getMovementByProduct(
        _currentSession!.id!,
        productId,
      );
      if (existing != null) {
        return true; // Already exists
      }

      // Create stock movement with 0 opening stock for the new product
      final movement = StockMovement(
        sessionId: _currentSession!.id!,
        productId: productId,
        openingGrams: 0,
        soldGrams: 0,
        expectedClosingGrams: 0,
      );

      await _db.insertStockMovement(movement);

      // Reload movements to reflect the new product
      _stockMovements = await _db.getSessionMovements(_currentSession!.id!);
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Error adding product to open session: $e');
      return false;
    }
  }
}
