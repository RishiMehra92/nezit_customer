import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../config/api_routes.dart';
import '../../../config/constant.dart';
import '../../../config/security.dart';
import '../model/support_models.dart';

class SupportApiException implements Exception {
  const SupportApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isConflict => statusCode == 409;

  @override
  String toString() => message;
}

class SupportRepository {
  SupportRepository({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 30),
              sendTimeout: const Duration(seconds: 30),
            ));

  final Dio _dio;
  static const Uuid _uuid = Uuid();

  Options _options({ResponseType? responseType}) => Options(
        headers: headers,
        responseType: responseType,
      );

  Future<SupportThreadPayload> getThread() async {
    final endpoint = ApiRoutes.supportThreadApi;
    final fullUrl = endpoint.startsWith('http') ? endpoint : '${AppConstant.baseUrl}$endpoint';
    if (kDebugMode) {
      debugPrint('[SupportAPI] ----------------------------------------');
      debugPrint('[SupportAPI] Fetching Support Thread API');
      debugPrint('[SupportAPI]   - Base URL:      "${AppConstant.baseUrl}"');
      debugPrint('[SupportAPI]   - Route Endpoint: "$endpoint"');
      debugPrint('[SupportAPI]   - Full Target:   "$fullUrl"');
      final safeHeaders = headers?.map((k, v) => MapEntry(k, k == 'Authorization' ? '${v.substring(0, v.length > 20 ? 20 : v.length)}...' : v));
      debugPrint('[SupportAPI]   - Headers:       $safeHeaders');
      debugPrint('[SupportAPI] ----------------------------------------');
    }
    final response = await _get(ApiRoutes.supportThreadApi);
    final dataMap = _data(response);
    if (kDebugMode) {
      debugPrint('[SupportAPI] Support Thread API Response Received:');
      debugPrint('[SupportAPI]   - HTTP Status: ${response.statusCode}');
      debugPrint('[SupportAPI]   - Thread UUID: ${dataMap['thread']?['uuid']}');
      debugPrint('[SupportAPI]   - Realtime JSON: ${dataMap['realtime']}');
    }
    return SupportThreadPayload.fromJson(dataMap);
  }

  Future<List<SupportTopic>> getTopics() async {
    final response = await _get(ApiRoutes.supportTopicsApi);
    final data = _rawData(response);
    return data is List
        ? data
            .whereType<Map>()
            .map((item) =>
                SupportTopic.fromJson(Map<String, dynamic>.from(item)))
            .toList()
        : <SupportTopic>[];
  }


  Future<SupportMessagePage> getOlderMessages(int beforeMessageId) async {
    final response = await _get(
      ApiRoutes.supportThreadMessagesApi,
      query: {'before_message_id': beforeMessageId, 'limit': 8},
    );
    return SupportMessagePage.fromJson(_data(response));
  }

  Future<SupportSession> startSession({
    required int topicId,
    int? orderId,
    required String message,
    required List<SupportLocalAttachment> attachments,
    String? clientMessageId,
  }) async {
    final form = FormData.fromMap({
      'topic_id': topicId,
      'client_message_id': clientMessageId ?? _uuid.v4(),
      if (orderId != null) 'order_id': orderId,
      if (message.trim().isNotEmpty) 'message': message.trim(),
      if (attachments.isNotEmpty)
        'attachments': await Future.wait(
          attachments.map(
            (file) => MultipartFile.fromFile(
              file.path,
              filename: file.name,
              contentType: DioMediaType.parse(file.mimeType),
            ),
          ),
        ),
    }, ListFormat.multiCompatible);
    final response = await _post(ApiRoutes.supportSessionsApi, form);
    return SupportSession.fromJson(_data(response));
  }

  Future<SupportMessage> sendMessage({
    required String slug,
    required String message,
    required List<SupportLocalAttachment> attachments,
    required String clientMessageId,
  }) async {
    final form = FormData.fromMap({
      'client_message_id': clientMessageId,
      if (message.trim().isNotEmpty) 'message': message.trim(),
      if (attachments.isNotEmpty)
        'attachments': await Future.wait(
          attachments.map(
            (file) => MultipartFile.fromFile(
              file.path,
              filename: file.name,
              contentType: DioMediaType.parse(file.mimeType),
            ),
          ),
        ),
    }, ListFormat.multiCompatible);
    final response = await _post(
      ApiRoutes.supportSessionMessagesApi(slug),
      form,
    );
    return SupportMessage.fromJson(_data(response));
  }

  Future<void> setTyping(String slug, bool typing) => _post(
        ApiRoutes.supportSessionTypingApi(slug),
        {'typing': typing},
      );

  Future<void> markRead(String slug, int? messageId) => _post(
        ApiRoutes.supportSessionReadApi(slug),
        {'message_id': messageId},
      );

  Future<void> requestCallback(String slug, {String? phone}) => _post(
        ApiRoutes.supportSessionCallbacksApi(slug),
        {'phone': phone?.trim().isEmpty == true ? null : phone?.trim()},
      );

  Future<void> resolve(String slug, {String? summary}) => _post(
        ApiRoutes.supportSessionResolveApi(slug),
        {'summary': summary?.trim().isEmpty == true ? null : summary?.trim()},
      );

  Future<void> rate(
    String slug, {
    required int score,
    String? feedback,
  }) =>
      _post(
        ApiRoutes.supportSessionRatingApi(slug),
        {
          'score': score,
          'feedback':
              feedback?.trim().isEmpty == true ? null : feedback?.trim(),
        },
      );

  Future<Uint8List> getAttachment(String url) async {
    try {
      final resolvedUrl = SupportAttachment.resolveUrl(url);
      final response = await _dio.get<List<int>>(
        resolvedUrl,
        options: _options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(response.data ?? const []);
    } on DioException catch (error) {
      throw _exception(error);
    }
  }

  Future<Response<dynamic>> _get(
    String url, {
    Map<String, dynamic>? query,
  }) async {
    try {
      return await _dio.get<dynamic>(
        url,
        queryParameters: query,
        options: _options(),
      );
    } on DioException catch (error) {
      throw _exception(error);
    }
  }

  Future<Response<dynamic>> _post(String url, dynamic body) async {
    try {
      final requestHeaders = Map<String, String>.from(headers ?? const {});
      if (body is FormData) requestHeaders.remove('Content-Type');
      return await _dio.post<dynamic>(
        url,
        data: body,
        options: Options(headers: requestHeaders),
      );
    } on DioException catch (error) {
      throw _exception(error);
    }
  }

  dynamic _rawData(Response<dynamic> response) {
    final body = response.data;
    if (body is Map && body.containsKey('data')) return body['data'];
    return body;
  }

  Map<String, dynamic> _data(Response<dynamic> response) {
    final data = _rawData(response);
    return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
  }

  SupportApiException _exception(DioException error) {
    final response = error.response;
    final data = response?.data;
    String message = 'Unable to connect. Please try again.';
    if (data is Map) {
      message = data['message']?.toString() ?? message;
      final validation = data['errors'];
      if (validation is Map && validation.values.isNotEmpty) {
        final first = validation.values.first;
        if (first is List && first.isNotEmpty) message = first.first.toString();
      }
    } else if (error.type == DioExceptionType.connectionError) {
      message = 'No internet connection.';
    }
    return SupportApiException(message, statusCode: response?.statusCode);
  }
}
