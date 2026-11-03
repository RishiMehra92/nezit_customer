import 'package:hyper_local/config/helper.dart';

class DiscoverStatusResponse {
  final bool? success;
  final String? message;
  final DiscoverStatusData? data;

  DiscoverStatusResponse({
    this.success,
    this.message,
    this.data,
  });

  factory DiscoverStatusResponse.fromJson(Map<String, dynamic> json) {
    return DiscoverStatusResponse(
      success: parseBool(json['success']),
      message: parseString(json['message']),
      data: json['data'] != null ? DiscoverStatusData.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        if (data != null) 'data': data!.toJson(),
      };
}

class DiscoverStatusData {
  final List<DiscoverStatusItem> items;
  final DiscoverStatusMeta? meta;

  DiscoverStatusData({
    this.items = const [],
    this.meta,
  });

  factory DiscoverStatusData.fromJson(Map<String, dynamic> json) {
    return DiscoverStatusData(
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => DiscoverStatusItem.fromJson(item))
              .toList() ??
          [],
      meta: json['meta'] != null ? DiscoverStatusMeta.fromJson(json['meta']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'items': items.map((e) => e.toJson()).toList(),
        if (meta != null) 'meta': meta!.toJson(),
      };
}

class DiscoverStatusItem {
  final DiscoverProfile? profile;
  final int? statusCount;

  DiscoverStatusItem({
    this.profile,
    this.statusCount,
  });

  factory DiscoverStatusItem.fromJson(Map<String, dynamic> json) {
    return DiscoverStatusItem(
      profile: json['profile'] != null ? DiscoverProfile.fromJson(json['profile']) : null,
      statusCount: parseInt(json['status_count']),
    );
  }

  Map<String, dynamic> toJson() => {
        if (profile != null) 'profile': profile!.toJson(),
        'status_count': statusCount,
      };
}

class DiscoverProfile {
  final int? id;
  final String? type;
  final String? username;
  final String? bio;
  final String? photoUrl;
  final String? status;
  final bool? hasActiveStatus;
  final bool? hasUnseenStatus;

  DiscoverProfile({
    this.id,
    this.type,
    this.username,
    this.bio,
    this.photoUrl,
    this.status,
    this.hasActiveStatus,
    this.hasUnseenStatus,
  });

  factory DiscoverProfile.fromJson(Map<String, dynamic> json) {
    return DiscoverProfile(
      id: parseInt(json['id']),
      type: parseString(json['type']),
      username: parseString(json['username']),
      bio: parseString(json['bio']),
      photoUrl: parseString(json['photo_url']),
      status: parseString(json['status']),
      hasActiveStatus: parseBool(json['has_active_status']),
      hasUnseenStatus: parseBool(json['has_unseen_status']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'username': username,
        'bio': bio,
        'photo_url': photoUrl,
        'status': status,
        'has_active_status': hasActiveStatus,
        'has_unseen_status': hasUnseenStatus,
      };
}

class DiscoverStatusMeta {
  final String? sessionId;
  final String? nextCursor;
  final int? perPage;

  DiscoverStatusMeta({
    this.sessionId,
    this.nextCursor,
    this.perPage,
  });

  factory DiscoverStatusMeta.fromJson(Map<String, dynamic> json) {
    return DiscoverStatusMeta(
      sessionId: parseString(json['session_id']),
      nextCursor: parseString(json['next_cursor']),
      perPage: parseInt(json['per_page']),
    );
  }

  Map<String, dynamic> toJson() => {
        'session_id': sessionId,
        'next_cursor': nextCursor,
        'per_page': perPage,
      };
}
