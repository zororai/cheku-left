import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/product.dart';

class ProductProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<Product> _products = [];
  List<Product> _activeProducts = [];
  bool _isLoading = false;
  int? _currentButcherId;

  List<Product> get products => _products;
  List<Product> get activeProducts => _activeProducts;
  bool get isLoading => _isLoading;

  void setCurrentButcher(int butcherId) {
    _currentButcherId = butcherId;
  }

  Future<void> loadProducts({int? butcherId}) async {
    _isLoading = true;
    notifyListeners();

    final bId = butcherId ?? _currentButcherId;

    try {
      _products = await _db.getAllProducts(butcherId: bId);
      _activeProducts = await _db.getActiveProducts(butcherId: bId);
    } catch (e) {
      debugPrint('Error loading products: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addProduct(Product product) async {
    try {
      await _db.insertProduct(product);
      await loadProducts(butcherId: product.butcherId);
      return true;
    } catch (e) {
      debugPrint('Error adding product: $e');
      return false;
    }
  }

  Future<bool> updateProduct(Product product) async {
    try {
      await _db.updateProduct(product);
      await loadProducts(butcherId: product.butcherId);
      return true;
    } catch (e) {
      debugPrint('Error updating product: $e');
      return false;
    }
  }

  Future<bool> deleteProduct(int id, {int? butcherId}) async {
    try {
      await _db.deleteProduct(id);
      await loadProducts(butcherId: butcherId ?? _currentButcherId);
      return true;
    } catch (e) {
      debugPrint('Error deleting product: $e');
      return false;
    }
  }

  Future<bool> toggleProductStatus(Product product) async {
    try {
      final updated = product.copyWith(isActive: !product.isActive);
      await _db.updateProduct(updated);
      await loadProducts(butcherId: product.butcherId);
      return true;
    } catch (e) {
      debugPrint('Error toggling product status: $e');
      return false;
    }
  }

  // STOCK MANAGEMENT METHODS
  Future<bool> updateStock(
    int productId,
    int stockGrams, {
    int? butcherId,
  }) async {
    try {
      await _db.updateProductStock(productId, stockGrams);
      await loadProducts(butcherId: butcherId ?? _currentButcherId);
      return true;
    } catch (e) {
      debugPrint('Error updating stock: $e');
      return false;
    }
  }

  Future<bool> addStock(int productId, int gramsToAdd, {int? butcherId}) async {
    try {
      await _db.addProductStock(productId, gramsToAdd);
      await loadProducts(butcherId: butcherId ?? _currentButcherId);
      return true;
    } catch (e) {
      debugPrint('Error adding stock: $e');
      return false;
    }
  }

  Future<bool> deductStock(
    int productId,
    int gramsToDeduct, {
    int? butcherId,
  }) async {
    try {
      await _db.deductProductStock(productId, gramsToDeduct);
      await loadProducts(butcherId: butcherId ?? _currentButcherId);
      return true;
    } catch (e) {
      debugPrint('Error deducting stock: $e');
      return false;
    }
  }

  Future<bool> hasEnoughStock(int productId, int requiredGrams) async {
    return await _db.hasEnoughStock(productId, requiredGrams);
  }

  Future<Product?> getProductById(int productId) async {
    return await _db.getProductById(productId);
  }

  List<Product> get outOfStockProducts =>
      _activeProducts.where((p) => p.isOutOfStock).toList();

  List<Product> get lowStockProducts =>
      _activeProducts.where((p) => p.isLowStock).toList();

  List<Product> get availableProducts =>
      _activeProducts.where((p) => !p.isOutOfStock).toList();
}
