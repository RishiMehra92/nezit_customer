import '../../../../config/api_routes.dart';
import '../../../../config/helper.dart';
import '../../../../services/location/location_service.dart';

class HomeLayoutRepository {
  /// Fetches the server-driven home layout, paginated by section
  /// ([page] / [perPage]). Pass [categorySlug] for a category-scoped layout;
  /// empty fetches the global layout.
  Future<Map<String, dynamic>> fetchHomeLayout({
    String categorySlug = '',
    int page = 1,
    int perPage = 5,
  }) async {
    try {
      final locationService = LocationService.getStoredLocation();
      final double? latitude = locationService?.latitude;
      final double? longitude = locationService?.longitude;

      final query = <String, dynamic>{
        'page': page,
        'per_page': perPage,
        if (categorySlug.isNotEmpty) 'category_slug': categorySlug,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      };
      final response = await AppHelpers.apiBaseHelper.getAPICall(
        ApiRoutes.homeLayoutApi,
        query,
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to fetch home layout');
    }
  }
}
