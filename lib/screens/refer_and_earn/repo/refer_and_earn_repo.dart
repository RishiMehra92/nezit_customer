import 'package:hyper_local/config/api_base_helper.dart';
import 'package:hyper_local/config/api_routes.dart';
import 'package:hyper_local/config/helper.dart';

import '../model/refer_and_earn_model.dart';

class ReferAndEarnRepository {

  Future<ReferAndEarnModel> fetchReferAndEarn() async {
    try{
      final response = await AppHelpers.apiBaseHelper.getAPICall(
        ApiRoutes.getReferInfoApi,
        {}
      );

      if(response.statusCode == 200) {
        return ReferAndEarnModel.fromJson(response.data);
      }
      return response.data;
    }catch(e) {
      throw ApiException(e.toString());
    }
  }

}