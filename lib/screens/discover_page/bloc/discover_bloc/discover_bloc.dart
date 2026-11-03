import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local/screens/discover_page/model/discover_reel_model.dart';
import 'package:hyper_local/utils/api_status.dart';
import 'package:hyper_local/config/global.dart';
import '../../model/discover_profile_status_model.dart';
import '../../model/discover_status_model.dart';
import '../../repo/discover_repo.dart';
import 'discover_event.dart';
import 'discover_state.dart';

class DiscoverBloc extends Bloc<DiscoverEvent, DiscoverState> {
  final DiscoverRepo discoverRepo;

  DiscoverBloc({required this.discoverRepo}) : super(const DiscoverState()) {
    on<FetchDiscoverStatuses>(_onFetchDiscoverStatuses);
    on<FetchDiscoverProfileStatuses>(_onFetchDiscoverProfileStatuses);
    on<MarkDiscoverStoriesAsSeen>(_onMarkDiscoverStoriesAsSeen);
    on<FetchDiscoverReels>(_onFetchDiscoverReels);
    on<LikeReelEvent>(_onLikeReel);
  }

  Future<void> _onLikeReel(
    LikeReelEvent event,
    Emitter<DiscoverState> emit,
  ) async {
    // Call repository to like reel silently
    await discoverRepo.likeReel(
      reelId: event.reelId,
      liked: event.liked,
      latitude: event.latitude,
      longitude: event.longitude,
    );

    // Update statically in the bloc state upon success
    final reels = List<DiscoverReelItem>.from(state.reels);
    final index = reels.indexWhere((r) => r.id == event.reelId);

    if (index != -1) {
      final oldReel = reels[index];
      if (oldReel.likedByMe != event.liked) {
        final oldCount = oldReel.likeCount ?? 0;
        final newCount =
            event.liked ? oldCount + 1 : (oldCount > 0 ? oldCount - 1 : 0);

        reels[index] = oldReel.copyWith(
          likedByMe: event.liked,
          likeCount: newCount,
        );

        emit(state.copyWith(reels: reels));
      }
    }
  }

  Future<void> _onFetchDiscoverStatuses(
    FetchDiscoverStatuses event,
    Emitter<DiscoverState> emit,
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

      final response = await discoverRepo.fetchWatchAndBuyStatuses(
        cursor: cursor,
        sessionId: sessionId,
        perPage: 20,
      );

      if (response.success == true) {
        final newItems = response.data?.items ?? [];
        final meta = response.data?.meta;
        final nextCursor = meta?.nextCursor;
        final sessionId = meta?.sessionId;
        final hasReachedMax = nextCursor == null || nextCursor.isEmpty;

        final items =
            event.isLoadMore ? [...state.items, ...newItems] : newItems;

        emit(state.copyWith(
          status: ApiStatus.success,
          items: items,
          nextCursor: nextCursor,
          sessionId: sessionId,
          hasReachedMax: hasReachedMax,
          isLoadMoreLoading: false,
        ));
      } else {
        emit(state.copyWith(
          status: ApiStatus.failure,
          errorMessage: response.message,
          isLoadMoreLoading: false,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: ApiStatus.failure,
        errorMessage: e.toString(),
        isLoadMoreLoading: false,
      ));
    }
  }

  Future<void> _onFetchDiscoverProfileStatuses(
    FetchDiscoverProfileStatuses event,
    Emitter<DiscoverState> emit,
  ) async {
    final username = event.username;
    final currentStatus = state.profileStatusMap[username] ?? ApiStatus.initial;

    if (event.isRefresh || currentStatus == ApiStatus.initial) {
      final updatedStatusMap =
          Map<String, ApiStatus>.from(state.profileStatusMap)
            ..[username] = ApiStatus.loading;
      final updatedErrorMap =
          Map<String, String?>.from(state.profileErrorMessageMap)
            ..[username] = null;

      emit(state.copyWith(
        profileStatusMap: updatedStatusMap,
        profileErrorMessageMap: updatedErrorMap,
      ));
    }

    try {
      final response = await discoverRepo.fetchProfileStatuses(
        username: username,
      );

      if (response.success == true) {
        final items = response.data?.items ?? [];
        final profile = response.data?.profile;

        final updatedStatusMap =
            Map<String, ApiStatus>.from(state.profileStatusMap)
              ..[username] = ApiStatus.success;
        final updatedProfilesMap =
            Map<String, DiscoverProfile?>.from(state.profilesMap)
              ..[username] = profile;
        final updatedItemsMap =
            Map<String, List<DiscoverProfileStatusItem>>.from(
                state.profileItemsMap)
              ..[username] = items;

        emit(state.copyWith(
          profileStatusMap: updatedStatusMap,
          profilesMap: updatedProfilesMap,
          profileItemsMap: updatedItemsMap,
        ));
      } else {
        final updatedStatusMap =
            Map<String, ApiStatus>.from(state.profileStatusMap)
              ..[username] = ApiStatus.failure;
        final updatedErrorMap =
            Map<String, String?>.from(state.profileErrorMessageMap)
              ..[username] = response.message;

        emit(state.copyWith(
          profileStatusMap: updatedStatusMap,
          profileErrorMessageMap: updatedErrorMap,
        ));
      }
    } catch (e) {
      final updatedStatusMap =
          Map<String, ApiStatus>.from(state.profileStatusMap)
            ..[username] = ApiStatus.failure;
      final updatedErrorMap =
          Map<String, String?>.from(state.profileErrorMessageMap)
            ..[username] = e.toString();

      emit(state.copyWith(
        profileStatusMap: updatedStatusMap,
        profileErrorMessageMap: updatedErrorMap,
      ));
    }
  }

  Future<void> _onMarkDiscoverStoriesAsSeen(
    MarkDiscoverStoriesAsSeen event,
    Emitter<DiscoverState> emit,
  ) async {
    if (event.statusIds.isEmpty) return;
    if (Global.token == null || Global.token!.isEmpty) return;

    try {
      await discoverRepo.markStatusesAsSeen(event.statusIds);
      // Fetch statuses again to update the UI rings globally
      add(const FetchDiscoverStatuses(isRefresh: true));
    } catch (_) {
      // Background task, ignore failure
    }
  }

  Future<void> _onFetchDiscoverReels(
    FetchDiscoverReels event,
    Emitter<DiscoverState> emit,
  ) async {
    // If it's not a refresh and we already have data, don't fetch again
    if (!event.isRefresh &&
        state.reelsStatus == ApiStatus.success &&
        state.reels.isNotEmpty) {
      return;
    }

    if (event.isRefresh) {
      emit(state.copyWith(reelsStatus: ApiStatus.loading));
    }

    try {
      final response = await discoverRepo.fetchReels();

      if (response.success == true && response.data != null) {
        emit(state.copyWith(
          reelsStatus: ApiStatus.success,
          reels: response.data!.items,
        ));
      } else {
        emit(state.copyWith(
          reelsStatus: ApiStatus.failure,
          reelsErrorMessage: response.message,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        reelsStatus: ApiStatus.failure,
        reelsErrorMessage: e.toString(),
      ));
    }
  }
}
