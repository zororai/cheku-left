import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/sale.dart';
import '../models/sale_item.dart';
import '../services/sync_service.dart';
import '../services/license_service.dart';

class SaleProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final SyncService _syncService = SyncService();
  final LicenseService _licenseService = LicenseService();

  List<Sale> _sales = [];
  List<Sale> _todaySales = [];
  List<Sale> _unsyncedSales = [];
  Map<String, dynamic> _dailySummary = {};
  bool _isLoading = false;
  bool _isSyncing = false;
  bool _isLicenseLocked = false;

  int? _currentButcherId;
  String? _currentButcherName;

  List<Sale> get sales => _sales;
  List<Sale> get todaySales => _todaySales;
  List<Sale> get unsyncedSales => _unsyncedSales;
  Map<String, dynamic> get dailySummary => _dailySummary;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  bool get isLicenseLocked => _isLicenseLocked;

  int get unsyncedCount => _unsyncedSales.length;

  void setCurrentUser({required int butcherId, String? butcherName}) {
    _currentButcherId = butcherId;
    _currentButcherName = butcherName;
  }

  Future<void> loadSales({int? butcherId, int? userId}) async {
    _isLoading = true;
    notifyListeners();

    final bId = butcherId ?? _currentButcherId;

    try {
      _sales = await _db.getAllSales(butcherId: bId);
      _todaySales = await _db.getTodaySales(butcherId: bId);
      _unsyncedSales = await _db.getUnsyncedSales(butcherId: bId);
      _dailySummary = await _db.getDailySummary(butcherId: bId);
    } catch (e) {
      debugPrint('Error loading sales: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> isDayOpen({int? butcherId}) async {
    final bId = butcherId ?? _currentButcherId;
    if (bId == null) return false;
    return await _db.hasUnclosedSession(butcherId: bId);
  }

  Future<String> createSale({
    required int butcherId,
    required int userId,
    required double totalAmount,
    required String paymentMethod,
    required List<SaleItem> items,
    bool checkStockSession = true,
    bool checkStockAvailability = true,
  }) async {
    try {
      // Check if day is open (stock session exists)
      if (checkStockSession) {
        final dayOpen = await isDayOpen(butcherId: butcherId);
        if (!dayOpen) {
          throw Exception('You must open stock for the day first.');
        }
      }

      // Check stock availability for all items
      if (checkStockAvailability) {
        for (var item in items) {
          final product = await _db.getProductById(item.productId);
          if (product == null) {
            throw Exception('Product not found: ${item.productName}');
          }
          if (product.isOutOfStock) {
            throw Exception('${product.name} is out of stock.');
          }
          if (!product.hasEnoughStock(item.weightGrams)) {
            final available = product.stockDisplay;
            throw Exception(
              'Insufficient stock for ${product.name}. Available: $available',
            );
          }
        }
      }

      final nextNumber = await _db.getNextSaleNumber(butcherId: butcherId);
      final saleNumber = 'CL-${nextNumber.toString().padLeft(4, '0')}';

      final sale = Sale(
        butcherId: butcherId,
        userId: userId,
        saleNumber: saleNumber,
        totalAmount: totalAmount,
        paymentMethod: paymentMethod,
        isSynced: false,
      );

      await _db.insertSale(sale, items);

      // Update stock movements - deduct sold grams
      final session = await _db.getOpenSession(butcherId: butcherId);
      if (session != null) {
        for (var item in items) {
          await _db.updateStockMovementSoldGrams(
            session.id!,
            item.productId,
            item.weightGrams,
          );
        }
      }

      // Deduct from product stock
      for (var item in items) {
        await _db.deductProductStock(item.productId, item.weightGrams);
      }

      await loadSales(butcherId: butcherId);

      // Increment payment count and check license status
      final butcherName = _currentButcherName ?? 'Unknown';
      final licenseStatus = await _licenseService.incrementPaymentCount(
        butcherId: butcherId,
        butcherName: butcherName,
      );

      if (licenseStatus.isLocked) {
        _isLicenseLocked = true;
        notifyListeners();
      }

      return saleNumber;
    } catch (e) {
      debugPrint('Error creating sale: $e');
      rethrow;
    }
  }

  Future<void> checkLicenseStatus({required int butcherId}) async {
    try {
      final status = await _licenseService.checkLicenseStatus(
        butcherId: butcherId,
      );
      _isLicenseLocked = status.isLocked;
      notifyListeners();
    } catch (e) {
      debugPrint('Error checking license: $e');
    }
  }

  void setLicenseLocked(bool locked) {
    _isLicenseLocked = locked;
    notifyListeners();
  }

  Future<SyncResult> syncSales({String? apiToken, int? butcherId}) async {
    _isSyncing = true;
    notifyListeners();

    try {
      final result = await _syncService.syncSales(
        apiToken: apiToken,
        butcherId: butcherId ?? _currentButcherId,
      );
      await loadSales(butcherId: butcherId ?? _currentButcherId);
      return result;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<bool> hasInternetConnection() async {
    return await _syncService.hasInternetConnection();
  }
}
