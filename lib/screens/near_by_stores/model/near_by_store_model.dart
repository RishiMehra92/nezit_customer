import 'dart:convert';
import 'dart:developer';
import '../../../config/helper.dart';

class NearbyStoresModel {
  final bool? success;
  final String? message;
  final NearbyStoresPageData? data;

  NearbyStoresModel({
    this.success,
    this.message,
    this.data,
  });

  factory NearbyStoresModel.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('current_page') && json['data'] is List) {
      return NearbyStoresModel(
        success: true,
        message: 'Success',
        data: NearbyStoresPageData.fromJson(json),
      );
    }
    return NearbyStoresModel(
      success: parseBool(json['success']),
      message: parseString(json['message']),
      data: json['data'] != null
          ? NearbyStoresPageData.fromJson(json['data'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        if (data != null) 'data': data!.toJson(),
      };
}

class NearbyStoresPageData {
  final int? currentPage;
  final List<StoreData> stores;
  final String? firstPageUrl;
  final int? from;
  final int? lastPage;
  final String? lastPageUrl;
  final List<PaginationLink> links;
  final String? nextPageUrl;
  final String? path;
  final int? perPage;
  final String? prevPageUrl;
  final int? to;
  final int? total;

  NearbyStoresPageData({
    this.currentPage,
    this.stores = const [],
    this.firstPageUrl,
    this.from,
    this.lastPage,
    this.lastPageUrl,
    this.links = const [],
    this.nextPageUrl,
    this.path,
    this.perPage,
    this.prevPageUrl,
    this.to,
    this.total,
  });

  NearbyStoresPageData copyWith({
    int? currentPage,
    List<StoreData>? stores,
    String? firstPageUrl,
    int? from,
    int? lastPage,
    String? lastPageUrl,
    List<PaginationLink>? links,
    String? nextPageUrl,
    String? path,
    int? perPage,
    String? prevPageUrl,
    int? to,
    int? total,
  }) {
    return NearbyStoresPageData(
      currentPage: currentPage ?? this.currentPage,
      stores: stores ?? this.stores,
      firstPageUrl: firstPageUrl ?? this.firstPageUrl,
      from: from ?? this.from,
      lastPage: lastPage ?? this.lastPage,
      lastPageUrl: lastPageUrl ?? this.lastPageUrl,
      links: links ?? this.links,
      nextPageUrl: nextPageUrl ?? this.nextPageUrl,
      path: path ?? this.path,
      perPage: perPage ?? this.perPage,
      prevPageUrl: prevPageUrl ?? this.prevPageUrl,
      to: to ?? this.to,
      total: total ?? this.total,
    );
  }

  factory NearbyStoresPageData.fromJson(Map<String, dynamic> json) {
    return NearbyStoresPageData(
      currentPage: parseInt(json['current_page']),
      stores: _parseStores(json['data']),
      firstPageUrl: parseString(json['first_page_url']),
      from: parseInt(json['from']),
      lastPage: parseInt(json['last_page']),
      lastPageUrl: parseString(json['last_page_url']),
      links: _parseLinks(json['links']),
      nextPageUrl: parseString(json['next_page_url']),
      path: parseString(json['path']),
      perPage: parseInt(json['per_page']),
      prevPageUrl: parseString(json['prev_page_url']),
      to: parseInt(json['to']),
      total: parseInt(json['total']),
    );
  }

  Map<String, dynamic> toJson() => {
        'current_page': currentPage,
        'data': stores.map((e) => e.toJson()).toList(),
        'first_page_url': firstPageUrl,
        'from': from,
        'last_page': lastPage,
        'last_page_url': lastPageUrl,
        'links': links.map((e) => e.toJson()).toList(),
        'next_page_url': nextPageUrl,
        'path': path,
        'per_page': perPage,
        'prev_page_url': prevPageUrl,
        'to': to,
        'total': total,
      };

  static List<StoreData> _parseStores(dynamic value) {
    if (value is! Iterable) return const [];
    return value
        .whereType<Map<String, dynamic>>()
        .map(StoreData.fromJson)
        .toList();
  }

  static List<PaginationLink> _parseLinks(dynamic value) {
    if (value is! Iterable) return const [];
    return value
        .whereType<Map<String, dynamic>>()
        .map(PaginationLink.fromJson)
        .toList();
  }
}

class StoreData {
  final int? id;
  final String? name;
  final String? slug;
  final int? productCount;
  final String? description;
  final String? contactNumber;
  final String? contactEmail;
  final String? address;
  final String? latitude;
  final String? longitude;
  final double? distance;
  final String? timing;
  final String? logo;
  final String? banner;
  final bool? sameLocation;
  final String? createdAt;
  final String? updatedAt;
  final String? verificationStatus;
  final String? visibilityStatus;
  final StoreStatus? status;
  final String? avgProductsRating;
  final String? avgStoreRating;
  final int? totalStoreFeedback;
  final bool? isRecommended;
  final OperatingHours? operatingHours;
  final bool? isNotify;

  StoreData({
    this.id,
    this.name,
    this.slug,
    this.productCount,
    this.description,
    this.contactNumber,
    this.contactEmail,
    this.address,
    this.latitude,
    this.longitude,
    this.distance,
    this.timing,
    this.logo,
    this.banner,
    this.sameLocation,
    this.createdAt,
    this.updatedAt,
    this.verificationStatus,
    this.visibilityStatus,
    this.status,
    this.avgProductsRating,
    this.avgStoreRating,
    this.totalStoreFeedback,
    this.isRecommended,
    this.operatingHours,
    this.isNotify,
  });

  factory StoreData.fromJson(Map<String, dynamic> json) {
    return StoreData(
      id: parseInt(json['id']),
      name: parseString(json['name']),
      slug: parseString(json['slug']),
      productCount: parseInt(json['product_count']),
      description: parseString(json['description']),
      contactNumber: parseString(json['contact_number']),
      contactEmail: parseString(json['contact_email']),
      address: parseString(json['address']),
      latitude: parseString(json['latitude']),
      longitude: parseString(json['longitude']),
      distance: parseDouble(json['distance']),
      timing: parseString(json['timing']),
      logo: parseString(json['logo']),
      banner: parseString(json['banner']),
      sameLocation: parseBool(json['same_location']),
      createdAt: parseString(json['created_at']),
      updatedAt: parseString(json['updated_at']),
      verificationStatus: parseString(json['verification_status']),
      visibilityStatus: parseString(json['visibility_status']),
      status: json['status'] != null
          ? StoreStatus.fromJson(jsonParser(json['status']))
          : null,
      avgProductsRating: parseString(json['avg_products_rating']),
      avgStoreRating: parseString(json['avg_store_rating']),
      totalStoreFeedback: parseInt(json['total_store_feedback']),
      isRecommended: parseBool(json['is_recommended']),
      operatingHours: _parseOperatingHours(json),
      isNotify: parseBool(json['is_notify']),
    );
  }

  static dynamic jsonParser(dynamic value) {
    if (value is String) {
      try {
        return jsonDecode(value);
      } catch (e) {
        return null;
      }
    }
    return value;
  }

  static OperatingHours? _parseOperatingHours(Map<String, dynamic> json) {
    try {
      dynamic metadata = jsonParser(json['metadata']);
      dynamic opHours;
      if (metadata != null && metadata['operating_hours'] != null) {
        opHours = jsonParser(metadata['operating_hours']);
      } else if (json['operating_hours'] != null) {
        opHours = jsonParser(json['operating_hours']);
      }

      if (opHours == null) {
        log('No operating_hours found for store: ${json['name']} (ID: ${json['id']})');
        return null;
      }

      Map<String, dynamic> hoursMap = {};
      if (opHours is List) {
        log('operating_hours is a List for store: ${json['name']} (ID: ${json['id']})');
        for (var item in opHours) {
          if (item is Map && item['day'] != null) {
            String day = item['day'].toString().toLowerCase();
            hoursMap[day] = item;
          }
        }
      } else if (opHours is Map) {
        log('operating_hours is a Map for store: ${json['name']} (ID: ${json['id']})');
        hoursMap = Map<String, dynamic>.from(opHours);
      } else {
        log('operating_hours is unknown format ${opHours.runtimeType} for store: ${json['name']} (ID: ${json['id']})');
        return null;
      }

      return OperatingHours.fromJson(hoursMap);
    } catch (e, stacktrace) {
      log('Error parsing operating hours for store ID: ${json['id']} - Error: $e\n$stacktrace');
      return null;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'product_count': productCount,
        'description': description,
        'contact_number': contactNumber,
        'contact_email': contactEmail,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'distance': distance,
        'timing': timing,
        'logo': logo,
        'banner': banner,
        'same_location': sameLocation,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'verification_status': verificationStatus,
        'visibility_status': visibilityStatus,
        if (status != null) 'status': status!.toJson(),
        'avg_products_rating': avgProductsRating,
        'avg_store_rating': avgStoreRating,
        'total_store_feedback': totalStoreFeedback,
        'is_recommended': isRecommended,
        if (operatingHours != null) 'operating_hours': operatingHours!.toJson(),
        if (isNotify != null) 'is_notify': isNotify,
      };

  StoreData copyWith({
    int? id,
    String? name,
    String? slug,
    int? productCount,
    String? description,
    String? contactNumber,
    String? contactEmail,
    String? address,
    String? latitude,
    String? longitude,
    double? distance,
    String? timing,
    String? logo,
    String? banner,
    bool? sameLocation,
    String? createdAt,
    String? updatedAt,
    String? verificationStatus,
    String? visibilityStatus,
    StoreStatus? status,
    String? avgProductsRating,
    String? avgStoreRating,
    int? totalStoreFeedback,
    bool? isRecommended,
    OperatingHours? operatingHours,
    bool? isNotify,
  }) {
    return StoreData(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      productCount: productCount ?? this.productCount,
      description: description ?? this.description,
      contactNumber: contactNumber ?? this.contactNumber,
      contactEmail: contactEmail ?? this.contactEmail,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      distance: distance ?? this.distance,
      timing: timing ?? this.timing,
      logo: logo ?? this.logo,
      banner: banner ?? this.banner,
      sameLocation: sameLocation ?? this.sameLocation,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      visibilityStatus: visibilityStatus ?? this.visibilityStatus,
      status: status ?? this.status,
      avgProductsRating: avgProductsRating ?? this.avgProductsRating,
      avgStoreRating: avgStoreRating ?? this.avgStoreRating,
      totalStoreFeedback: totalStoreFeedback ?? this.totalStoreFeedback,
      isRecommended: isRecommended ?? this.isRecommended,
      operatingHours: operatingHours ?? this.operatingHours,
      isNotify: isNotify ?? this.isNotify,
    );
  }
}

class StoreStatus {
  final bool? isOpen;
  final String? status;

  StoreStatus({
    this.isOpen,
    this.status,
  });

  factory StoreStatus.fromJson(Map<String, dynamic> json) {
    return StoreStatus(
      isOpen: parseBool(json['is_open']),
      status: parseString(json['status']),
    );
  }

  Map<String, dynamic> toJson() => {
        'is_open': isOpen,
        'status': status,
      };
}

class PaginationLink {
  final String? url;
  final String? label;
  final bool? active;

  PaginationLink({
    this.url,
    this.label,
    this.active,
  });

  factory PaginationLink.fromJson(Map<String, dynamic> json) {
    return PaginationLink(
      url: parseString(json['url']),
      label: parseString(json['label']),
      active: parseBool(json['active']),
    );
  }

  Map<String, dynamic> toJson() => {
        'url': url,
        'label': label,
        'active': active,
      };
}

class OperatingHours {
  final DayOperatingHours? monday;
  final DayOperatingHours? tuesday;
  final DayOperatingHours? wednesday;
  final DayOperatingHours? thursday;
  final DayOperatingHours? friday;
  final DayOperatingHours? saturday;
  final DayOperatingHours? sunday;

  OperatingHours({
    this.monday,
    this.tuesday,
    this.wednesday,
    this.thursday,
    this.friday,
    this.saturday,
    this.sunday,
  });

  factory OperatingHours.fromJson(Map<String, dynamic> json) {
    return OperatingHours(
      monday: json['monday'] != null
          ? DayOperatingHours.fromJson(json['monday'])
          : null,
      tuesday: json['tuesday'] != null
          ? DayOperatingHours.fromJson(json['tuesday'])
          : null,
      wednesday: json['wednesday'] != null
          ? DayOperatingHours.fromJson(json['wednesday'])
          : null,
      thursday: json['thursday'] != null
          ? DayOperatingHours.fromJson(json['thursday'])
          : null,
      friday: json['friday'] != null
          ? DayOperatingHours.fromJson(json['friday'])
          : null,
      saturday: json['saturday'] != null
          ? DayOperatingHours.fromJson(json['saturday'])
          : null,
      sunday: json['sunday'] != null
          ? DayOperatingHours.fromJson(json['sunday'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        if (monday != null) 'monday': monday!.toJson(),
        if (tuesday != null) 'tuesday': tuesday!.toJson(),
        if (wednesday != null) 'wednesday': wednesday!.toJson(),
        if (thursday != null) 'thursday': thursday!.toJson(),
        if (friday != null) 'friday': friday!.toJson(),
        if (saturday != null) 'saturday': saturday!.toJson(),
        if (sunday != null) 'sunday': sunday!.toJson(),
      };
}

class DayOperatingHours {
  final bool? isOpen;
  final String? openTime;
  final String? closeTime;
  final bool? hasBreak;
  final String? breakStartTime;
  final String? breakEndTime;

  DayOperatingHours({
    this.isOpen,
    this.openTime,
    this.closeTime,
    this.hasBreak,
    this.breakStartTime,
    this.breakEndTime,
  });

  factory DayOperatingHours.fromJson(Map<String, dynamic> json) {
    return DayOperatingHours(
      isOpen: json['is_open'] == "1" ||
          json['is_open'] == 1 ||
          json['is_open'] == true,
      openTime: json['open_time']?.toString(),
      closeTime: json['close_time']?.toString(),
      hasBreak: json['has_break'] == "1" ||
          json['has_break'] == 1 ||
          json['has_break'] == true,
      breakStartTime: json['break_start_time']?.toString(),
      breakEndTime: json['break_end_time']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'is_open': isOpen,
        'open_time': openTime,
        'close_time': closeTime,
        'has_break': hasBreak,
        'break_start_time': breakStartTime,
        'break_end_time': breakEndTime,
      };
}
