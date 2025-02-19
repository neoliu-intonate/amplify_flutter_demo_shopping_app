import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/Product.dart';

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
