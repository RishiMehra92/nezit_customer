import 'package:equatable/equatable.dart';

abstract class SectionSeeAllState extends Equatable {
  const SectionSeeAllState();

  @override
  List<Object?> get props => [];
}

class SectionSeeAllInitial extends SectionSeeAllState {}

class SectionSeeAllLoading extends SectionSeeAllState {}

class SectionSeeAllLoaded extends SectionSeeAllState {
  /// Section type — 'categories' | 'brands'. Drives which card the view renders.
  final String type;

  /// Parsed items (each is a CategoryData or BrandData depending on [type]).
  final List<dynamic> items;

  /// No more pages to load.
  final bool hasReachedMax;

  /// A next-page request is in flight (show a bottom loader).
  final bool isLoadingMore;

  const SectionSeeAllLoaded({
    required this.type,
    required this.items,
    this.hasReachedMax = false,
    this.isLoadingMore = false,
  });

  SectionSeeAllLoaded copyWith({
    String? type,
    List<dynamic>? items,
    bool? hasReachedMax,
    bool? isLoadingMore,
  }) {
    return SectionSeeAllLoaded(
      type: type ?? this.type,
      items: items ?? this.items,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [type, items, hasReachedMax, isLoadingMore];
}

class SectionSeeAllFailed extends SectionSeeAllState {
  final String error;

  const SectionSeeAllFailed({required this.error});

  @override
  List<Object?> get props => [error];
}
