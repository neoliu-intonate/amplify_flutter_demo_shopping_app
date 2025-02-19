import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/ModelProvider.dart';
import '../router/app_router.dart';
import '../services/shopping_cart.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> with RouteAware {
  List<Product> _products = [];

  @override
  void initState() {
    super.initState();
    _refreshProducts();
  }

  // Subscribe to the route observer when dependencies change.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  // Called when this route has been popped back to (i.e. becomes visible).
  @override
  void didPopNext() {
    _refreshProducts();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  Future<void> _refreshProducts() async {
    try {
      final request = ModelQueries.list(Product.classType);
      final response = await Amplify.API.query(request: request).response;
      if (response.hasErrors) {
        safePrint('Errors: ${response.errors}');
        return;
      }
      final products = response.data?.items.whereType<Product>().toList() ?? [];
      setState(() {
        _products = products;
      });
    } catch (e) {
      safePrint('Query failed: $e');
    }
  }

  void _addToCart(Product product) {
    ShoppingCart.instance.addProduct(product);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${product.name} added to cart')),
    );
  }

  Widget _buildRow(Product product) {
    return ListTile(
      title: Row(
        children: [
          Expanded(child: Text(product.name)),
          Expanded(child: Text('Stock: ${product.stock}')),
          Expanded(child: Text('\$ ${product.price.toStringAsFixed(2)}')),
          IconButton(
            icon: const Icon(Icons.add_shopping_cart),
            onPressed: () => _addToCart(product),
          ),
        ],
      ),
      onTap: () {
        context.pushNamed('product_detail', extra: product);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          // Button to navigate to the shopping cart page
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () => context.pushNamed('cart'),
          ),
        ],
      ),
      // Floating button for product owners to add new products
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.pushNamed('manage_product', extra: null);
        },
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshProducts,
        child: ListView.separated(
          itemCount: _products.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final product = _products[index];
            return _buildRow(product);
          },
        ),
      ),
    );
  }
}
