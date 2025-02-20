part of 'product_bloc.dart';

abstract class ProductEvent extends Equatable {
  const ProductEvent();
  @override
  List<Object> get props => [];
}

class LoadProducts extends ProductEvent {}

class CreateProduct extends ProductEvent {
  final Product product;
  const CreateProduct(this.product);
  @override
  List<Object> get props => [product];
}

class UpdateProduct extends ProductEvent {
  final Product product;
  const UpdateProduct(this.product);
  @override
  List<Object> get props => [product];
}

class DeleteProduct extends ProductEvent {
  final Product product;
  const DeleteProduct(this.product);
  @override
  List<Object> get props => [product];
}
