part of 'product_bloc.dart';

enum OperationType { create, update, delete }

abstract class ProductState extends Equatable {
  const ProductState();
  @override
  List<Object?> get props => [];
}

class ProductInitial extends ProductState {}

class ProductLoading extends ProductState {}

class ProductLoaded extends ProductState {
  final List<Product> products;
  const ProductLoaded(this.products);
  @override
  List<Object> get props => [products];
}

class ProductError extends ProductState {
  final String message;
  const ProductError(this.message);
  @override
  List<Object> get props => [message];
}

class ProductOperationSuccess extends ProductState {
  final OperationType operation;
  final Product? product;
  const ProductOperationSuccess({required this.operation, this.product});
  @override
  List<Object?> get props => [operation, product];
}
