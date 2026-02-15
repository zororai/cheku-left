import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../database/database_helper.dart';
import '../models/sale.dart';
import '../models/product.dart';

class SyncService {
  static const String baseUrl = 'https://api.chekuleft.com';
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<bool> hasInternetConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<SyncResult> syncSales({String? apiToken, int? butcherId}) async {
    if (!await hasInternetConnection()) {
      return SyncResult(
        success: false,
        message: 'No internet connection',
        syncedCount: 0,
        failedCount: 0,
      );
    }

    final unsyncedSales = await _db.getUnsyncedSales(butcherId: butcherId);

    if (unsyncedSales.isEmpty) {
      return SyncResult(
        success: true,
        message: 'No sales to sync',
        syncedCount: 0,
        failedCount: 0,
      );
    }

    int syncedCount = 0;
    int failedCount = 0;
    List<String> errors = [];

    for (var sale in unsyncedSales) {
      try {
        final response = await _sendSaleToServer(sale, apiToken);

        if (response) {
          await _db.markSaleAsSynced(sale.id!);
          syncedCount++;
        } else {
          failedCount++;
          errors.add('Failed to sync sale ${sale.saleNumber}');
        }
      } catch (e) {
        failedCount++;
        errors.add('Error syncing ${sale.saleNumber}: $e');
      }
    }

    return SyncResult(
      success: failedCount == 0,
      message: failedCount == 0
          ? 'Successfully synced $syncedCount sales'
          : 'Synced $syncedCount, failed $failedCount',
      syncedCount: syncedCount,
      failedCount: failedCount,
      errors: errors,
    );
  }

  Future<bool> _sendSaleToServer(Sale sale, String? apiToken) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (apiToken != null && apiToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $apiToken';
      }

      final body = jsonEncode({
        'sales': [sale.toJson()],
      });

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/sales/sync'),
            headers: headers,
            body: body,
          )
          .timeout(const Duration(seconds: 30));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<SyncResult> syncAllSales({String? apiToken}) async {
    if (!await hasInternetConnection()) {
      return SyncResult(
        success: false,
        message: 'No internet connection',
        syncedCount: 0,
        failedCount: 0,
      );
    }

    final unsyncedSales = await _db.getUnsyncedSales();

    if (unsyncedSales.isEmpty) {
      return SyncResult(
        success: true,
        message: 'No sales to sync',
        syncedCount: 0,
        failedCount: 0,
      );
    }

    try {
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (apiToken != null && apiToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $apiToken';
      }

      final body = jsonEncode({
        'sales': unsyncedSales.map((s) => s.toJson()).toList(),
      });

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/sales/sync'),
            headers: headers,
            body: body,
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200 || response.statusCode == 201) {
        for (var sale in unsyncedSales) {
          await _db.markSaleAsSynced(sale.id!);
        }

        return SyncResult(
          success: true,
          message: 'Successfully synced ${unsyncedSales.length} sales',
          syncedCount: unsyncedSales.length,
          failedCount: 0,
        );
      } else {
        return SyncResult(
          success: false,
          message: 'Server error: ${response.statusCode}',
          syncedCount: 0,
          failedCount: unsyncedSales.length,
        );
      }
    } catch (e) {
      return SyncResult(
        success: false,
        message: 'Sync failed: $e',
        syncedCount: 0,
        failedCount: unsyncedSales.length,
      );
    }
  }

  // PRODUCTS SYNC
  Future<SyncResult> syncProducts({
    required List<Product> products,
    required int butcherId,
    String? apiToken,
  }) async {
    if (!await hasInternetConnection()) {
      return SyncResult(
        success: false,
        message: 'No internet connection',
        syncedCount: 0,
        failedCount: 0,
      );
    }

    if (products.isEmpty) {
      return SyncResult(
        success: true,
        message: 'No products to sync',
        syncedCount: 0,
        failedCount: 0,
      );
    }

    try {
      final headers = _buildHeaders(apiToken);

      final body = jsonEncode({
        'butcher_id': butcherId,
        'products': products
            .map(
              (p) => {
                'id': p.id,
                'name': p.name,
                'price_per_kg': p.pricePerKg,
                'is_active': p.isActive ? 1 : 0,
              },
            )
            .toList(),
      });

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/products/sync'),
            headers: headers,
            body: body,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return SyncResult(
          success: true,
          message: 'Successfully synced ${products.length} products',
          syncedCount: products.length,
          failedCount: 0,
        );
      } else {
        return SyncResult(
          success: false,
          message: 'Server error: ${response.statusCode}',
          syncedCount: 0,
          failedCount: products.length,
        );
      }
    } catch (e) {
      debugPrint('Error syncing products: $e');
      return SyncResult(
        success: false,
        message: 'Sync failed: $e',
        syncedCount: 0,
        failedCount: products.length,
      );
    }
  }

  // OPEN DAY (STOCK SESSION) SYNC - Per Product
  Future<SyncResult> syncOpenDay({
    required int butcherId,
    required int userId,
    required int sessionId,
    required DateTime openedAt,
    required List<Map<String, dynamic>> stockMovements,
    String? apiToken,
  }) async {
    if (!await hasInternetConnection()) {
      return SyncResult(
        success: false,
        message: 'No internet connection',
        syncedCount: 0,
        failedCount: 0,
      );
    }

    try {
      final headers = _buildHeaders(apiToken);

      final body = jsonEncode({
        'butcher_id': butcherId,
        'user_id': userId,
        'local_session_id': sessionId,
        'opened_at': openedAt.toIso8601String(),
        'stock_movements': stockMovements,
      });

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/stock-sessions/open'),
            headers: headers,
            body: body,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return SyncResult(
          success: true,
          message: 'Open day synced successfully',
          syncedCount: stockMovements.length,
          failedCount: 0,
        );
      } else {
        return SyncResult(
          success: false,
          message: 'Server error: ${response.statusCode}',
          syncedCount: 0,
          failedCount: stockMovements.length,
        );
      }
    } catch (e) {
      debugPrint('Error syncing open day: $e');
      return SyncResult(
        success: false,
        message: 'Sync failed: $e',
        syncedCount: 0,
        failedCount: 1,
      );
    }
  }

  // CLOSE DAY (STOCK SESSION) SYNC - Per Product
  Future<SyncResult> syncCloseDay({
    required int butcherId,
    required int userId,
    required int sessionId,
    required DateTime openedAt,
    required DateTime closedAt,
    required List<Map<String, dynamic>> stockMovements,
    String? notes,
    String? apiToken,
  }) async {
    if (!await hasInternetConnection()) {
      return SyncResult(
        success: false,
        message: 'No internet connection',
        syncedCount: 0,
        failedCount: 0,
      );
    }

    try {
      final headers = _buildHeaders(apiToken);

      final body = jsonEncode({
        'butcher_id': butcherId,
        'user_id': userId,
        'local_session_id': sessionId,
        'notes': notes,
        'opened_at': openedAt.toIso8601String(),
        'closed_at': closedAt.toIso8601String(),
        'stock_movements': stockMovements,
      });

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/stock-sessions/close'),
            headers: headers,
            body: body,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return SyncResult(
          success: true,
          message: 'Close day synced successfully',
          syncedCount: stockMovements.length,
          failedCount: 0,
        );
      } else {
        return SyncResult(
          success: false,
          message: 'Server error: ${response.statusCode}',
          syncedCount: 0,
          failedCount: stockMovements.length,
        );
      }
    } catch (e) {
      debugPrint('Error syncing close day: $e');
      return SyncResult(
        success: false,
        message: 'Sync failed: $e',
        syncedCount: 0,
        failedCount: 1,
      );
    }
  }

  // SYNC ALL DATA (Products + Sales + Stock)
  Future<Map<String, SyncResult>> syncAll({
    required int butcherId,
    required int userId,
    String? apiToken,
  }) async {
    final results = <String, SyncResult>{};

    // Sync products
    final products = await _db.getAllProducts(butcherId: butcherId);
    results['products'] = await syncProducts(
      products: products,
      butcherId: butcherId,
      apiToken: apiToken,
    );

    // Sync sales
    results['sales'] = await syncSales(
      butcherId: butcherId,
      apiToken: apiToken,
    );

    return results;
  }

  Map<String, String> _buildHeaders(String? apiToken) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (apiToken != null && apiToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $apiToken';
    }

    return headers;
  }
}

class SyncResult {
  final bool success;
  final String message;
  final int syncedCount;
  final int failedCount;
  final List<String> errors;

  SyncResult({
    required this.success,
    required this.message,
    required this.syncedCount,
    required this.failedCount,
    this.errors = const [],
  });
}
