import '../../../config/helper.dart';
import 'near_by_store_model.dart';

class StoreDetailModel {
  bool? success;
  String? message;
  StoreData? data;
  bool? isNotify;

  StoreDetailModel({this.success, this.message, this.data, this.isNotify});

  StoreDetailModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    data = json['data'] != null ? StoreData.fromJson(json['data']) : null;
    isNotify = parseBool(json['is_notify']) ?? data?.isNotify;
    if (data != null && data!.isNotify == null && isNotify != null) {
      data = data!.copyWith(isNotify: isNotify);
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    if (isNotify != null) {
      data['is_notify'] = isNotify;
    }
    return data;
  }
}
