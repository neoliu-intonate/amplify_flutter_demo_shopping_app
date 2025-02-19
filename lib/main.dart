import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_authenticator/amplify_authenticator.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'amplifyconfiguration.dart';
import 'models/ModelProvider.dart';

// Global RouteObserver to monitor route changes
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _configureAmplify();
  runApp(const MyApp());
}

Future<void> _configureAmplify() async {
  try {
    final api = AmplifyAPI(
      options: APIPluginOptions(modelProvider: ModelProvider.instance),
    );
    final auth = AmplifyAuthCognito();
    await Amplify.addPlugins([api, auth]);
    await Amplify.configure(amplifyconfig);
    safePrint('Successfully configured Amplify');
  } catch (e) {
    safePrint('Error configuring Amplify: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // GoRouter configuration with routes for product list, detail, cart, and management.
  // Note: We pass our routeObserver in the observers parameter of GoRouter.
  static final _router = GoRouter(
    observers: [routeObserver],
    routes: [
      GoRoute(
        path: '/',
        name: 'product_list',
        builder: (context, state) => const ProductListPage(),
      ),
      GoRoute(
        path: '/product',
        name: 'product_detail',
        builder: (context, state) {
          final product = state.extra as Product;
          return ProductDetailPage(product: product);
        },
      ),
      GoRoute(
        path: '/cart',
        name: 'cart',
        builder: (context, state) => const CartPage(),
      ),
      GoRoute(
        path: '/manage',
        name: 'manage_product',
        builder: (context, state) {
          final product = state.extra as Product?;
          return ManageProductScreen(product: product);
        },
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Authenticator(
      child: MaterialApp.router(
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
        builder: Authenticator.builder(),
      ),
    );
  }
}

/// -------------------------------------------------------------------------
/// Shopping Cart Models (in‑memory)
/// -------------------------------------------------------------------------

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});
}

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

/// -------------------------------------------------------------------------
/// Product List Page
/// -------------------------------------------------------------------------

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

/// -------------------------------------------------------------------------
/// Product Detail Page
/// -------------------------------------------------------------------------

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

/// -------------------------------------------------------------------------
/// Cart Page
/// -------------------------------------------------------------------------

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

/// -------------------------------------------------------------------------
/// Manage Product Screen (Create / Update)
/// -------------------------------------------------------------------------
class ManageProductScreen extends StatefulWidget {
  final Product? product;
  const ManageProductScreen({super.key, this.product});

  @override
  State<ManageProductScreen> createState() => _ManageProductScreenState();
}

class _ManageProductScreenState extends State<ManageProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  late final String _titleText;
  bool get _isCreate => widget.product == null;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _descriptionController.text = widget.product!.description ?? '';
      _stockController.text = widget.product!.stock.toString();
      _priceController.text = widget.product!.price.toStringAsFixed(2);
      _titleText = 'Update Product';
    } else {
      _titleText = 'Create Product';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _stockController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text;
    final description = _descriptionController.text;
    final stock = int.parse(_stockController.text);
    final price = double.parse(_priceController.text);

    if (_isCreate) {
      final newProduct = Product(
        name: name,
        description: description.isNotEmpty ? description : null,
        stock: stock,
        price: price,
      );
      try {
        final request = ModelMutations.create(newProduct);
        final response = await Amplify.API.mutate(request: request).response;
        safePrint('Product created: $response');
      } catch (e) {
        safePrint('Creation failed: $e');
      }
    } else {
      final updatedProduct = widget.product!.copyWith(
        name: name,
        description: description.isNotEmpty ? description : null,
        stock: stock,
        price: price,
      );
      try {
        final request = ModelMutations.update(updatedProduct);
        final response = await Amplify.API.mutate(request: request).response;
        safePrint('Product updated: $response');
      } catch (e) {
        safePrint('Update failed: $e');
      }
    }

    if (!mounted) return;
    context.pop();
  }

  Future<void> _deleteProduct() async {
    // Only attempt deletion if a product exists.
    if (widget.product == null) return;

    try {
      final request = ModelMutations.delete(widget.product!);
      final response = await Amplify.API.mutate(request: request).response;
      if (response.hasErrors) {
        safePrint('Deletion error: ${response.errors}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete product')),
        );
      } else {
        safePrint('Product deleted: ${widget.product!.id}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted successfully')),
        );
        if (!mounted) return;
        context.goNamed('product_list');
      }
    } catch (e) {
      safePrint('Deletion failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deletion failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titleText),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration:
                          const InputDecoration(labelText: 'Name (required)'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter product name';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _descriptionController,
                      decoration:
                          const InputDecoration(labelText: 'Description'),
                    ),
                    TextFormField(
                      controller: _stockController,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Stock (required)'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter stock value';
                        }
                        final stock = int.tryParse(value);
                        if (stock == null || stock < 0) {
                          return 'Enter valid stock';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _priceController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration:
                          const InputDecoration(labelText: 'Price (required)'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter price';
                        }
                        final price = double.tryParse(value);
                        if (price == null || price <= 0) {
                          return 'Enter valid price';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: submitForm,
                      child: Text(_titleText),
                    ),
                    // Only show the Delete button if updating an existing product.
                    if (!_isCreate) ...[
                      const SizedBox(height: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        onPressed: _deleteProduct,
                        child: const Text('Delete Product'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
