part of 'wishlist_product_bloc.dart';

abstract class WishlistProductEvent extends Equatable {
  @override
  
  List<Object?> get props => [];
}

class FetchWishlistProductData extends WishlistProductEvent {
  final int wishlistId;
  FetchWishlistProductData({required this.wishlistId});

  @override
  
  List<Object?> get props => [wishlistId];
}


class RemoveProductLocally extends WishlistProductEvent {
  final int itemId;
  RemoveProductLocally({required this.itemId});

  @override
  
  List<Object?> get props => [itemId];
}