import 'package:equatable/equatable.dart';
import 'package:hyper_local/screens/product_detail_page/model/product_detail_model.dart'
    show ProductData;

abstract class ProductSectionSeeAllState extends Equatable {
  const ProductSectionSeeAllState();

  @override
  List<Object?> get props => [];
}

class ProductSectionSeeAllInitial extends ProductSectionSeeAllState {}

class ProductSectionSeeAllLoading extends ProductSectionSeeAllState {}

class ProductSectionSeeAllLoaded extends ProductSectionSeeAllState {
  /// Parsed product items for the section.
  final List<ProductData> items;

  /// No more pages to load.
  final bool hasReachedMax;

  /// A next-page request is in flight (show a bottom loader).
  final bool isLoadingMore;

  const ProductSectionSeeAllLoaded({
    required this.items,
    this.hasReachedMax = false,
    this.isLoadingMore = false,
  });

  ProductSectionSeeAllLoaded copyWith({
    List<ProductData>? items,
    bool? hasReachedMax,
    bool? isLoadingMore,
  }) {
    return ProductSectionSeeAllLoaded(
      items: items ?? this.items,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [items, hasReachedMax, isLoadingMore];
}

class ProductSectionSeeAllFailed extends ProductSectionSeeAllState {
  final String error;

  const ProductSectionSeeAllFailed({required this.error});

  @override
  List<Object?> get props => [error];
}
