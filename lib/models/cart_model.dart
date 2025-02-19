import 'package:amplify_flutter/amplify_flutter.dart';
import 'ModelProvider.dart'; // This should point to your generated models (e.g., Product)

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});
}

class ShoppingCart {
  static final ShoppingCart instance = ShoppingCart._internal();
  ShoppingCart._internal();

  final Map<String, CartItem> _items = {};

  void addProduct(Product product) {
    final id = product.id;
    if (_items.containsKey(id)) {
      _items[id]!.quantity++;
    } else {
      _items[id] = CartItem(product: product, quantity: 1);
    }
  }

  void removeProduct(Product product) {
    final id = product.id;
    if (_items.containsKey(id)) {
      if (_items[id]!.quantity > 1) {
        _items[id]!.quantity--;
      } else {
        _items.remove(id);
      }
    }
  }

  void clear() => _items.clear();

  List<CartItem> getItems() => _items.values.toList();
}
