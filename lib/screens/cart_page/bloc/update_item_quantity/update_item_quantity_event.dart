import 'package:equatable/equatable.dart';

abstract class UpdateItemQuantityEvent extends Equatable {
  @override
  
  List<Object?> get props => [];
}

class UpdateItemQuantityRequest extends UpdateItemQuantityEvent{
  final int cartItemId;
  final int quantity;

  UpdateItemQuantityRequest({
    required this.cartItemId,
    required this.quantity
  });

  @override
  
  List<Object?> get props => [cartItemId, quantity];
}
