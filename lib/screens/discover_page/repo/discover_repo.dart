import 'dart:developer';

import 'package:hyper_local/config/helper.dart';
import 'package:hyper_local/config/api_routes.dart';

import 'package:hyper_local/services/location/location_service.dart';

import '../model/discover_profile_status_model.dart';
import '../model/discover_status_model.dart';
import '../model/discover_reel_model.dart';

class DiscoverRepo {
  Future<DiscoverStatusResponse> fetchWatchAndBuyStatuses({
    String? cursor,
    String? sessionId,
    int perPage = 20,
  }) async {
    try {
      final locationService = LocationService.getStoredLocation();
      final double? latitude = locationService?.latitude;
      final double? longitude = locationService?.longitude;

      final queryParams = <String, dynamic>{
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
        if (sessionId != null && sessionId.isNotEmpty) 'session_id': sessionId,
        'per_page': perPage,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      };

      final response = await AppHelpers.apiBaseHelper.getAPICall(
        ApiRoutes.watchAndBuyStatusesApi,
        queryParams,
      );
      return DiscoverStatusResponse.fromJson(response.data as Map<String, dynamic>);
    } catch (e, stacktrace) {
      log('Error fetching WatchAndBuy Statuses: $e', stackTrace: stacktrace);
      rethrow;
    }
  }

  Future<DiscoverProfileStatusResponse> fetchProfileStatuses({
    required String username,
  }) async {
    try {
      final response = await AppHelpers.apiBaseHelper.getAPICall(
        ApiRoutes.watchAndBuyProfileStatusesApi(username),
        {},
      );
      return DiscoverProfileStatusResponse.fromJson(response.data as Map<String, dynamic>);
    } catch (e, stacktrace) {
      log('Error fetching Profile Statuses ($username): $e', stackTrace: stacktrace);
      rethrow;
    }
  }

  Future<void> markStatusesAsSeen(List<int> statusIds) async {
    if (statusIds.isEmpty) return;
    try {
      await AppHelpers.apiBaseHelper.putAPICall(
        ApiRoutes.watchAndBuyStatusesSeenApi,
        {
          "status_ids": statusIds,
        },
      );
    } catch (e, stacktrace) {
      log('Error marking statuses as seen: $e', stackTrace: stacktrace);
    }
  }

  Future<DiscoverReelResponse> fetchReels() async {
    try {
      final locationService = LocationService.getStoredLocation();
      final double? latitude = locationService?.latitude;
      final double? longitude = locationService?.longitude;

      final queryParams = <String, dynamic>{
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      };

      final response = await AppHelpers.apiBaseHelper.getAPICall(
        ApiRoutes.watchAndBuyReelsApi,
        queryParams,
      );
      return DiscoverReelResponse.fromJson(response.data as Map<String, dynamic>);
    } catch (e, stacktrace) {
      log('Error fetching WatchAndBuy Reels: $e', stackTrace: stacktrace);
      rethrow;
    }
  }
  Future<void> likeReel({
    required int reelId,
    required bool liked,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final body = <String, dynamic>{
        if (latitude != null) "latitude": latitude,
        if (longitude != null) "longitude": longitude,
        "items": [
          {
            "reel_id": reelId,
            "liked": liked,
          }
        ]
      };
      await AppHelpers.apiBaseHelper.putAPICall(
        ApiRoutes.watchAndBuyReelsLikesApi,
        body,
      );
    } catch (e, stacktrace) {
      log('Error liking reel: $e', stackTrace: stacktrace);
    }
  }
}
