part of 'get_user_cart_bloc.dart';

abstract class GetUserCartEvent extends Equatable {
  @override
  
  List<Object?> get props => [];
}

class FetchUserCart extends GetUserCartEvent {
  final int? addressId;
  final String? promoCode;
  final bool? rushDelivery;
  final bool? useWallet;
  final bool? isRefresh;
  /// When true, skip emitting [GetUserCartLoading] so the UI does not.
  final bool silent;
  final bool reconcileImportedCart;
  final String? deliveryType;
  final bool? useLoyaltyPoints;

  FetchUserCart({
    this.addressId,
    this.promoCode,
    this.rushDelivery,
    this.useWallet,
    this.isRefresh = false,
    this.silent = false,
    this.reconcileImportedCart = false,
    this.deliveryType,
    this.useLoyaltyPoints,
  });

  @override
  List<Object?> get props => [
        addressId,
        promoCode,
        rushDelivery,
        useWallet,
        isRefresh,
        silent,
        reconcileImportedCart,
        deliveryType,
        useLoyaltyPoints,
      ];
}

class RefreshUserCart extends GetUserCartEvent {
  final int? addressId;
  final String? promoCode;
  final bool? rushDelivery;
  final bool? useWallet;
  final bool? isRefresh;
  final String? deliveryType;
  final bool? useLoyaltyPoints;

  RefreshUserCart({
    this.addressId,
    this.promoCode,
    this.rushDelivery,
    this.useWallet,
    this.isRefresh = true,
    this.deliveryType,
    this.useLoyaltyPoints,
  });

  @override
  List<Object?> get props => [addressId, promoCode, rushDelivery, useWallet, isRefresh, deliveryType, useLoyaltyPoints];
}

class UpdateUserCart extends GetUserCartEvent {
  final int? addressId;
  final String? promoCode;
  final bool? rushDelivery;
  final bool? useWallet;
  final String? deliveryType;
  final bool? useLoyaltyPoints;

  UpdateUserCart({
    this.addressId,
    this.promoCode,
    this.rushDelivery,
    this.useWallet,
    this.deliveryType,
    this.useLoyaltyPoints,
  });

  @override
  List<Object?> get props => [addressId, promoCode, rushDelivery, useWallet, deliveryType, useLoyaltyPoints];
}

class FallbackToRegularDelivery extends GetUserCartEvent {
  final int? addressId;

  FallbackToRegularDelivery({this.addressId});
}

class SyncCart extends GetUserCartEvent {}

class SyncServerCartToLocal extends GetUserCartEvent {
  final List<Map<String, dynamic>> serverItems;

  SyncServerCartToLocal({required this.serverItems});
}

/// Optimistic UI: patch the last-known server [CartModel] with fresh.
class ApplyLocalCartPatch extends GetUserCartEvent {
  final List<UserCart> localItems;

  ApplyLocalCartPatch({required this.localItems});

  @override
  List<Object?> get props => [localItems];
}

class SetCartTipEvent extends GetUserCartEvent {
  final int? cartId;
  final double tipAmount;

  SetCartTipEvent({
    required this.cartId,
    required this.tipAmount,
  });

  @override
  List<Object?> get props => [cartId, tipAmount];
}

