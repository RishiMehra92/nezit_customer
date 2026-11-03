import 'package:hyper_local/config/api_base_helper.dart';
import 'package:hyper_local/config/api_routes.dart';
import 'package:hyper_local/screens/coins_page/model/coins_summary_model.dart';
import '../../../config/helper.dart';

class CoinsRepository {
  Future<CoinsSummaryModel?> fetchCoinsSummary({required int page, required int perPage}) async {
    try {
      final response = await AppHelpers.apiBaseHelper.getAPICall(
        ApiRoutes.loyaltyPointsTransactionsApi,
        {
          'page': page,
          'per_page': perPage,
        }
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return CoinsSummaryModel.fromJson(response.data['data']);
      } else {
        return null;
      }
    } catch (e) {
      throw ApiException(e.toString());
    }
  }
}
