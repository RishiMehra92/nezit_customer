import 'package:equatable/equatable.dart';

abstract class StoreStoriesEvent extends Equatable {
  const StoreStoriesEvent();

  @override
  List<Object?> get props => [];
}

class FetchStoreStories extends StoreStoriesEvent {
  final String storeSlug;

  const FetchStoreStories({
    required this.storeSlug,
  });

  @override
  List<Object?> get props => [storeSlug];
}
