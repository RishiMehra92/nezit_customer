import 'package:equatable/equatable.dart';

abstract class StoreReelsEvent extends Equatable {
  const StoreReelsEvent();

  @override
  List<Object?> get props => [];
}

class FetchStoreReels extends StoreReelsEvent {
  final String storeSlug;
  final bool isRefresh;
  final bool isLoadMore;

  const FetchStoreReels({
    required this.storeSlug,
    this.isRefresh = false,
    this.isLoadMore = false,
  });

  @override
  List<Object?> get props => [storeSlug, isRefresh, isLoadMore];
}
