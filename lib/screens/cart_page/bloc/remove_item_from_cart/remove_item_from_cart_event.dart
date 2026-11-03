import 'package:equatable/equatable.dart';

abstract class RemoveItemFromCartEvent extends Equatable {
  @override
  
  List<Object?> get props => [];
}

class RemoveItemFromCartRequest extends RemoveItemFromCartEvent{
  final int cartItemId;

  RemoveItemFromCartRequest({required this.cartItemId});

  @override
  
  List<Object?> get props => [cartItemId];
}
