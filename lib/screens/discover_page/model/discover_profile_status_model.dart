import 'package:hyper_local/config/helper.dart';
import 'discover_status_model.dart';

class DiscoverProfileStatusResponse {
  final bool? success;
  final String? message;
  final DiscoverProfileStatusData? data;

  DiscoverProfileStatusResponse({
    this.success,
    this.message,
    this.data,
  });

  factory DiscoverProfileStatusResponse.fromJson(Map<String, dynamic> json) {
    return DiscoverProfileStatusResponse(
      success: parseBool(json['success']),
      message: parseString(json['message']),
      data: json['data'] != null ? DiscoverProfileStatusData.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        if (data != null) 'data': data!.toJson(),
      };
}

class DiscoverProfileStatusData {
  final DiscoverProfile? profile;
  final List<DiscoverProfileStatusItem> items;
  final DiscoverProfileStatusPagination? pagination;

  DiscoverProfileStatusData({
    this.profile,
    this.items = const [],
    this.pagination,
  });

  factory DiscoverProfileStatusData.fromJson(Map<String, dynamic> json) {
    return DiscoverProfileStatusData(
      profile: json['profile'] != null ? DiscoverProfile.fromJson(json['profile']) : null,
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => DiscoverProfileStatusItem.fromJson(item))
              .toList() ??
          [],
      pagination: json['pagination'] != null
          ? DiscoverProfileStatusPagination.fromJson(json['pagination'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        if (profile != null) 'profile': profile!.toJson(),
        'items': items.map((e) => e.toJson()).toList(),
        if (pagination != null) 'pagination': pagination!.toJson(),
      };
}

class DiscoverProfileStatusItem {
  final int? id;
  final String? uuid;
  final String? source;
  final String? contentType;
  final String? text;
  final String? mediaUrl;
  final int? mediaWidth;
  final int? mediaHeight;
  final int? durationMs;
  final bool? seenByMe;
  final List<DiscoverProfileProduct> products;
  final String? createdAt;
  final int? timeAgo;
  final String? expiresAt;

  DiscoverProfileStatusItem({
    this.id,
    this.uuid,
    this.source,
    this.contentType,
    this.text,
    this.mediaUrl,
    this.mediaWidth,
    this.mediaHeight,
    this.durationMs,
    this.seenByMe,
    this.products = const [],
    this.createdAt,
    this.timeAgo,
    this.expiresAt,
  });

  factory DiscoverProfileStatusItem.fromJson(Map<String, dynamic> json) {
    return DiscoverProfileStatusItem(
      id: parseInt(json['id']),
      uuid: parseString(json['uuid']),
      source: parseString(json['source']),
      contentType: parseString(json['content_type']),
      text: parseString(json['text']),
      mediaUrl: parseString(json['media_url']),
      mediaWidth: parseInt(json['media_width']),
      mediaHeight: parseInt(json['media_height']),
      durationMs: parseInt(json['duration_ms']),
      seenByMe: parseBool(json['seen_by_me']),
      products: (json['products'] as List<dynamic>?)
              ?.map((p) => DiscoverProfileProduct.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: parseString(json['created_at']),
      timeAgo: parseInt(json['time_ago']),
      expiresAt: parseString(json['expires_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'uuid': uuid,
        'source': source,
        'content_type': contentType,
        'text': text,
        'media_url': mediaUrl,
        'media_width': mediaWidth,
        'media_height': mediaHeight,
        'duration_ms': durationMs,
        'seen_by_me': seenByMe,
        'products': products.map((e) => e.toJson()).toList(),
        'created_at': createdAt,
        'time_ago': timeAgo,
        'expires_at': expiresAt,
      };
}

class DiscoverProfileStatusPagination {
  final bool? hasMorePages;
  final String? nextCursor;
  final String? previousCursor;
  final int? perPage;
  final int? total;

  DiscoverProfileStatusPagination({
    this.hasMorePages,
    this.nextCursor,
    this.previousCursor,
    this.perPage,
    this.total,
  });

  factory DiscoverProfileStatusPagination.fromJson(Map<String, dynamic> json) {
    return DiscoverProfileStatusPagination(
      hasMorePages: parseBool(json['has_more_pages']),
      nextCursor: parseString(json['next_cursor']),
      previousCursor: parseString(json['previous_cursor']),
      perPage: parseInt(json['per_page']),
      total: parseInt(json['total']),
    );
  }

  Map<String, dynamic> toJson() => {
        'has_more_pages': hasMorePages,
        'next_cursor': nextCursor,
        'previous_cursor': previousCursor,
        'per_page': perPage,
        'total': total,
      };
}

class DiscoverProfileProduct {
  final int? id;
  final DiscoverProfileProductDetails? product;
  final DiscoverProfileVariant? variant;
  final DiscoverProfileStore? store;

  DiscoverProfileProduct({
    this.id,
    this.product,
    this.variant,
    this.store,
  });

  factory DiscoverProfileProduct.fromJson(Map<String, dynamic> json) {
    return DiscoverProfileProduct(
      id: parseInt(json['id']),
      product: json['product'] != null ? DiscoverProfileProductDetails.fromJson(json['product']) : null,
      variant: json['variant'] != null ? DiscoverProfileVariant.fromJson(json['variant']) : null,
      store: json['store'] != null ? DiscoverProfileStore.fromJson(json['store']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        if (product != null) 'product': product!.toJson(),
        if (variant != null) 'variant': variant!.toJson(),
        if (store != null) 'store': store!.toJson(),
      };
}

class DiscoverProfileProductDetails {
  final int? id;
  final String? slug;
  final String? title;
  final String? imageUrl;

  DiscoverProfileProductDetails({this.id, this.slug, this.title, this.imageUrl});

  factory DiscoverProfileProductDetails.fromJson(Map<String, dynamic> json) {
    return DiscoverProfileProductDetails(
      id: parseInt(json['id']),
      slug: parseString(json['slug']),
      title: parseString(json['title']),
      imageUrl: parseString(json['image_url']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'slug': slug,
        'title': title,
        'image_url': imageUrl,
      };
}

class DiscoverProfileVariant {
  final int? id;
  final String? title;
  final String? sku;
  final num? price;
  final num? specialPrice;

  DiscoverProfileVariant({this.id, this.title, this.sku, this.price, this.specialPrice});

  factory DiscoverProfileVariant.fromJson(Map<String, dynamic> json) {
    return DiscoverProfileVariant(
      id: parseInt(json['id']),
      title: parseString(json['title']),
      sku: parseString(json['sku']),
      price: parseDouble(json['price']),
      specialPrice: parseDouble(json['special_price']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'sku': sku,
        'price': price,
        'special_price': specialPrice,
      };
}

class DiscoverProfileStore {
  final int? id;
  final String? slug;
  final String? name;

  DiscoverProfileStore({this.id, this.slug, this.name});

  factory DiscoverProfileStore.fromJson(Map<String, dynamic> json) {
    return DiscoverProfileStore(
      id: parseInt(json['id']),
      slug: parseString(json['slug']),
      name: parseString(json['name']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'slug': slug,
        'name': name,
      };
}
