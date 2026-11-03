import 'package:equatable/equatable.dart';

import '../../model/product_detail_model.dart';

abstract class ProductDetailState extends Equatable {
  @override
  
  List<Object?> get props => [];
}

class ProductDetailInitial extends ProductDetailState {}

class ProductDetailLoading extends ProductDetailState {}

class ProductDetailLoaded extends ProductDetailState {
  final List<ProductData> productData;
  final String message;
  final bool isNotifying;
  final String? errorMessage;

  ProductDetailLoaded({
    required this.message,
    required this.productData,
    this.isNotifying = false,
    this.errorMessage,
  });

  ProductDetailLoaded copyWith({
    List<ProductData>? productData,
    String? message,
    bool? isNotifying,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProductDetailLoaded(
      message: message ?? this.message,
      productData: productData ?? this.productData,
      isNotifying: isNotifying ?? this.isNotifying,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [message, productData, isNotifying, errorMessage];
}

class ProductDetailFailed extends ProductDetailState {
  final String error;
  ProductDetailFailed({required this.error});

  @override
  
  List<Object?> get props => [error];
}