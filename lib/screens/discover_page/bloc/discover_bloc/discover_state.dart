import 'package:equatable/equatable.dart';
import 'package:hyper_local/utils/api_status.dart';
import '../../model/discover_status_model.dart';
import '../../model/discover_profile_status_model.dart';
import '../../model/discover_reel_model.dart';

class DiscoverState extends Equatable {
  final ApiStatus status;
  final bool isLoadMoreLoading;
  final List<DiscoverStatusItem> items;
  final String? errorMessage;
  final int page;
  final String? nextCursor;
  final String? sessionId;
  final bool hasReachedMax;

  final ApiStatus reelsStatus;
  final List<DiscoverReelItem> reels;
  final String? reelsErrorMessage;

  final Map<String, ApiStatus> profileStatusMap;
  final Map<String, DiscoverProfile?> profilesMap;
  final Map<String, List<DiscoverProfileStatusItem>> profileItemsMap;
  final Map<String, String?> profileErrorMessageMap;

  const DiscoverState({
    this.status = ApiStatus.initial,
    this.isLoadMoreLoading = false,
    this.items = const [],
    this.errorMessage,
    this.page = 1,
    this.nextCursor,
    this.sessionId,
    this.hasReachedMax = false,
    this.reelsStatus = ApiStatus.initial,
    this.reels = const [],
    this.reelsErrorMessage,
    this.profileStatusMap = const {},
    this.profilesMap = const {},
    this.profileItemsMap = const {},
    this.profileErrorMessageMap = const {},
  });

  static const Object _sentinel = Object();

  DiscoverState copyWith({
    ApiStatus? status,
    bool? isLoadMoreLoading,
    List<DiscoverStatusItem>? items,
    String? errorMessage,
    int? page,
    Object? nextCursor = _sentinel,
    Object? sessionId = _sentinel,
    bool? hasReachedMax,
    ApiStatus? reelsStatus,
    List<DiscoverReelItem>? reels,
    String? reelsErrorMessage,
    Map<String, ApiStatus>? profileStatusMap,
    Map<String, DiscoverProfile?>? profilesMap,
    Map<String, List<DiscoverProfileStatusItem>>? profileItemsMap,
    Map<String, String?>? profileErrorMessageMap,
  }) {
    return DiscoverState(
      status: status ?? this.status,
      isLoadMoreLoading: isLoadMoreLoading ?? this.isLoadMoreLoading,
      items: items ?? this.items,
      errorMessage: errorMessage ?? this.errorMessage,
      page: page ?? this.page,
      nextCursor: nextCursor == _sentinel ? this.nextCursor : (nextCursor as String?),
      sessionId: sessionId == _sentinel ? this.sessionId : (sessionId as String?),
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      reelsStatus: reelsStatus ?? this.reelsStatus,
      reels: reels ?? this.reels,
      reelsErrorMessage: reelsErrorMessage ?? this.reelsErrorMessage,
      profileStatusMap: profileStatusMap ?? this.profileStatusMap,
      profilesMap: profilesMap ?? this.profilesMap,
      profileItemsMap: profileItemsMap ?? this.profileItemsMap,
      profileErrorMessageMap: profileErrorMessageMap ?? this.profileErrorMessageMap,
    );
  }

  @override
  List<Object?> get props => [
        status,
        isLoadMoreLoading,
        items,
        errorMessage,
        page,
        nextCursor,
        sessionId,
        hasReachedMax,
        reelsStatus,
        reels,
        reelsErrorMessage,
        profileStatusMap,
        profilesMap,
        profileItemsMap,
        profileErrorMessageMap,
      ];
}
