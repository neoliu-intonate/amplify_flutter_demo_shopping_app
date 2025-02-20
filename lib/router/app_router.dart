import 'package:go_router/go_router.dart';

import '../models/Product.dart';
import '../pages/product_list_page.dart';
import '../pages/product_detail_page.dart';
import '../pages/cart_page.dart';
import '../pages/manage_product_screen.dart';

class AppRouter {
  static final router = GoRouter(
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
}
