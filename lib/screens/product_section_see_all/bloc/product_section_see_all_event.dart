import 'package:equatable/equatable.dart';

abstract class ProductSectionSeeAllEvent extends Equatable {
  const ProductSectionSeeAllEvent();

  @override
  List<Object?> get props => [];
}

/// Fetch the first page of a product section's items.
class FetchProductSectionItems extends ProductSectionSeeAllEvent {
  final int sectionId;

  const FetchProductSectionItems({required this.sectionId});

  @override
  List<Object?> get props => [sectionId];
}

/// Fetch the next page and append. Uses the section id / page cursor held by
/// the bloc.
class FetchMoreProductSectionItems extends ProductSectionSeeAllEvent {
  const FetchMoreProductSectionItems();
}
