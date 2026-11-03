import 'package:hyper_local/screens/cart_page/model/promo_code_model.dart';
import '../../../config/helper.dart'; // parseInt, parseString, parseBool, parseDouble

class CartModel {
  final bool? success;
  final String? message;
  final CartData? data;

  CartModel({
    this.success,
    this.message,
    this.data,
  });

  factory CartModel.fromJson(Map<String, dynamic> json) {
    return CartModel(
      success: parseBool(json['success']),
      message: parseString(json['message']),
      data: json['data'] != null && json['data'] is Map<String, dynamic>
          ? CartData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        if (data != null) 'data': data?.toJson(),
      };
}

class CartData {
  final int? id;
  final String? uuid;
  final int? userId;
  final int? itemsCount;
  final int? totalQuantity;
  final List<CartItem> items;
  final List<Store> stores;
  final PaymentSummary? paymentSummary;
  final List<RemovedItem> removedItems;
  final int? removedCount;
  final DeliveryZone? deliveryZone;
  final String? createdAt;
  final String? updatedAt;
  final bool? useLoyaltyPoints;
  final String? currencyCode;
  final List<String> currencyCodes;
  final String? currencyLabel;
  final List<AvailablePaymentMethod> availablePaymentMethods;

  bool get hasMixedCurrencies => currencyCodes.length > 1;
  bool get isCheckoutAllowed => currencyCodes.length == 1 && currencyCode != null && currencyCode!.isNotEmpty;

  CartData({
    this.id,
    this.uuid,
    this.userId,
    this.itemsCount,
    this.totalQuantity,
    this.items = const [],
    this.stores = const [],
    this.paymentSummary,
    this.removedItems = const [],
    this.removedCount,
    this.deliveryZone,
    this.createdAt,
    this.updatedAt,
    this.useLoyaltyPoints,
    this.currencyCode,
    this.currencyCodes = const [],
    this.currencyLabel,
    this.availablePaymentMethods = const [],
  });

  factory CartData.fromJson(Map<String, dynamic> json) {
    final rawCodes = json['currency_codes'];
    List<String> parsedCodes = [];
    if (rawCodes is Iterable) {
      parsedCodes = rawCodes.map((e) => e.toString()).toList();
    } else if (json['currency_code'] != null && json['currency_code'].toString().isNotEmpty) {
      parsedCodes = [json['currency_code'].toString()];
    }

    return CartData(
      id: parseInt(json['id']),
      uuid: parseString(json['uuid']),
      userId: parseInt(json['user_id']),
      itemsCount: parseInt(json['items_count']),
      totalQuantity: parseInt(json['total_quantity']),
      items: _parseCartItems(json['items']),
      stores: _parseStores(json['stores']),
      paymentSummary: json['payment_summary'] != null &&
              json['payment_summary'] is Map<String, dynamic>
          ? PaymentSummary.fromJson(json['payment_summary'])
          : null,
      removedItems: _parseRemovedItems(json['removed_items']),
      removedCount: parseInt(json['removed_count']),
      deliveryZone: json['delivery_zone'] != null
          ? DeliveryZone.fromJson(json['delivery_zone'])
          : null,
      createdAt: parseString(json['created_at']),
      updatedAt: parseString(json['updated_at']),
      useLoyaltyPoints: parseBool(json['use_loyalty_points']),
      currencyCode: parseString(json['currency_code']),
      currencyCodes: parsedCodes,
      currencyLabel: parseString(json['currency_label']),
      availablePaymentMethods: _parseAvailablePaymentMethods(json['available_payment_methods']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'uuid': uuid,
        'user_id': userId,
        'items_count': itemsCount,
        'total_quantity': totalQuantity,
        'items': items.map((e) => e.toJson()).toList(),
        'stores': stores.map((e) => e.toJson()).toList(),
        if (paymentSummary != null) 'payment_summary': paymentSummary?.toJson(),
        'removed_items': removedItems.map((e) => e.toJson()).toList(),
        'removed_count': removedCount,
        if (deliveryZone != null) 'delivery_zone': deliveryZone?.toJson(),
        'created_at': createdAt,
        'updated_at': updatedAt,
        'use_loyalty_points': useLoyaltyPoints,
        'currency_code': currencyCode,
        'currency_codes': currencyCodes,
        'currency_label': currencyLabel,
        'available_payment_methods': availablePaymentMethods.map((e) => e.toJson()).toList(),
      };

  static List<CartItem> _parseCartItems(dynamic value) {
    if (value is! Iterable) return const [];
    return value
        .whereType<Map<String, dynamic>>()
        .map(CartItem.fromJson)
        .toList();
  }

  static List<Store> _parseStores(dynamic value) {
    if (value is! Iterable) return const [];
    return value.whereType<Map<String, dynamic>>().map(Store.fromJson).toList();
  }

  static List<RemovedItem> _parseRemovedItems(dynamic value) {
    if (value is! Iterable) return const [];
    return value
        .whereType<Map<String, dynamic>>()
        .map(RemovedItem.fromJson)
        .toList();
  }

  static List<AvailablePaymentMethod> _parseAvailablePaymentMethods(dynamic value) {
    if (value is! Iterable) return const [];
    return value
        .whereType<Map<String, dynamic>>()
        .map(AvailablePaymentMethod.fromJson)
        .toList();
  }
}

class AvailablePaymentMethod {
  final String key;
  final String name;
  final String label;
  final String mode;
  final bool isEnabled;
  final String? configuredCurrency;
  final List<String> allowedCurrencies;
  final bool requiresAccountApproval;
  final String? currencyCode;
  final bool isAvailable;
  final String? reasonCode;
  final String? message;

  AvailablePaymentMethod({
    this.key = '',
    this.name = '',
    this.label = '',
    this.mode = '',
    this.isEnabled = false,
    this.configuredCurrency,
    this.allowedCurrencies = const [],
    this.requiresAccountApproval = false,
    this.currencyCode,
    this.isAvailable = false,
    this.reasonCode,
    this.message,
  });

  factory AvailablePaymentMethod.fromJson(Map<String, dynamic> json) {
    return AvailablePaymentMethod(
      key: parseString(json['key']) ?? '',
      name: parseString(json['name']) ?? parseString(json['key']) ?? '',
      label: parseString(json['label']) ?? '',
      mode: parseString(json['mode']) ?? '',
      isEnabled: parseBool(json['is_enabled']) ?? false,
      configuredCurrency: parseString(json['configured_currency']),
      allowedCurrencies: (json['allowed_currencies'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      requiresAccountApproval:
          parseBool(json['requires_account_approval']) ?? false,
      currencyCode: parseString(json['currency_code']),
      isAvailable: parseBool(json['is_available']) ?? false,
      reasonCode: parseString(json['reason_code']),
      message: parseString(json['message']),
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'name': name,
        'label': label,
        'mode': mode,
        'is_enabled': isEnabled,
        'configured_currency': configuredCurrency,
        'allowed_currencies': allowedCurrencies,
        'requires_account_approval': requiresAccountApproval,
        'currency_code': currencyCode,
        'is_available': isAvailable,
        'reason_code': reasonCode,
        'message': message,
      };
}

class CartItem {
  final int? id;
  final int? cartId;
  final int? productId;
  final int? productVariantId;
  final int? storeId;
  final int? quantity;
  final bool? saveForLater;
  final Product? product;
  final Variant? variant;
  final Store? store;
  final List<CartItemAddon> addons;
  final double? totalAddonPrice;
  final double? totalItemPrice;
  final double? totalItemSpecialPrice;
  final String? createdAt;
  final String? updatedAt;

  CartItem({
    this.id,
    this.cartId,
    this.productId,
    this.productVariantId,
    this.storeId,
    this.quantity,
    this.saveForLater,
    this.product,
    this.variant,
    this.store,
    this.addons = const [],
    this.totalAddonPrice,
    this.totalItemPrice,
    this.totalItemSpecialPrice,
    this.createdAt,
    this.updatedAt,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: parseInt(json['id']),
      cartId: parseInt(json['cart_id']),
      productId: parseInt(json['product_id']),
      productVariantId: parseInt(json['product_variant_id']),
      storeId: parseInt(json['store_id']),
      quantity: parseInt(json['quantity']),
      saveForLater: parseBool(json['save_for_later']),
      product:
          json['product'] != null ? Product.fromJson(json['product']) : null,
      variant:
          json['variant'] != null ? Variant.fromJson(json['variant']) : null,
      store: json['store'] != null ? Store.fromJson(json['store']) : null,
      addons: _parseCartItemAddons(json['addons']),
      totalAddonPrice: parseDouble(json['addons_total']),
      totalItemPrice: parseDouble(json['total_item_price']),
      totalItemSpecialPrice: parseDouble(json['total_item_special_price']),
      createdAt: parseString(json['created_at']),
      updatedAt: parseString(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'cart_id': cartId,
        'product_id': productId,
        'product_variant_id': productVariantId,
        'store_id': storeId,
        'quantity': quantity,
        'save_for_later': saveForLater,
        if (product != null) 'product': product?.toJson(),
        if (variant != null) 'variant': variant?.toJson(),
        if (store != null) 'store': store?.toJson(),
        'addons': addons.map((e) => e.toJson()).toList(),
        'addons_total': totalAddonPrice,
        'total_item_price': totalItemPrice,
        'total_item_special_price': totalItemSpecialPrice,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  static List<CartItemAddon> _parseCartItemAddons(dynamic value) {
    if (value is! Iterable) return const [];
    return value
        .whereType<Map<String, dynamic>>()
        .map(CartItemAddon.fromJson)
        .toList();
  }
}

/// Addon snapshot attached to a server-side [CartItem].
class CartItemAddon {
  final int? id;
  final String? uuid;
  final int? addonGroupId;
  final int? addonItemId;
  final double? price;
  final CartItemAddonGroup? group;
  final CartItemAddonItem? item;

  CartItemAddon({
    this.id,
    this.uuid,
    this.addonGroupId,
    this.addonItemId,
    this.price,
    this.group,
    this.item,
  });

  factory CartItemAddon.fromJson(Map<String, dynamic> json) {
    return CartItemAddon(
      id: parseInt(json['id']),
      uuid: parseString(json['uuid']),
      addonGroupId: parseInt(json['addon_group_id']),
      addonItemId: parseInt(json['addon_item_id']),
      price: parseDouble(json['price']),
      group: json['group'] != null && json['group'] is Map<String, dynamic>
          ? CartItemAddonGroup.fromJson(json['group'] as Map<String, dynamic>)
          : null,
      item: json['item'] != null && json['item'] is Map<String, dynamic>
          ? CartItemAddonItem.fromJson(json['item'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'uuid': uuid,
        'addon_group_id': addonGroupId,
        'addon_item_id': addonItemId,
        'price': price,
        if (group != null) 'group': group?.toJson(),
        if (item != null) 'item': item?.toJson(),
      };
}

class CartItemAddonGroup {
  final int? id;
  final String? title;
  final String? selectionType;
  final bool? isRequired;

  CartItemAddonGroup({
    this.id,
    this.title,
    this.selectionType,
    this.isRequired,
  });

  factory CartItemAddonGroup.fromJson(Map<String, dynamic> json) {
    return CartItemAddonGroup(
      id: parseInt(json['id']),
      title: parseString(json['title']),
      selectionType: parseString(json['selection_type']),
      isRequired: parseBool(json['is_required']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'selection_type': selectionType,
        'is_required': isRequired,
      };
}

class CartItemAddonItem {
  final int? id;
  final String? title;
  final String? indicator;

  CartItemAddonItem({
    this.id,
    this.title,
    this.indicator,
  });

  factory CartItemAddonItem.fromJson(Map<String, dynamic> json) {
    return CartItemAddonItem(
      id: parseInt(json['id']),
      title: parseString(json['title']),
      indicator: parseString(json['indicator']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'indicator': indicator,
      };
}

class Product {
  final int? id;
  final String? name;
  final String? slug;
  final int? minimumOrderQuantity;
  final int? quantityStepSize;
  final int? totalAllowedQuantity;
  final bool? isAttachmentRequired;
  final String? attachmentMode;
  final String? image;
  final int? estimatedDeliveryTime;
  final String? imageFit;
  final StoreStatus? storeStatus;
  final double? ratings;
  final int? ratingCount;
  final String? currencyCode;

  Product({
    this.id,
    this.name,
    this.slug,
    this.minimumOrderQuantity,
    this.quantityStepSize,
    this.totalAllowedQuantity,
    this.isAttachmentRequired,
    this.attachmentMode,
    this.image,
    this.estimatedDeliveryTime,
    this.imageFit,
    this.storeStatus,
    this.ratings,
    this.ratingCount,
    this.currencyCode,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: parseInt(json['id']),
      name: parseString(json['name']),
      slug: parseString(json['slug']),
      minimumOrderQuantity: parseInt(json['minimum_order_quantity']),
      quantityStepSize: parseInt(json['quantity_step_size']),
      totalAllowedQuantity: parseInt(json['total_allowed_quantity']),
      isAttachmentRequired: parseBool(json['is_attachment_required']),
      attachmentMode: parseString(json['attachment_mode']),
      image: parseString(json['image']),
      estimatedDeliveryTime: parseInt(json['estimated_delivery_time']),
      imageFit: parseString(json['image_fit']),
      storeStatus: json['store_status'] != null
          ? StoreStatus.fromJson(json['store_status'])
          : null,
      ratings: parseDouble(json['ratings']),
      ratingCount: parseInt(json['rating_count']),
      currencyCode: parseString(json['currency_code'] ?? json['currency']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'minimum_order_quantity': minimumOrderQuantity,
        'quantity_step_size': quantityStepSize,
        'total_allowed_quantity': totalAllowedQuantity,
        'is_attachment_required': isAttachmentRequired,
        'attachment_mode': attachmentMode,
        'image': image,
        'estimated_delivery_time': estimatedDeliveryTime,
        'image_fit': imageFit,
        if (storeStatus != null) 'store_status': storeStatus?.toJson(),
        'ratings': ratings,
        'rating_count': ratingCount,
        'currency_code': currencyCode,
      };
}

class Variant {
  final int? id;
  final String? title;
  final String? slug;
  final String? image;
  final double? price;
  final double? specialPrice;
  final int? stock;
  final String? sku;
  final bool? isAddons;
  final String? currencyCode;
  final String? formattedPrice;
  final String? formattedSpecialPrice;

  Variant({
    this.id,
    this.title,
    this.slug,
    this.image,
    this.price,
    this.specialPrice,
    this.stock,
    this.sku,
    this.isAddons,
    this.currencyCode,
    this.formattedPrice,
    this.formattedSpecialPrice,
  });

  factory Variant.fromJson(Map<String, dynamic> json) {
    return Variant(
      id: parseInt(json['id']),
      title: parseString(json['title']),
      slug: parseString(json['slug']),
      image: parseString(json['image']),
      price: parseDouble(json['price']),
      specialPrice: parseDouble(json['special_price']),
      stock: parseInt(json['stock']),
      sku: parseString(json['sku']),
      isAddons: parseBool(json['is_addons']),
      currencyCode: parseString(json['currency_code'] ?? json['currency']),
      formattedPrice: parseString(json['formatted_price']),
      formattedSpecialPrice: parseString(json['formatted_special_price']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'slug': slug,
        'image': image,
        'price': price,
        'special_price': specialPrice,
        'stock': stock,
        'sku': sku,
        'is_addons': isAddons,
        'currency_code': currencyCode,
        'formatted_price': formattedPrice,
        'formatted_special_price': formattedSpecialPrice,
      };
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

class Store {
  final int? id;
  final String? name;
  final String? slug;
  final int? totalProducts;
  final Status? status;
  final bool? allowsPickup;
  final bool? isPickupCodEnabled;
  final String? pickupInstructions;
  final ScheduledDeliveryInfo? scheduledDeliveryInfo;

  Store({
    this.id,
    this.name,
    this.slug,
    this.totalProducts,
    this.status,
    this.allowsPickup,
    this.isPickupCodEnabled,
    this.pickupInstructions,
    this.scheduledDeliveryInfo,
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: parseInt(json['id']),
      name: parseString(json['name']),
      slug: parseString(json['slug']),
      totalProducts: parseInt(json['total_products']),
      status: json['status'] != null ? Status.fromJson(json['status']) : null,
      allowsPickup: parseBool(json['allows_pickup']),
      isPickupCodEnabled: parseBool(json['is_pickup_cod_enabled']),
      pickupInstructions: parseString(json['pickup_instructions']),
      scheduledDeliveryInfo: json['scheduled_delivery_info'] != null
          ? ScheduledDeliveryInfo.fromJson(json['scheduled_delivery_info'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'total_products': totalProducts,
        if (status != null) 'status': status?.toJson(),
        'allows_pickup': allowsPickup,
        'is_pickup_cod_enabled': isPickupCodEnabled,
        'pickup_instructions': pickupInstructions,
        if (scheduledDeliveryInfo != null)
          'scheduled_delivery_info': scheduledDeliveryInfo?.toJson(),
      };
}

class Status {
  final bool? isOpen;
  final String? status;

  Status({
    this.isOpen,
    this.status,
  });

  factory Status.fromJson(Map<String, dynamic> json) {
    return Status(
      isOpen: parseBool(json['is_open']),
      status: parseString(json['status']),
    );
  }

  Map<String, dynamic> toJson() => {
        'is_open': isOpen,
        'status': status,
      };
}

class PaymentSummary {
  final double? itemsTotal;
  final int? perStoreDropOffFee;
  final bool? isRushDelivery;
  final bool? isRushDeliveryAvailable;
  final int? deliveryCharges;
  final double? regularDeliveryCharge;
  final double? rushDeliveryCharge;
  final int? handlingCharges;
  final double? codCharges;
  final dynamic deliveryDistanceCharges;
  final dynamic deliveryDistanceKm;
  final int? totalStores;
  final dynamic totalDeliveryCharges;
  final int? estimatedDeliveryTime;
  final bool? useWallet;
  final String? promoCode;
  final String? promoDiscount;
  final PromoCodeData? promoApplied;
  final String? promoError;
  final dynamic walletBalance;
  final double? walletAmountUsed;
  final dynamic payableAmount;
  final double? riderTipAmount;
  final LoyaltySummary? loyaltySummary;

  PaymentSummary({
    this.itemsTotal,
    this.perStoreDropOffFee,
    this.isRushDelivery,
    this.isRushDeliveryAvailable,
    this.deliveryCharges,
    this.regularDeliveryCharge,
    this.rushDeliveryCharge,
    this.handlingCharges,
    this.codCharges,
    this.deliveryDistanceCharges,
    this.deliveryDistanceKm,
    this.totalStores,
    this.totalDeliveryCharges,
    this.estimatedDeliveryTime,
    this.useWallet,
    this.promoCode,
    this.promoDiscount,
    this.promoApplied,
    this.promoError,
    this.walletBalance,
    this.walletAmountUsed,
    this.payableAmount,
    this.riderTipAmount,
    this.loyaltySummary,
  });

  factory PaymentSummary.fromJson(Map<String, dynamic> json) {
    return PaymentSummary(
      itemsTotal: parseDouble(json['items_total']),
      perStoreDropOffFee: parseInt(json['per_store_drop_off_fee']),
      isRushDelivery: parseBool(json['is_rush_delivery']),
      isRushDeliveryAvailable: parseBool(json['is_rush_delivery_available']),
      deliveryCharges: parseInt(json['delivery_charges']),
      regularDeliveryCharge: parseDouble(json['regular_delivery_charge']),
      rushDeliveryCharge: parseDouble(json['rush_delivery_charge']),
      handlingCharges: parseInt(json['handling_charges']),
      codCharges: parseDouble(json['cod_charges']),
      deliveryDistanceCharges: json['delivery_distance_charges'],
      deliveryDistanceKm: json['delivery_distance_km'],
      totalStores: parseInt(json['total_stores']),
      totalDeliveryCharges: json['total_delivery_charges'],
      estimatedDeliveryTime: parseInt(json['estimated_delivery_time']),
      useWallet: parseBool(json['use_wallet']),
      promoCode: parseString(json['promo_code']),
      promoDiscount: parseString(json['promo_discount']),
      promoApplied: _parsePromoApplied(json['promo_applied']),
      promoError: parseString(json['promo_error']),
      walletBalance: json['wallet_balance'],
      walletAmountUsed: parseDouble(json['wallet_amount_used']),
      payableAmount: json['payable_amount'],
      riderTipAmount: parseDouble(json['rider_tip_amount']),
      loyaltySummary: json['loyalty_summary'] != null
          ? LoyaltySummary.fromJson(json['loyalty_summary'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'items_total': itemsTotal,
        'per_store_drop_off_fee': perStoreDropOffFee,
        'is_rush_delivery': isRushDelivery,
        'is_rush_delivery_available': isRushDeliveryAvailable,
        'delivery_charges': deliveryCharges,
        'regular_delivery_charge': regularDeliveryCharge,
        'rush_delivery_charge': rushDeliveryCharge,
        'handling_charges': handlingCharges,
        'cod_charges': codCharges,
        'delivery_distance_charges': deliveryDistanceCharges,
        'delivery_distance_km': deliveryDistanceKm,
        'total_stores': totalStores,
        'total_delivery_charges': totalDeliveryCharges,
        'estimated_delivery_time': estimatedDeliveryTime,
        'use_wallet': useWallet,
        'promo_code': promoCode,
        'promo_discount': promoDiscount,
        if (promoApplied != null) 'promo_applied': promoApplied?.toJson(),
        'promo_error': promoError,
        'wallet_balance': walletBalance,
        'wallet_amount_used': walletAmountUsed,
        'payable_amount': payableAmount,
        'rider_tip_amount': riderTipAmount,
        if (loyaltySummary != null) 'loyalty_summary': loyaltySummary?.toJson(),
      };

  static PromoCodeData? _parsePromoApplied(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) {
      return PromoCodeData.fromJson(value);
    }
    if (value is List && value.isNotEmpty && value.first is Map) {
      return PromoCodeData.fromJson(value.first as Map<String, dynamic>);
    }
    return null;
  }
}

class RemovedItem {
  final String? productName;
  final String? variantName;
  final String? storeName;
  final int? quantity;
  final String? reason;

  RemovedItem({
    this.productName,
    this.variantName,
    this.storeName,
    this.quantity,
    this.reason,
  });

  factory RemovedItem.fromJson(Map<String, dynamic> json) {
    return RemovedItem(
      productName: parseString(json['product_name']),
      variantName: parseString(json['variant_name']),
      storeName: parseString(json['store_name']),
      quantity: parseInt(json['quantity']),
      reason: parseString(json['reason']),
    );
  }

  Map<String, dynamic> toJson() => {
        'product_name': productName,
        'variant_name': variantName,
        'store_name': storeName,
        'quantity': quantity,
        'reason': reason,
      };
}

class DeliveryZone {
  final bool? exists;
  final String? zone;
  final int? zoneCount;
  final int? zoneId;
  final int? handlingCharges;
  final int? deliveryTimePerKm;
  final bool? rushDeliveryEnabled;
  final int? rushDeliveryTimePerKm;
  final int? rushDeliveryCharges;
  final int? regularDeliveryCharges;
  final int? freeDeliveryAmount;
  final int? distanceBasedDeliveryCharges;
  final int? perStoreDropOffFee;
  final int? bufferTime;
  final bool? rushDeliveryAvailable;

  DeliveryZone({
    this.exists,
    this.zone,
    this.zoneCount,
    this.zoneId,
    this.handlingCharges,
    this.deliveryTimePerKm,
    this.rushDeliveryEnabled,
    this.rushDeliveryTimePerKm,
    this.rushDeliveryCharges,
    this.regularDeliveryCharges,
    this.freeDeliveryAmount,
    this.distanceBasedDeliveryCharges,
    this.perStoreDropOffFee,
    this.bufferTime,
    this.rushDeliveryAvailable,
  });

  factory DeliveryZone.fromJson(Map<String, dynamic> json) {
    return DeliveryZone(
      exists: parseBool(json['exists']),
      zone: parseString(json['zone']),
      zoneCount: parseInt(json['zone_count']),
      zoneId: parseInt(json['zone_id']),
      handlingCharges: parseInt(json['handling_charges']),
      deliveryTimePerKm: parseInt(json['delivery_time_per_km']),
      rushDeliveryEnabled: parseBool(json['rush_delivery_enabled']),
      rushDeliveryTimePerKm: parseInt(json['rush_delivery_time_per_km']),
      rushDeliveryCharges: parseInt(json['rush_delivery_charges']),
      regularDeliveryCharges: parseInt(json['regular_delivery_charges']),
      freeDeliveryAmount: parseInt(json['free_delivery_amount']),
      distanceBasedDeliveryCharges:
          parseInt(json['distance_based_delivery_charges']),
      perStoreDropOffFee: parseInt(json['per_store_drop_off_fee']),
      bufferTime: parseInt(json['buffer_time']),
      rushDeliveryAvailable: parseBool(json['rush_delivery_available']),
    );
  }

  Map<String, dynamic> toJson() => {
        'exists': exists,
        'zone': zone,
        'zone_count': zoneCount,
        'zone_id': zoneId,
        'handling_charges': handlingCharges,
        'delivery_time_per_km': deliveryTimePerKm,
        'rush_delivery_enabled': rushDeliveryEnabled,
        'rush_delivery_time_per_km': rushDeliveryTimePerKm,
        'rush_delivery_charges': rushDeliveryCharges,
        'regular_delivery_charges': regularDeliveryCharges,
        'free_delivery_amount': freeDeliveryAmount,
        'distance_based_delivery_charges': distanceBasedDeliveryCharges,
        'per_store_drop_off_fee': perStoreDropOffFee,
        'buffer_time': bufferTime,
        'rush_delivery_available': rushDeliveryAvailable,
      };
}

class DeliverySlot {
  final int? id;
  final String? label;
  final String? startTime;
  final String? endTime;
  final int? remainingCapacity;
  final bool? maxOrdersReached;
  final bool? isActive;
  final bool? isAvailable;
  final String? reason;

  DeliverySlot({
    this.id,
    this.label,
    this.startTime,
    this.endTime,
    this.remainingCapacity,
    this.maxOrdersReached,
    this.isActive,
    this.isAvailable,
    this.reason,
  });

  factory DeliverySlot.fromJson(Map<String, dynamic> json) {
    return DeliverySlot(
      id: parseInt(json['id']),
      label: parseString(json['label']),
      startTime: parseString(json['start_time']),
      endTime: parseString(json['end_time']),
      remainingCapacity: parseInt(json['remaining_capacity']),
      maxOrdersReached: parseBool(json['max_orders_reached']),
      isActive: parseBool(json['is_active']),
      isAvailable: parseBool(json['is_available']),
      reason: parseString(json['reason']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'start_time': startTime,
        'end_time': endTime,
        'remaining_capacity': remainingCapacity,
        'max_orders_reached': maxOrdersReached,
        'is_active': isActive,
        'is_available': isAvailable,
        'reason': reason,
      };
}

class ScheduledDeliveryInfo {
  final bool? isEnabled;
  final int? maxDays;
  final int? maxAdvanceBookingDays;
  final int? bufferMinutes;
  final List<String>? availableDays;
  final List<DeliverySlot>? slots;

  ScheduledDeliveryInfo({
    this.isEnabled,
    this.maxDays,
    this.maxAdvanceBookingDays,
    this.bufferMinutes,
    this.availableDays,
    this.slots,
  });

  factory ScheduledDeliveryInfo.fromJson(Map<String, dynamic> json) {
    return ScheduledDeliveryInfo(
      isEnabled: parseBool(json['is_enabled']),
      maxDays: parseInt(json['max_days'] ?? json['max_advance_booking_days']),
      maxAdvanceBookingDays: parseInt(json['max_advance_booking_days']),
      bufferMinutes: parseInt(json['buffer_minutes']),
      availableDays: json['available_days'] != null
          ? List<String>.from(json['available_days'].map((x) => parseString(x)))
          : null,
      slots: json['slots'] != null
          ? List<DeliverySlot>.from(
              json['slots'].map(
                  (x) => DeliverySlot.fromJson(Map<String, dynamic>.from(x))),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'is_enabled': isEnabled,
        'max_days': maxDays,
        'max_advance_booking_days': maxAdvanceBookingDays,
        'buffer_minutes': bufferMinutes,
        'available_days': availableDays != null
            ? List<dynamic>.from(availableDays!.map((x) => x))
            : null,
        'slots': slots != null
            ? List<dynamic>.from(slots!.map((x) => x.toJson()))
            : null,
      };
}

class LoyaltySummary {
  final bool? isLoyaltyEnabled;
  final int? userPointsBalance;
  final double? minOrderValueToRedeem;
  final bool? isEligibleForRedemption;
  final int? maxPointsRedeemable;
  final int? loyaltyPointsRedeemed;
  final double? loyaltyPointsDiscountAmount;
  final double? potentialPointsToEarn;

  LoyaltySummary({
    this.isLoyaltyEnabled,
    this.userPointsBalance,
    this.minOrderValueToRedeem,
    this.isEligibleForRedemption,
    this.maxPointsRedeemable,
    this.loyaltyPointsRedeemed,
    this.loyaltyPointsDiscountAmount,
    this.potentialPointsToEarn,
  });

  factory LoyaltySummary.fromJson(Map<String, dynamic> json) {
    return LoyaltySummary(
      isLoyaltyEnabled: parseBool(json['is_loyalty_enabled']),
      userPointsBalance: parseInt(json['user_points_balance']),
      minOrderValueToRedeem: parseDouble(json['min_order_value_to_redeem']),
      isEligibleForRedemption: parseBool(json['is_eligible_for_redemption']),
      maxPointsRedeemable: parseInt(json['max_points_redeemable']),
      loyaltyPointsRedeemed: parseInt(json['loyalty_points_redeemed']),
      loyaltyPointsDiscountAmount: parseDouble(json['loyalty_points_discount_amount']),
      potentialPointsToEarn: parseDouble(json['potential_points_to_earn']),
    );
  }

  Map<String, dynamic> toJson() => {
        'is_loyalty_enabled': isLoyaltyEnabled,
        'user_points_balance': userPointsBalance,
        'min_order_value_to_redeem': minOrderValueToRedeem,
        'is_eligible_for_redemption': isEligibleForRedemption,
        'max_points_redeemable': maxPointsRedeemable,
        'loyalty_points_redeemed': loyaltyPointsRedeemed,
        'loyalty_points_discount_amount': loyaltyPointsDiscountAmount,
        'potential_points_to_earn': potentialPointsToEarn,
      };
}
