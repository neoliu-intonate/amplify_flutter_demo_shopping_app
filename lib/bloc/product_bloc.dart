import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/ModelProvider.dart';
import '../services/product_repository.dart';

part 'product_event.dart';
part 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductRepository repository;
  ProductBloc(this.repository) : super(ProductInitial()) {
    on<LoadProducts>(_onLoadProducts);
    on<CreateProduct>(_onCreateProduct);
    on<UpdateProduct>(_onUpdateProduct);
    on<DeleteProduct>(_onDeleteProduct);
  }

  Future<void> _onLoadProducts(
      LoadProducts event, Emitter<ProductState> emit) async {
    emit(ProductLoading());
    try {
      final products = await repository.fetchProducts();
      emit(ProductLoaded(products));
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  Future<void> _onCreateProduct(
      CreateProduct event, Emitter<ProductState> emit) async {
    try {
      await repository.createProduct(event.product);
      emit(ProductOperationSuccess(
          operation: OperationType.create, product: event.product));
      add(LoadProducts());
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  Future<void> _onUpdateProduct(
      UpdateProduct event, Emitter<ProductState> emit) async {
    try {
      await repository.updateProduct(event.product);
      emit(ProductOperationSuccess(
          operation: OperationType.update, product: event.product));
      add(LoadProducts());
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  Future<void> _onDeleteProduct(
      DeleteProduct event, Emitter<ProductState> emit) async {
    try {
      await repository.deleteProduct(event.product);
      emit(ProductOperationSuccess(
          operation: OperationType.delete, product: event.product));
      add(LoadProducts());
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }
}
