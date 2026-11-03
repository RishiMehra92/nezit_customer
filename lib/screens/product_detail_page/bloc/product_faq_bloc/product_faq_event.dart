part of 'product_faq_bloc.dart';

abstract class ProductFAQEvent extends Equatable {
  @override
  
  List<Object?> get props => [];
}

class FetchProductFAQ extends ProductFAQEvent {
  final String productSlug;
  FetchProductFAQ({required this.productSlug});
  @override
  
  List<Object?> get props => [productSlug];
}