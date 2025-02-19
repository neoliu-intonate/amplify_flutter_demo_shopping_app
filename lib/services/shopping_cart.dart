import '../models/cart_item.dart';
import '../models/Product.dart';

class ShoppingCart {
  static final ShoppingCart instance = ShoppingCart._internal();
  ShoppingCart._internal();

  final Map<String, CartItem> items = {};

  void addProduct(Product product) {
    final id = product.id;
    if (items.containsKey(id)) {
      items[id]!.quantity++;
    } else {
      items[id] = CartItem(product: product, quantity: 1);
    }
  }

  void removeProduct(Product product) {
    final id = product.id;
    if (items.containsKey(id)) {
      if (items[id]!.quantity > 1) {
        items[id]!.quantity--;
      } else {
        items.remove(id);
      }
    }
  }

  void clear() {
    items.clear();
  }

  List<CartItem> getItems() => items.values.toList();
}
