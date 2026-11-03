import '../../../config/helper.dart';

Map<String, dynamic> sharedCartMap(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

List<Map<String, dynamic>> sharedCartMaps(dynamic value) => value is List
    ? value.whereType<Map>().map(sharedCartMap).toList()
    : <Map<String, dynamic>>[];

enum SharedCartAction { merge, replace }

class CartShareLink {
  final String code;
  final String url;
  final String? title;
  final int itemsCount;
  final DateTime? expiresAt;

  const CartShareLink(
      {required this.code,
      required this.url,
      this.title,
      required this.itemsCount,
      this.expiresAt});

  factory CartShareLink.fromJson(Map<String, dynamic> json) {
    final url = parseString(json['share_url']) ?? '';
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw const FormatException(
          'The server returned an invalid sharing link.');
    }
    return CartShareLink(
      code: parseString(json['share_code']) ?? '',
      url: url,
      title: parseString(json['title']),
      itemsCount: parseInt(json['items_count']) ?? 0,
      expiresAt: DateTime.tryParse(parseString(json['expires_at']) ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
        'share_code': code,
        'share_url': url,
        'title': title,
        'items_count': itemsCount,
        'expires_at': expiresAt?.toIso8601String(),
      };
}

class SharedCartItem {
  final Map<String, dynamic> json;
  const SharedCartItem(this.json);

  Map<String, dynamic> get product => sharedCartMap(json['product']);
  Map<String, dynamic> get variant => sharedCartMap(json['variant']);
  int get productId => parseInt(json['product_id'] ?? product['id']) ?? 0;
  int get variantId =>
      parseInt(json['product_variant_id'] ?? variant['id']) ?? 0;
  int get storeId => parseInt(json['store_id']) ?? 0;
  int get quantity =>
      parseInt(json['shared_quantity'] ?? json['quantity']) ?? 1;
  String get name =>
      parseString(json['product_name'] ?? product['name'] ?? json['name']) ??
      '';
  String get image =>
      parseString(json['product_image'] ??
          json['image'] ??
          product['image'] ??
          variant['image']) ??
      '';
  String get variantName =>
      parseString(
          json['variant_title'] ?? json['variant_name'] ?? variant['title']) ??
      '';
  String? get reason =>
      parseString(json['reason'] ?? json['unavailable_reason']);
  bool get available =>
      parseBool(json['is_available']) != false &&
      parseBool(json['is_out_of_stock']) != true;
  bool get deliverable => parseBool(json['is_deliverable']) != false;
  bool get storeOnline =>
      parseBool(json['is_store_online']) != false &&
      parseBool(json['store_is_accepting_orders']) != false;
  double? get unitPrice => parseDouble(json['effective_unit_price'] ??
      json['special_price'] ??
      variant['special_price'] ??
      json['unit_price'] ??
      variant['price']);
  double? get originalPrice =>
      parseDouble(json['unit_price'] ?? variant['price']);
  String? get currencyCode => parseString(json['currency_code'] ?? product['currency_code']);
  String? get formattedUnitPrice => parseString(json['formatted_effective_unit_price'] ?? json['formatted_unit_price'] ?? json['formatted_price']);
  List<Map<String, dynamic>> get addons => sharedCartMaps(json['addons']);

  factory SharedCartItem.fromJson(Map<String, dynamic> json) =>
      SharedCartItem(json);
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(json);
}

class SharedCartPreview {
  final String? title;
  final List<SharedCartItem> items;
  final bool isExpired;
  const SharedCartPreview(
      {this.title, required this.items, this.isExpired = false});

  // Preview parsing is kept separate from the active-cart model: a shared
  // snapshot may include products that cannot be delivered to the recipient.
  factory SharedCartPreview.fromJson(Map<String, dynamic> json) {
    final cart = json['cart'] is Map ? sharedCartMap(json['cart']) : json;
    final rawItems = sharedCartMaps(cart['items']);
    if (rawItems.isEmpty) {
      for (final store in sharedCartMaps(cart['stores'])) {
        rawItems.addAll(sharedCartMaps(store['items']).map((item) => {
              ...item,
              'store_id': item['store_id'] ?? store['store_id'] ?? store['id'],
            }));
      }
    }
    if (!cart.containsKey('items') && !cart.containsKey('stores')) {
      throw const FormatException('Unable to read the shared cart preview.');
    }
    return SharedCartPreview(
      title: parseString(json['title']),
      isExpired: parseBool(json['is_expired']) ?? false,
      items: rawItems.map(SharedCartItem.fromJson).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'is_expired': isExpired,
        'items': items.map((item) => item.toJson()).toList(),
      };
}

class SharedCartImport {
  final String message;
  final List<Map<String, dynamic>> cartItems;
  final int skippedCount;
  final List<SharedCartItem> skippedItems;

  const SharedCartImport(
      {required this.message,
      required this.cartItems,
      required this.skippedCount,
      required this.skippedItems});

  factory SharedCartImport.fromJson(Map<String, dynamic> response) {
    final data = sharedCartMap(response['data']);
    final cart = sharedCartMap(data['cart']);
    if (!cart.containsKey('items') && !cart.containsKey('stores')) {
      throw const FormatException(
          'The import response is missing the updated cart.');
    }
    final items = sharedCartMaps(cart['items']);
    if (items.isEmpty) {
      for (final store in sharedCartMaps(cart['stores'])) {
        items.addAll(sharedCartMaps(store['items']).map((item) => {
              ...item,
              'store_id': item['store_id'] ?? store['store_id'],
            }));
      }
    }
    final summary = sharedCartMap(data['import_summary']);
    return SharedCartImport(
      message: parseString(response['message']) ?? '',
      cartItems: items,
      skippedCount: parseInt(summary['skipped_count']) ?? 0,
      skippedItems: sharedCartMaps(summary['skipped_items'])
          .map(SharedCartItem.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'message': message,
        'cart_items': cartItems,
        'skipped_count': skippedCount,
        'skipped_items': skippedItems.map((item) => item.toJson()).toList(),
      };
}
