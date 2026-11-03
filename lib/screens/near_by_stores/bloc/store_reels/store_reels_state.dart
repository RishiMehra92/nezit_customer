import 'package:equatable/equatable.dart';
import 'package:hyper_local/utils/api_status.dart';
import 'package:hyper_local/screens/discover_page/model/discover_reel_model.dart';

class StoreReelsState extends Equatable {
  final ApiStatus status;
  final List<DiscoverReelItem> items;
  final String? nextCursor;
  final String? sessionId;
  final bool hasReachedMax;
  final bool isLoadMoreLoading;
  final String? errorMessage;

  const StoreReelsState({
    this.status = ApiStatus.initial,
    this.items = const [],
    this.nextCursor,
    this.sessionId,
    this.hasReachedMax = false,
    this.isLoadMoreLoading = false,
    this.errorMessage,
  });

  StoreReelsState copyWith({
    ApiStatus? status,
    List<DiscoverReelItem>? items,
    String? nextCursor,
    String? sessionId,
    bool? hasReachedMax,
    bool? isLoadMoreLoading,
    String? errorMessage,
  }) {
    return StoreReelsState(
      status: status ?? this.status,
      items: items ?? this.items,
      nextCursor: nextCursor ?? this.nextCursor,
      sessionId: sessionId ?? this.sessionId,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isLoadMoreLoading: isLoadMoreLoading ?? this.isLoadMoreLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        items,
        nextCursor,
        sessionId,
        hasReachedMax,
        isLoadMoreLoading,
        errorMessage,
      ];
}
