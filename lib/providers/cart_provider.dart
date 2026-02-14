import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../models/sale_item.dart';

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];
  String _selectedPaymentMethod = 'Cash';

  List<CartItem> get items => List.unmodifiable(_items);
  String get selectedPaymentMethod => _selectedPaymentMethod;

  int get itemCount => _items.length;

  double get totalAmount {
    double total = 0;
    for (var item in _items) {
      total += item.totalPrice;
    }
    return double.parse(total.toStringAsFixed(2));
  }

  int get totalGrams {
    int total = 0;
    for (var item in _items) {
      total += item.weightGrams;
    }
    return total;
  }

  void addItem(Product product, int weightGrams) {
    if (weightGrams <= 0) return;

    final cartItem = CartItem.create(product, weightGrams);
    _items.add(cartItem);
    notifyListeners();
  }

  void removeItem(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      notifyListeners();
    }
  }

  void updateItem(int index, int newWeightGrams) {
    if (index >= 0 && index < _items.length && newWeightGrams > 0) {
      final oldItem = _items[index];
      _items[index] = CartItem.create(oldItem.product, newWeightGrams);
      notifyListeners();
    }
  }

  void setPaymentMethod(String method) {
    _selectedPaymentMethod = method;
    notifyListeners();
  }

  List<SaleItem> toSaleItems() {
    return _items.map((item) => item.toSaleItem()).toList();
  }

  void clear() {
    _items.clear();
    _selectedPaymentMethod = 'Cash';
    notifyListeners();
  }

  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;
}
