import 'package:equatable/equatable.dart';

abstract class ProductDetailEvent extends Equatable {
  @override
  
  List<Object?> get props => [];
}

class FetchProductDetail extends ProductDetailEvent {
  final String productSlug;
  final int? isNotify;
  final int? variantId;

  FetchProductDetail({
    required this.productSlug,
    this.isNotify,
    this.variantId,
  });

  @override
  List<Object?> get props => [productSlug, isNotify, variantId];
}

class ClearProductDetailError extends ProductDetailEvent {
  @override
  List<Object?> get props => [];
}