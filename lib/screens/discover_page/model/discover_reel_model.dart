import 'package:hyper_local/config/helper.dart';
import 'discover_profile_status_model.dart';
import 'discover_status_model.dart';

class DiscoverReelResponse {
  final bool? success;
  final String? message;
  final DiscoverReelData? data;

  DiscoverReelResponse({
    this.success,
    this.message,
    this.data,
  });

  factory DiscoverReelResponse.fromJson(Map<String, dynamic> json) {
    return DiscoverReelResponse(
      success: parseBool(json['success']),
      message: parseString(json['message']),
      data: json['data'] != null ? DiscoverReelData.fromJson(json['data']) : null,
    );
  }
}

class DiscoverReelData {
  final List<DiscoverReelItem> items;

  DiscoverReelData({
    this.items = const [],
  });

  factory DiscoverReelData.fromJson(Map<String, dynamic> json) {
    return DiscoverReelData(
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => DiscoverReelItem.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class DiscoverReelItem {
  final int? id;
  final String? uuid;
  final String? slug;
  final String? caption;
  final String? source;
  final String? videoUrl;
  final String? coverUrl;
  final int? videoWidth;
  final int? videoHeight;
  final int? durationMs;
  final int? likeCount;
  final bool? likedByMe;
  final int? effectivePrimaryVariantId;
  final DiscoverProfile? profile;
  final List<DiscoverProfileProduct> products;
  final String? publishedAt;

  DiscoverReelItem({
    this.id,
    this.uuid,
    this.slug,
    this.caption,
    this.source,
    this.videoUrl,
    this.coverUrl,
    this.videoWidth,
    this.videoHeight,
    this.durationMs,
    this.likeCount,
    this.likedByMe,
    this.effectivePrimaryVariantId,
    this.profile,
    this.products = const [],
    this.publishedAt,
  });

  factory DiscoverReelItem.fromJson(Map<String, dynamic> json) {
    return DiscoverReelItem(
      id: parseInt(json['id']),
      uuid: parseString(json['uuid']),
      slug: parseString(json['slug']),
      caption: parseString(json['caption']),
      source: parseString(json['source']),
      videoUrl: parseString(json['video_url']),
      coverUrl: parseString(json['cover_url']),
      videoWidth: parseInt(json['video_width']),
      videoHeight: parseInt(json['video_height']),
      durationMs: parseInt(json['duration_ms']),
      likeCount: parseInt(json['like_count']),
      likedByMe: parseBool(json['liked_by_me']),
      effectivePrimaryVariantId: parseInt(json['effective_primary_variant_id']),
      profile: json['profile'] != null ? DiscoverProfile.fromJson(json['profile']) : null,
      products: (json['products'] as List<dynamic>?)
              ?.map((p) => DiscoverProfileProduct.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      publishedAt: parseString(json['published_at']),
    );
  }

  DiscoverReelItem copyWith({
    int? id,
    String? uuid,
    String? slug,
    String? caption,
    String? source,
    String? videoUrl,
    String? coverUrl,
    int? videoWidth,
    int? videoHeight,
    int? durationMs,
    int? likeCount,
    bool? likedByMe,
    int? effectivePrimaryVariantId,
    DiscoverProfile? profile,
    List<DiscoverProfileProduct>? products,
    String? publishedAt,
  }) {
    return DiscoverReelItem(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      slug: slug ?? this.slug,
      caption: caption ?? this.caption,
      source: source ?? this.source,
      videoUrl: videoUrl ?? this.videoUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      videoWidth: videoWidth ?? this.videoWidth,
      videoHeight: videoHeight ?? this.videoHeight,
      durationMs: durationMs ?? this.durationMs,
      likeCount: likeCount ?? this.likeCount,
      likedByMe: likedByMe ?? this.likedByMe,
      effectivePrimaryVariantId: effectivePrimaryVariantId ?? this.effectivePrimaryVariantId,
      profile: profile ?? this.profile,
      products: products ?? this.products,
      publishedAt: publishedAt ?? this.publishedAt,
    );
  }
}
