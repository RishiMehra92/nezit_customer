import 'package:hyper_local/config/api_base_helper.dart';

import '../../../config/api_routes.dart';
import '../../../config/helper.dart';
import '../../../services/location/location_service.dart';

/// Fetches the full, paginated item list for a single home-layout section
/// (GET /api/home-layout/sections/{section}). The inner `data` array shape
/// depends on the section type (categories / brands / …).
class SectionSeeAllRepository {
  Future<Map<String, dynamic>> fetchSection({
    required int sectionId,
    int page = 1,
    int perPage = 12,
  }) async {
    try {
      final locationService = LocationService.getStoredLocation();
      final double? latitude = locationService?.latitude;
      final double? longitude = locationService?.longitude;

      final response = await AppHelpers.apiBaseHelper.getAPICall(
        '${ApiRoutes.homeLayoutSectionApi}$sectionId',
        <String, dynamic>{
          'page': page,
          'per_page': perPage,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw ApiException('Failed to fetch section');
    }
  }
}
