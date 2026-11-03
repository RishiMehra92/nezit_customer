import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local/utils/api_status.dart';
import 'package:hyper_local/screens/discover_page/model/discover_reel_model.dart';
import '../../repo/near_by_store_repo.dart';
import 'store_reels_event.dart';
import 'store_reels_state.dart';

class StoreReelsBloc extends Bloc<StoreReelsEvent, StoreReelsState> {
  final NearByStoreRepo repository;

  StoreReelsBloc({required this.repository}) : super(const StoreReelsState()) {
    on<FetchStoreReels>(_onFetchStoreReels);
  }

  Future<void> _onFetchStoreReels(
    FetchStoreReels event,
    Emitter<StoreReelsState> emit,
  ) async {
    if (event.isRefresh || state.status == ApiStatus.initial) {
      emit(state.copyWith(
        status: ApiStatus.loading,
        errorMessage: null,
      ));
    } else if (event.isLoadMore) {
      if (state.hasReachedMax ||
          state.status == ApiStatus.loading ||
          state.isLoadMoreLoading ||
          state.nextCursor == null ||
          state.nextCursor!.isEmpty) {
        return;
      }
      emit(state.copyWith(isLoadMoreLoading: true));
    }

    try {
      final String? cursor = event.isLoadMore ? state.nextCursor : null;
      final String? sessionId = event.isLoadMore ? state.sessionId : null;

      final response = await repository.fetchStoreReels(
        storeSlug: event.storeSlug,
        cursor: cursor,
        sessionId: sessionId,
        perPage: 10,
      );

      final data = response['data'] as Map<String, dynamic>?;
      final rawItems = data?['items'] as List<dynamic>? ?? [];
      final newItems =
          rawItems.map((e) => DiscoverReelItem.fromJson(e)).toList();

      final meta = data?['meta'] as Map<String, dynamic>?;
      final nextCursor = meta?['next_cursor'] as String?;
      final newSessionId = meta?['session_id'] as String?;
      final hasReachedMax = nextCursor == null || nextCursor.isEmpty;

      final items = event.isLoadMore ? [...state.items, ...newItems] : newItems;

      emit(state.copyWith(
        status: ApiStatus.success,
        items: items,
        nextCursor: nextCursor,
        sessionId: newSessionId ?? sessionId,
        hasReachedMax: hasReachedMax,
        isLoadMoreLoading: false,
      ));
    } catch (e) {
      if (event.isLoadMore) {
        emit(state.copyWith(
          isLoadMoreLoading: false,
          errorMessage: e.toString(),
        ));
      } else {
        emit(state.copyWith(
          status: ApiStatus.failure,
          errorMessage: e.toString(),
        ));
      }
    }
  }
}
