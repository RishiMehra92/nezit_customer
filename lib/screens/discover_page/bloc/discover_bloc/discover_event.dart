import 'package:equatable/equatable.dart';

abstract class DiscoverEvent extends Equatable {
  const DiscoverEvent();

  @override
  List<Object?> get props => [];
}

class FetchDiscoverStatuses extends DiscoverEvent {
  final bool isRefresh;
  final bool isLoadMore;

  const FetchDiscoverStatuses({
    this.isRefresh = false,
    this.isLoadMore = false,
  });

  @override
  List<Object> get props => [isRefresh, isLoadMore];
}

class FetchDiscoverProfileStatuses extends DiscoverEvent {
  final String username;
  final bool isRefresh;

  const FetchDiscoverProfileStatuses({
    required this.username,
    this.isRefresh = false,
  });

  @override
  List<Object> get props => [username, isRefresh];
}

class MarkDiscoverStoriesAsSeen extends DiscoverEvent {
  final List<int> statusIds;

  const MarkDiscoverStoriesAsSeen(this.statusIds);

  @override
  List<Object> get props => [statusIds];
}

class FetchDiscoverReels extends DiscoverEvent {
  final bool isRefresh;

  const FetchDiscoverReels({
    this.isRefresh = false,
  });

  @override
  List<Object> get props => [isRefresh];
}

class LikeReelEvent extends DiscoverEvent {
  final int reelId;
  final bool liked;
  final double? latitude;
  final double? longitude;

  const LikeReelEvent({
    required this.reelId,
    required this.liked,
    this.latitude,
    this.longitude,
  });

  @override
  List<Object?> get props => [
        reelId,
        liked,
        latitude,
        longitude,
      ];
}
