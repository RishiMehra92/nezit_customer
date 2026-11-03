import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local/utils/api_status.dart';
import 'package:hyper_local/screens/discover_page/model/discover_status_model.dart';
import '../../repo/near_by_store_repo.dart';
import 'store_stories_event.dart';
import 'store_stories_state.dart';

class StoreStoriesBloc extends Bloc<StoreStoriesEvent, StoreStoriesState> {
  final NearByStoreRepo repository;

  StoreStoriesBloc({required this.repository})
      : super(const StoreStoriesState()) {
    on<FetchStoreStories>(_onFetchStoreStories);
  }

  Future<void> _onFetchStoreStories(
    FetchStoreStories event,
    Emitter<StoreStoriesState> emit,
  ) async {
    emit(state.copyWith(
      status: ApiStatus.loading,
      errorMessage: null,
    ));

    try {
      final response = await repository.fetchStoreStories(
        storeSlug: event.storeSlug,
      );

      final data = response['data'] as Map<String, dynamic>?;
      final rawItems = data?['items'] as List<dynamic>? ?? [];
      final newItems =
          rawItems.map((e) => DiscoverStatusItem.fromJson(e)).toList();

      emit(state.copyWith(
        status: ApiStatus.success,
        items: newItems,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ApiStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}
