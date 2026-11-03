import 'package:hyper_local/config/api_base_helper.dart';
import 'package:hyper_local/config/api_routes.dart';
import '../../../services/location/location_service.dart';

class ProductDetailRepository {
  final ApiBaseHelper apiBaseHelper = ApiBaseHelper();

  Future<Map<String, dynamic>> fetchProductDetail({
    required String productSlug,
    int? isNotify,
    int? variantId,
  }) async {
    try{
      final locationService = LocationService.getStoredLocation();
      final latitude = locationService!.latitude;
      final longitude = locationService.longitude;
      String url = '${ApiRoutes.productDetailApi}$productSlug?latitude=$latitude&longitude=$longitude';
      if (isNotify != null) {
        url += '&is_notify=$isNotify';
      }
      if (variantId != null) {
        url += '&variant_id=$variantId';
      }
      final response = await apiBaseHelper.getAPICall(url, {});
      return response.data;
    }catch(e){
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> fetchSimilarProduct({required List<String> excludeProductSlug}) async {
    try{
      final locationService = LocationService.getStoredLocation();
      final latitude = locationService!.latitude;
      final longitude = locationService.longitude;

      String apiUrl = '';
      if(excludeProductSlug.isNotEmpty){
        String excludeParam = excludeProductSlug.join(",");
        apiUrl = '${ApiRoutes.getSimilarProductApi}?exclude_product=$excludeParam&latitude=$latitude&longitude=$longitude';
      } else {
        apiUrl = '${ApiRoutes.getSimilarProductApi}?latitude=$latitude&longitude=$longitude';
      }
      final response = await apiBaseHelper.getAPICall(
          apiUrl,
          {}
      );
      return response.data;
    } catch(e){
      throw ApiException('Failed to fetch similar product');
    }
  }
}