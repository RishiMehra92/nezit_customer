import 'package:equatable/equatable.dart';

abstract class AddToCartEvent extends Equatable {
  @override
  
  List<Object?> get props => [];
}

class AddItemToCart extends AddToCartEvent{
  final int productVariantId;
  final int storeId;
  final int quantity;

  AddItemToCart({required this.productVariantId, required this.storeId, required this.quantity});

  @override
  
  List<Object?> get props => [productVariantId, storeId, quantity];
}
