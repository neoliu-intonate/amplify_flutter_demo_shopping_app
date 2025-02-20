import '../models/cart_item.dart';
import '../models/Product.dart';

class ShoppingCart {
  static final ShoppingCart instance = ShoppingCart._internal();
  ShoppingCart._internal();

  final Map<String, CartItem> items = {};

  void addProduct(Product product) {
    final id = product.id;
    if (items.containsKey(id)) {
      // Only add if quantity is less than product stock.
      if (items[id]!.quantity < product.stock) {
        items[id]!.quantity++;
      }
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

  void deleteProduct(Product product) {
    items.remove(product.id);
  }

  void clear() {
    items.clear();
  }

  List<CartItem> getItems() => items.values.toList();

  /// Update cart items with the latest product info.
  void updateItemsWithLatestProducts(List<Product> latestProducts) {
    final keysToRemove = <String>[];
    items.forEach((id, cartItem) {
      // Find the latest version of this product.
      final matching = latestProducts.where((product) => product.id == id);
      if (matching.isEmpty) {
        // Product no longer exists, mark for removal.
        keysToRemove.add(id);
      } else {
        final latest = matching.first;
        // Update the cart item with latest product info.
        items[id] = CartItem(product: latest, quantity: cartItem.quantity);
        // Ensure quantity does not exceed new stock.
        if (items[id]!.quantity > latest.stock) {
          items[id]!.quantity = latest.stock;
        }
      }
    });
    for (final key in keysToRemove) {
      items.remove(key);
    }
  }
}
