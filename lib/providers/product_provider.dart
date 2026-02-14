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
}
