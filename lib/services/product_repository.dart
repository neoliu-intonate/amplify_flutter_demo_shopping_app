import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

import '../models/ModelProvider.dart';

class ProductRepository {
  Future<List<Product>> fetchProducts() async {
    try {
      final request = ModelQueries.list(Product.classType);
      final response = await Amplify.API.query(request: request).response;
      if (response.hasErrors) {
        safePrint('Errors: ${response.errors}');
        throw Exception('Error fetching products');
      }
      final products = response.data?.items.whereType<Product>().toList() ?? [];
      return products;
    } catch (e) {
      safePrint('Query failed: $e');
      rethrow;
    }
  }

  Future<void> createProduct(Product product) async {
    try {
      final request = ModelMutations.create(product);
      final response = await Amplify.API.mutate(request: request).response;
      if (response.hasErrors) {
        throw Exception('Error creating product: ${response.errors}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateProduct(Product product) async {
    try {
      final request = ModelMutations.update(product);
      final response = await Amplify.API.mutate(request: request).response;
      if (response.hasErrors) {
        throw Exception('Error updating product: ${response.errors}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteProduct(Product product) async {
    try {
      final request = ModelMutations.delete(product);
      final response = await Amplify.API.mutate(request: request).response;
      if (response.hasErrors) {
        throw Exception('Error deleting product: ${response.errors}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
