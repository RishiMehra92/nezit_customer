import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hyper_local/config/helper.dart';

import '../../../config/constant.dart';

enum SupportConnectionMode { live, polling, offline }

int _int(dynamic value, [int fallback = 0]) =>
    value is int ? value : int.tryParse(value?.toString() ?? '') ?? fallback;

Map<String, dynamic> _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

List<Map<String, dynamic>> _maps(dynamic value) => value is List
    ? value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList()
    : <Map<String, dynamic>>[];

DateTime? _date(dynamic value) =>
    DateTime.tryParse(value?.toString() ?? '')?.toLocal();

class SupportAttachment {
  const SupportAttachment({
    required this.id,
    required this.name,
    required this.mimeType,
    required this.size,
    required this.downloadUrl,
  });

  final int id;
  final String name;
  final String mimeType;
  final int size;
  final String downloadUrl;

  static String resolveUrl(String raw) {
    final url = raw.trim();
    if (url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    if (url.startsWith('//')) return 'https:$url';
    final baseUri = Uri.tryParse(AppConstant.baseUrl);
    final origin = baseUri != null && baseUri.hasScheme && baseUri.hasAuthority
        ? '${baseUri.scheme}://${baseUri.authority}'
        : 'https://dev-hypercommerce.spa-point.in';
    if (url.startsWith('/')) {
      return '$origin$url';
    }
    final base = AppConstant.baseUrl.endsWith('/')
        ? AppConstant.baseUrl
        : '${AppConstant.baseUrl}/';
    return '$base$url';
  }

  bool get isImage => mimeType.startsWith('image/');
  bool get isPdf => mimeType == 'application/pdf';

  factory SupportAttachment.fromJson(Map<String, dynamic> json) =>
      SupportAttachment(
        id: parseInt(json['id']) ?? 0,
        name: parseString(json['name']) ?? '',
        mimeType: parseString(json['mime_type']) ?? '',
        size: parseInt(json['size']) ?? 0,
        downloadUrl: parseString(json['download_url']) ?? '',
      );

}

class SupportMessage {
  const SupportMessage({
    required this.id,
    required this.sessionId,
    required this.senderRole,
    required this.type,
    required this.text,
    required this.attachments,
    this.clientMessageId,
    this.senderName,
    this.senderAvatar,
    this.metadata,
    this.createdAt,
    this.pending = false,
    this.failed = false,
    this.localFiles = const [],
  });

  final int id;
  final int sessionId;
  final String? clientMessageId;
  final String senderRole;
  final String? senderName;
  final String? senderAvatar;
  final String type;
  final String text;
  final Map<String, dynamic>? metadata;
  final List<SupportAttachment> attachments;
  final DateTime? createdAt;
  final bool pending;
  final bool failed;
  final List<SupportLocalAttachment> localFiles;

  bool get isCustomer => senderRole == 'user';
  bool get isAgent => senderRole == 'admin';
  bool get isSystem => senderRole == 'system';

  SupportMessage copyWith({
    bool? pending,
    bool? failed,
    List<SupportAttachment>? attachments,
  }) =>
      SupportMessage(
        id: id,
        sessionId: sessionId,
        clientMessageId: clientMessageId,
        senderRole: senderRole,
        senderName: senderName,
        senderAvatar: senderAvatar,
        type: type,
        text: text,
        metadata: metadata,
        attachments: attachments ?? this.attachments,
        createdAt: createdAt,
        pending: pending ?? this.pending,
        failed: failed ?? this.failed,
        localFiles: localFiles,
      );

  factory SupportMessage.fromJson(Map<String, dynamic> json) => SupportMessage(
        id: parseInt(json['id']) ?? 0,
        sessionId: parseInt(json['session_id']) ?? 0,
        clientMessageId: parseString(json['client_message_id']),
        senderRole: parseString(json['sender_role']) ?? 'system',
        senderName: parseString(json['sender_name']),
        senderAvatar: parseString(json['sender_avatar']),
        type: parseString(json['type']) ?? 'text',
        text: parseString(json['text']) ?? '',
        metadata: json['metadata'] is Map ? _map(json['metadata']) : null,
        attachments:
            _maps(json['attachments']).map(SupportAttachment.fromJson).toList(),
        createdAt: _date(json['created_at']),
        pending: parseBool(json['pending']) ?? false,
        failed: parseBool(json['failed']) ?? false,
      );

}

class SupportCall {
  const SupportCall({
    required this.id,
    required this.status,
    this.sessionId,
    this.phone,
    this.scheduledAt,
    this.attemptedAt,
    this.outcome,
    this.createdAt,
  });

  final int id;
  final int? sessionId;
  final String status;
  final String? phone;
  final DateTime? scheduledAt;
  final DateTime? attemptedAt;
  final String? outcome;
  final DateTime? createdAt;

  factory SupportCall.fromJson(Map<String, dynamic> json) => SupportCall(
        id: parseInt(json['id']) ?? 0,
        sessionId: parseInt(json['session_id']),
        status: parseString(json['status']) ?? '',
        phone: parseString(json['phone']),
        scheduledAt: _date(json['scheduled_at']),
        attemptedAt: _date(json['attempted_at']),
        outcome: parseString(json['outcome']),
        createdAt: _date(json['created_at']),
      );

}

class SupportRating {
  const SupportRating({required this.score, this.feedback, this.agentName});

  final int score;
  final String? feedback;
  final String? agentName;

  factory SupportRating.fromJson(Map<String, dynamic> json) => SupportRating(
        score: parseInt(json['score']) ?? 0,
        feedback: parseString(json['feedback']),
        agentName: parseString(_map(json['agent'])['name']),
      );

}

class SupportTopic {
  const SupportTopic({
    required this.id,
    required this.slug,
    required this.title,
    required this.context,
    required this.quickReplies,
    this.guidance,
  });

  final int id;
  final String slug;
  final String title;
  final String context;
  final String? guidance;
  final List<String> quickReplies;

  bool supports(bool hasOrder) =>
      context == 'both' || context == (hasOrder ? 'order' : 'general');

  factory SupportTopic.fromJson(Map<String, dynamic> json) => SupportTopic(
        id: parseInt(json['id']) ?? 0,
        slug: parseString(json['slug']) ?? '',
        title: parseString(json['title']) ?? '',
        context: parseString(json['context']) ?? 'both',
        guidance: parseString(json['guidance']),
        quickReplies: json['quick_replies'] is List
            ? List<String>.from(
                (json['quick_replies'] as List).map((item) => item.toString()),
              )
            : const [],
      );

}

class SupportOrder {
  const SupportOrder({
    required this.id,
    required this.slug,
    required this.number,
    required this.status,
    required this.paymentStatus,
    required this.currencyCode,
    required this.total,
    this.createdAt,
  });

  final int id;
  final String slug;
  final String number;
  final String status;
  final String paymentStatus;
  final String currencyCode;
  final double total;
  final DateTime? createdAt;

  factory SupportOrder.fromJson(Map<String, dynamic> json) => SupportOrder(
        id: parseInt(json['id']) ?? 0,
        slug: parseString(json['slug']) ?? '',
        number: parseString(json['number']) ?? '',
        status: parseString(json['status']) ?? '',
        paymentStatus: parseString(json['payment_status']) ?? '',
        currencyCode: parseString(json['currency_code']) ?? '',
        total: parseDouble(json['total']) ?? 0.0,
        createdAt: _date(json['created_at']),
      );

}

class SupportSession {
  const SupportSession({
    required this.id,
    required this.slug,
    required this.subject,
    required this.status,
    required this.messages,
    required this.calls,
    this.parentTicketId,
    this.topic,
    this.order,
    this.assigneeId,
    this.assigneeName,
    this.assigneeAvatar,
    this.resolutionSummary,
    this.resolvedBy,
    this.resolvedAt,
    this.closedAt,
    this.createdAt,
    this.rating,
  });

  final int id;
  final String slug;
  final int? parentTicketId;
  final String subject;
  final String status;
  final SupportTopic? topic;
  final SupportOrder? order;
  final int? assigneeId;
  final String? assigneeName;
  final String? assigneeAvatar;
  final String? resolutionSummary;
  final String? resolvedBy;
  final DateTime? resolvedAt;
  final DateTime? closedAt;
  final DateTime? createdAt;
  final List<SupportMessage> messages;
  final List<SupportCall> calls;
  final SupportRating? rating;

  bool get isActive => const {
        'open',
        'in_progress',
        'waiting_customer',
      }.contains(status);

  factory SupportSession.fromJson(Map<String, dynamic> json) {
    final topic = _map(json['topic']);
    final order = _map(json['order']);
    final assignee = _map(json['assignee']);
    final rating = _map(json['rating']);
    return SupportSession(
      id: parseInt(json['id']) ?? 0,
      slug: parseString(json['slug']) ?? '',
      parentTicketId: parseInt(json['parent_ticket_id']),
      subject: parseString(json['subject']) ?? '',
      status: parseString(json['status']) ?? 'closed',
      topic: topic.isEmpty ? null : SupportTopic.fromJson(topic),
      order: order.isEmpty ? null : SupportOrder.fromJson(order),
      assigneeId: parseInt(assignee['id']),
      assigneeName: parseString(assignee['name']),
      assigneeAvatar: parseString(assignee['avatar']),
      resolutionSummary: parseString(json['resolution_summary']),
      resolvedBy: parseString(json['resolved_by']),
      resolvedAt: _date(json['resolved_at']),
      closedAt: _date(json['closed_at']),
      createdAt: _date(json['created_at']),
      messages: _maps(json['messages']).map(SupportMessage.fromJson).toList(),
      calls: _maps(json['calls']).map(SupportCall.fromJson).toList(),
      rating: rating.isEmpty ? null : SupportRating.fromJson(rating),
    );
  }

}

class SupportCustomer {
  const SupportCustomer({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.avatar,
  });

  final int id;
  final String name;
  final String? email;
  final String? phone;
  final String? avatar;

  factory SupportCustomer.fromJson(Map<String, dynamic> json) =>
      SupportCustomer(
        id: parseInt(json['id']) ?? 0,
        name: parseString(json['name']) ?? '',
        email: parseString(json['email']),
        phone: parseString(json['phone']),
        avatar: parseString(json['avatar']),
      );

}

class SupportThread {
  const SupportThread({
    required this.id,
    required this.uuid,
    required this.customer,
    required this.sessions,
    required this.hasMoreMessages,
    this.activeTicketId,
    this.lastMessageAt,
    this.oldestMessageId,
  });

  final int id;
  final String uuid;
  final int? activeTicketId;
  final DateTime? lastMessageAt;
  final SupportCustomer customer;
  final List<SupportSession> sessions;
  final bool hasMoreMessages;
  final int? oldestMessageId;

  SupportSession? get activeSession {
    for (final session in sessions) {
      if (session.id == activeTicketId) return session;
    }
    return null;
  }

  SupportSession? get latestSession => sessions.isEmpty ? null : sessions.last;

  List<SupportMessage> get messages =>
      sessions.expand((session) => session.messages).toList()
        ..sort((a, b) => a.id.compareTo(b.id));

  factory SupportThread.fromJson(Map<String, dynamic> json) {
    final pagination = _map(json['message_pagination']);
    return SupportThread(
      id: parseInt(json['id']) ?? 0,
      uuid: parseString(json['uuid']) ?? '',
      activeTicketId: parseInt(json['active_ticket_id']),
      lastMessageAt: _date(json['last_message_at']),
      customer: SupportCustomer.fromJson(_map(json['customer'])),
      sessions: _maps(json['sessions']).map(SupportSession.fromJson).toList(),
      hasMoreMessages: parseBool(pagination['has_more']) ?? false,
      oldestMessageId: parseInt(pagination['oldest_message_id']),
    );
  }

}

class SupportRealtimeConfig {
  const SupportRealtimeConfig({
    required this.driver,
    required this.port,
    required this.scheme,
    required this.cluster,
    required this.authEndpoint,
    this.key,
    this.host,
  });

  final String driver;
  final String? key;
  final String? host;
  final int port;
  final String scheme;
  final String cluster;
  final String authEndpoint;

  bool get isConfigured =>
      key?.isNotEmpty == true &&
      authEndpoint.isNotEmpty &&
      (driver == 'pusher' ? cluster.isNotEmpty : host?.isNotEmpty == true);

  factory SupportRealtimeConfig.fromJson(Map<String, dynamic> json) {
    var authEndpoint = json['auth_endpoint']?.toString() ?? '';
    if (authEndpoint.isNotEmpty &&
        !authEndpoint.startsWith('http://') &&
        !authEndpoint.startsWith('https://')) {
      final base = AppConstant.baseUrl.endsWith('/')
          ? AppConstant.baseUrl.substring(0, AppConstant.baseUrl.length - 1)
          : AppConstant.baseUrl;
      final cleanAuth = authEndpoint.startsWith('/')
          ? authEndpoint.substring(1)
          : authEndpoint;
      authEndpoint = '$base/$cleanAuth';
    }
    final config = SupportRealtimeConfig(
      driver: json['driver']?.toString() ?? 'reverb',
      key: json['key']?.toString(),
      host: json['host']?.toString(),
      port: _int(json['port'], 443),
      scheme: json['scheme']?.toString() ?? 'https',
      cluster: json['cluster']?.toString() ?? 'mt1',
      authEndpoint: authEndpoint,
    );

    if (kDebugMode) {
      debugPrint('[SupportRealtimeConfig] ----------------------------------------');
      debugPrint('[SupportRealtimeConfig] API baseUrl: "${AppConstant.baseUrl}"');
      debugPrint('[SupportRealtimeConfig] Raw Realtime JSON payload from API: $json');
      debugPrint('[SupportRealtimeConfig] Parsed Realtime Fields:');
      debugPrint('[SupportRealtimeConfig]   - driver:       "${config.driver}"');
      debugPrint('[SupportRealtimeConfig]   - key:          "${config.key}"');
      debugPrint('[SupportRealtimeConfig]   - host:         "${config.host}"');
      debugPrint('[SupportRealtimeConfig]   - port:         ${config.port}');
      debugPrint('[SupportRealtimeConfig]   - scheme:       "${config.scheme}"');
      debugPrint('[SupportRealtimeConfig]   - cluster:      "${config.cluster}"');
      debugPrint('[SupportRealtimeConfig]   - authEndpoint: "${config.authEndpoint}"');
      debugPrint('[SupportRealtimeConfig]   - isConfigured: ${config.isConfigured}');
      if (!config.isConfigured) {
        if (config.key == null || config.key!.isEmpty) {
          debugPrint('[SupportRealtimeConfig] ⚠️ "key" field is missing or empty in API response!');
        }
        if (config.authEndpoint.isEmpty) {
          debugPrint('[SupportRealtimeConfig] ⚠️ "authEndpoint" field is missing or empty in API response!');
        }
        if (config.driver == 'pusher' && config.cluster.isEmpty) {
          debugPrint('[SupportRealtimeConfig] ⚠️ driver is "pusher" but "cluster" is empty!');
        }
        if (config.driver != 'pusher' && (config.host == null || config.host!.isEmpty)) {
          debugPrint('[SupportRealtimeConfig] ⚠️ driver is "${config.driver}" but "host" is missing/empty!');
        }
      }
      debugPrint('[SupportRealtimeConfig] ----------------------------------------');
    }

    return config;
  }

}

class SupportThreadPayload {
  const SupportThreadPayload({
    required this.thread,
    required this.recentOrders,
    required this.pollIntervalMs,
    required this.pollingEnabled,
    required this.realtime,
  });

  final SupportThread thread;
  final List<SupportOrder> recentOrders;
  final int pollIntervalMs;
  final bool pollingEnabled;
  final SupportRealtimeConfig realtime;

  factory SupportThreadPayload.fromJson(Map<String, dynamic> json) =>
      SupportThreadPayload(
        thread: SupportThread.fromJson(_map(json['thread'])),
        recentOrders:
            _maps(json['recent_orders']).map(SupportOrder.fromJson).toList(),
        pollIntervalMs: parseInt(json['poll_interval_ms']) ?? 15000,
        pollingEnabled: parseBool(json['polling_enabled']) ?? true,
        realtime: SupportRealtimeConfig.fromJson(_map(json['realtime'])),
      );

}



class SupportMessagePage {
  const SupportMessagePage({
    required this.messages,
    required this.hasMore,
    this.oldestMessageId,
  });

  final List<SupportMessage> messages;
  final bool hasMore;
  final int? oldestMessageId;

  factory SupportMessagePage.fromJson(Map<String, dynamic> json) =>
      SupportMessagePage(
        messages: _maps(json['messages']).map(SupportMessage.fromJson).toList(),
        hasMore: parseBool(json['has_more']) ?? false,
        oldestMessageId: parseInt(json['oldest_message_id']),
      );

}

class SupportLocalAttachment {
  const SupportLocalAttachment({
    required this.path,
    required this.name,
    required this.size,
    required this.mimeType,
    this.temporary = false,
  });

  final String path;
  final String name;
  final int size;
  final String mimeType;

  final bool temporary;

  File get file => File(path);
  bool get isImage {
    if (mimeType.toLowerCase().startsWith('image/')) return true;
    final ext = (name.isNotEmpty ? name : path).toLowerCase();
    return ext.endsWith('.jpg') ||
        ext.endsWith('.jpeg') ||
        ext.endsWith('.png') ||
        ext.endsWith('.gif') ||
        ext.endsWith('.webp') ||
        ext.endsWith('.bmp') ||
        ext.endsWith('.heic') ||
        ext.endsWith('.heif');
  }

  bool get isPdf {
    if (mimeType.toLowerCase() == 'application/pdf') return true;
    final ext = (name.isNotEmpty ? name : path).toLowerCase();
    return ext.endsWith('.pdf');
  }
}

