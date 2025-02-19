import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/ModelProvider.dart';
import '../services/shopping_cart.dart';

class ProductDetailPage extends StatelessWidget {
  final Product product;

  const ProductDetailPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        actions: [
          // Allow the owner to navigate to the manage page to edit the product
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              context.pushNamed('manage_product', extra: product);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${product.name}',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),
            Text('Description: ${product.description ?? 'No description'}'),
            const SizedBox(height: 10),
            Text('Stock: ${product.stock}'),
            const SizedBox(height: 10),
            Text('Price: \$ ${product.price.toStringAsFixed(2)}'),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Add to Cart'),
              onPressed: () {
                ShoppingCart.instance.addProduct(product);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${product.name} added to cart')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
