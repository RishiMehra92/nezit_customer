import 'dart:convert';

import '../../../config/api_base_helper.dart';
import '../../../config/api_routes.dart';
import '../../../config/helper.dart';
import '../model/shared_cart.dart';

class SharedCartRepository {
  final ApiBaseHelper api;
  SharedCartRepository({ApiBaseHelper? api})
      : api = api ?? AppHelpers.apiBaseHelper;

  Map<String, dynamic> _response(dynamic response) {
    final status = response.statusCode as int?;
    final body = response.data is String
        ? jsonDecode(response.data as String)
        : response.data;
    final json = sharedCartMap(body);
    if (status == null ||
        status < 200 ||
        status >= 300 ||
        parseBool(json['success']) != true) {
      throw ApiException(
          parseString(json['message']) ?? 'Unable to load the shared cart.');
    }
    return json;
  }

  Future<CartShareLink> createLink({String? title}) async {
    final response = await api.postAPICall(ApiRoutes.shareCartApi,
        {if (title != null && title.trim().isNotEmpty) 'title': title.trim()});
    return CartShareLink.fromJson(sharedCartMap(_response(response)['data']));
  }

  Future<SharedCartPreview> preview(
    String code, {
    required bool authenticated,
    int? addressId,
    double? latitude,
    double? longitude,
  }) async {
    if ((!authenticated || addressId == null) &&
        (latitude == null || longitude == null)) {
      throw const FormatException(
          'Select your location to preview these items.');
    }
    final params = <String, dynamic>{
      if (authenticated && addressId != null)
        'address_id': addressId
      else ...{'latitude': latitude, 'longitude': longitude},
    };
    final response = await api.getAPICall(ApiRoutes.sharedCartApi(code), params,
        authenticated: authenticated);
    return SharedCartPreview.fromJson(
        sharedCartMap(_response(response)['data']));
  }

  Future<SharedCartImport> importCart(
      String code, SharedCartAction action) async {
    final response = await api.postAPICall(
        ApiRoutes.importSharedCartApi(code), {'action': action.name});
    return SharedCartImport.fromJson(_response(response));
  }
}
