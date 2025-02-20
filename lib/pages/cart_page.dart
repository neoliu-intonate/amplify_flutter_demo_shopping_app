import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../services/shopping_cart.dart';
import '../bloc/product_bloc.dart';

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

    // Check stock for each cart item.
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

    // Deduct ordered quantity from each product.
    for (final item in cartItems) {
      final updatedStock = item.product.stock - item.quantity;
      final updatedProduct = item.product.copyWith(stock: updatedStock);
      try {
        final request = ModelMutations.update(updatedProduct);
        final response = await Amplify.API.mutate(request: request).response;
        if (response.hasErrors) {
          safePrint('Error updating product: ${response.errors}');
        } else {
          safePrint('Updated ${item.product.name} stock to $updatedStock');
        }
      } catch (e) {
        safePrint('Update failed: $e');
      }
    }

    ShoppingCart.instance.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Order placed successfully')),
    );

    // Refresh the product list so the UI is up-to-date.
    context.read<ProductBloc>().add(LoadProducts());

    setState(() {
      _isPlacingOrder = false;
    });

    if (mounted) {
      context.pop();
    }
  }

  void _logout() async {
    try {
      await Amplify.Auth.signOut();
    } catch (e) {
      safePrint('Sign out failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        // If we have the latest product list, update the cart.
        if (state is ProductLoaded) {
          ShoppingCart.instance.updateItemsWithLatestProducts(state.products);
        }
        final cartItems = ShoppingCart.instance.getItems();
        double overallTotal = 0;
        for (final item in cartItems) {
          overallTotal += item.product.price * item.quantity;
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('Shopping Cart'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: _logout,
              ),
            ],
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
                      subtitle: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: item.quantity > 1
                                ? () {
                                    setState(() {
                                      item.quantity--;
                                    });
                                  }
                                : null,
                          ),
                          Text('${item.quantity}'),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: item.quantity < item.product.stock
                                ? () {
                                    setState(() {
                                      item.quantity++;
                                    });
                                  }
                                : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              setState(() {
                                ShoppingCart.instance
                                    .deleteProduct(item.product);
                              });
                            },
                          ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Show the sum price for this product.
                          Text(
                              '\$ ${(item.product.price).toStringAsFixed(2)} x ${item.quantity} = \$ ${(item.product.price * item.quantity).toStringAsFixed(2)}'),
                        ],
                      ),
                    );
                  },
                ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Display overall cart total.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total:',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '\$ ${overallTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _isPlacingOrder ? null : _placeOrder,
                  child: _isPlacingOrder
                      ? const CircularProgressIndicator()
                      : const Text('Place Order'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
