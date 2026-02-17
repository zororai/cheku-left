import 'product.dart';
import 'sale_item.dart';

class CartItem {
  final Product product;
  final int weightGrams; // For items, this represents quantity
  final double totalPrice;

  CartItem({
    required this.product,
    required this.weightGrams,
    required this.totalPrice,
  });

  factory CartItem.create(Product product, int weightGrams) {
    double totalPrice = SaleItem.calculateTotalPrice(
      weightGrams,
      product.pricePerKg,
      product.unit,
    );
    return CartItem(
      product: product,
      weightGrams: weightGrams,
      totalPrice: totalPrice,
    );
  }

  SaleItem toSaleItem() {
    return SaleItem(
      productId: product.id!,
      productName: product.name,
      weightGrams: weightGrams,
      pricePerKg: product.pricePerKg,
      totalPrice: totalPrice,
      unit: product.unit,
    );
  }
}
