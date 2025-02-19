import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/shopping_cart.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  bool _isPlacingOrder = false;

  Future<void> _placeOrder() async {
    setState(() {
      _isPlacingOrder = true;
    });

    final cartItems = ShoppingCart.instance.getItems();

    // Check if there is enough stock for each cart item
    for (final item in cartItems) {
      if (item.quantity > item.product.stock) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Not enough stock for ${item.product.name}')),
        );
        setState(() {
          _isPlacingOrder = false;
        });
        return;
      }
    }

    // Deduct the ordered quantity from the product stock and update the product
    for (final item in cartItems) {
      final updatedStock = item.product.stock - item.quantity;
      final updatedProduct = item.product.copyWith(stock: updatedStock);
      try {
        final request = ModelMutations.update(updatedProduct);
        final response = await Amplify.API.mutate(request: request).response;
        if (response.hasErrors) {
          safePrint('Error updating product: ${response.errors}');
        } else {
          safePrint(
              'Updated product ${item.product.name} stock to $updatedStock');
        }
      } catch (e) {
        safePrint('Update failed: $e');
      }
    }

    // Clear the cart after a successful order
    ShoppingCart.instance.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Order placed successfully')),
    );

    setState(() {
      _isPlacingOrder = false;
    });

    // Optionally, navigate back to the product list
    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ShoppingCart.instance.getItems();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
      ),
      body: cartItems.isEmpty
          ? const Center(child: Text('Your cart is empty'))
          : ListView.separated(
              itemCount: cartItems.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final item = cartItems[index];
                return ListTile(
                  title: Text(item.product.name),
                  subtitle: Text('Quantity: ${item.quantity}'),
                  trailing: Text(
                    '\$ ${(item.product.price * item.quantity).toStringAsFixed(2)}',
                  ),
                );
              },
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _isPlacingOrder ? null : _placeOrder,
          child: _isPlacingOrder
              ? const CircularProgressIndicator()
              : const Text('Place Order'),
        ),
      ),
    );
  }
}
