import 'dart:convert';
import 'dart:developer';

import 'package:hyper_local/config/api_base_helper.dart';
import 'package:hyper_local/config/api_routes.dart';

import '../../../config/helper.dart';
import '../../../services/location/location_service.dart';
import '../model/store_detail_model.dart';

class NearByStoreRepo {
  Future<Map<String, dynamic>?> getNearByStores({
    int page = 1,
    int perPage = 15,
    required String searchQuery,
  }) async {
    try {
      final locationService = LocationService.getStoredLocation();
      if (locationService == null) {
        return null;
      }

      final latitude = locationService.latitude;
      final longitude = locationService.longitude;

      final Map<String, dynamic> query = {
        'latitude': latitude,
        'longitude': longitude,
        'page': page.toString(),
        'per_page': perPage.toString(),
        if (searchQuery.isNotEmpty) 'search': searchQuery
      };

      final response = await AppHelpers.apiBaseHelper.getAPICall(
        ApiRoutes.nearByStores,
        query,
      );

      // Extract .data and ensure it's a Map
      dynamic data = response.data;

      if (data is String) {
        data = jsonDecode(data);
      }

      if (data is Map<String, dynamic>) {
        log('API SUCCESS: Stores fetched');
        return data;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<List<StoreDetailModel>> fetchStoreDetail({
    required String storeSlug,
    int? isNotify,
  }) async {
    try {
      final locationService = LocationService.getStoredLocation();
      final latitude = locationService?.latitude;
      final longitude = locationService?.longitude;

      String url = '${ApiRoutes.storeDetailApi}$storeSlug';
      List<String> queryParams = [];
      if (latitude != null) queryParams.add('latitude=$latitude');
      if (longitude != null) queryParams.add('longitude=$longitude');
      if (isNotify != null) queryParams.add('is_notify=$isNotify');
      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      final response = await AppHelpers.apiBaseHelper.getAPICall(url, {});
      if (response.statusCode == 200) {
        List<StoreDetailModel> storeData = [];
        storeData.add(StoreDetailModel.fromJson(response.data));
        return storeData;
      } else {
        return [];
      }
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> toggleStoreNotification({
    required int storeId,
    required bool isNotify,
  }) async {
    try {
      final response = await AppHelpers.apiBaseHelper.postAPICall(
        ApiRoutes.storeNotifyMeApi(storeId),
        {
          'is_notify': isNotify ? '1' : '0',
        },
      );

      dynamic data = response.data;
      if (data is String) {
        data = jsonDecode(data);
      }

      if (response.statusCode == 200) {
        if (data is Map<String, dynamic>) {
          return data;
        }
        return {'success': true, 'message': 'Notification updated successfully'};
      } else {
        final message = (data is Map && data['message'] != null)
            ? data['message'].toString()
            : 'Failed to update notification';
        throw ApiException(message);
      }
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> findStoresReq({
    required double neLat,
    required double neLng,
    required double swLat,
    required double swLng,
    required double userLat,
    required double userLng,
  }) async {
    try {
      final response = await AppHelpers.apiBaseHelper.postAPICall(
        ApiRoutes.findStoresApi,
        {
          'ne_lat': neLat,
          'ne_lng': neLng,
          'sw_lat': swLat,
          'sw_lng': swLng,
          'latitude': userLat,
          'longitude': userLng,
        },
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw ApiException(response.data['message'] ?? '');
      }
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> fetchStoreReels({
    required String storeSlug,
    String? cursor,
    String? sessionId,
    int perPage = 10,
  }) async {
    try {
      final locationService = LocationService.getStoredLocation();
      final latitude = locationService?.latitude ?? 0.0;
      final longitude = locationService?.longitude ?? 0.0;

      final Map<String, dynamic> query = {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'store_slug': storeSlug,
        'per_page': perPage.toString(),
      };
      if (cursor != null && cursor.isNotEmpty) {
        query['cursor'] = cursor;
      }
      if (sessionId != null && sessionId.isNotEmpty) {
        query['session_id'] = sessionId;
      }

      final response = await AppHelpers.apiBaseHelper.getAPICall(
        ApiRoutes.watchAndBuyReelsApi,
        query,
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw ApiException(response.data['message'] ?? 'Failed to fetch reels');
      }
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> fetchStoreStories({
    required String storeSlug,
  }) async {
    try {
      final locationService = LocationService.getStoredLocation();
      final latitude = locationService?.latitude ?? 0.0;
      final longitude = locationService?.longitude ?? 0.0;

      final Map<String, dynamic> query = {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'store_slug': storeSlug,
        'per_page': '20',
      };

      final response = await AppHelpers.apiBaseHelper.getAPICall(
        ApiRoutes.watchAndBuyStatusesApi,
        query,
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw ApiException(
            response.data['message'] ?? 'Failed to fetch store stories');
      }
    } catch (e) {
      throw ApiException(e.toString());
    }
  }
}
