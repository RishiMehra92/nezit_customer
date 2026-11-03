part of 'product_review_bloc.dart';

abstract class ProductReviewEvent extends Equatable {
  @override
  
  List<Object?> get props => [];
}

class FetchProductReview extends ProductReviewEvent {
  final String productSlug;
  FetchProductReview({required this.productSlug});
  @override
  
  List<Object?> get props => [productSlug];
}