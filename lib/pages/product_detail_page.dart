import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

import '../bloc/product_bloc.dart';
import '../models/ModelProvider.dart';
import '../services/shopping_cart.dart';

class ProductDetailPage extends StatelessWidget {
  final Product product;
  const ProductDetailPage({super.key, required this.product});

  Future<void> _logout(BuildContext context) async {
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
        // Look for an updated version of the product in the loaded list.
        Product updatedProduct = product;
        if (state is ProductLoaded) {
          final match = state.products
              .firstWhere((p) => p.id == product.id, orElse: () => product);
          updatedProduct = match;
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(updatedProduct.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => _logout(context),
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  context.pushNamed('manage_product', extra: updatedProduct);
                },
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Name: ${updatedProduct.name}',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 10),
                Text(
                    'Description: ${updatedProduct.description ?? 'No description'}'),
                const SizedBox(height: 10),
                Text('Stock: ${updatedProduct.stock}'),
                const SizedBox(height: 10),
                Text('Price: \$ ${updatedProduct.price.toStringAsFixed(2)}'),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Add to Cart'),
                  onPressed: () {
                    ShoppingCart.instance.addProduct(updatedProduct);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text('${updatedProduct.name} added to cart')),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
