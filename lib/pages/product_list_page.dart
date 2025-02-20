import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/product_bloc.dart';
import '../models/ModelProvider.dart';
import '../services/shopping_cart.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

class ProductListPage extends StatelessWidget {
  const ProductListPage({super.key});

  void _addToCart(BuildContext context, Product product) {
    ShoppingCart.instance.addProduct(product);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${product.name} added to cart')),
    );
  }

  Widget _buildRow(BuildContext context, Product product) {
    return ListTile(
      title: Row(
        children: [
          Expanded(child: Text(product.name)),
          Expanded(child: Text('Stock: ${product.stock}')),
          Expanded(child: Text('\$ ${product.price.toStringAsFixed(2)}')),
          IconButton(
            icon: const Icon(Icons.add_shopping_cart),
            onPressed: () => _addToCart(context, product),
          ),
        ],
      ),
      onTap: () {
        context.pushNamed('product_detail', extra: product);
      },
    );
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await Amplify.Auth.signOut();
    } catch (e) {
      safePrint('Sign out failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () => context.pushNamed('cart'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.pushNamed('manage_product', extra: null);
        },
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<ProductBloc>().add(LoadProducts());
        },
        child: BlocBuilder<ProductBloc, ProductState>(
          builder: (context, state) {
            if (state is ProductLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is ProductLoaded) {
              final products = state.products;
              return ListView.separated(
                itemCount: products.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) =>
                    _buildRow(context, products[index]),
              );
            } else if (state is ProductError) {
              return Center(child: Text('Error: ${state.message}'));
            }
            return const Center(child: Text('No products available.'));
          },
        ),
      ),
    );
  }
}
