import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

import '../bloc/product_bloc.dart';
import '../models/ModelProvider.dart';

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

  void _submitForm() {
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
      context.read<ProductBloc>().add(CreateProduct(newProduct));
    } else {
      final updatedProduct = widget.product!.copyWith(
        name: name,
        description: description.isNotEmpty ? description : null,
        stock: stock,
        price: price,
      );
      context.read<ProductBloc>().add(UpdateProduct(updatedProduct));
    }
  }

  void _deleteProduct() {
    if (widget.product == null) return;
    context.read<ProductBloc>().add(DeleteProduct(widget.product!));
  }

  Future<void> _logout() async {
    try {
      await Amplify.Auth.signOut();
    } catch (e) {
      safePrint('Sign out failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProductBloc, ProductState>(
      listener: (context, state) {
        if (state is ProductOperationSuccess) {
          if (state.operation == OperationType.delete || _isCreate) {
            // For creation or deletion, navigate to product list.
            context.goNamed('product_list');
          } else if (state.operation == OperationType.update) {
            // For update, simply pop so that the product detail page remains.
            context.pop();
          }
        }
        if (state is ProductError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${state.message}')),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_titleText),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
            ),
          ],
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
                        decoration: const InputDecoration(
                            labelText: 'Stock (required)'),
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
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                            labelText: 'Price (required)'),
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
                        onPressed: _submitForm,
                        child: Text(_titleText),
                      ),
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
      ),
    );
  }
}
