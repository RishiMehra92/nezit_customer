import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:hyper_local/config/api_base_helper.dart';
import 'package:hyper_local/config/constant.dart';
import 'package:hyper_local/config/security.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart' as dio;
import '../../../config/api_routes.dart';
import '../../../config/helper.dart';
import '../../cart_page/widgets/cart_product_item.dart';
import '../model/order_detail_model.dart';
import '../model/delivery_tracking_model.dart';
import '../model/return_reason_model.dart';
import 'package:intl/intl.dart';
import '../../cart_page/model/get_cart_model.dart';

class OrderRepository {
  Future<Map<String, dynamic>> createOrder({
    required String paymentType,
    required String promoCode,
    required String giftCard,
    int? addressId,
    required bool rushDelivery,
    required bool useWallet,
    required String orderNote,
    Map<String, dynamic>? paymentDetails,
    required Map<int, List<CartItemAttachment>>? attachments,
    required String deliveryType,
    String? scheduledDate,
    String? scheduledTimeSlotLabel,
    String? scheduledSlotStartTime,
    String? scheduledSlotEndTime,
  }) async {
    try {
      final formData = dio.FormData();

      String? paymenttype;
      if (paymentType.isNotEmpty && paymentType != 'wallet') {
        paymenttype =
            paymentType == 'cod' ? paymentType : '${paymentType}Payment';
      } else if (paymentType == 'wallet') {
        paymenttype = paymentType;
      } else {
        paymenttype = '';
      }

      formData.fields.addAll([
        MapEntry('payment_type', paymenttype),
        MapEntry('promo_code', promoCode),
        MapEntry('gift_card', giftCard),
        if (addressId != null) MapEntry('address_id', addressId.toString()),
        MapEntry('rush_delivery', rushDelivery ? '1' : '0'),
        MapEntry('use_wallet', useWallet ? '1' : '0'),
        MapEntry('order_note', orderNote),
        MapEntry('delivery_type', deliveryType),
        if (scheduledDate != null) MapEntry('scheduled_date', scheduledDate),
        if (scheduledSlotStartTime != null)
          MapEntry('scheduled_slot_start_time', scheduledSlotStartTime),
        if (scheduledSlotEndTime != null)
          MapEntry('scheduled_slot_end_time', scheduledSlotEndTime),
        if (paymentType != 'flutterwave' &&
            paymentType != 'xendit' &&
            paymentType != 'mercadoPago' &&
            paymentType != 'mercadopago')
          MapEntry('redirect_url', AppConstant.baseUrl),
        // Add paymentDetails if needed (flatten them)
        ...?paymentDetails?.entries
            .map((e) => MapEntry(e.key, e.value.toString())),
      ]);

      if (attachments != null && attachments.isNotEmpty) {
        for (final entry in attachments.entries) {
          final productId = entry.key;
          final List<CartItemAttachment> attachmentList = entry.value;

          for (final attachment in attachmentList) {
            if (attachment.filePath.isEmpty) continue;

            final file = File(attachment.filePath);
            if (!await file.exists()) {
              log('⚠️ File not found: ${attachment.fileName} (Product ID: $productId)');
              continue;
            }

            formData.files.add(
              MapEntry(
                'attachments[$productId][]',
                await MultipartFile.fromFile(
                  attachment.filePath,
                  filename: attachment.fileName,
                ),
              ),
            );
          }
        }
      }

      final response = await AppHelpers.dio.post(
        ApiRoutes.createOrderApi,
        data: formData,
        options: dio.Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final rawData = response.data;
        if (rawData is List && rawData.isNotEmpty) {
          return Map<String, dynamic>.from(rawData.first);
        } else if (rawData is Map) {
          return Map<String, dynamic>.from(rawData);
        }
        return {};
      } else {
        return {};
      }
      // return {};
    } on dio.DioException catch (e) {
      if (e.response != null) {
        final dynamic data = e.response?.data;
        if (data is Map) {
          final message = data['message'] ?? data['error'];
          if (message != null) {
            throw ApiException(message.toString());
          }
        }
      }
      throw ApiException(e.message ?? 'Something went wrong');
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> fetchMyOrderList({
    required int perPage,
    required int page,
    required String dateFilter,
    required String statusFilter,
    String? orderType,
    int? isScheduled,
  }) async {
    try {
      final Map<String, dynamic> query = {
        'page': page.toString(),
        'per_page': perPage.toString(),
      };
      if (dateFilter.isNotEmpty) {
        query['date_range'] = dateFilter;
      }
      if (statusFilter.isNotEmpty) {
        query['status'] = statusFilter;
      }
      if (orderType != null && orderType.isNotEmpty) {
        query['order_type'] = orderType;
      }
      if (isScheduled != null) {
        query['is_scheduled'] = isScheduled.toString();
      }

      final response = await AppHelpers.apiBaseHelper.getAPICall(
        ApiRoutes.getMyOrderApi,
        query,
      );
      if (response.statusCode == 200) {
        return response.data;
      }
      return {};
    } catch (e) {
      throw ApiException('Failed to get my orders list');
    }
  }

  Future<List<OrderDetailModel>> getOrderDetail({
    required String orderSlug,
  }) async {
    try {
      final response = await AppHelpers.apiBaseHelper.getAPICall(
        ApiRoutes.orderDetailApi + orderSlug,
        {},
      );

      if (response.statusCode == 200) {
        final List<OrderDetailModel> orderData = [];
        orderData.add(OrderDetailModel.fromJson(response.data));
        return orderData;
      } else {
        return [];
      }
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<DeliveryBoyTrackingModel?> getDeliveryTracking({
    required String orderSlug,
  }) async {
    try {
      final response = await AppHelpers.apiBaseHelper.getAPICall(
        '${ApiRoutes.orderDetailApi}$orderSlug/delivery-boy-location',
        {},
      );

      if (response.statusCode == 200) {
        return DeliveryBoyTrackingModel.fromJson(response.data);
      } else {
        return response.data;
      }
    } catch (e) {
      log('Hello Gello ${e.toString()}');
      throw ApiException(e.toString());
    }
  }

  Future<String> downloadInvoicePdf(String invoiceUrl) async {
    try {
      final response =
          await AppHelpers.apiBaseHelper.getAPICall(invoiceUrl, {});
      if (response.data != null) {
        if (Platform.isAndroid) {
          await Permission.storage.request();
        }
        // Get the appropriate directory
        Directory? directory;
        if (Platform.isAndroid) {
          // For Android - use Downloads directory
          directory = Directory('/storage/emulated/0/Download');
          if (!await directory.exists()) {
            directory = await getExternalStorageDirectory();
          }
        } else if (Platform.isIOS) {
          // For iOS - use Documents directory (accessible in Files app)
          directory = await getApplicationDocumentsDirectory();
        }
        final fileName = 'invoice_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final filePath = '${directory!.path}/$fileName';
        await AppHelpers.apiBaseHelper.downloadFile(
          url: invoiceUrl,
          cancelToken: CancelToken(),
          savePath: filePath,
          updateDownloadedPercentage: (received, total) {
            // Two parameters
            if (total != -1) {
              final percentage = (received / total * 100);
              log('Download: ${percentage.toStringAsFixed(0)}%');
            }
          },
        );
        return filePath;
      } else {
        return '';
      }
    } catch (e) {
      throw ApiException('Failed to download invoice: $e');
    }
  }

  Future<List<ReturnReason>> fetchReturnReasons({
    required int orderItemId,
  }) async {
    try {
      final response = await AppHelpers.apiBaseHelper.getAPICall(
        '${ApiRoutes.returnOrderItemApi}$orderItemId/return-reasons',
        {},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((json) => ReturnReason.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> returnOrderItemRequest({
    required int orderItemId,
    int? returnReasonId,
    required String reason,
    List<XFile> images = const [],
  }) async {
    try {
      final Map<String, String> fields = {
        'reason': reason,
      };
      if (returnReasonId != null && returnReasonId != -1) {
        fields['return_reason_id'] = returnReasonId.toString();
      }
      final form = await formDataWithImages(
          fields: fields, images: images, imageFieldLabel: 'images');

      log('Return Order Item Request ${form.files}');

      final response = await AppHelpers.apiBaseHelper.postAPICall(
          '${ApiRoutes.returnOrderItemApi}$orderItemId/return', form);
      if (response.statusCode == 200) {
        return response.data;
      }
      return {};
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> cancelReturnRequest({
    required int orderItemId,
  }) async {
    try {
      final response = await AppHelpers.apiBaseHelper.postAPICall(
          '${ApiRoutes.cancelReturnRequestApi}$orderItemId/return-cancel', {});

      if (response.statusCode == 200) {
        return response.data;
      }
      return {};
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> cancelOrderItem({
    required int orderItemId,
  }) async {
    try {
      final response = await AppHelpers.apiBaseHelper.postAPICall(
          '${ApiRoutes.cancelOrderItemApi}$orderItemId/cancel', {});

      if (response.statusCode == 200) {
        return response.data;
      }
      return {};
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> reOrderRequest({
    required int orderId,
  }) async {
    try {
      final response = await AppHelpers.apiBaseHelper
          .postAPICall('${ApiRoutes.reOrderApi}$orderId/reorder', {});

      if (response.statusCode == 200) {
        return response.data;
      }
      return {};
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<String?> rescheduleOrder({
    required int orderId,
    required String date,
    required String startTime,
    required String endTime,
  }) async {
    try {
      final response = await AppHelpers.apiBaseHelper.postAPICall(
        ApiRoutes.rescheduleOrderApi(orderId),
        {
          'scheduled_date': date,
          'scheduled_slot_start_time': startTime,
          'scheduled_slot_end_time': endTime,
        },
      );
      if (response != null && response.data is Map) {
        return response.data['message']?.toString();
      }
      return null;
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<String?> cancelOrder({
    required int orderId,
  }) async {
    try {
      final response = await AppHelpers.apiBaseHelper.postAPICall(
        ApiRoutes.cancelOrderApi(orderId),
        {},
      );
      if (response != null && response.data is Map) {
        return response.data['message']?.toString();
      }
      return null;
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<List<DeliverySlot>> getRecoverySlots({
    required int orderId,
    required DateTime date,
  }) async {
    try {
      final String formattedDate = DateFormat('yyyy-MM-dd').format(date);
      final response = await AppHelpers.apiBaseHelper.getAPICall(
        ApiRoutes.recoverySlotsApi(orderId, formattedDate),
        {},
      );
      if (response.statusCode == 200) {
        final dynamic responseBody = response.data;
        if (responseBody is Map<String, dynamic>) {
          final dynamic payload = responseBody.containsKey('data')
              ? responseBody['data']
              : responseBody;
          if (payload is Map<String, dynamic>) {
            final dynamic slots = payload['slots'];
            if (slots is List) {
              return slots
                  .whereType<Map>()
                  .map((slot) => DeliverySlot.fromJson(Map<String, dynamic>.from(slot)))
                  .toList();
            }
          }
        }
      }
      return [];
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> payOrderTip({
    required String orderSlug,
    required double riderTipAmount,
    required String paymentMethod,
    String? transactionId,
  }) async {
    try {
      final response = await AppHelpers.apiBaseHelper.postAPICall(
        '${AppConstant.baseUrl}user/orders/$orderSlug/tip',
        {
          'rider_tip_amount': riderTipAmount,
          'payment_method': paymentMethod,
          if (transactionId != null) 'transaction_id': transactionId,
        },
      );
      if (response.statusCode == 200) {
        return response.data;
      }
      return {};
    } catch (e) {
      throw ApiException(e.toString());
    }
  }
}
